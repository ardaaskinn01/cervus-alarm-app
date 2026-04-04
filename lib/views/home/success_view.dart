import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_localizations.dart';

class SuccessView extends ConsumerStatefulWidget {
  const SuccessView({super.key});

  @override
  ConsumerState<SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends ConsumerState<SuccessView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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

  @override
  void initState() {
    super.initState();
    // Quote and task are selected once here so they don't randomly flip on rebuild
    // But they will be locale-dependent when used in the build method.
    final randQuoteIndex = Random().nextInt(_quotesTr.length);
    final randTaskIndex = Random().nextInt(_tasksTr.length);
    
    _todaysQuote = randQuoteIndex.toString(); // store index
    _todaysTask = randTaskIndex.toString(); // store index

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = 'tr'; // localeProvider kaldırıldı
    final int quoteIdx = int.parse(_todaysQuote);
    final int taskIdx = int.parse(_todaysTask);
    
    final currentQuote = locale == 'en' ? _quotesEn[quoteIdx] : _quotesTr[quoteIdx];
    final currentTask = locale == 'en' ? _tasksEn[taskIdx] : _tasksTr[taskIdx];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1CB5E0),
              Color(0xFF000851),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 20,
                      )
                    ]
                  ),
                  child: const Icon(
                    Icons.wb_sunny_rounded,
                    size: 120,
                    color: Colors.yellowAccent,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.get('success_morning', locale),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        currentQuote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Today's Positive Task
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.task_alt_rounded, color: Colors.greenAccent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.get('success_task_title', locale),
                                style: TextStyle(
                                  color: Colors.greenAccent.withOpacity(0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentTask,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Container(
                    width: double.infinity,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.get('success_start', locale),
                        style: const TextStyle(
                          fontSize: 20, 
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
