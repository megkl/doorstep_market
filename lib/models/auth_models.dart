import 'package:flutter/material.dart';

enum AuthRoute {
  splash,
  onboarding,
  login,
  signup,
  verifyPhone,
  createPassword,
  apartmentVerification,
  profileSetup,
  success,
  marketplace,
}

class SignupFormState {
  final String fullName;
  final String phone;

  const SignupFormState({this.fullName = '', this.phone = ''});

  SignupFormState copyWith({String? fullName, String? phone}) {
    return SignupFormState(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
    );
  }
}

class LoginFormState {
  final String phone;
  final String password;

  const LoginFormState({this.phone = '', this.password = ''});

  LoginFormState copyWith({String? phone, String? password}) {
    return LoginFormState(
      phone: phone ?? this.phone,
      password: password ?? this.password,
    );
  }
}

class PasswordFormState {
  final String password;
  final String confirmPassword;

  const PasswordFormState({this.password = '', this.confirmPassword = ''});

  PasswordFormState copyWith({String? password, String? confirmPassword}) {
    return PasswordFormState(
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
    );
  }
}

class ProfileFormState {
  final String displayName;
  final String apartment;

  const ProfileFormState({this.displayName = '', this.apartment = ''});

  ProfileFormState copyWith({String? displayName, String? apartment}) {
    return ProfileFormState(
      displayName: displayName ?? this.displayName,
      apartment: apartment ?? this.apartment,
    );
  }
}

class ApartmentOption {
  final String title;
  final String description;
  final IconData icon;

  const ApartmentOption({
    required this.title,
    required this.description,
    required this.icon,
  });
}
