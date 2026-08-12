import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community_models.dart';
import '../../services/seller_subscription_service.dart';
import '../../state/auth_providers.dart';
import '../screens/splash_screen.dart';

class SellerSubscriptionCard extends ConsumerStatefulWidget {
  const SellerSubscriptionCard({super.key, required this.apartment});

  final Apartment apartment;

  @override
  ConsumerState<SellerSubscriptionCard> createState() =>
      _SellerSubscriptionCardState();
}

class _SellerSubscriptionCardState
    extends ConsumerState<SellerSubscriptionCard> {
  StreamSubscription<SellerSubscriptionOutcome>? _outcomes;
  String? _weeklyPrice;
  bool _busy = false;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _outcomes = SellerSubscriptionService.instance.outcomes.listen(
      _handleOutcome,
    );
    unawaited(_load());
  }

  Future<void> _load() async {
    final active = await ref
        .read(communityServiceProvider)
        .hasActiveSellerAdvertising();
    await SellerSubscriptionService.instance.loadProduct();
    if (!mounted) return;
    setState(() {
      _active = active;
      _weeklyPrice = SellerSubscriptionService.instance.recurringPrice;
    });
  }

  Future<void> _subscribe() async {
    setState(() => _busy = true);
    final started = await SellerSubscriptionService.instance.subscribe();
    if (!started && mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The seller advertising plan is not available yet.'),
        ),
      );
    }
  }

  Future<void> _handleOutcome(SellerSubscriptionOutcome outcome) async {
    if (!outcome.successful) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    try {
      await ref
          .read(communityServiceProvider)
          .activateSellerAdvertising(
            apartment: widget.apartment,
            purchaseId: outcome.purchaseId,
            purchaseToken: outcome.verificationToken,
          );
      await SellerSubscriptionService.instance.complete(outcome);
      if (!mounted) return;
      setState(() {
        _active = true;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seller plan active. You can now publish listings.'),
        ),
      );
      Navigator.of(context).maybePop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Subscription received, but advertising could not be activated.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _outcomes?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF6EE),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFB9DEC6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.campaign_outlined, color: primaryGreen),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                _active ? 'Seller plan active' : 'Unlock seller listings',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          _active
              ? 'You can publish sale and rental listings while your plan remains active.'
              : 'A seller plan is required to publish goods. Get one week free, then ${_weeklyPrice ?? 'KSh 50'} per week. Cancel anytime in Google Play.',
        ),
        if (!_active) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _subscribe,
              icon: const Icon(Icons.rocket_launch_outlined),
              label: Text(
                _busy ? 'Opening Google Play…' : 'Start one-week free trial',
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
