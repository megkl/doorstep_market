import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';

class AuthFlowNotifier extends StateNotifier<AuthRoute> {
  AuthFlowNotifier() : super(AuthRoute.splash);

  void nextFromSplash() {
    state = AuthRoute.onboarding;
  }

  void skipOnboarding() {
    state = AuthRoute.login;
  }

  void goToLogin() {
    state = AuthRoute.login;
  }

  void goToSignup() {
    state = AuthRoute.signup;
  }

  void goToVerifyPhone() {
    state = AuthRoute.verifyPhone;
  }

  void goToCreatePassword() {
    state = AuthRoute.createPassword;
  }

  void goToApartmentVerification() {
    state = AuthRoute.apartmentVerification;
  }

  void goToProfileSetup() {
    state = AuthRoute.profileSetup;
  }

  void goToSuccess() {
    state = AuthRoute.success;
  }

  void goToMarketplace() {
    state = AuthRoute.marketplace;
  }
}

final authFlowProvider = StateNotifierProvider<AuthFlowNotifier, AuthRoute>((
  ref,
) {
  return AuthFlowNotifier();
});

final onboardingPageProvider = StateProvider<int>((ref) => 0);
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final communityServiceProvider = Provider<CommunityService>(
  (ref) => CommunityService(),
);
final signupFormProvider = StateProvider<SignupFormState>(
  (ref) => const SignupFormState(),
);
final loginFormProvider = StateProvider<LoginFormState>(
  (ref) => const LoginFormState(),
);
final passwordFormProvider = StateProvider<PasswordFormState>(
  (ref) => const PasswordFormState(),
);
final profileFormProvider = StateProvider<ProfileFormState>(
  (ref) => const ProfileFormState(),
);
final verificationCodeProvider = StateProvider<String>((ref) => '');
final apartmentRequestProvider = StateProvider<String>((ref) => '');
final resendCountdownProvider = StateProvider<int>((ref) => 30);
