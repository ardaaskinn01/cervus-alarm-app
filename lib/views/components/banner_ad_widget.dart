import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/ad_helper.dart';
import 'dart:io';

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
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    // Güvenliği artırmak için standart banner boyutuna geri dönüyoruz.
    // Adaptive Banner hesaplama sırasında null dönüp veya hata verebiliyor.
    final adUnitId = AdHelper.bannerAdUnitId;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner, // Garantili ve stabil standart boyut (320x50)
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('BannerAd loaded ✅');
          if (mounted) {
            setState(() {
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
    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // ADMOB HATA VERİYORSA BURAYA DÜŞER
    // Eğer reklam çıkmıyorsa, siyah bir zemin veya boşluk bırakabiliriz test için,
    // ancak production'da görünmez olması daha iyidir.
    if (_isFailed) {
      // Geçici olarak hatayı anlamak için shrink değil, tamamen kaldırıyoruz
      return const SizedBox.shrink();
    }

    // YÜKLENİYORSA BURAYA DÜŞER: 320x50 yer tutar (Mizanpaj oynamaması için)
    return SizedBox(
      width: AdSize.banner.width.toDouble(),
      height: AdSize.banner.height.toDouble(),
    );
  }
}
