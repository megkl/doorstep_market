enum UserRole {
  buyer('Buyer', 'Browse and buy items from verified neighbors'),
  seller('Seller / Renter', 'List items for sale or rent in your community'),
  landlord(
    'Property Manager',
    'Manage one or more properties and their communities',
  );

  const UserRole(this.label, this.description);
  final String label;
  final String description;
}

class Apartment {
  const Apartment({
    required this.id,
    required this.name,
    required this.invitationCode,
  });

  final String id;
  final String name;
  final String invitationCode;
}

class UserAccess {
  const UserAccess({this.role, this.apartment, this.approved = false});

  final UserRole? role;
  final Apartment? apartment;
  final bool approved;

  bool get requiresSetup => role == null || !approved;
}

class MarketplaceListing {
  const MarketplaceListing({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.isRental,
    required this.active,
  });

  factory MarketplaceListing.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final price = data['price'];
    final rental = data['listingType'] == 'rent';
    return MarketplaceListing(
      id: id,
      title: data['title'] as String? ?? 'Untitled item',
      priceLabel: rental ? 'KSh ${price ?? 0} / day' : 'KSh ${price ?? 0}',
      isRental: rental,
      active: data['active'] as bool? ?? true,
    );
  }

  final String id;
  final String title;
  final String priceLabel;
  final bool isRental;
  final bool active;
}
