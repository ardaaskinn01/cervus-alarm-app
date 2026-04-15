import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../services/alarm_service.dart';
import 'puzzle_view.dart';
import '../home/success_view.dart';
import '../components/banner_ad_widget.dart';

class RingingView extends ConsumerStatefulWidget {
  final int alarmId;

  const RingingView({super.key, required this.alarmId});

  @override
  ConsumerState<RingingView> createState() => _RingingViewState();
}

class _RingingViewState extends ConsumerState<RingingView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSnoozePressed(BuildContext context) {
    // Erteleme için Puzzle'a git
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PuzzleView(alarmId: widget.alarmId, isSnooze: true),
      ),
    );
  }

  void _onWakeUpPressed(BuildContext context, WidgetRef ref) {
    // Tamamen kapatmak için de Puzzle'a git
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PuzzleView(alarmId: widget.alarmId, isSnooze: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return Scaffold(
      bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.gradientEndColor,
              AppTheme.backgroundColor,
            ],
            stops: const [0.0, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
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
                          blurRadius: 40 * scale,
                          spreadRadius: 20 * scale,
                        ),
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.2 * (1.3 - scale)),
                          blurRadius: 80 * scale,
                          spreadRadius: 40 * scale,
                        ),
                      ],
                    ),
                    child: Transform.scale(
                      scale: scale,
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 60),
              Text(
                AppLocalizations.get('ringing_title', locale),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36, // Slightly reduced from 42 to fit better
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0, // Reduced from 4.0
                  shadows: [
                    Shadow(color: Colors.black45, offset: Offset(0, 4), blurRadius: 10),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  AppLocalizations.get('ringing_subtitle', locale),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    // Wake Up Button (Primary Action)
                    Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Colors.greenAccent, Colors.green],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _onWakeUpPressed(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.get('ringing_wakeup', locale),
                          style: const TextStyle(
                            fontSize: 22, 
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Snooze Button (Secondary Action)
                    TextButton(
                      onPressed: () => _onSnoozePressed(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.snooze, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.get('ringing_snooze', locale),
                            style: const TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
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
        ),
      ),
    );
  }
}
