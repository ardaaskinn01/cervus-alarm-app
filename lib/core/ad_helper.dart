import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-2073707860224174/2356130826'; // Real Android Banner Ad Unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2073707860224174/1418973199'; // Real iOS Banner Ad Unit ID
    }
    throw UnsupportedError('Unsupported platform');
  }
}
