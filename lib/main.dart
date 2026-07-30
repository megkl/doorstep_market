import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: DoorstepMarketApp()));
}

final selectedIndexProvider = StateProvider<int>((ref) => 0);
final categoriesProvider = Provider<List<CategoryItem>>((ref) => const [
      CategoryItem(name: 'Electronics', icon: Icons.tv),
      CategoryItem(name: 'Furniture', icon: Icons.chair_alt),
      CategoryItem(name: 'Kitchen', icon: Icons.kitchen),
      CategoryItem(name: 'Gaming', icon: Icons.videogame_asset),
      CategoryItem(name: 'Baby items', icon: Icons.child_care),
      CategoryItem(name: 'Appliances', icon: Icons.local_laundry_service),
    ]);
final featuredListingsProvider = Provider<List<ListingItem>>((ref) => const [
      ListingItem(
        title: 'Smart TV',
        subtitle: '55" 4K UHD',
        price: '15,000',
        location: 'Greenview Apartments',
        badge: 'Featured',
      ),
      ListingItem(
        title: 'Baby Cot',
        subtitle: 'Like new with mattress',
        price: '6,000',
        location: 'Parkside Residences',
        badge: 'Rentable',
      ),
      ListingItem(
        title: 'Sofa Set',
        subtitle: '3-seater + 2 chairs',
        price: '24,000',
        location: 'Sunrise Towers',
        badge: 'Pickup only',
      ),
    ]);

class DoorstepMarketApp extends StatelessWidget {
  const DoorstepMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doorstep Market',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MarketplaceHomePage(),
    );
  }
}

class MarketplaceHomePage extends ConsumerWidget {
  const MarketplaceHomePage({super.key});

  static const List<Widget> _pages = <Widget>[
    HomeSection(),
    PlaceholderView(title: 'Sell'),
    PlaceholderView(title: 'Chat'),
    PlaceholderView(title: 'Notifications'),
    PlaceholderView(title: 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doorstep Market'),
        actions: const [VerifiedBadge(), SizedBox(width: 12)],
      ),
      body: _pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => ref.read(selectedIndexProvider.notifier).state = index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.add_box_outlined), label: 'Sell'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.notifications_none), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeSection extends StatelessWidget {
  const HomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SectionHeader(title: 'Trusted community marketplace'),
            SizedBox(height: 8),
            InfoBanner(),
            SizedBox(height: 24),
            CategorySection(),
            SizedBox(height: 24),
            FeaturedSection(),
            SizedBox(height: 24),
            ValueSection(),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Verified apartment residents only', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Buy, sell, rent and message neighbors in your apartment community.'),
          ],
        ),
      ),
    );
  }
}

class CategorySection extends ConsumerWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Categories'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: categories.map((item) => CategoryCard(item: item)).toList(growable: false),
        ),
      ],
    );
  }
}

class FeaturedSection extends ConsumerWidget {
  const FeaturedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(featuredListingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Featured listings'),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: listings.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => ListingCard(item: listings[index]),
          ),
        ),
      ],
    );
  }
}

class ValueSection extends StatelessWidget {
  const ValueSection({super.key});

  static const values = <ValueItem>[
    ValueItem(title: 'Secure payments', subtitle: 'Escrow-style protection and commission capture.'),
    ValueItem(title: 'Verified sellers', subtitle: 'Only residents of approved apartments.'),
    ValueItem(title: 'Rent or buy', subtitle: 'Temporary and permanent home item options.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Why Doorstep Market?'),
        const SizedBox(height: 12),
        ...values.map((value) => ValueRow(item: value)),
      ],
    );
  }
}

class CategoryItem {
  final String name;
  final IconData icon;

  const CategoryItem({required this.name, required this.icon});
}

class ValueItem {
  final String title;
  final String subtitle;

  const ValueItem({required this.title, required this.subtitle});
}

class ListingItem {
  final String title;
  final String subtitle;
  final String price;
  final String location;
  final String badge;

  const ListingItem({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.location,
    required this.badge,
  });
}

class CategoryCard extends StatelessWidget {
  final CategoryItem item;

  const CategoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(item.icon, size: 18, color: Theme.of(context).colorScheme.onPrimary),
      label: Text(item.name),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      backgroundColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
    );
  }
}

class ListingCard extends StatelessWidget {
  final ListingItem item;

  const ListingCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(item.badge, style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                  Icon(Icons.favorite_border, color: Colors.grey.shade600),
                ],
              ),
              const SizedBox(height: 16),
              Text(item.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              Text('KSh ${item.price}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.location,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ValueRow extends StatelessWidget {
  final ValueItem item;

  const ValueRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(item.subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceholderView extends StatelessWidget {
  final String title;

  const PlaceholderView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title view is coming soon',
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: const [
          Icon(Icons.verified, size: 18, color: Colors.blue),
          SizedBox(width: 6),
          Text('Verified'),
        ],
      ),
    );
  }
}
