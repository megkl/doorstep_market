// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doorstep_market/presentation/app.dart';
import 'package:doorstep_market/presentation/screens/account_setup_screens.dart';
import 'package:doorstep_market/presentation/screens/auth_screen.dart';
import 'package:doorstep_market/presentation/screens/role_selection_screen.dart';

void main() {
  testWidgets('App launches with splash then opens onboarding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(ProviderScope(child: const DoorstepMarketApp()));

    expect(find.textContaining('Doorstep'), findsOneWidget);
    expect(
      find.text('Buy, sell or rent items\nwithin your apartment\ncommunity.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    expect(find.text('Your Community\nMarketplace'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Welcome Back 👋'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Password'), findsNothing);
    expect(find.text('Phone number'), findsNothing);

    await tester.tap(find.byKey(const Key('switchAuthModeButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign up with Google'), findsOneWidget);
  });

  testWidgets('UI-only account setup flow reaches success', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthScreen(
            mode: AuthMode.signUp,
            googleSignInOverride: _completeFakeGoogleSignIn,
            authenticatedDestinationOverride: RoleSelectionScreen(),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('googleAuthButton')));
    await tester.pumpAndSettle();
    expect(find.text('How would you like\nto continue?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('role-buyer')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('continueRoleButton')));
    await tester.pumpAndSettle();
    expect(find.text('Verify Your Apartment'), findsOneWidget);

    await tester.tap(find.text('Enter Invitation Code'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invitationCodeField')), findsOneWidget);
    expect(find.textContaining('Starter codes'), findsNothing);

    await tester.pumpWidget(
      const ProviderScope(
        key: ValueKey('profileTestScope'),
        child: MaterialApp(home: ProfileSetupScreen()),
      ),
    );
    expect(find.text('Complete Your Profile'), findsOneWidget);

    await tester.tap(find.byKey(const Key('saveProfileButton')));
    await tester.pumpAndSettle();
    expect(find.text("You're All Set! 🎉"), findsOneWidget);
    expect(find.text('Explore Marketplace'), findsOneWidget);

    await tester.tap(find.text('Explore Marketplace'));
    await tester.pumpAndSettle();
    expect(find.text('Your Apartment'), findsOneWidget);
    expect(
      find.text('Verify your apartment to view its marketplace.'),
      findsOneWidget,
    );
  });
}

Future<void> _completeFakeGoogleSignIn() async {}
