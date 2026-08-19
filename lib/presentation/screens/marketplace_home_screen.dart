import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community_models.dart';
import '../../state/auth_providers.dart';
import 'marketplace_action_screens.dart';
import 'marketplace_tabs.dart';
import 'community_feature_screens.dart';
import 'order_profile_screens.dart';
import 'splash_screen.dart';

class MarketplaceHomeScreen extends ConsumerStatefulWidget {
  const MarketplaceHomeScreen({super.key, this.apartment});

  final Apartment? apartment;

  @override
  ConsumerState<MarketplaceHomeScreen> createState() =>
      _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends ConsumerState<MarketplaceHomeScreen> {
  int _tab = 0;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openBuy() {
    final apartment = widget.apartment;
    if (apartment == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BuyScreen(apartment: apartment)),
    );
  }

  void _openListing(bool rental) {
    final apartment = widget.apartment;
    if (apartment == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ListingFormScreen(apartment: apartment, isRental: rental),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: switch (_tab) {
        1 => CategoriesScreen(apartment: widget.apartment),
        3 => ChatsScreen(apartment: widget.apartment),
        4 => ProfileScreen(apartment: widget.apartment),
        _ => SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                sliver: SliverList.list(
                  children: [
                    _HomeHeader(apartment: widget.apartment),
                    const SizedBox(height: 19),
                    _SearchBar(
                      controller: _searchController,
                      query: _searchQuery,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value.trim()),
                      onBrowseCategories: () => setState(() => _tab = 1),
                    ),
                    const SizedBox(height: 18),
                    _PromoBanner(onListItem: () => _openListing(false)),
                    const SizedBox(height: 18),
                    _QuickActions(
                      onBuy: _openBuy,
                      onSell: () => _openListing(false),
                      onRent: () => _openListing(true),
                      onCategories: () => setState(() => _tab = 1),
                    ),
                    const SizedBox(height: 25),
                    _ApartmentListings(
                      apartment: widget.apartment,
                      query: _searchQuery,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openListing(false),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 4),
        ),
        child: const Icon(Icons.add_rounded, size: 29),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 78,
        padding: EdgeInsets.zero,
        color: Colors.white,
        elevation: 18,
        shadowColor: Colors.black38,
        notchMargin: 7,
        shape: const CircularNotchedRectangle(),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Home',
              selected: _tab == 0,
              onTap: () => setState(() => _tab = 0),
            ),
            _NavItem(
              icon: Icons.grid_view_outlined,
              selectedIcon: Icons.grid_view_rounded,
              label: 'Categories',
              selected: _tab == 1,
              onTap: () => setState(() => _tab = 1),
            ),
            const SizedBox(width: 62),
            _UnreadMessagesNavItem(
              apartment: widget.apartment,
              selected: _tab == 3,
              onTap: () => setState(() => _tab = 3),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'Profile',
              selected: _tab == 4,
              onTap: () => setState(() => _tab = 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.apartment});

  final Apartment? apartment;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: primaryGreen,
                    size: 19,
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      apartment?.name ?? 'Your Apartment',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 19),
                ],
              ),
              SizedBox(height: 15),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Doorstep\n',
                      style: TextStyle(color: primaryGreen),
                    ),
                    TextSpan(text: 'Market'),
                  ],
                ),
                style: TextStyle(
                  fontSize: 27,
                  height: .85,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                ),
              ),
            ],
          ),
        ),
        const _NotificationButton(),
        _ReservationCartButton(apartment: apartment),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    final uid = Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser?.uid;
    final button = IconButton(
      tooltip: 'Notifications',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      ),
      icon: const Icon(
        Icons.notifications_none_rounded,
        color: Colors.black,
        size: 27,
      ),
    );
    if (uid == null) return SizedBox.square(dimension: 48, child: button);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .snapshots(),
      builder: (context, snapshot) {
        final unread = snapshot.data?.docs
            .where((item) => item.data()['read'] != true)
            .length;
        return _HeaderActionBadge(count: unread ?? 0, child: button);
      },
    );
  }
}

class _HeaderActionBadge extends StatelessWidget {
  const _HeaderActionBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 48,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: child),
        if (count > 0)
          Positioned(
            right: 1,
            top: 1,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18),
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFF04F38),
                borderRadius: BorderRadius.all(Radius.circular(9)),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _ReservationCartButton extends StatelessWidget {
  const _ReservationCartButton({required this.apartment});

  final Apartment? apartment;

  @override
  Widget build(BuildContext context) {
    final currentApartment = apartment;
    final uid = Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser?.uid;
    final icon = IconButton(
      tooltip: 'My reservations',
      onPressed: currentApartment == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MyOrdersScreen(apartment: currentApartment),
              ),
            ),
      icon: const Icon(
        Icons.shopping_cart_outlined,
        color: primaryGreen,
        size: 31,
      ),
    );
    if (currentApartment == null || uid == null) return icon;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('apartments')
          .doc(currentApartment.id)
          .collection('reservations')
          .where('buyerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        const activeStatuses = <String>{
          'pending',
          'accepted',
          'ready_for_pickup',
        };
        final count = snapshot.data?.docs
            .where(
              (reservation) => activeStatuses.contains(
                reservation.data()['status'] as String?,
              ),
            )
            .length;
        final activeCount = count ?? 0;
        return _HeaderActionBadge(count: activeCount, child: icon);
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onBrowseCategories,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onBrowseCategories;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search items, e.g. sofa, microwave...',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8B918D),
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 22),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFDDE1DE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: primaryGreen),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        InkWell(
          onTap: onBrowseCategories,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onListItem});

  final VoidCallback onListItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF148F51), Color(0xFF08733F)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            bottom: -18,
            width: 190,
            height: 138,
            child: Image.asset(
              'assets/images/onboarding/community.png',
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buy, sell or rent\nitems within your\ncommunity.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 34,
                  child: FilledButton(
                    onPressed: onListItem,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: const Text(
                      'List an Item',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onBuy,
    required this.onSell,
    required this.onRent,
    required this.onCategories,
  });

  final VoidCallback onBuy;
  final VoidCallback onSell;
  final VoidCallback onRent;
  final VoidCallback onCategories;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickAction(
          icon: Icons.shopping_bag_outlined,
          label: 'Buy',
          color: primaryGreen,
          background: const Color(0xFFF0F8F3),
          onTap: onBuy,
        ),
        const SizedBox(width: 9),
        _QuickAction(
          icon: Icons.sell_outlined,
          label: 'Sell',
          color: const Color(0xFF459D56),
          background: const Color(0xFFF3F9F1),
          onTap: onSell,
        ),
        const SizedBox(width: 9),
        _QuickAction(
          icon: Icons.calendar_month_outlined,
          label: 'Rent',
          color: const Color(0xFFF29B20),
          background: const Color(0xFFFFF7E9),
          onTap: onRent,
        ),
        const SizedBox(width: 9),
        _QuickAction(
          icon: Icons.grid_view_rounded,
          label: 'Categories',
          color: const Color(0xFF6263D8),
          background: const Color(0xFFF3F2FF),
          onTap: onCategories,
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 86,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 29),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      if (onSeeAll != null)
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: const Text(
            'See all',
            style: TextStyle(
              color: primaryGreen,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
    ],
  );
}

class _ApartmentListings extends ConsumerWidget {
  const _ApartmentListings({required this.apartment, required this.query});

  final Apartment? apartment;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentApartment = apartment;
    if (currentApartment == null) {
      return const _EmptyListings(
        message: 'Verify your apartment to view its marketplace.',
      );
    }
    return StreamBuilder<List<MarketplaceListing>>(
      stream: ref
          .read(communityServiceProvider)
          .watchApartmentListings(currentApartment.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _EmptyListings(
            message: 'Could not load this apartment’s listings.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: primaryGreen),
            ),
          );
        }
        final normalizedQuery = query.toLowerCase();
        final listings = snapshot.data!.where((item) {
          if (normalizedQuery.isEmpty) return true;
          return <String>[
            item.title,
            item.category,
            item.description,
            item.condition,
            item.sellerName,
            item.price.toString(),
            item.priceLabel,
          ].any((value) => value.toLowerCase().contains(normalizedQuery));
        }).toList();
        if (listings.isEmpty) {
          return _EmptyListings(
            message: normalizedQuery.isEmpty
                ? 'No items have been listed in this apartment yet.'
                : 'No listings match “$query”.',
          );
        }
        if (normalizedQuery.isNotEmpty) {
          return Column(
            children: [
              _SectionHeader(
                title:
                    '${listings.length} search result${listings.length == 1 ? '' : 's'}',
              ),
              const SizedBox(height: 12),
              _ListingRow(listings: listings, apartment: currentApartment),
            ],
          );
        }
        final sales = listings.where((item) => !item.isRental).toList();
        final rentals = listings.where((item) => item.isRental).toList();
        return Column(
          children: [
            if (sales.isNotEmpty) ...[
              _SectionHeader(
                title: 'Available in Your Apartment',
                onSeeAll: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _AllListingsScreen(
                      apartment: currentApartment,
                      rentals: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ListingRow(
                listings: sales,
                apartment: currentApartment,
                limit: 4,
              ),
            ],
            if (sales.isNotEmpty && rentals.isNotEmpty)
              const SizedBox(height: 28),
            if (rentals.isNotEmpty) ...[
              _SectionHeader(
                title: 'Recent Rentals',
                onSeeAll: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _AllListingsScreen(
                      apartment: currentApartment,
                      rentals: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ListingRow(
                listings: rentals,
                apartment: currentApartment,
                limit: 4,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ListingRow extends StatelessWidget {
  const _ListingRow({
    required this.listings,
    required this.apartment,
    this.limit,
  });

  final List<MarketplaceListing> listings;
  final Apartment apartment;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final itemCount = limit == null
        ? listings.length
        : listings.length.clamp(0, limit!);
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: 224,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, index) => SizedBox(
            width: (constraints.maxWidth - 10) / 2,
            child: _HomeProductCard(
              item: listings[index],
              apartment: apartment,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeProductCard extends StatelessWidget {
  const _HomeProductCard({required this.item, required this.apartment});

  final MarketplaceListing item;
  final Apartment apartment;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ReservationScreen(apartment: apartment, listing: item),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8E4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.imageUrls.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFFE7F2EB),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: primaryGreen,
                            size: 46,
                          ),
                        )
                      : Image.network(item.imageUrls.first, fit: BoxFit.cover),
                  Positioned(
                    left: 7,
                    top: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: item.isRental
                            ? const Color(0xFF244C8A)
                            : primaryGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.isRental ? 'For rent' : 'For sale',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.condition,
                    style: const TextStyle(color: Colors.black54, fontSize: 10),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.priceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AllListingsScreen extends ConsumerStatefulWidget {
  const _AllListingsScreen({required this.apartment, required this.rentals});

  final Apartment apartment;
  final bool rentals;

  @override
  ConsumerState<_AllListingsScreen> createState() => _AllListingsScreenState();
}

class _AllListingsScreenState extends ConsumerState<_AllListingsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9F7),
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: Text(
        widget.rentals ? 'All Rentals' : 'All Items for Sale',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value.trim()),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: widget.rentals
                  ? 'Search rentals by item or price...'
                  : 'Search items by name or price...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: const Color(0xFFF4F7F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryGreen),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<MarketplaceListing>>(
            stream: ref
                .read(communityServiceProvider)
                .watchApartmentListings(widget.apartment.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _EmptyListings(
                  message: 'Could not load listings right now.',
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                );
              }
              final normalizedQuery = _query.toLowerCase();
              final listings = snapshot.data!.where((item) {
                if (item.isRental != widget.rentals) return false;
                if (normalizedQuery.isEmpty) return true;
                return <String>[
                  item.title,
                  item.category,
                  item.description,
                  item.condition,
                  item.sellerName,
                  item.price.toString(),
                  item.priceLabel,
                ].any((value) => value.toLowerCase().contains(normalizedQuery));
              }).toList();
              if (listings.isEmpty) {
                return _EmptyListings(
                  message: normalizedQuery.isNotEmpty
                      ? 'No listings match “$_query”.'
                      : widget.rentals
                      ? 'No rentals are available yet.'
                      : 'No items are for sale yet.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                itemCount: listings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = listings[index];
                  return _ProductCard(
                    icon: item.isRental
                        ? Icons.inventory_2_outlined
                        : Icons.shopping_bag_outlined,
                    title: item.title,
                    price: item.priceLabel,
                    condition: item.condition,
                    isRental: item.isRental,
                    tone: const Color(0xFF86B799),
                    imageUrl: item.imageUrls.isEmpty
                        ? null
                        : item.imageUrls.first,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReservationScreen(
                          apartment: widget.apartment,
                          listing: item,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _EmptyListings extends StatelessWidget {
  const _EmptyListings({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F7F4),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Center(child: Text(message, textAlign: TextAlign.center)),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.icon,
    required this.title,
    required this.price,
    required this.condition,
    required this.isRental,
    required this.tone,
    required this.onTap,
    this.imageUrl,
  });
  final IconData icon;
  final String title;
  final String price;
  final String condition;
  final bool isRental;
  final Color tone;
  final String? imageUrl;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      height: 118,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E9E6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            child: Stack(
              children: [
                Positioned.fill(
                  child: imageUrl == null
                      ? ColoredBox(
                          color: tone.withAlpha(70),
                          child: Center(
                            child: Icon(icon, size: 62, color: tone),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(7),
                          ),
                          child: Image.network(
                            imageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                Positioned(
                  left: 7,
                  top: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(130),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'Verified',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 12, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isRental
                              ? const Color(0xFFE8EEF8)
                              : const Color(0xFFE8F5EC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isRental ? 'For rent' : 'For sale',
                          style: TextStyle(
                            color: isRental
                                ? const Color(0xFF244C8A)
                                : primaryGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    condition,
                    style: const TextStyle(color: Colors.black54, fontSize: 10),
                  ),
                  const Spacer(),
                  Text(
                    price,
                    style: const TextStyle(
                      color: primaryGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _UnreadMessagesNavItem extends StatelessWidget {
  const _UnreadMessagesNavItem({
    required this.apartment,
    required this.selected,
    required this.onTap,
  });

  final Apartment? apartment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final uid = Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser?.uid;
    final currentApartment = apartment;
    if (uid == null || currentApartment == null) {
      return _NavItem(
        icon: Icons.chat_bubble_outline_rounded,
        selectedIcon: Icons.chat_bubble_rounded,
        label: 'Messages',
        selected: selected,
        onTap: onTap,
      );
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('apartments')
          .doc(currentApartment.id)
          .collection('chats')
          .where('participants', arrayContains: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final unread = snapshot.data?.docs.fold<int>(0, (total, chat) {
          final counts = Map<String, dynamic>.from(
            chat.data()['unreadCounts'] as Map? ?? const {},
          );
          return total + ((counts[uid] as num?)?.toInt() ?? 0);
        });
        return _NavItem(
          icon: Icons.chat_bubble_outline_rounded,
          selectedIcon: Icons.chat_bubble_rounded,
          label: 'Messages',
          selected: selected,
          onTap: onTap,
          badgeCount: unread ?? 0,
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE5F4EA) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  color: selected ? primaryGreen : const Color(0xFF59605B),
                  size: 22,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -12,
                    top: -8,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 17),
                      height: 17,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF04F38),
                        borderRadius: BorderRadius.all(Radius.circular(9)),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: selected ? primaryGreen : const Color(0xFF242A26),
              fontSize: 9.5,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
