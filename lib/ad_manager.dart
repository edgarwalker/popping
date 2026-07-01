import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static final AdManager _instance = AdManager._();
  static AdManager get instance => _instance;
  AdManager._();

  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;
  int _levelGameOverCount = 0;
  bool _initialized = false;

  // Test ad unit IDs — replace with real ones before publishing
  String get _interstitialAdUnitId =>
      Platform.isAndroid
          ? 'ca-app-pub-5660767238092646/6671720674'
          : 'ca-app-pub-5660767238092646/1016069314';

  String get _bannerAdUnitId =>
      Platform.isAndroid
          ? 'ca-app-pub-5660767238092646/1639684604'
          : 'ca-app-pub-5660767238092646/7172881187';

  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    _loadInterstitialAd();
  }

  // --- Interstitial Ad ---

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!
              .fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitialAd(); // Preload next
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          debugPrint(
            'Interstitial failed to load: ${error.message} (code: ${error.code})',
          );
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
        },
      ),
    );
  }

  /// Level mode: show interstitial every 4th game over.
  void onLevelGameOver() {
    _levelGameOverCount++;
    if (_levelGameOverCount % 7 == 0) {
      showInterstitial();
    }
  }

  /// Score/Adventure mode: show interstitial on start game or app resume.
  /// [onDismissed] is called when the ad is closed (or immediately if no ad available).
  void onScoreOrAdventureStart({void Function()? onDismissed}) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitialAd();
          onDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitialAd();
          onDismissed?.call();
        },
      );
      _interstitialAd!.show();
    } else {
      onDismissed?.call();
    }
  }

  void showInterstitial() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    }
  }

  // --- Banner Ad ---

  BannerAd? createBannerAd({required void Function() onLoaded}) {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            'Banner failed to load: ${error.message} (code: ${error.code})',
          );
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
    return _bannerAd;
  }

  BannerAd? get bannerAd => _bannerAd;

  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
  }
}
