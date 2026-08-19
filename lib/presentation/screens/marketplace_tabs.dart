import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community_models.dart';
import '../../state/auth_providers.dart';
import 'marketplace_action_screens.dart';
import 'community_feature_screens.dart';
import 'order_profile_screens.dart';
import 'seller_reservation_screens.dart';
import 'splash_screen.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({
    super.key,
    required this.apartment,
    this.initialCategory = 'All',
  });

  final Apartment? apartment;
  final String initialCategory;

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  late String _selected;
  final _searchController = TextEditingController();
  String _query = '';
  static const _categories = [
    'All',
    'Furniture',
    'Electronics',
    'Appliances',
    'Gaming',
    'Baby Items',
    'Other',
  ];

  static const _categoryIcons = <String, IconData>{
    'All': Icons.apps_rounded,
    'Furniture': Icons.chair_outlined,
    'Electronics': Icons.devices_other_rounded,
    'Appliances': Icons.kitchen_outlined,
    'Gaming': Icons.sports_esports_outlined,
    'Baby Items': Icons.child_friendly_outlined,
    'Other': Icons.more_horiz_rounded,
  };

  @override
  void initState() {
    super.initState();
    _selected = _categories.contains(widget.initialCategory)
        ? widget.initialCategory
        : 'All';
  }

  @override
  void didUpdateWidget(CategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory &&
        _categories.contains(widget.initialCategory)) {
      _selected = widget.initialCategory;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apartment = widget.apartment;
    return ColoredBox(
      color: const Color(0xFFF7F9F7),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              color: Colors.white,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Browse categories',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Find something useful right in your apartment.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search in categories...',
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
                  fillColor: const Color(0xFFF5F8F6),
                  isDense: true,
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
            Container(
              height: 70,
              color: Colors.white,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final category = _categories[index];
                  return ChoiceChip(
                    avatar: Icon(
                      _categoryIcons[category],
                      size: 18,
                      color: category == _selected
                          ? Colors.white
                          : primaryGreen,
                    ),
                    label: Text(category),
                    selected: category == _selected,
                    selectedColor: primaryGreen,
                    backgroundColor: const Color(0xFFF4F7F5),
                    side: BorderSide(
                      color: category == _selected
                          ? primaryGreen
                          : const Color(0xFFDCE4DF),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    labelStyle: TextStyle(
                      color: category == _selected
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    onSelected: (_) => setState(() => _selected = category),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: apartment == null
                  ? const _TabEmpty(
                      'Verify your apartment to browse categories.',
                    )
                  : StreamBuilder<List<MarketplaceListing>>(
                      stream: ref
                          .read(communityServiceProvider)
                          .watchApartmentListings(apartment.id),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const _TabEmpty(
                            'Could not load categories right now.',
                          );
                        }
                        if (!snapshot.hasData && !snapshot.hasError) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: primaryGreen,
                            ),
                          );
                        }
                        final normalizedQuery = _query.toLowerCase();
                        final listings = (snapshot.data ?? const []).where((
                          item,
                        ) {
                          final inCategory =
                              _selected == 'All' || item.category == _selected;
                          if (!inCategory) return false;
                          if (normalizedQuery.isEmpty) return true;
                          return <String>[
                            item.title,
                            item.category,
                            item.description,
                            item.condition,
                            item.sellerName,
                            item.price.toString(),
                            item.priceLabel,
                          ].any(
                            (value) =>
                                value.toLowerCase().contains(normalizedQuery),
                          );
                        }).toList();
                        if (listings.isEmpty) {
                          return _TabEmpty(
                            normalizedQuery.isEmpty
                                ? 'No $_selected listings here yet.'
                                : 'No $_selected listings match “$_query”.',
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selected == 'All'
                                          ? 'All listings'
                                          : _selected,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${listings.length} item${listings.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  100,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: .72,
                                    ),
                                itemCount: listings.length,
                                itemBuilder: (context, index) =>
                                    _CategoryListingCard(
                                      item: listings[index],
                                      apartment: apartment,
                                    ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryListingCard extends StatelessWidget {
  const _CategoryListingCard({required this.item, required this.apartment});

  final MarketplaceListing item;
  final Apartment apartment;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 0,
    borderRadius: BorderRadius.circular(14),
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
          border: Border.all(color: const Color(0xFFE1E7E3)),
          borderRadius: BorderRadius.circular(14),
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
                          child: Center(
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: primaryGreen,
                              size: 44,
                            ),
                          ),
                        )
                      : Image.network(item.imageUrls.first, fit: BoxFit.cover),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item.isRental
                            ? const Color(0xFF244C8A)
                            : primaryGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.isRental ? 'For rent' : 'For sale',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
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
                    style: const TextStyle(color: Colors.black54, fontSize: 11),
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

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key, required this.apartment});

  final Apartment? apartment;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final currentApartment = apartment;
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Text(
                'Messages',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
            ),
            Expanded(
              child: user == null || currentApartment == null
                  ? const _TabEmpty('Your apartment conversations appear here.')
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('apartments')
                          .doc(currentApartment.id)
                          .collection('chats')
                          .where('participants', arrayContains: user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData && !snapshot.hasError) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: primaryGreen,
                            ),
                          );
                        }
                        final chats = [...?snapshot.data?.docs]
                          ..sort((a, b) {
                            final aTime = a.data()['updatedAt'] as Timestamp?;
                            final bTime = b.data()['updatedAt'] as Timestamp?;
                            return (bTime?.millisecondsSinceEpoch ?? 0)
                                .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
                          });
                        if (chats.isEmpty) {
                          return const _TabEmpty(
                            'No conversations yet. Open a listing to message its seller.',
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: chats.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final chat = chats[index];
                            final data = chat.data();
                            final names = Map<String, dynamic>.from(
                              data['participantNames'] as Map? ?? const {},
                            );
                            final otherEntry = names.entries
                                .where((entry) => entry.key != user.uid)
                                .firstOrNull;
                            final otherName =
                                otherEntry?.value?.toString() ?? 'Resident';
                            final unreadCounts = Map<String, dynamic>.from(
                              data['unreadCounts'] as Map? ?? const {},
                            );
                            final unread =
                                (unreadCounts[user.uid] as num?)?.toInt() ?? 0;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 7,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFE6F3EB),
                                child: Text(otherName.characters.first),
                              ),
                              title: Text(
                                otherName,
                                style: TextStyle(
                                  fontWeight: unread > 0
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                data['lastMessage'] as String? ??
                                    'Ask about ${data['listingTitle'] ?? 'this item'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: unread > 0
                                  ? _UnreadBadge(count: unread)
                                  : const Icon(Icons.chevron_right_rounded),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ChatThreadScreen(
                                    apartment: currentApartment,
                                    chatId: chat.id,
                                    otherName: otherName,
                                    listingTitle:
                                        data['listingTitle'] as String? ??
                                        'Listing',
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
      ),
    );
  }
}

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.apartment,
    required this.chatId,
    required this.otherName,
    required this.listingTitle,
  });

  final Apartment apartment;
  final String chatId;
  final String otherName;
  final String listingTitle;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _message = TextEditingController();
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _loadBlockedState();
    unawaited(_markRead());
  }

  Future<void> _markRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _chat.update({'unreadCounts.$uid': 0});
    } on FirebaseException {
      // The chat may have been removed between navigation and this update.
    }
  }

  Future<void> _loadBlockedState() async {
    final otherId = await _otherUserId();
    if (otherId == null) return;
    final blocked = await ref
        .read(communityServiceProvider)
        .isUserBlocked(otherId);
    if (mounted) setState(() => _blocked = blocked);
  }

  DocumentReference<Map<String, dynamic>> get _chat => FirebaseFirestore
      .instance
      .collection('apartments')
      .doc(widget.apartment.id)
      .collection('chats')
      .doc(widget.chatId);

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (text.isEmpty || user == null) return;
    final chat = await _chat.get();
    final participants = List<String>.from(
      chat.data()?['participants'] as List? ?? const [],
    );
    final recipient = participants.where((id) => id != user.uid).firstOrNull;
    if (recipient == null) return;
    _message.clear();
    final message = _chat.collection('messages').doc();
    final batch = FirebaseFirestore.instance.batch();
    batch.set(message, {
      'senderId': user.uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_chat, {
      'lastMessage': text,
      'lastMessageSenderId': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCounts.$recipient': FieldValue.increment(1),
      'unreadCounts.${user.uid}': 0,
    });
    await batch.commit();
    await ref
        .read(communityServiceProvider)
        .notifyChatMessage(
          apartment: widget.apartment,
          chatId: widget.chatId,
          recipientId: recipient,
          preview: text,
        );
  }

  Future<String?> _otherUserId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final data = (await _chat.get()).data();
    return List<String>.from(
      data?['participants'] as List? ?? const [],
    ).where((id) => id != uid).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherName,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(widget.listingTitle, style: const TextStyle(fontSize: 11)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final otherId = await _otherUserId();
              if (!context.mounted || otherId == null) return;
              if (value == 'report') {
                await showReportDialog(
                  context,
                  ref,
                  targetType: 'user',
                  targetId: otherId,
                  apartmentId: widget.apartment.id,
                );
              } else {
                await ref.read(communityServiceProvider).blockUser(otherId);
                if (!context.mounted) return;
                setState(() => _blocked = true);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('User blocked.')));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('Report user')),
              PopupMenuItem(value: 'block', child: Text('Block user')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chat
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) unawaited(_markRead());
                  });
                }
                final messages = snapshot.data?.docs ?? const [];
                if (messages.isEmpty) {
                  return const _TabEmpty(
                    'Start the conversation safely in Doorstep Market.',
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, index) {
                    final data = messages[index].data();
                    final mine = data['senderId'] == uid;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        margin: const EdgeInsets.only(bottom: 9),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: mine ? primaryGreen : const Color(0xFFF0F1F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['text'] as String? ?? '',
                          style: TextStyle(
                            color: mine ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      enabled: !_blocked,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: _blocked
                            ? 'You blocked this user'
                            : 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _blocked ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 22),
    height: 22,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: primaryGreen,
      borderRadius: BorderRadius.all(Radius.circular(11)),
    ),
    child: Text(
      count > 99 ? '99+' : '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.apartment});

  final Apartment? apartment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    void open(Widget Function(Apartment apartment) builder) {
      final currentApartment = apartment;
      if (currentApartment == null) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => builder(currentApartment)),
      );
    }

    return ColoredBox(
      color: const Color(0xFFF7F9F7),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E9B57), Color(0xFF147742)],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: user?.photoURL == null
                        ? null
                        : NetworkImage(user!.photoURL!),
                    child: user?.photoURL == null
                        ? const Icon(
                            Icons.person_rounded,
                            size: 42,
                            color: primaryGreen,
                          )
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Doorstep Resident',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '✓ Verified • ${apartment?.name ?? 'Apartment'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
              child: Text(
                'My Activity',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            _ProfileTile(
              icon: Icons.inventory_2_outlined,
              label: 'My Listings',
              onTap: () =>
                  open((apartment) => MyListingsScreen(apartment: apartment)),
            ),
            _ProfileTile(
              icon: Icons.calendar_month_outlined,
              label: 'My Rentals',
              onTap: () => open(
                (apartment) =>
                    MyListingsScreen(apartment: apartment, rentals: true),
              ),
            ),
            _ProfileTile(
              icon: Icons.receipt_long_outlined,
              label: 'My Reservations',
              onTap: () =>
                  open((apartment) => MyOrdersScreen(apartment: apartment)),
            ),
            _ProfileTile(
              icon: Icons.assignment_outlined,
              label: 'Reservation Requests',
              onTap: () => open(
                (apartment) => SellerReservationsScreen(apartment: apartment),
              ),
            ),
            _ProfileTile(
              icon: Icons.campaign_outlined,
              label: 'Seller Advertising',
              onTap: () => open(
                (apartment) => SellerAdvertisingScreen(apartment: apartment),
              ),
            ),
            _ProfileTile(
              icon: Icons.favorite_border_rounded,
              label: 'Saved Items',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SavedItemsScreen(),
                ),
              ),
            ),
            _ProfileTile(
              icon: Icons.star_border_rounded,
              label: 'Reviews',
              onTap: () =>
                  open((apartment) => ReviewsScreen(apartment: apartment)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
              child: Text(
                'Account',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            _ProfileTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {},
            ),
            _ProfileTile(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HelpSupportScreen(),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Log out',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const SplashScreen()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    child: ListTile(
      leading: Icon(icon, color: primaryGreen),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

class _TabEmpty extends StatelessWidget {
  const _TabEmpty(this.message);
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
