import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AdHelper {
  static DateTime? _lastInterstitialTime;
  static const Duration _adCooldown = Duration(seconds: 45);
  static InterstitialAd? _preloadedAd;

  static bool get canShowInterstitial {
    if (_lastInterstitialTime == null) return true;
    return DateTime.now().difference(_lastInterstitialTime!) > _adCooldown;
  }

  static void recordAdShown() {
    _lastInterstitialTime = DateTime.now();
  }

  // Preload Interstitial
  static void preloadInterstitialAd() {
    if (!canShowInterstitial) return;
    
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _preloadedAd = ad;
        },
        onAdFailedToLoad: (err) {
          _preloadedAd = null;
        },
      ),
    );
  }

  // Show Preloaded Ad
  static void showInterstitialAd(BuildContext context) {
    if (_preloadedAd != null && canShowInterstitial) {
      _preloadedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          recordAdShown();
          ad.dispose();
          _preloadedAd = null;
          preloadInterstitialAd(); // Load next one
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _preloadedAd = null;
        },
      );
      _preloadedAd!.show();
    }
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-2073707860224174/2356130826';
    if (Platform.isIOS) return 'ca-app-pub-2073707860224174/1418973199';
    return '';
  }

  static String get settingsBannerAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-2073707860224174/3837577343';
    if (Platform.isIOS) return 'ca-app-pub-2073707860224174/1902890590';
    return '';
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-2073707860224174/6027839020';
    if (Platform.isIOS) return 'ca-app-pub-2073707860224174/4152498035';
    return '';
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-2073707860224174/1756914342';
    if (Platform.isIOS) return 'ca-app-pub-2073707860224174/8798859050';
    return '';
  }

  static String get ringingBannerAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-2073707860224174/9485102800';
    if (Platform.isIOS) return 'ca-app-pub-2073707860224174/4228906696';
    return '';
  }

  static String get puzzleBannerAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-2073707860224174/9022068374';
    if (Platform.isIOS) return 'ca-app-pub-2073707860224174/5541988366';
    return '';
  }
}

