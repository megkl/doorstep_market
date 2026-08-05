import 'package:flutter/material.dart';

class CategoryItem {
  final String name;
  final IconData icon;

  const CategoryItem({required this.name, required this.icon});
}

class ListingItem {
  final String title;
  final String subtitle;
  final String price;
  final String location;
  final String distance;
  final String badge;
  final bool verified;

  const ListingItem({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.location,
    required this.distance,
    required this.badge,
    this.verified = true,
  });
}

class ValueItem {
  final String title;
  final String subtitle;

  const ValueItem({required this.title, required this.subtitle});
}
