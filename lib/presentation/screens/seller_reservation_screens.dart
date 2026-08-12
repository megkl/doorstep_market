import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community_models.dart';
import '../../state/auth_providers.dart';
import '../widgets/seller_subscription_card.dart';
import 'splash_screen.dart';

class SellerReservationsScreen extends ConsumerStatefulWidget {
  const SellerReservationsScreen({super.key, required this.apartment});

  final Apartment apartment;

  @override
  ConsumerState<SellerReservationsScreen> createState() =>
      _SellerReservationsScreenState();
}

class _SellerReservationsScreenState
    extends ConsumerState<SellerReservationsScreen> {
  String _filter = 'Pending';
  String? _busyId;

  Future<void> _accept(String id) async {
    await _run(
      id,
      () => ref
          .read(communityServiceProvider)
          .acceptReservation(apartment: widget.apartment, reservationId: id),
    );
  }

  Future<void> _update(String id, String status) async {
    await _run(
      id,
      () => ref
          .read(communityServiceProvider)
          .updateReservationStatus(
            apartment: widget.apartment,
            reservationId: id,
            status: status,
          ),
    );
  }

  Future<void> _relist(String id) async {
    await _run(
      id,
      () => ref
          .read(communityServiceProvider)
          .relistCancelledReservation(
            apartment: widget.apartment,
            reservationId: id,
          ),
    );
  }

  Future<void> _run(String id, Future<void> Function() operation) async {
    if (_busyId != null) return;
    setState(() => _busyId = id);
    try {
      await operation();
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update this reservation.')),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Reservation Requests',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: uid == null
          ? const Center(child: Text('Sign in to manage reservations.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Pending', label: Text('Pending')),
                      ButtonSegment(value: 'Active', label: Text('Active')),
                      ButtonSegment(value: 'Closed', label: Text('Closed')),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (value) =>
                        setState(() => _filter = value.first),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('apartments')
                        .doc(widget.apartment.id)
                        .collection('reservations')
                        .where('sellerId', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData && !snapshot.hasError) {
                        return const Center(
                          child: CircularProgressIndicator(color: primaryGreen),
                        );
                      }
                      final items = (snapshot.data?.docs ?? const [])
                          .where(
                            (item) =>
                                _matches(item.data()['status'] as String?),
                          )
                          .toList();
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            'No ${_filter.toLowerCase()} reservations.',
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final document = items[index];
                          return _SellerReservationCard(
                            data: document.data(),
                            busy: _busyId == document.id,
                            onAccept: () => _accept(document.id),
                            onDecline: () => _update(document.id, 'declined'),
                            onReady: () =>
                                _update(document.id, 'ready_for_pickup'),
                            onCollected: () =>
                                _update(document.id, 'collected'),
                            onRelist: () => _relist(document.id),
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

  bool _matches(String? status) => switch (_filter) {
    'Pending' => status == 'pending',
    'Active' => status == 'accepted' || status == 'ready_for_pickup',
    _ => status == 'collected' || status == 'declined' || status == 'cancelled',
  };
}

class _SellerReservationCard extends StatelessWidget {
  const _SellerReservationCard({
    required this.data,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
    required this.onReady,
    required this.onCollected,
    required this.onRelist,
  });

  final Map<String, dynamic> data;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onReady;
  final VoidCallback onCollected;
  final VoidCallback onRelist;

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFDDE3DF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['listingTitle'] as String? ?? 'Reserved item',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text('Buyer: ${data['buyerName'] ?? 'Verified neighbour'}'),
            Text(
              'Asking price: KSh ${(data['askingPrice'] as num? ?? 0).toStringAsFixed(0)}',
            ),
            const SizedBox(height: 8),
            Chip(label: Text(_statusLabel(status))),
            if (busy) const LinearProgressIndicator(),
            if (!busy && status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onAccept,
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            if (!busy && status == 'accepted')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onReady,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Mark Ready for Pickup'),
                ),
              ),
            if (!busy && status == 'ready_for_pickup')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onCollected,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Confirm Collection'),
                ),
              ),
            if (!busy && status == 'cancelled')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRelist,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Relist Item'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
  'pending' => 'Awaiting your response',
  'accepted' => 'Accepted',
  'ready_for_pickup' => 'Ready for pickup',
  'collected' => 'Collected',
  'declined' => 'Declined',
  'cancelled' => 'Cancelled by buyer',
  _ => 'In progress',
};

class SellerAdvertisingScreen extends StatelessWidget {
  const SellerAdvertisingScreen({super.key, required this.apartment});

  final Apartment apartment;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const Text(
        'Seller Plan',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        SellerSubscriptionCard(apartment: apartment),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            'An active plan is required to publish sale or rental listings. The first week is free for eligible new subscribers, then Google Play bills KSh 50 weekly. Manage or cancel the plan from Google Play → Payments & subscriptions.',
            style: TextStyle(height: 1.5, color: Colors.black54),
          ),
        ),
      ],
    ),
  );
}
