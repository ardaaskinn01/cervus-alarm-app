import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/ad_helper.dart';
import '../../services/revenuecat_service.dart';

class SuccessView extends ConsumerStatefulWidget {
  const SuccessView({super.key});

  @override
  ConsumerState<SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends ConsumerState<SuccessView> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  

  final List<String> _quotesTr = [
    "Dün dündü, bugün yeni bir gün. Harika bir başlangıç yap!",
    "Her sabah yeni bir fırsattır, derin bir nefes al ve başla.",
    "Zor oldu ama kalktın. Bugün senin günün olacak!",
    "Erken kalkan yol alır. Yolun açık olsun!",
    "Başarı, her sabah uyanıp vazgeçmemekte gizlidir.",
  ];

  final List<String> _tasksTr = [
    "Bugün birine samimiyetle gülümse.",
    "Bir bardak su içerek güne başla.",
    "Derin bir nefes al ve bugün başardığın 3 şeyi düşün.",
    "Bugün yapman gereken en önemli 1 şeyi belirle.",
    "1 dakikalığına gözlerini kapa ve sessizliği dinle.",
  ];

  final List<String> _quotesEn = [
    "Yesterday is gone, today is a new day. Make a great start!",
    "Every morning is a new opportunity, take a deep breath and begin.",
    "It was hard, but you're up. Today is going to be your day!",
    "The early bird catches the worm. Have a great day!",
    "Success is hidden in waking up every morning and not giving up.",
  ];

  final List<String> _tasksEn = [
    "Smile sincerely at someone today.",
    "Start your day by drinking a glass of water.",
    "Take a deep breath and think of 3 things you accomplished.",
    "Determine the 1 most important thing you need to do today.",
    "Close your eyes for 1 minute and listen to the silence.",
  ];
  late String _todaysQuote;
  late String _todaysTask;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    final randQuoteIndex = Random().nextInt(_quotesTr.length);
    final randTaskIndex = Random().nextInt(_tasksTr.length);
    _todaysQuote = randQuoteIndex.toString();
    _todaysTask = randTaskIndex.toString();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final isTr = locale == 'tr';
    final quote = isTr ? _quotesTr[int.parse(_todaysQuote)] : _quotesEn[int.parse(_todaysQuote)];
    final task = isTr ? _tasksTr[int.parse(_todaysTask)] : _tasksEn[int.parse(_todaysTask)];

    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND PULSE
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(color: AppTheme.backgroundColor),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.12),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Spacer(),
                  
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.secondaryColor.withOpacity(0.1),
                        border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.2), width: 2),
                      ),
                      child: const Icon(Icons.wb_sunny_rounded, size: 80, color: AppTheme.secondaryColor),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    AppLocalizations.get('success_title', locale),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                  ),
                  
                  const SizedBox(height: 48),

                  // GLASS CARD: QUOTE
                  _buildGlassCard(
                    icon: Icons.format_quote_rounded,
                    title: AppLocalizations.get('success_quote_title', locale),
                    content: quote,
                    color: AppTheme.primaryColor,
                  ),

                  const SizedBox(height: 20),

                  // GLASS CARD: TASK
                  _buildGlassCard(
                    icon: Icons.rocket_launch_rounded,
                    title: AppLocalizations.get('success_task_title', locale),
                    content: task,
                    color: AppTheme.secondaryColor,
                  ),

                  const Spacer(),

                  // ANA BUTON: GÜNE BAŞLA
                  SizedBox(
                    width: double.infinity,
                    height: 68,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        elevation: 10,
                        shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                      ),
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.get('success_start', locale).toUpperCase(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required IconData icon, required String title, required String content, required Color color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 10),
                  Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                content,
                style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
