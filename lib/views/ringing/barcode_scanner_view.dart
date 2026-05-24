import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/app_localizations.dart';
import '../../core/app_theme.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../services/alarm_service.dart';
import '../home/success_view.dart';
import '../home/home_view.dart';
import '../../views/components/banner_ad_widget.dart';
import '../../core/ad_helper.dart';
import '../../services/revenuecat_service.dart';


class BarcodeScannerView extends ConsumerStatefulWidget {
  final int alarmId;
  final bool isSnooze;

  const BarcodeScannerView({super.key, required this.alarmId, this.isSnooze = false});

  @override
  ConsumerState<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends ConsumerState<BarcodeScannerView> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    // REKLAMI ÖNCEDEN YÜKLE
    if (!ref.read(isPremiumProvider)) {
      AdHelper.preloadInterstitialAd();
    }
  }

  Future<void> _finishTask() async {
    if (_isFinished) return;
    _isFinished = true;
    
    // Kamerayı kapat
    await cameraController.stop();

    if (widget.isSnooze) {
      await ref.read(homeViewModelProvider.notifier).snoozeAlarm(widget.alarmId);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeView()),
          (route) => false,
        );
      }
    } else {
      try {
        final alarms = ref.read(homeViewModelProvider);
        final currentAlarm = alarms.firstWhere((a) => a.id == widget.alarmId);
        await ref.read(homeViewModelProvider.notifier).toggleAlarm(currentAlarm, false);
      } catch (e) {
        await ref.read(alarmServiceProvider).stopAlarm(widget.alarmId);
      }
      
      if (mounted) {
        // REKLAMI HEMEN GÖSTER
        if (!ref.read(isPremiumProvider)) {
          AdHelper.showInterstitialAd(context);
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuccessView()),
        );
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(AppLocalizations.get('qr_title', locale), style: const TextStyle(fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  // Herhangi bir barkod bulduğunda hemen kapat!
                  _finishTask();
                }
              },
            ),
            // Gradient Frame Overlay
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  radius: 0.8,
                ),
              ),
            ),
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryColor, width: 4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0, left: 0,
                      child: Container(width: 30, height: 4, color: Colors.white),
                    ),
                    Positioned(
                      top: 0, left: 0,
                      child: Container(width: 4, height: 30, color: Colors.white),
                    ),
                    Positioned(
                      top: 0, right: 0,
                      child: Container(width: 30, height: 4, color: Colors.white),
                    ),
                    Positioned(
                      top: 0, right: 0,
                      child: Container(width: 4, height: 30, color: Colors.white),
                    ),
                    Positioned(
                      bottom: 0, left: 0,
                      child: Container(width: 30, height: 4, color: Colors.white),
                    ),
                    Positioned(
                      bottom: 0, left: 0,
                      child: Container(width: 4, height: 30, color: Colors.white),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(width: 30, height: 4, color: Colors.white),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(width: 4, height: 30, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Text(
                AppLocalizations.get('qr_subtitle', locale),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const SafeArea(child: BannerAdWidget(type: BannerType.puzzle)),
      ),
    );
  }
}

