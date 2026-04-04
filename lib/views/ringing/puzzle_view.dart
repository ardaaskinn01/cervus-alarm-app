import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:math';
import '../../core/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../services/alarm_service.dart';
import '../home/success_view.dart';

class PuzzleView extends ConsumerStatefulWidget {
  final int alarmId;
  final bool isSnooze; // Yeni: Erteleme mi yoksa Kapatma mı?

  const PuzzleView({
    Key? key, 
    required this.alarmId, 
    this.isSnooze = false,
  }) : super(key: key);

  @override
  ConsumerState<PuzzleView> createState() => _PuzzleViewState();
}

class _PuzzleViewState extends ConsumerState<PuzzleView> {
  final TextEditingController _answerController = TextEditingController();
  
  int num1 = 0;
  int num2 = 0;
  int correctAnswer = 0;
  String operatorText = '+';

  BannerAd? _bannerAd;

  // Test Banner ID
  final String _adUnitId = 'ca-app-pub-3940256099942544/2934735716';

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
    _loadAds();
  }

  void _generatePuzzle() {
    final random = Random();
    final isSubtraction = random.nextBool();

    num1 = random.nextInt(30) + 1; // 1-30
    num2 = random.nextInt(30) + 1; // 1-30

    if (isSubtraction) {
      if (num1 < num2) {
        final temp = num1;
        num1 = num2;
        num2 = temp;
      }
      operatorText = '-';
      correctAnswer = num1 - num2;
    } else {
      operatorText = '+';
      correctAnswer = num1 + num2;
    }

    _answerController.clear();
    setState(() {});
  }

  void _loadAds() {
    BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _bannerAd = ad as BannerAd),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    ).load();
  }

  Future<void> _checkAnswer() async {
    final int? userAnswer = int.tryParse(_answerController.text.trim());
    if (userAnswer == correctAnswer) {
      // 🎯 DOĞRU CEVAP!
      if (widget.isSnooze) {
        // Erteleme Modu
        await ref.read(homeViewModelProvider.notifier).snoozeAlarm(widget.alarmId);
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        // Kapatma Modu
        await ref.read(alarmServiceProvider).stopAlarm(widget.alarmId);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SuccessView()),
          );
        }
      }
    } else {
      final locale = ref.read(localeProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.get('puzzle_wrong', locale)),
          backgroundColor: Colors.red,
        ),
      );
      _generatePuzzle();
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.get('puzzle_appbar', locale)),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.secondaryColor,
              AppTheme.backgroundColor,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 2,
                          ),
                        ),
                        child: const Icon(Icons.psychology, size: 80, color: Colors.white),
                      ),
                      const SizedBox(height: 48),
                      
                      // Puzzle Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              AppLocalizations.get('puzzle_question', locale),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '$num1 $operatorText $num2',
                              style: const TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('=', style: TextStyle(fontSize: 40, color: Colors.white.withOpacity(0.4))),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Answer Input
                      TextField(
                        controller: _answerController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        autofocus: true,
                        style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: '???',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          contentPadding: const EdgeInsets.symmetric(vertical: 24),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Control Button
                      SizedBox(
                        width: double.infinity,
                        height: 70,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
                          ),
                          child: ElevatedButton(
                            onPressed: _checkAnswer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(
                              AppLocalizations.get('puzzle_check', locale),
                              style: const TextStyle(fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_bannerAd != null)
                SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
