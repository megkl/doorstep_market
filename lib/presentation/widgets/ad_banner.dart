import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A consent-aware adaptive AdMob banner.
///
/// Debug builds always use Google's test units. Release builds only request an
/// ad when a production unit is supplied with `--dart-define`.
class DoorstepBannerAd extends StatefulWidget {
  const DoorstepBannerAd({super.key});

  @override
  State<DoorstepBannerAd> createState() => _DoorstepBannerAdState();
}

class _DoorstepBannerAdState extends State<DoorstepBannerAd> {
  BannerAd? _banner;
  int? _loadedWidth;

  String get _adUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/9214589741'
          : 'ca-app-pub-3940256099942544/2435281174';
    }
    return Platform.isAndroid
        ? const String.fromEnvironment('ADMOB_ANDROID_BANNER_ID')
        : const String.fromEnvironment('ADMOB_IOS_BANNER_ID');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width.floor() - 40;
    if (width > 0 && width != _loadedWidth && _adUnitId.isNotEmpty) {
      _loadedWidth = width;
      unawaited(_load(width));
    }
  }

  Future<void> _load(int width) async {
    final canRequestAds = await _AdConsent.instance.initialize();
    if (!canRequestAds || !mounted) return;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;

    final ad = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (loadedAd) {
          if (!mounted) {
            loadedAd.dispose();
            return;
          }
          _banner?.dispose();
          setState(() => _banner = loadedAd as BannerAd);
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          debugPrint('Banner ad failed to load: $error');
        },
      ),
    );
    await ad.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (banner == null) return const SizedBox.shrink();
    return Center(
      child: Semantics(
        label: 'Advertisement',
        child: SizedBox(
          width: banner.size.width.toDouble(),
          height: banner.size.height.toDouble(),
          child: AdWidget(ad: banner),
        ),
      ),
    );
  }
}

class _AdConsent {
  _AdConsent._();

  static final instance = _AdConsent._();
  Future<bool>? _initialization;

  Future<bool> initialize() => _initialization ??= _initialize();

  Future<bool> _initialize() async {
    final update = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => update.complete(),
      (error) => update.complete(),
    );
    await update.future;

    final form = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((error) => form.complete());
    await form.future;

    final canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (canRequestAds) await MobileAds.instance.initialize();
    return canRequestAds;
  }
}
