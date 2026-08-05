import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community_models.dart';
import '../../state/auth_providers.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              sliver: SliverList.list(
                children: [
                  _HomeHeader(
                    apartmentName: widget.apartment?.name ?? 'Your Apartment',
                  ),
                  const SizedBox(height: 19),
                  const _SearchBar(),
                  const SizedBox(height: 18),
                  const _PromoBanner(),
                  const SizedBox(height: 18),
                  const _QuickActions(),
                  const SizedBox(height: 25),
                  _ApartmentListings(apartment: widget.apartment),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 72,
        padding: EdgeInsets.zero,
        color: Colors.white,
        elevation: 12,
        shadowColor: Colors.black26,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: _tab == 0,
              onTap: () => setState(() => _tab = 0),
            ),
            _NavItem(
              icon: Icons.grid_view_rounded,
              label: 'Categories',
              selected: _tab == 1,
              onTap: () => setState(() => _tab = 1),
            ),
            const SizedBox(width: 62),
            _NavItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Messages',
              selected: _tab == 3,
              onTap: () => setState(() => _tab = 3),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
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
  const _HomeHeader({required this.apartmentName});

  final String apartmentName;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                      apartmentName,
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
        IconButton(
          onPressed: null,
          icon: Icon(
            Icons.notifications_none_rounded,
            color: Colors.black,
            size: 26,
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.shopping_cart_outlined, color: primaryGreen, size: 31),
            Positioned(
              right: -5,
              top: -7,
              child: CircleAvatar(
                radius: 9,
                backgroundColor: Color(0xFFF04F38),
                child: Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search items, e.g. sofa, microwave...',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8B918D),
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 22),
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
        Container(
          width: 49,
          height: 49,
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.tune_rounded, color: Colors.white),
        ),
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

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
                    onPressed: () {},
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
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _QuickAction(
          icon: Icons.shopping_bag_outlined,
          label: 'Buy',
          color: primaryGreen,
          background: Color(0xFFF0F8F3),
        ),
        SizedBox(width: 9),
        _QuickAction(
          icon: Icons.sell_outlined,
          label: 'Sell',
          color: Color(0xFF459D56),
          background: Color(0xFFF3F9F1),
        ),
        SizedBox(width: 9),
        _QuickAction(
          icon: Icons.calendar_month_outlined,
          label: 'Rent',
          color: Color(0xFFF29B20),
          background: Color(0xFFFFF7E9),
        ),
        SizedBox(width: 9),
        _QuickAction(
          icon: Icons.grid_view_rounded,
          label: 'Categories',
          color: Color(0xFF6263D8),
          background: Color(0xFFF3F2FF),
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
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Expanded(
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
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      const Text(
        'See all',
        style: TextStyle(
          color: primaryGreen,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _ApartmentListings extends ConsumerWidget {
  const _ApartmentListings({required this.apartment});

  final Apartment? apartment;

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
        final listings = snapshot.data!;
        if (listings.isEmpty) {
          return const _EmptyListings(
            message: 'No items have been listed in this apartment yet.',
          );
        }
        final sales = listings.where((item) => !item.isRental).toList();
        final rentals = listings.where((item) => item.isRental).toList();
        return Column(
          children: [
            if (sales.isNotEmpty) ...[
              const _SectionHeader(title: 'Available in Your Apartment'),
              const SizedBox(height: 12),
              _ListingRow(
                listings: sales,
                apartmentName: currentApartment.name,
              ),
            ],
            if (sales.isNotEmpty && rentals.isNotEmpty)
              const SizedBox(height: 28),
            if (rentals.isNotEmpty) ...[
              const _SectionHeader(title: 'Recent Rentals'),
              const SizedBox(height: 12),
              _ListingRow(
                listings: rentals,
                apartmentName: currentApartment.name,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ListingRow extends StatelessWidget {
  const _ListingRow({required this.listings, required this.apartmentName});

  final List<MarketplaceListing> listings;
  final String apartmentName;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 178,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: listings.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, index) => SizedBox(
        width: 112,
        child: _ProductCard(
          icon: listings[index].isRental
              ? Icons.inventory_2_outlined
              : Icons.shopping_bag_outlined,
          title: listings[index].title,
          price: listings[index].priceLabel,
          tone: const Color(0xFF86B799),
          apartmentName: apartmentName,
        ),
      ),
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
    required this.tone,
    required this.apartmentName,
  });
  final IconData icon;
  final String title;
  final String price;
  final Color tone;
  final String apartmentName;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        height: 104,
        width: double.infinity,
        decoration: BoxDecoration(
          color: tone.withAlpha(95),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, size: 66, color: tone)),
            const Positioned(
              right: 7,
              top: 7,
              child: CircleAvatar(
                radius: 11,
                backgroundColor: Colors.white70,
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 3),
      Text(
        price,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 3),
      Text(
        apartmentName,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 8.5, color: Color(0xFF777D79)),
      ),
    ],
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected ? primaryGreen : const Color(0xFF242A26),
            size: 24,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: selected ? primaryGreen : const Color(0xFF242A26),
              fontSize: 9,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
