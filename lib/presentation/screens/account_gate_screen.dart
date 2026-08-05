import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community_models.dart';
import '../../state/auth_providers.dart';
import 'account_setup_screens.dart';
import 'marketplace_home_screen.dart';
import 'role_selection_screen.dart';
import 'splash_screen.dart';

class AccountGateScreen extends ConsumerStatefulWidget {
  const AccountGateScreen({super.key});

  @override
  ConsumerState<AccountGateScreen> createState() => _AccountGateScreenState();
}

class _AccountGateScreenState extends ConsumerState<AccountGateScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    setState(() => _error = null);
    try {
      final service = ref.read(communityServiceProvider);
      final results = await Future.wait([
        service.loadApprovedApartment(),
        service.isCurrentUserWhitelistedLandlord(),
      ]);
      if (!mounted) return;
      final apartment = results[0] as Apartment?;
      final isManager = results[1] as bool;
      final destination = isManager
          ? RoleSelectionScreen(apartment: apartment)
          : apartment != null
          ? MarketplaceHomeScreen(apartment: apartment)
          : const ApartmentVerificationScreen();
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: _error == null
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primaryGreen),
                  SizedBox(height: 14),
                  Text('Opening your community...'),
                ],
              )
            : FilledButton(onPressed: _resolve, child: const Text('Try Again')),
      ),
    ),
  );
}
