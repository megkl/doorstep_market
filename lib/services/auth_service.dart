import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInCancelledException implements Exception {
  const GoogleSignInCancelledException();
}

class AuthService {
  static const _webClientId =
      '589396162904-427csadrv49feu281q9p27rcf5vtu9cp.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const <String>['email'],
    serverClientId: _webClientId,
  );

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const GoogleSignInCancelledException();
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<bool> login({required String phone, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return phone.isNotEmpty && password.length >= 6;
  }

  Future<bool> signup({required String fullName, required String phone}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return fullName.trim().isNotEmpty && phone.trim().length >= 10;
  }

  Future<bool> sendVerificationCode(String phone) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return phone.trim().isNotEmpty;
  }

  Future<bool> verifyCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return code.trim().length == 6;
  }

  Future<bool> createPassword(String password, String confirmPassword) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return password == confirmPassword && password.length >= 8;
  }

  Future<bool> requestApartmentVerification(String method) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return method.isNotEmpty;
  }

  Future<bool> completeProfile(String displayName, String apartment) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return displayName.trim().isNotEmpty && apartment.trim().isNotEmpty;
  }
}
