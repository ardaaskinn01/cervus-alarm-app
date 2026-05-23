import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../services/alarm_service.dart';
import 'puzzle_view.dart';
import 'shake_view.dart';
import 'typing_view.dart';
import 'memory_view.dart';
import 'barcode_scanner_view.dart';
import '../../views/components/banner_ad_widget.dart';

class RingingView extends ConsumerStatefulWidget {
  final int alarmId;

  const RingingView({super.key, required this.alarmId});

  @override
  ConsumerState<RingingView> createState() => _RingingViewState();
}

class _RingingViewState extends ConsumerState<RingingView> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _bgPulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bgPulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _bgPulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _bgPulseAnimation = Tween<double>(begin: 0.8, end: 1.5).animate(CurvedAnimation(parent: _bgPulseController, curve: Curves.slowMiddle));

    // Servis üzerinden sesi başlat (Tüm sayfalarda çalmaya devam edecek)
    _startContinuousSound();
  }

  Future<void> _startContinuousSound() async {
    try {
      final alarms = ref.read(homeViewModelProvider);
      String soundPath = 'assets/audio/hard_alarm.mp3'; // Varsayılan

      if (alarms.isNotEmpty) {
        final currentAlarm = alarms.firstWhere((a) => a.id == widget.alarmId, orElse: () => alarms.first);
        soundPath = currentAlarm.soundPath;
      }
      
      await ref.read(alarmServiceProvider).playForegroundRinging(soundPath);
    } catch (e) {
      debugPrint("Ses başlatılamadı: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgPulseController.dispose();
    // Buradan sesi DURDURMUYORUZ (Süreklilik için)
    super.dispose();
  }

  void _navigateToStopTask(BuildContext context, WidgetRef ref, bool isSnooze) {
    String stopMethod = 'math';
    try {
      final alarms = ref.read(homeViewModelProvider);
      // Eğer henüz veritabanı yüklenmediyse veya liste boşsa hata fırlatabilir
      if (alarms.isNotEmpty) {
        final currentAlarm = alarms.firstWhere((a) => a.id == widget.alarmId, orElse: () => alarms.first);
        stopMethod = currentAlarm.stopMethod;

        if (!isSnooze && currentAlarm.rewardUnlocked) {
          final updatedAlarm = currentAlarm.copyWith(rewardUnlocked: false, stopMethod: 'math');
          ref.read(homeViewModelProvider.notifier).silentEditAlarm(updatedAlarm);
        }
      }
    } catch (e) {
      debugPrint("Alarm verisi okunurken hata veya boş liste: $e");
    }

    Widget nextView;
    if (stopMethod == 'shake') {
      nextView = ShakeView(alarmId: widget.alarmId, isSnooze: isSnooze);
    } else if (stopMethod == 'typing') {
      nextView = TypingView(alarmId: widget.alarmId, isSnooze: isSnooze);
    } else if (stopMethod == 'memory') {
      nextView = MemoryView(alarmId: widget.alarmId, isSnooze: isSnooze);
    } else if (stopMethod == 'qr') {
      nextView = BarcodeScannerView(alarmId: widget.alarmId, isSnooze: isSnooze);
    } else {
      nextView = PuzzleView(alarmId: widget.alarmId, isSnooze: isSnooze);
    }

    // Navigasyonu garanti et
    Future.microtask(() {
      if (context.mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => nextView));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            // DYNAMIC BG PULSE
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(color: AppTheme.backgroundColor),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ScaleTransition(
                    scale: _bgPulseAnimation,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.15),
                            AppTheme.primaryColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  
                  // ICON PULSE
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      final scale = _pulseAnimation.value;
                      return Container(
                        padding: const EdgeInsets.all(50),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.secondaryColor.withOpacity(0.3 * (1.3 - scale)),
                              blurRadius: 50 * scale,
                              spreadRadius: 25 * scale,
                            ),
                          ],
                        ),
                        child: Transform.scale(
                          scale: scale,
                          child: const Icon(Icons.notifications_active_rounded, size: 120, color: Colors.white),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 60),
                  
                  Text(
                    AppLocalizations.get('ringing_title', locale),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      AppLocalizations.get('ringing_subtitle', locale),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        // WAKE UP BUTTON (Premium Gradient)
                        GestureDetector(
                          onTap: () => _navigateToStopTask(context, ref, false),
                          child: Container(
                            width: double.infinity,
                            height: 84,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: const LinearGradient(colors: [Colors.greenAccent, Colors.green]),
                              boxShadow: [
                                BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 12)),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              AppLocalizations.get('ringing_wakeup', locale).toUpperCase(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 28),
                        
                        TextButton(
                          onPressed: () => _navigateToStopTask(context, ref, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.snooze_rounded, size: 24),
                              const SizedBox(width: 10),
                              Text(
                                AppLocalizations.get('ringing_snooze', locale),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: const SafeArea(child: BannerAdWidget(type: BannerType.ringing)),
      ),
    );
  }
}

