import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => MarketplaceListing.fromFirestore(
                  document.id,
                  document.data(),
                ),
              )
              .where((listing) => listing.active)
              .toList(),
        );
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
