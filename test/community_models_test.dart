import 'package:doorstep_market/models/community_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expired seller plan makes a listing unavailable for browsing', () {
    final listing = MarketplaceListing(
      id: 'listing-1',
      title: 'Chair',
      priceLabel: 'KSh 500',
      price: 500,
      isRental: false,
      active: true,
      description: 'A chair',
      category: 'Furniture',
      condition: 'Used',
      sellerId: 'seller-1',
      sellerName: 'Seller',
      imageUrls: const [],
      pickupHouseNumber: '',
      promotedUntil: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    expect(listing.sellerPlanActive, isFalse);
  });

  test('rental listing retains availability and deposit', () {
    final from = DateTime(2026, 8, 12);
    final to = DateTime(2026, 8, 19);
    final listing = MarketplaceListing(
      id: 'rental-1',
      title: 'Drill',
      priceLabel: 'KSh 200 / day',
      price: 200,
      isRental: true,
      active: true,
      description: 'Power drill',
      category: 'Other',
      condition: 'Used',
      sellerId: 'seller-1',
      sellerName: 'Seller',
      imageUrls: const [],
      pickupHouseNumber: '',
      promotedUntil: DateTime.now().add(const Duration(days: 1)),
      securityDeposit: 1000,
      availableFrom: from,
      availableTo: to,
    );

    expect(listing.sellerPlanActive, isTrue);
    expect(listing.availableFrom, from);
    expect(listing.availableTo, to);
    expect(listing.securityDeposit, 1000);
  });
}
