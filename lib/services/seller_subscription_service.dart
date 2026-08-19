import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

const sellerAdvertisingProductId = 'seller_advertising_weekly';

class SellerSubscriptionService {
  SellerSubscriptionService._();

  static final instance = SellerSubscriptionService._();

  final _store = InAppPurchase.instance;
  final _outcomes = StreamController<SellerSubscriptionOutcome>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchases;
  ProductDetails? _product;

  Stream<SellerSubscriptionOutcome> get outcomes => _outcomes.stream;
  ProductDetails? get product => _product;

  Future<ProductDetails?> loadProduct({bool restore = true}) async {
    _purchases ??= _store.purchaseStream.listen(_handlePurchases);
    if (!await _store.isAvailable()) return null;
    final response = await _store.queryProductDetails({
      sellerAdvertisingProductId,
    });
    if (response.error != null || response.productDetails.isEmpty) return null;

    _product = _selectTrialOffer(response.productDetails);
    if (restore) unawaited(_store.restorePurchases());
    return _product;
  }

  ProductDetails _selectTrialOffer(List<ProductDetails> products) {
    if (!Platform.isAndroid) return products.first;
    return products.cast<GooglePlayProductDetails>().firstWhere((product) {
      final index = product.subscriptionIndex;
      final offers = product.productDetails.subscriptionOfferDetails;
      if (index == null || offers == null) return false;
      return offers[index].pricingPhases.any(
        (phase) => phase.priceAmountMicros == 0,
      );
    }, orElse: () => products.cast<GooglePlayProductDetails>().first);
  }

  String? get recurringPrice {
    final product = _product;
    if (product is! GooglePlayProductDetails) return product?.price;
    final index = product.subscriptionIndex;
    final offers = product.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null) return product.price;
    final paidPhases = offers[index].pricingPhases.where(
      (phase) => phase.priceAmountMicros > 0,
    );
    return paidPhases.isEmpty ? product.price : paidPhases.last.formattedPrice;
  }

  Future<bool> subscribe() async {
    final product = _product ?? await loadProduct(restore: false);
    if (product == null) return false;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final accountHash = sha256.convert(utf8.encode(uid)).toString();
    final purchaseParam =
        Platform.isAndroid && product is GooglePlayProductDetails
        ? GooglePlayPurchaseParam(
            productDetails: product,
            offerToken: product.offerToken,
            applicationUserName: accountHash,
          )
        : PurchaseParam(
            productDetails: product,
            applicationUserName: accountHash,
          );
    return _store.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != sellerAdvertisingProductId) continue;
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _outcomes.add(
          SellerSubscriptionOutcome(
            purchaseId:
                purchase.purchaseID ??
                purchase.verificationData.serverVerificationData,
            successful: true,
            purchase: purchase,
          ),
        );
      } else if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        _outcomes.add(
          SellerSubscriptionOutcome(
            purchaseId: purchase.purchaseID ?? '',
            successful: false,
            purchase: purchase,
          ),
        );
      }
      if (purchase.pendingCompletePurchase &&
          purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        await _store.completePurchase(purchase);
      }
    }
  }

  Future<void> complete(SellerSubscriptionOutcome outcome) async {
    if (outcome.purchase.pendingCompletePurchase) {
      await _store.completePurchase(outcome.purchase);
    }
  }
}

class SellerSubscriptionOutcome {
  const SellerSubscriptionOutcome({
    required this.purchaseId,
    required this.successful,
    required this.purchase,
  });

  final String purchaseId;
  final bool successful;
  final PurchaseDetails purchase;

  bool get restored => purchase.status == PurchaseStatus.restored;

  String get verificationToken =>
      purchase.verificationData.serverVerificationData;
}
