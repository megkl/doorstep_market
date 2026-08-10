import 'package:flutter/material.dart';

import 'auth_screen.dart';
import 'splash_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingData(
      title: 'Your Community\nMarketplace',
      description:
          'Buy, sell or rent household items\nfrom verified neighbors in your\napartment.',
      illustration: _CommunityIllustration(),
    ),
    _OnboardingData(
      title: 'Safe & Secure\nTransactions',
      description:
          'We verify residents so you can\nreserve items and arrange pickup\nwith trusted neighbours.',
      illustration: _SecurityIllustration(),
    ),
    _OnboardingData(
      title: 'Nearby. Convenient.\nAffordable.',
      description: 'Find great deals close to home\nand save on transport.',
      illustration: _NearbyIllustration(),
    ),
  ];

  void _finish() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AuthScreen(mode: AuthMode.signIn),
      ),
    );
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(foregroundColor: Colors.black87),
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: _pages[index]),
              ),
            ),
            _PageIndicator(current: _page, count: _pages.length),
            const SizedBox(height: 27),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(_page == 2 ? 'Get Started' : 'Next'),
                ),
              ),
            ),
            SizedBox(
              height: 54,
              child: _page < 2
                  ? TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text('Skip'),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.description,
    required this.illustration,
  });
  final String title;
  final String description;
  final Widget illustration;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});
  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          SizedBox(
            height: 250,
            width: double.infinity,
            child: data.illustration,
          ),
          const Spacer(),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -.35,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF444444),
              height: 1.45,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.current, required this.count});
  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == current ? 17 : 9,
          height: 5,
          decoration: BoxDecoration(
            color: index == current ? primaryGreen : const Color(0xFFE6E7E7),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }
}

class _CommunityIllustration extends StatelessWidget {
  const _CommunityIllustration();
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/onboarding/community.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Neighbors buying and selling household items',
    );
  }
}

class _SecurityIllustration extends StatelessWidget {
  const _SecurityIllustration();
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/onboarding/security.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Secure marketplace transactions',
    );
  }
}

class _NearbyIllustration extends StatelessWidget {
  const _NearbyIllustration();
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/onboarding/nearby.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Nearby marketplace items in your apartment community',
    );
  }
}
