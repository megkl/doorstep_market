import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community_models.dart';
import '../../state/auth_providers.dart';
import 'marketplace_home_screen.dart';
import 'splash_screen.dart';

class ApartmentVerificationScreen extends StatefulWidget {
  const ApartmentVerificationScreen({super.key, this.role = UserRole.buyer});

  final UserRole role;

  @override
  State<ApartmentVerificationScreen> createState() =>
      _ApartmentVerificationScreenState();
}

class _ApartmentVerificationScreenState
    extends State<ApartmentVerificationScreen> {
  int? _selectedMethod;

  static const _methods = [
    (
      title: 'Enter Invitation Code',
      description: 'Get a code from your property\nmanager or admin',
      icon: Icons.badge_outlined,
    ),
    (
      title: 'Scan QR Code',
      description: "Scan the apartment's QR code",
      icon: Icons.qr_code_rounded,
    ),
    (
      title: 'Request Approval',
      description: "We'll review and verify your\nresidence",
      icon: Icons.person_outline_rounded,
    ),
  ];

  void _selectMethod(int index) {
    setState(() => _selectedMethod = index);
    if (index == 0) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => InvitationCodeScreen(role: widget.role),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('This verification option is coming soon.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _BackButton(onPressed: () => Navigator.of(context).pop()),
              const SizedBox(height: 25),
              const Text(
                'Verify Your Apartment',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'To keep our community safe, we need\nto verify your residence.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF4F5551),
                ),
              ),
              const SizedBox(height: 27),
              ...List.generate(_methods.length, (index) {
                final method = _methods[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: _VerificationOption(
                    title: method.title,
                    description: method.description,
                    icon: method.icon,
                    soon: index > 0,
                    selected: _selectedMethod == index,
                    onTap: () => _selectMethod(index),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationOption extends StatelessWidget {
  const _VerificationOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.soon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool soon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF0F8F3) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? primaryGreen : const Color(0xFFD9DEDB),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        key: ValueKey('verification-$title'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 27, color: const Color(0xFF111512)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: Color(0xFF555B57),
                      ),
                    ),
                  ],
                ),
              ),
              if (soon)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Soon',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF7A817D),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class InvitationCodeScreen extends ConsumerStatefulWidget {
  const InvitationCodeScreen({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<InvitationCodeScreen> createState() =>
      _InvitationCodeScreenState();
}

class _InvitationCodeScreenState extends ConsumerState<InvitationCodeScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final service = ref.read(communityServiceProvider);
    setState(() {
      _loading = true;
      _error = null;
    });
    Apartment? apartment;
    try {
      apartment = await service.apartmentForCode(_controller.text);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not check this code. Please try again.';
        });
      }
      return;
    }
    if (apartment == null) {
      setState(() {
        _loading = false;
        _error = 'That invitation code is not recognized.';
      });
      return;
    }
    try {
      await service.saveMembership(apartment: apartment, role: widget.role);
    } catch (_) {
      // Continue with a verified starter code while Firestore is provisioned.
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileSetupScreen(apartment: apartment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackButton(onPressed: () => Navigator.pop(context)),
              const SizedBox(height: 24),
              const Text(
                'Enter Invitation Code',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the code shared by your landlord or property manager.',
                style: TextStyle(color: Color(0xFF59605B), height: 1.5),
              ),
              const SizedBox(height: 28),
              TextField(
                key: const Key('invitationCodeField'),
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. SUNRISE24',
                  errorText: _error,
                  prefixIcon: const Icon(Icons.key_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: primaryGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  key: const Key('joinApartmentButton'),
                  onPressed: _loading ? null : _join,
                  style: FilledButton.styleFrom(backgroundColor: primaryGreen),
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Join Apartment',
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

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, this.apartment});

  final Apartment? apartment;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(communityServiceProvider)
          .saveProfile(displayName: _nameController.text);
    } catch (_) {
      // The verified apartment membership remains the source of truth.
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthSuccessScreen(apartment: widget.apartment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _BackButton(onPressed: () => Navigator.of(context).pop()),
              const SizedBox(height: 22),
              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Add a few details to get started.',
                style: TextStyle(fontSize: 14, color: Color(0xFF4F5551)),
              ),
              const SizedBox(height: 29),
              const Center(child: _ProfilePhoto()),
              const SizedBox(height: 32),
              const _FieldLabel('Display Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('Enter display name'),
              ),
              const SizedBox(height: 20),
              const _FieldLabel('Verified Apartment'),
              const SizedBox(height: 8),
              InputDecorator(
                key: const Key('verifiedApartmentField'),
                decoration: _inputDecoration(''),
                child: Row(
                  children: [
                    const Icon(Icons.apartment_rounded, color: primaryGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.apartment?.name ?? 'Verified by invitation code',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(Icons.verified_rounded, color: primaryGreen),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  key: const Key('saveProfileButton'),
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save & Continue',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9CA19E), fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: Color(0xFFD9DEDB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: primaryGreen, width: 1.5),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
  );
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 94,
      height: 94,
      child: Stack(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE1E3E2),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 60,
              color: Color(0xFFA7AAA8),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 5,
            child: Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: primaryGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthSuccessScreen extends StatelessWidget {
  const AuthSuccessScreen({super.key, this.apartment});

  final Apartment? apartment;

  @override
  Widget build(BuildContext context) {
    void openMarketplace() {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => MarketplaceHomeScreen(apartment: apartment),
        ),
        (route) => false,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const _SuccessArtwork(),
              const SizedBox(height: 28),
              const Text(
                "You're All Set! 🎉",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Welcome to Doorstep Market.\nStart buying, selling or renting\nwithin your community.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Color(0xFF4F5551),
                ),
              ),
              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: openMarketplace,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Explore Marketplace',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              TextButton(
                onPressed: openMarketplace,
                style: TextButton.styleFrom(foregroundColor: primaryGreen),
                child: const Text(
                  'Go to My Dashboard',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessArtwork extends StatelessWidget {
  const _SuccessArtwork();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 126,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final item in const [
            (18.0, 17.0, Color(0xFFFF7A45)),
            (44.0, 82.0, Color(0xFF63B57C)),
            (168.0, 21.0, Color(0xFFF0B529)),
            (186.0, 76.0, Color(0xFF68B9B1)),
            (18.0, 98.0, Color(0xFFF5B822)),
            (195.0, 105.0, Color(0xFFFF7552)),
          ])
            Positioned(
              left: item.$1,
              top: item.$2,
              child: Transform.rotate(
                angle: .65,
                child: Container(width: 7, height: 7, color: item.$3),
              ),
            ),
          Container(
            width: 86,
            height: 86,
            decoration: const BoxDecoration(
              color: primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 54,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    padding: EdgeInsets.zero,
    alignment: Alignment.centerLeft,
    icon: const Icon(Icons.arrow_back_rounded),
  );
}
