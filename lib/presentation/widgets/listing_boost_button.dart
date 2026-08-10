import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community_models.dart';
import '../../services/listing_boost_service.dart';
import '../../state/auth_providers.dart';

class ListingBoostButton extends ConsumerStatefulWidget {
  const ListingBoostButton({
    super.key,
    required this.apartment,
    required this.listing,
  });

  final Apartment apartment;
  final MarketplaceListing listing;

  @override
  ConsumerState<ListingBoostButton> createState() => _ListingBoostButtonState();
}

class _ListingBoostButtonState extends ConsumerState<ListingBoostButton> {
  StreamSubscription<BoostPurchaseOutcome>? _outcomes;
  String? _price;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _outcomes = ListingBoostService.instance.outcomes.listen(_handleOutcome);
    unawaited(_load());
  }

  Future<void> _load() async {
    final product = await ListingBoostService.instance.loadProduct();
    if (mounted) setState(() => _price = product?.price);
  }

  Future<void> _buy() async {
    setState(() => _busy = true);
    final started = await ListingBoostService.instance.buyFor(
      widget.listing.id,
    );
    if (!started && mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Listing boosts are not available from Google Play yet.',
          ),
        ),
      );
    }
  }

  Future<void> _handleOutcome(BoostPurchaseOutcome outcome) async {
    if (outcome.listingId != widget.listing.id) return;
    if (!outcome.successful) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    try {
      await ref
          .read(communityServiceProvider)
          .boostListing(
            apartment: widget.apartment,
            listingId: widget.listing.id,
            purchaseId: outcome.purchaseId,
          );
      await ListingBoostService.instance.complete(outcome);
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing boosted for 7 days.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Purchase received, but the boost could not be applied.',
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
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: _busy ? null : _buy,
    icon: const Icon(Icons.rocket_launch_outlined, size: 18),
    label: Text(
      _busy
          ? 'Opening Google Play…'
          : 'Boost for 7 days${_price == null ? '' : ' • $_price'}',
    ),
  );
}
