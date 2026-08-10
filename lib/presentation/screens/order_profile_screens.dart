import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community_models.dart';
import '../../state/auth_providers.dart';
import '../widgets/listing_boost_button.dart';
import 'marketplace_action_screens.dart';
import 'splash_screen.dart';

String _money(num? value) => 'KSh ${(value ?? 0).toStringAsFixed(0)}';

class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({
    super.key,
    required this.apartment,
    this.rentals = false,
  });

  final Apartment apartment;
  final bool rentals;

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.rentals ? 'My Rentals' : 'My Listings',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'All', label: Text('All')),
                ButtonSegment(value: 'Active', label: Text('Active')),
                ButtonSegment(value: 'Closed', label: Text('Closed')),
              ],
              selected: {_filter},
              onSelectionChanged: (value) =>
                  setState(() => _filter = value.first),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<MarketplaceListing>>(
              stream: ref
                  .read(communityServiceProvider)
                  .watchApartmentListings(widget.apartment.id),
              builder: (context, snapshot) {
                final items = (snapshot.data ?? const [])
                    .where((item) => item.sellerId == uid)
                    .where((item) => item.isRental == widget.rentals)
                    .where(
                      (item) =>
                          _filter == 'All' ||
                          (_filter == 'Active' ? item.active : !item.active),
                    )
                    .toList();
                if (!snapshot.hasData && !snapshot.hasError) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  );
                }
                if (items.isEmpty) {
                  return _Empty(
                    widget.rentals
                        ? 'You have not listed any rentals yet.'
                        : 'You have not listed any items yet.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) => _ListingTile(
                    apartment: widget.apartment,
                    item: items[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ListingFormScreen(
                  apartment: widget.apartment,
                  isRental: widget.rentals,
                ),
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text(
              widget.rentals ? 'List an Item for Rent' : 'List a New Item',
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.apartment, required this.item});

  final Apartment apartment;
  final MarketplaceListing item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: item.imageUrls.isEmpty
              ? const ColoredBox(
                  color: Color(0xFFE7F2EB),
                  child: SizedBox(
                    width: 72,
                    height: 64,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: primaryGreen,
                    ),
                  ),
                )
              : Image.network(
                  item.imageUrls.first,
                  width: 72,
                  height: 64,
                  fit: BoxFit.cover,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (item.isBoosted)
                    const Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('Boosted'),
                    ),
                ],
              ),
              Text('${item.priceLabel} • ${item.category}'),
              const SizedBox(height: 6),
              if (item.active && !item.isBoosted)
                ListingBoostButton(apartment: apartment, listing: item),
            ],
          ),
        ),
      ],
    ),
  );
}

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key, required this.apartment});

  final Apartment apartment;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'My Reservations',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: uid == null
          ? const _Empty('Sign in to view your reservations.')
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('apartments')
                  .doc(apartment.id)
                  .collection('reservations')
                  .where('buyerId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData && !snapshot.hasError) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  );
                }
                final reservations = snapshot.data?.docs ?? const [];
                if (reservations.isEmpty) {
                  return const _Empty('You have no reservations yet.');
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reservations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];
                    final data = reservation.data();
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE7F2EB),
                          child: Icon(
                            Icons.bookmark_added_outlined,
                            color: primaryGreen,
                          ),
                        ),
                        title: Text(
                          data['listingTitle'] as String? ?? 'Reserved item',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          '${_money(data['askingPrice'] as num?)}\n${_statusLabel(data['status'] as String?)}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReservationStatusScreen(
                              apartment: apartment,
                              reservationId: reservation.id,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class ReservationStatusScreen extends StatelessWidget {
  const ReservationStatusScreen({
    super.key,
    required this.apartment,
    required this.reservationId,
  });

  final Apartment apartment;
  final String reservationId;

  @override
  Widget build(BuildContext context) {
    final reference = FirebaseFirestore.instance
        .collection('apartments')
        .doc(apartment.id)
        .collection('reservations')
        .doc(reservationId);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Reservation Status',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: reference.snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          if (data == null) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }
          final collected = data['collected'] == true;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Reservation #${reservationId.length > 8 ? reservationId.substring(0, 8) : reservationId}',
              ),
              const SizedBox(height: 18),
              const _ReservationStep(
                complete: true,
                icon: Icons.bookmark_added_outlined,
                title: 'Item Reserved',
                subtitle: 'The seller has been notified of your interest.',
              ),
              const _ReservationStep(
                complete: false,
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Arrange Pickup',
                subtitle:
                    'Use chat to agree on a time, place and payment method.',
              ),
              _ReservationStep(
                complete: collected,
                icon: Icons.inventory_2_outlined,
                title: 'Inspect and Collect',
                subtitle: collected
                    ? 'The item was marked as collected.'
                    : 'Inspect the item before paying the seller directly.',
              ),
              const SizedBox(height: 20),
              if (!collected)
                FilledButton(
                  onPressed: () => reference.update({
                    'collected': true,
                    'status': 'collected',
                    'collectedAt': FieldValue.serverTimestamp(),
                  }),
                  child: const Text('Mark as Collected'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReservationStep extends StatelessWidget {
  const _ReservationStep({
    required this.complete,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final bool complete;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
    leading: CircleAvatar(
      backgroundColor: complete ? primaryGreen : const Color(0xFFF0F2F0),
      child: Icon(
        complete ? Icons.check : icon,
        color: complete ? Colors.white : Colors.black45,
      ),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
    subtitle: Text(subtitle),
  );
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const Text(
        'Help & Support',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final topic in const [
          ('How Reservations Work', Icons.bookmark_added_outlined),
          ('How to List an Item', Icons.inventory_2_outlined),
          ('How Rentals Work', Icons.calendar_month_outlined),
          ('Pickup Arrangements', Icons.location_on_outlined),
          ('Paying the Seller', Icons.handshake_outlined),
          ('Safety Tips', Icons.health_and_safety_outlined),
        ])
          ExpansionTile(
            leading: Icon(topic.$2, color: primaryGreen),
            title: Text(
              topic.$1,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 20, 16),
                child: Text(_helpText(topic.$1)),
              ),
            ],
          ),
      ],
    ),
  );
}

String _statusLabel(String? status) => switch (status) {
  'reserved' => 'Reserved',
  'collected' => 'Collected',
  'cancelled' => 'Cancelled',
  _ => 'In progress',
};

String _helpText(String topic) => switch (topic) {
  'How Reservations Work' =>
    'Reserve an available item, then use chat to arrange inspection and pickup with the seller.',
  'How to List an Item' =>
    'Add photos, item details, an asking price and your private pickup unit, then publish.',
  'How Rentals Work' =>
    'Rental listings show a daily price. Agree on dates and handover details directly with the owner.',
  'Pickup Arrangements' =>
    'Use chat to agree on a safe pickup time. Exact unit details are not shown publicly.',
  'Paying the Seller' =>
    'Doorstep Market does not collect or hold payment. Inspect the item and pay the seller directly using a method you both agree on.',
  _ =>
    'Meet in a safe place, inspect the item before paying, and report suspicious listings.',
};

class _Empty extends StatelessWidget {
  const _Empty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54),
      ),
    ),
  );
}
