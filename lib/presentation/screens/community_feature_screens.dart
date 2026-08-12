import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community_models.dart';
import '../../state/auth_providers.dart';
import 'marketplace_action_screens.dart';
import 'splash_screen.dart';

class SavedItemsScreen extends ConsumerWidget {
  const SavedItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const Text(
        'Saved Items',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ref.read(communityServiceProvider).watchSavedListings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(
            child: CircularProgressIndicator(color: primaryGreen),
          );
        }
        final items = snapshot.data?.docs ?? const [];
        if (items.isEmpty) {
          return const _FeatureEmpty('Items you save will appear here.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, index) {
            final data = items[index].data();
            return ListTile(
              leading: _ListingThumb(url: data['imageUrl'] as String?),
              title: Text(data['title'] as String? ?? 'Saved item'),
              subtitle: Text(
                '${data['priceLabel'] ?? ''}\n${data['sellerName'] ?? ''}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _openListing(context, data),
            );
          },
        );
      },
    ),
  );

  Future<void> _openListing(
    BuildContext context,
    Map<String, dynamic> saved,
  ) async {
    final apartmentId = saved['apartmentId'] as String?;
    final listingId = saved['listingId'] as String?;
    if (apartmentId == null || listingId == null) return;
    final results = await Future.wait([
      FirebaseFirestore.instance
          .collection('apartments')
          .doc(apartmentId)
          .get(),
      FirebaseFirestore.instance
          .collection('apartments')
          .doc(apartmentId)
          .collection('listings')
          .doc(listingId)
          .get(),
    ]);
    if (!context.mounted) return;
    final apartmentData = results[0].data();
    final listingData = results[1].data();
    if (apartmentData == null ||
        listingData == null ||
        listingData['active'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This listing is no longer available.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReservationScreen(
          apartment: Apartment(
            id: apartmentId,
            name: apartmentData['name'] as String? ?? 'Your apartment',
            invitationCode: '',
          ),
          listing: MarketplaceListing.fromFirestore(listingId, listingData),
        ),
      ),
    );
  }
}

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key, required this.apartment});

  final Apartment apartment;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'My Reviews',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: uid == null
          ? const _FeatureEmpty('Sign in to see reviews.')
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('apartments')
                  .doc(apartment.id)
                  .collection('reviews')
                  .where('revieweeId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData && !snapshot.hasError) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  );
                }
                final reviews = snapshot.data?.docs ?? const [];
                if (reviews.isEmpty) {
                  return const _FeatureEmpty(
                    'Reviews from completed collections will appear here.',
                  );
                }
                final average =
                    reviews.fold<double>(
                      0,
                      (total, item) =>
                          total + (item.data()['rating'] as num? ?? 0),
                    ) /
                    reviews.length;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: Text(
                        '${average.toStringAsFixed(1)} ★  •  ${reviews.length} reviews',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    for (final review in reviews)
                      Card(
                        color: Colors.white,
                        child: ListTile(
                          title: Text(
                            '${review.data()['rating']} ★  ${review.data()['listingTitle']}',
                          ),
                          subtitle: Text(
                            '${review.data()['comment'] ?? ''}\n— ${review.data()['reviewerName'] ?? 'Verified neighbour'}',
                          ),
                          isThreeLine: true,
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final query = uid == null
        ? null
        : FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('notifications')
              .orderBy('createdAt', descending: true);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: query == null
          ? const _FeatureEmpty('Sign in to see notifications.')
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData && !snapshot.hasError) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  );
                }
                final items = snapshot.data?.docs ?? const [];
                if (items.isEmpty) {
                  return const _FeatureEmpty('You are all caught up.');
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    final data = item.data();
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: data['read'] == true
                            ? const Color(0xFFF0F2F0)
                            : const Color(0xFFE7F2EB),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: primaryGreen,
                        ),
                      ),
                      title: Text(
                        data['title'] as String? ?? 'Update',
                        style: TextStyle(
                          fontWeight: data['read'] == true
                              ? FontWeight.w600
                              : FontWeight.w900,
                        ),
                      ),
                      subtitle: Text(data['body'] as String? ?? ''),
                      onTap: () => item.reference.update({'read': true}),
                    );
                  },
                );
              },
            ),
    );
  }
}

Future<void> showReportDialog(
  BuildContext context,
  WidgetRef ref, {
  required String targetType,
  required String targetId,
  String? apartmentId,
}) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Report a concern'),
      children: [
        for (final value in const [
          'Misleading or unavailable item',
          'Harassment or abusive behaviour',
          'Spam or suspicious activity',
          'Unsafe or prohibited item',
        ])
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(value),
            ),
          ),
      ],
    ),
  );
  if (reason == null || !context.mounted) return;
  await ref
      .read(communityServiceProvider)
      .reportContent(
        targetType: targetType,
        targetId: targetId,
        reason: reason,
        apartmentId: apartmentId,
      );
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Report submitted for review.')));
}

class _ListingThumb extends StatelessWidget {
  const _ListingThumb({this.url});
  final String? url;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(7),
    child: url == null
        ? const ColoredBox(
            color: Color(0xFFE7F2EB),
            child: SizedBox(
              width: 60,
              height: 60,
              child: Icon(Icons.inventory_2_outlined),
            ),
          )
        : Image.network(url!, width: 60, height: 60, fit: BoxFit.cover),
  );
}

class _FeatureEmpty extends StatelessWidget {
  const _FeatureEmpty(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(36),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54),
      ),
    ),
  );
}
