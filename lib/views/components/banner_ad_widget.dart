import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/ad_helper.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Yükleme burada yapılıyor çünkü ekran genişliğini (MediaQuery) daha doğru okuyabiliyoruz.
    if (_bannerAd == null && !_isFailed) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    // Adaptive Banner: ekranın tüm genişliğini kullanır, fill rate çok daha yüksek.
    final AnchoredAdaptiveBannerAdSize? adSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
    );

    if (adSize == null) {
      debugPrint('BannerAd: Could not get adaptive ad size.');
      if (mounted) setState(() => _isFailed = true);
      return;
    }

    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('BannerAd loaded ✅');
          if (mounted) {
            setState(() {
              _bannerAd = ad as BannerAd;
              _isLoaded = true;
              _isFailed = false;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed: $err');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
              _isFailed = true;
              _bannerAd = null;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Yüklendi ve reklam hazır: göster.
    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // AdMob reklam vermeyi reddetti (No Fill): boşluk bırakma.
    if (_isFailed) {
      return const SizedBox.shrink();
    }

    // Yüklenirken yer tut (Layout Shift'i engeller).
    return const SizedBox(height: 50);
  }
}
