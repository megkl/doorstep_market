import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community_models.dart';
import 'account_setup_screens.dart';
import 'landlord_screens.dart';
import 'marketplace_home_screen.dart';
import 'splash_screen.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key, this.apartment});

  final Apartment? apartment;

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selected;
  bool _opening = false;

  Future<void> _continue() async {
    final role = _selected;
    if (role == null || _opening) return;
    setState(() => _opening = true);
    Widget destination;
    if (role == UserRole.landlord) {
      destination = const LandlordPortfolioScreen();
    } else {
      destination = widget.apartment == null
          ? const ApartmentVerificationScreen()
          : MarketplaceHomeScreen(apartment: widget.apartment);
    }
    if (!mounted) return;
    setState(() => _opening = false);
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'How would you like\nto continue?',
                style: TextStyle(
                  fontSize: 29,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Use the community marketplace or manage your properties.',
                style: TextStyle(
                  color: Color(0xFF5D635F),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              for (final role in const [UserRole.buyer, UserRole.landlord])
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _RoleCard(
                    role: role,
                    selected: _selected == role,
                    onTap: () => setState(() => _selected = role),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  key: const Key('continueRoleButton'),
                  onPressed: _selected == null || _opening ? null : _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryGreen,
                    disabledBackgroundColor: const Color(0xFFD9E0DC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: _opening
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  IconData get icon => switch (role) {
    UserRole.buyer => Icons.storefront_outlined,
    UserRole.seller => Icons.storefront_outlined,
    UserRole.landlord => Icons.apartment_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEDF7F1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? primaryGreen : const Color(0xFFDCE1DE),
          width: selected ? 1.7 : 1,
        ),
      ),
      child: InkWell(
        key: ValueKey('role-${role.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: selected ? primaryGreen : const Color(0xFFF1F5F2),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : primaryGreen,
                  size: 27,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role == UserRole.buyer ? 'Marketplace' : role.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role == UserRole.buyer
                          ? 'Buy, sell or rent within your verified apartment'
                          : role.description,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Color(0xFF636A65),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? primaryGreen : const Color(0xFFBBC1BD),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
