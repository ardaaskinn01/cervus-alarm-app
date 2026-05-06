import 'dart:io';

class AdHelper {
  static DateTime? _lastInterstitialTime;
  static const Duration _adCooldown = Duration(seconds: 45);

  static bool get canShowInterstitial {
    if (_lastInterstitialTime == null) return true;
    return DateTime.now().difference(_lastInterstitialTime!) > _adCooldown;
  }

  static void recordAdShown() {
    _lastInterstitialTime = DateTime.now();
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-2073707860224174/2356130826'; // Real Android Banner Ad Unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2073707860224174/1418973199'; // Real iOS Banner Ad Unit ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-2073707860224174/6027839020'; // Real Android Interstitial Ad Unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2073707860224174/4152498035'; // Real iOS Interstitial Ad Unit ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-2073707860224174/1756914342'; // Real Android Rewarded Ad Unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2073707860224174/8798859050'; // Real iOS Rewarded Ad Unit ID
    }
    throw UnsupportedError('Unsupported platform');
  }
}

