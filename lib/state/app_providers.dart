import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../services/mpesa_service.dart';

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
        distance: '240m',
        badge: 'Featured',
      ),
      ListingItem(
        title: 'Baby Cot',
        subtitle: 'Like new with mattress',
        price: '6,000',
        location: 'Parkside Residences',
        distance: '90m',
        badge: 'Rentable',
      ),
      ListingItem(
        title: 'Sofa Set',
        subtitle: '3-seater + 2 chairs',
        price: '24,000',
        location: 'Sunrise Towers',
        distance: '410m',
        badge: 'Pickup only',
      ),
    ]);

final mpesaServiceProvider = Provider<MpesaService>((ref) {
  return MpesaService(
    consumerKey: 'YOUR_CONSUMER_KEY',
    consumerSecret: 'YOUR_CONSUMER_SECRET',
    businessShortCode: '174379',
    passKey: 'YOUR_PASSKEY',
    callbackUrl: 'https://your-server.com/mpesa/callback',
    useSandbox: true,
  );
});
