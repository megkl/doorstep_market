import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/community_models.dart';

class CommunityService {
  CommunityService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestoreOverride = firestore,
      _authOverride = auth;

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  Future<UserAccess> loadCurrentUserAccess() async {
    final user = _auth.currentUser;
    if (user == null) return const UserAccess();
    final userDocument = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    if (!userDocument.exists) return const UserAccess();

    final data = userDocument.data()!;
    final roleName = data['role'] as String?;
    final role = UserRole.values
        .where((item) => item.name == roleName)
        .firstOrNull;
    if (role == null) return const UserAccess();

    if (role == UserRole.landlord) {
      if (!await isCurrentUserWhitelistedLandlord()) {
        return const UserAccess();
      }
      final apartmentIds = List<String>.from(
        data['managedApartmentIds'] as List? ?? const [],
      );
      if (apartmentIds.isEmpty) return UserAccess(role: role);
      final apartmentDocument = await _firestore
          .collection('apartments')
          .doc(apartmentIds.first)
          .get();
      if (!apartmentDocument.exists) return UserAccess(role: role);
      final apartmentData = apartmentDocument.data()!;
      return UserAccess(
        role: role,
        approved: true,
        apartment: Apartment(
          id: apartmentDocument.id,
          name: apartmentData['name'] as String,
          invitationCode: apartmentData['invitationCode'] as String,
        ),
      );
    }

    if (data['membershipStatus'] != 'approved') {
      return UserAccess(role: role);
    }
    final apartmentId = data['apartmentId'] as String?;
    final apartmentName = data['apartmentName'] as String?;
    if (apartmentId == null || apartmentName == null) {
      return UserAccess(role: role);
    }
    return UserAccess(
      role: role,
      approved: true,
      apartment: Apartment(
        id: apartmentId,
        name: apartmentName,
        invitationCode: '',
      ),
    );
  }

  Future<bool> isCurrentUserWhitelistedLandlord() async {
    final email = _auth.currentUser?.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return false;
    final document = await _firestore
        .collection('landlord_whitelist')
        .doc(email)
        .get();
    return document.exists && document.data()?['active'] == true;
  }

  Future<Apartment?> loadApprovedApartment() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final document = await _firestore.collection('users').doc(user.uid).get();
    final data = document.data();
    if (data == null || data['membershipStatus'] != 'approved') return null;
    final apartmentId = data['apartmentId'] as String?;
    final apartmentName = data['apartmentName'] as String?;
    if (apartmentId == null || apartmentName == null) return null;
    return Apartment(id: apartmentId, name: apartmentName, invitationCode: '');
  }

  Future<List<Apartment>> loadManagedApartments() async {
    final user = _auth.currentUser;
    if (user == null) return const [];
    final userDocument = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    final ids = List<String>.from(
      userDocument.data()?['managedApartmentIds'] as List? ?? const [],
    );
    if (ids.isEmpty) return const [];
    final apartments = <Apartment>[];
    for (final id in ids) {
      final document = await _firestore.collection('apartments').doc(id).get();
      final data = document.data();
      if (data == null) continue;
      apartments.add(
        Apartment(
          id: document.id,
          name: data['name'] as String,
          invitationCode: data['invitationCode'] as String,
        ),
      );
    }
    return apartments;
  }

  Future<Apartment?> apartmentForCode(String value) async {
    final code = value.trim().toUpperCase();
    if (code.isEmpty) return null;
    final result = await _firestore
        .collection('apartments')
        .where('invitationCode', isEqualTo: code)
        .limit(1)
        .get();
    if (result.docs.isEmpty) return null;
    final document = result.docs.first;
    return Apartment(
      id: document.id,
      name: document.data()['name'] as String,
      invitationCode: code,
    );
  }

  Future<void> saveMembership({
    required Apartment apartment,
    required UserRole role,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'displayName': user.displayName,
      'email': user.email,
      'photoUrl': user.photoURL,
      'role': role.name,
      'roles': FieldValue.arrayUnion([role.name]),
      'apartmentId': apartment.id,
      'apartmentName': apartment.name,
      'membershipStatus': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _firestore
        .collection('apartments')
        .doc(apartment.id)
        .collection('members')
        .doc(user.uid)
        .set({
          'userId': user.uid,
          'displayName': user.displayName,
          'email': user.email,
          'role': role.name,
          'status': 'approved',
          'joinedAt': FieldValue.serverTimestamp(),
        });
  }

  Stream<List<ApartmentMember>> watchApartmentMembers(String apartmentId) {
    return _firestore
        .collection('apartments')
        .doc(apartmentId)
        .collection('members')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
          final members = snapshot.docs
              .map(
                (document) =>
                    ApartmentMember.fromFirestore(document.id, document.data()),
              )
              .toList();
          members.sort(
            (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
          );
          return members;
        });
  }

  Future<void> removeApartmentMember({
    required String apartmentId,
    required String memberId,
  }) async {
    final member = _firestore
        .collection('apartments')
        .doc(apartmentId)
        .collection('members')
        .doc(memberId);
    final user = _firestore.collection('users').doc(memberId);
    final batch = _firestore.batch();
    batch.delete(member);
    batch.update(user, {
      'apartmentId': FieldValue.delete(),
      'apartmentName': FieldValue.delete(),
      'membershipStatus': 'removed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> saveProfile({required String displayName}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'displayName': displayName.trim().isEmpty
          ? user.displayName
          : displayName.trim(),
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<MarketplaceListing>> watchApartmentListings(String apartmentId) {
    return _firestore
        .collection('apartments')
        .doc(apartmentId)
        .collection('listings')
        .snapshots()
        .asyncMap((snapshot) async {
          final uid = _auth.currentUser?.uid;
          final blocked = uid == null
              ? <String>{}
              : (await _firestore
                        .collection('users')
                        .doc(uid)
                        .collection('blockedUsers')
                        .get())
                    .docs
                    .map((document) => document.id)
                    .toSet();
          return snapshot.docs
              .map(
                (document) => MarketplaceListing.fromFirestore(
                  document.id,
                  document.data(),
                ),
              )
              .where(
                (listing) =>
                    listing.active &&
                    listing.sellerPlanActive &&
                    !blocked.contains(listing.sellerId),
              )
              .toList()
            ..sort((a, b) {
              if (a.isPromoted == b.isPromoted) return 0;
              return a.isPromoted ? -1 : 1;
            });
        });
  }

  Stream<List<MarketplaceListing>> watchMyListings(String apartmentId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection('apartments')
        .doc(apartmentId)
        .collection('listings')
        .where('sellerId', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => MarketplaceListing.fromFirestore(
                  document.id,
                  document.data(),
                ),
              )
              .toList(),
        );
  }

  Future<void> setListingActive({
    required Apartment apartment,
    required String listingId,
    required bool active,
  }) async {
    if (active && !await hasActiveSellerAdvertising()) {
      throw StateError('An active seller plan is required to relist an item.');
    }
    await _firestore
        .collection('apartments')
        .doc(apartment.id)
        .collection('listings')
        .doc(listingId)
        .update({'active': active, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteListing({
    required Apartment apartment,
    required String listingId,
  }) async {
    final listing = _firestore
        .collection('apartments')
        .doc(apartment.id)
        .collection('listings')
        .doc(listingId);
    final private = _firestore
        .collection('apartments')
        .doc(apartment.id)
        .collection('listingPrivate')
        .doc(listingId);
    final batch = _firestore.batch();
    batch.delete(listing);
    batch.delete(private);
    await batch.commit();
  }

  Future<void> createListing({
    required Apartment apartment,
    required String title,
    required String category,
    required String condition,
    required String description,
    required double price,
    required bool isRental,
    required String pickupHouseNumber,
    required List<String> imageUrls,
    double? securityDeposit,
    DateTime? availableFrom,
    DateTime? availableTo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    final listing = _firestore
        .collection('apartments')
        .doc(apartment.id)
        .collection('listings')
        .doc();
    final privateDetails = _firestore
        .collection('apartments')
        .doc(apartment.id)
        .collection('listingPrivate')
        .doc(listing.id);
    final userData = await _firestore.collection('users').doc(user.uid).get();
    final advertisingUntil =
        (userData.data()?['sellerAdvertisingUntil'] as Timestamp?)?.toDate();
    final advertisingActive =
        advertisingUntil?.isAfter(DateTime.now().toUtc()) ?? false;
    if (!advertisingActive) {
      throw StateError(
        'An active seller subscription is required to publish listings.',
      );
    }
    final batch = _firestore.batch();
    batch.set(listing, {
      'apartmentId': apartment.id,
      'title': title.trim(),
      'category': category,
      'condition': condition,
      'description': description.trim(),
      'price': price,
      'listingType': isRental ? 'rent' : 'sale',
      'securityDeposit': securityDeposit,
      'availableFrom': availableFrom == null
          ? null
          : Timestamp.fromDate(availableFrom),
      'availableTo': availableTo == null
          ? null
          : Timestamp.fromDate(availableTo),
      'sellerId': user.uid,
      'sellerName': user.displayName ?? user.email ?? 'Verified resident',
      'imageUrls': imageUrls,
      'active': true,
      'promotedUntil': Timestamp.fromDate(advertisingUntil!),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(privateDetails, {
      'sellerId': user.uid,
      'pickupHouseNumber': pickupHouseNumber.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<List<String>> uploadListingImages({
    required Apartment apartment,
    required List<({String name, Uint8List bytes})> images,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    final urls = <String>[];
    final stamp = DateTime.now().microsecondsSinceEpoch;
    for (var index = 0; index < images.length; index++) {
      final image = images[index];
      final extension = image.name.toLowerCase().endsWith('.png')
          ? 'png'
          : 'jpg';
      final reference = FirebaseStorage.instance.ref(
        'apartments/${apartment.id}/listings/${user.uid}/'
        '${stamp}_$index.$extension',
      );
      await reference.putData(
        image.bytes,
        SettableMetadata(contentType: 'image/$extension'),
      );
      urls.add(await reference.getDownloadURL());
    }
    return urls;
  }

  Future<String> createReservation({
    required Apartment apartment,
    required MarketplaceListing listing,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    if (listing.sellerId == user.uid) {
      throw StateError('You cannot buy your own listing.');
    }
    final reservation = _firestore
        .collection('apartments')
        .doc(apartment.id)
        .collection('reservations')
        .doc();
    final participantIds = [user.uid, listing.sellerId]..sort();
    final chatId = participantIds.join('_');
    final chat = _firestore
        .collection('apartments')
        .doc(apartment.id)
        .collection('chats')
        .doc(chatId);
    final batch = _firestore.batch();
    batch.set(reservation, {
      'apartmentId': apartment.id,
      'listingId': listing.id,
      'listingTitle': listing.title,
      'askingPrice': listing.price,
      'buyerId': user.uid,
      'buyerName': user.displayName ?? user.email,
      'sellerId': listing.sellerId,
      'sellerName': listing.sellerName,
      'reservationType': listing.isRental ? 'rent' : 'sale',
      'status': 'pending',
      'collected': false,
      'chatId': chatId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(chat, {
      'participants': participantIds,
      'participantNames': {
        user.uid: user.displayName ?? user.email ?? 'Buyer',
        listing.sellerId: listing.sellerName,
      },
      'listingId': listing.id,
      'listingTitle': listing.title,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final notification = _firestore
        .collection('users')
        .doc(listing.sellerId)
        .collection('notifications')
        .doc();
    batch.set(notification, {
      'recipientId': listing.sellerId,
      'actorId': user.uid,
      'type': 'reservation_requested',
      'title': 'New reservation request',
      'body': '${user.displayName ?? 'A neighbour'} wants ${listing.title}.',
      'apartmentId': apartment.id,
      'reservationId': reservation.id,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return reservation.id;
  }

  Future<void> acceptReservation({
    required Apartment apartment,
    required String reservationId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    final reservation = _firestore
        .collection('apartments')
        .doc(apartment.id)
        .collection('reservations')
        .doc(reservationId);

    late String listingId;
    await _firestore.runTransaction((transaction) async {
      final reservationSnapshot = await transaction.get(reservation);
      final data = reservationSnapshot.data();
      if (data == null || data['sellerId'] != user.uid) {
        throw StateError('This reservation is not available to you.');
      }
      if (data['status'] != 'pending') {
        throw StateError('This reservation has already been handled.');
      }
      listingId = data['listingId'] as String;
      final listing = _firestore
          .collection('apartments')
          .doc(apartment.id)
          .collection('listings')
          .doc(listingId);
      final listingSnapshot = await transaction.get(listing);
      final listingData = listingSnapshot.data();
      if (listingData == null || listingData['sellerId'] != user.uid) {
        throw StateError('The listing is no longer available.');
      }
      if (listingData['active'] != true || listingData['reservedBy'] != null) {
        throw StateError('Another reservation already has this item.');
      }
      transaction.update(reservation, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(listing, {
        'active': false,
        'reservedBy': data['buyerId'],
        'acceptedReservationId': reservationId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final notification = _firestore
          .collection('users')
          .doc(data['buyerId'] as String)
          .collection('notifications')
          .doc();
      transaction.set(notification, {
        'recipientId': data['buyerId'],
        'actorId': user.uid,
        'type': 'reservation_accepted',
        'title': 'Reservation accepted',
        'body': '${data['listingTitle']} is reserved for you.',
        'apartmentId': apartment.id,
        'reservationId': reservationId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    final competing = await _firestore
        .collection('apartments')
        .doc(apartment.id)
        .collection('reservations')
        .where('listingId', isEqualTo: listingId)
        .get();
    final batch = _firestore.batch();
    for (final document in competing.docs) {
      if (document.id == reservationId ||
          document.data()['status'] != 'pending') {
        continue;
      }
      batch.update(document.reference, {
        'status': 'declined',
        'declineReason': 'Another reservation was accepted.',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> updateReservationStatus({
    required Apartment apartment,
    required String reservationId,
    required String status,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    final reservation = _firestore
        .collection('apartments')
        .doc(apartment.id)
        .collection('reservations')
        .doc(reservationId);
    final data = (await reservation.get()).data();
    if (data == null) throw StateError('Reservation not found.');
    final currentStatus = data['status'] as String? ?? 'pending';
    final seller = data['sellerId'] == user.uid;
    final buyer = data['buyerId'] == user.uid;
    final allowed = switch ((currentStatus, status)) {
      ('pending', 'declined') => seller,
      ('accepted', 'ready_for_pickup') => seller,
      ('ready_for_pickup', 'collected') => seller || buyer,
      ('pending', 'cancelled') || ('accepted', 'cancelled') => buyer,
      _ => false,
    };
    if (!allowed) throw StateError('This status change is not allowed.');
    await reservation.update({
      'status': status,
      'collected': status == 'collected',
      '${status}At': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final recipientId = seller
        ? data['buyerId'] as String
        : data['sellerId'] as String;
    await _createNotification(
      recipientId: recipientId,
      type: 'reservation_$status',
      title: switch (status) {
        'declined' => 'Reservation declined',
        'ready_for_pickup' => 'Item ready for pickup',
        'collected' => 'Collection confirmed',
        'cancelled' => 'Reservation cancelled',
        _ => 'Reservation updated',
      },
      body: '${data['listingTitle']} is now ${status.replaceAll('_', ' ')}.',
      apartmentId: apartment.id,
      reservationId: reservationId,
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSavedListings() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('savedListings')
        .orderBy('savedAt', descending: true)
        .snapshots();
  }

  Future<bool> isListingSaved(String listingId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    return (await _firestore
            .collection('users')
            .doc(uid)
            .collection('savedListings')
            .doc(listingId)
            .get())
        .exists;
  }

  Future<void> setListingSaved({
    required Apartment apartment,
    required MarketplaceListing listing,
    required bool saved,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('You must be signed in.');
    final reference = _firestore
        .collection('users')
        .doc(uid)
        .collection('savedListings')
        .doc(listing.id);
    if (!saved) return reference.delete();
    await reference.set({
      'listingId': listing.id,
      'apartmentId': apartment.id,
      'title': listing.title,
      'priceLabel': listing.priceLabel,
      'sellerName': listing.sellerName,
      'imageUrl': listing.imageUrls.firstOrNull,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitReview({
    required Apartment apartment,
    required String reservationId,
    required int rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    final reservation = await _firestore
        .collection('apartments')
        .doc(apartment.id)
        .collection('reservations')
        .doc(reservationId)
        .get();
    final data = reservation.data();
    if (data == null ||
        data['buyerId'] != user.uid ||
        data['status'] != 'collected') {
      throw StateError('You can review only a collected reservation.');
    }
    final review = _firestore
        .collection('apartments')
        .doc(apartment.id)
        .collection('reviews')
        .doc(reservationId);
    await review.set({
      'reservationId': reservationId,
      'listingId': data['listingId'],
      'listingTitle': data['listingTitle'],
      'reviewerId': user.uid,
      'reviewerName': user.displayName ?? 'Verified neighbour',
      'revieweeId': data['sellerId'],
      'rating': rating.clamp(1, 5),
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _createNotification(
      recipientId: data['sellerId'] as String,
      type: 'review_received',
      title: 'New review',
      body: '${user.displayName ?? 'A buyer'} left you a $rating-star review.',
      apartmentId: apartment.id,
    );
  }

  Future<void> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
    String? apartmentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    await _firestore.collection('reports').add({
      'reporterId': user.uid,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'apartmentId': apartmentId,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> blockUser(String blockedUserId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('You must be signed in.');
    if (uid == blockedUserId) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('blockedUsers')
        .doc(blockedUserId)
        .set({
          'blockedUserId': blockedUserId,
          'blockedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<bool> isUserBlocked(String userId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    return (await _firestore
            .collection('users')
            .doc(uid)
            .collection('blockedUsers')
            .doc(userId)
            .get())
        .exists;
  }

  Future<void> notifyChatMessage({
    required Apartment apartment,
    required String chatId,
    required String recipientId,
    required String preview,
  }) => _createNotification(
    recipientId: recipientId,
    type: 'chat_message',
    title: 'New message',
    body: preview.length > 80 ? '${preview.substring(0, 80)}…' : preview,
    apartmentId: apartment.id,
    chatId: chatId,
  );

  Future<void> _createNotification({
    required String recipientId,
    required String type,
    required String title,
    required String body,
    String? apartmentId,
    String? reservationId,
    String? chatId,
  }) async {
    final actor = _auth.currentUser;
    if (actor == null || actor.uid == recipientId) return;
    await _firestore
        .collection('users')
        .doc(recipientId)
        .collection('notifications')
        .add({
          'recipientId': recipientId,
          'actorId': actor.uid,
          'type': type,
          'title': title,
          'body': body,
          'apartmentId': apartmentId,
          'reservationId': reservationId,
          'chatId': chatId,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> relistCancelledReservation({
    required Apartment apartment,
    required String reservationId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    final reservation = _firestore
        .collection('apartments')
        .doc(apartment.id)
        .collection('reservations')
        .doc(reservationId);
    final data = (await reservation.get()).data();
    if (data == null || data['sellerId'] != user.uid) {
      throw StateError('This reservation is not available to you.');
    }
    if (data['status'] != 'cancelled') {
      throw StateError('Only a cancelled reservation can be relisted.');
    }
    await _firestore
        .collection('apartments')
        .doc(apartment.id)
        .collection('listings')
        .doc(data['listingId'] as String)
        .update({
          'active': true,
          'reservedBy': FieldValue.delete(),
          'acceptedReservationId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<bool> hasActiveSellerAdvertising() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final document = await _firestore.collection('users').doc(user.uid).get();
    final until = (document.data()?['sellerAdvertisingUntil'] as Timestamp?)
        ?.toDate();
    return until?.isAfter(DateTime.now().toUtc()) ?? false;
  }

  Future<void> activateSellerAdvertising({
    required Apartment apartment,
    required String purchaseId,
    required String purchaseToken,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    final callable = FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).httpsCallable('verifySellerSubscription');
    await callable.call<void>({
      'purchaseToken': purchaseToken,
      'purchaseId': purchaseId,
    });
  }

  Future<String> getOrCreateChat({
    required Apartment apartment,
    required MarketplaceListing listing,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    final ids = [user.uid, listing.sellerId]..sort();
    final chatId = ids.join('_');
    await _firestore
        .collection('apartments')
        .doc(apartment.id)
        .collection('chats')
        .doc(chatId)
        .set({
          'participants': ids,
          'participantNames': {
            user.uid: user.displayName ?? user.email ?? 'Buyer',
            listing.sellerId: listing.sellerName,
          },
          'listingId': listing.id,
          'listingTitle': listing.title,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    return chatId;
  }

  Future<Apartment> createApartment({required String name}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('A landlord must be signed in.');
    final code = await _createUniqueInvitationCode(name);
    final document = await _firestore.collection('apartments').add({
      'name': name.trim(),
      'invitationCode': code,
      'ownerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('users').doc(user.uid).set({
      'role': UserRole.landlord.name,
      'roles': FieldValue.arrayUnion([UserRole.landlord.name]),
      'managedApartmentIds': FieldValue.arrayUnion([document.id]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return Apartment(id: document.id, name: name.trim(), invitationCode: code);
  }

  Future<void> removeManagedApartment(String apartmentId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('A property manager must be signed in.');
    await _firestore.collection('apartments').doc(apartmentId).delete();
    await _firestore.collection('users').doc(user.uid).set({
      'managedApartmentIds': FieldValue.arrayRemove([apartmentId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> _createUniqueInvitationCode(String name) async {
    final letters = name.replaceAll(RegExp('[^A-Za-z]'), '').toUpperCase();
    final prefix = (letters.isEmpty ? 'HOME' : letters).substring(
      0,
      min(5, letters.isEmpty ? 4 : letters.length),
    );
    final random = Random.secure();
    for (var attempt = 0; attempt < 8; attempt++) {
      final suffix = 1000 + random.nextInt(9000);
      final code = '$prefix$suffix';
      final existing = await _firestore
          .collection('apartments')
          .where('invitationCode', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) return code;
    }
    throw StateError('Could not generate a unique invitation code.');
  }
}
