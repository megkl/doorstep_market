import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

const listingBoostProductId = 'listing_boost_7_day';

class ListingBoostService {
  ListingBoostService._();

  static final instance = ListingBoostService._();

  final _store = InAppPurchase.instance;
  final _outcomes = StreamController<BoostPurchaseOutcome>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchases;
  ProductDetails? _product;
  String? _pendingListingId;

  Stream<BoostPurchaseOutcome> get outcomes => _outcomes.stream;
  ProductDetails? get product => _product;

  Future<ProductDetails?> loadProduct() async {
    _purchases ??= _store.purchaseStream.listen(_handlePurchases);
    if (!await _store.isAvailable()) return null;
    final response = await _store.queryProductDetails({listingBoostProductId});
    if (response.error != null || response.productDetails.isEmpty) return null;
    return _product = response.productDetails.first;
  }

  Future<bool> buyFor(String listingId) async {
    final product = _product ?? await loadProduct();
    if (product == null) return false;
    _pendingListingId = listingId;
    return _store.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != listingBoostProductId) continue;
      final listingId = _pendingListingId;
      if (purchase.status == PurchaseStatus.purchased && listingId != null) {
        _outcomes.add(
          BoostPurchaseOutcome(
            listingId: listingId,
            purchaseId:
                purchase.purchaseID ??
                purchase.verificationData.serverVerificationData,
            successful: true,
            purchase: purchase,
          ),
        );
        _pendingListingId = null;
      } else if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        _outcomes.add(
          BoostPurchaseOutcome(
            listingId: listingId,
            purchaseId: purchase.purchaseID ?? '',
            successful: false,
            purchase: purchase,
          ),
        );
        _pendingListingId = null;
      }
      if (purchase.pendingCompletePurchase &&
          purchase.status != PurchaseStatus.purchased) {
        await _store.completePurchase(purchase);
      }
    }
  }

  Future<void> complete(BoostPurchaseOutcome outcome) async {
    if (outcome.purchase.pendingCompletePurchase) {
      await _store.completePurchase(outcome.purchase);
    }
  }
}

class BoostPurchaseOutcome {
  const BoostPurchaseOutcome({
    required this.listingId,
    required this.purchaseId,
    required this.successful,
    required this.purchase,
  });

  final String? listingId;
  final String purchaseId;
  final bool successful;
  final PurchaseDetails purchase;
}
