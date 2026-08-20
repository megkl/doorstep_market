import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import 'account_gate_screen.dart';
import 'splash_screen.dart';

enum AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.mode,
    this.googleSignInOverride,
    this.authenticatedDestinationOverride,
  });

  final AuthMode mode;
  final Future<void> Function()? googleSignInOverride;
  final Widget? authenticatedDestinationOverride;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _loading = false;

  bool get _isSignIn => widget.mode == AuthMode.signIn;

  Future<void> _continueWithGoogle() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      if (widget.googleSignInOverride != null) {
        await widget.googleSignInOverride!();
      } else {
        await AuthService().signInWithGoogle();
      }
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              widget.authenticatedDestinationOverride ??
              const AccountGateScreen(),
        ),
      );
    } on GoogleSignInCancelledException catch (error, stackTrace) {
      debugPrint('Google sign-in cancelled: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showGoogleSignInError(
        'Google sign-in was cancelled. Select an account to continue.',
      );
    } on PlatformException catch (error, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Google Sign-In platform failure: ${error.code}',
      );
      debugPrint(
        'Google platform sign-in failed: ${error.code}: ${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showGoogleSignInError(
        error.code == 'network_error'
            ? 'Could not reach Google. Check your connection and try again.'
            : 'Google sign-in failed (${error.code}). ${error.message ?? ''}'
                  .trim(),
      );
    } on FirebaseAuthException catch (error, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Firebase Google authentication failure: ${error.code}',
      );
      debugPrint(
        'Firebase Google authentication failed: ${error.code}: '
        '${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showGoogleSignInError(
        error.code == 'network-request-failed'
            ? 'Could not reach Google. Check your connection and try again.'
            : 'Google authentication failed (${error.code}). Please try again.',
      );
    } catch (error, stackTrace) {
      debugPrint('Unexpected Google sign-in failure: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showGoogleSignInError(
        'Google sign-in could not be completed. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showGoogleSignInError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _switchMode() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) =>
            AuthScreen(mode: _isSignIn ? AuthMode.signUp : AuthMode.signIn),
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const Spacer(),
              const Center(child: _AnimatedAuthIllustration()),
              const SizedBox(height: 18),
              Text(
                _isSignIn ? 'Welcome Back 👋' : 'Create Account',
                style: const TextStyle(
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isSignIn
                    ? 'Sign in with Google to continue to your Doorstep Market account.'
                    : 'Join your apartment community marketplace with your Google account.',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF555A57),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  key: const Key('googleAuthButton'),
                  onPressed: _loading ? null : _continueWithGoogle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1C211E),
                    side: const BorderSide(color: Color(0xFFDADFDB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.3),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _GoogleMark(),
                              const SizedBox(width: 13),
                              Text(
                                _isSignIn
                                    ? 'Continue with Google'
                                    : 'Sign up with Google',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const Spacer(),
              Center(
                child: TextButton(
                  key: const Key('switchAuthModeButton'),
                  onPressed: _switchMode,
                  style: TextButton.styleFrom(foregroundColor: Colors.black54),
                  child: Text.rich(
                    TextSpan(
                      text: _isSignIn
                          ? "Don't have an account?  "
                          : 'Already have an account?  ',
                      children: [
                        TextSpan(
                          text: _isSignIn ? 'Sign up' : 'Sign in',
                          style: const TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedAuthIllustration extends StatefulWidget {
  const _AnimatedAuthIllustration();

  @override
  State<_AnimatedAuthIllustration> createState() =>
      _AnimatedAuthIllustrationState();
}

class _AnimatedAuthIllustrationState extends State<_AnimatedAuthIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 205,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        child: Image.asset(
          'assets/images/onboarding/community.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        builder: (context, child) {
          final value = Curves.easeInOut.transform(_controller.value);
          return Transform.translate(
            offset: Offset(0, -4 + value * 8),
            child: Transform.scale(scale: .97 + value * .03, child: child),
          );
        },
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 22,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * .2;
    final arcs = <(Color, double, double)>[
      (const Color(0xFF4285F4), -.2, 1.55),
      (const Color(0xFF34A853), 1.35, 1.45),
      (const Color(0xFFFBBC05), 2.8, 1.05),
      (const Color(0xFFEA4335), 3.85, 1.45),
    ];
    for (final arc in arcs) {
      canvas.drawArc(
        rect.deflate(stroke / 2),
        arc.$2,
        arc.$3,
        false,
        Paint()
          ..color = arc.$1
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.square,
      );
    }
    canvas.drawLine(
      Offset(size.width * .53, size.height * .51),
      Offset(size.width * .94, size.height * .51),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.square,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
