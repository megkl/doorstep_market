import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'onboarding_screen.dart';
import 'account_gate_screen.dart';

const primaryGreen = Color(0xFF2E9B57);
const darkGreen = Color(0xFF217A46);
const accentYellow = Color(0xFFFFC23D);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1800), _openNextScreen);
  }

  void _openNextScreen() {
    if (!mounted) return;
    var authenticated = false;
    try {
      authenticated = FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      // Firebase is not initialized in widget tests or offline previews.
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => authenticated
            ? const AccountGateScreen()
            : const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryGreen,
      body: SafeArea(
        child: InkWell(
          onTap: _openNextScreen,
          child: Stack(
            children: [
              const Positioned.fill(child: _SplashBackground()),
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 100),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _SplashLogo(size: 126),
                      const SizedBox(height: 22),
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'Doorstep\n'),
                            TextSpan(
                              text: 'Market',
                              style: TextStyle(color: accentYellow),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          height: 1.02,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Buy, sell or rent items\nwithin your apartment\ncommunity.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 27,
                child: _SplashDots(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        'assets/images/doorstep-logo.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'Doorstep Market logo',
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SkylinePainter());
  }
}

class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withAlpha(13);
    final heights = <double>[.08, .13, .19, .12, .24, .17, .1, .21, .14];
    final width = size.width / heights.length;
    for (var i = 0; i < heights.length; i++) {
      final rect = Rect.fromLTWH(
        i * width + 2,
        size.height * (1 - heights[i]),
        width - 5,
        size.height * heights[i],
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        paint,
      );
    }
    canvas.drawCircle(Offset(size.width * .1, size.height * .9), 22, paint);
    canvas.drawCircle(Offset(size.width * .9, size.height * .91), 26, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SplashDots extends StatelessWidget {
  const _SplashDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: index == 0 ? 17 : 9,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(index == 0 ? 255 : 100),
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
    );
  }
}
