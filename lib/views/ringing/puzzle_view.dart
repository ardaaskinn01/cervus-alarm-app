import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../core/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../services/alarm_service.dart';
import '../../services/local_storage_service.dart';
import '../home/success_view.dart';
import '../components/banner_ad_widget.dart';

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
  
  int _targetQuestionCount = 1;
  int _questionsSolved = 0;
  List<Map<String, dynamic>> _customQuestions = [];
  String _currentQuestionString = "";

  int num1 = 0;
  int num2 = 0;
  int correctAnswer = 0;
  String operatorText = '+';

  @override
  void initState() {
    super.initState();
    final storage = ref.read(localStorageServiceProvider);
    _targetQuestionCount = storage.getPuzzleQuestionCount();
    _customQuestions = storage.getCustomQuestions();
    _generatePuzzle();
  }

  void _generatePuzzle() {
    if (_questionsSolved < _customQuestions.length) {
      // Use Custom Question
      final q = _customQuestions[_questionsSolved];
      _currentQuestionString = q['q'].toString();
      correctAnswer = q['a'] as int;
    } else {
      // Generate Random Question
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
      _currentQuestionString = '$num1 $operatorText $num2';
    }

    _answerController.clear();
    setState(() {});
  }



  Future<void> _checkAnswer() async {
    final int? userAnswer = int.tryParse(_answerController.text.trim());
    if (userAnswer == correctAnswer) {
      // 🎯 DOĞRU CEVAP!
      _questionsSolved++;
      if (_questionsSolved < _targetQuestionCount) {
        // Sonraki soruya geç
        _generatePuzzle();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Devam et! Kaldı: ${_targetQuestionCount - _questionsSolved}"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        // Tümü bitti, alarmı kapat/ertele
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
              AppTheme.gradientEndColor,
              AppTheme.backgroundColor,
            ],
            stops: const [0.0, 0.7, 1.0],
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
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                            child: Column(
                              children: [
                                Text(
                                  AppLocalizations.get('puzzle_question', locale),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  _currentQuestionString,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: _currentQuestionString.length > 8 ? 44 : 68,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: AppTheme.secondaryColor.withOpacity(0.6),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('=', style: TextStyle(
                                  fontSize: 40, 
                                  color: Colors.white.withOpacity(0.6),
                                  shadows: [Shadow(color: Colors.white30, blurRadius: 10)],
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Answer Input
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _answerController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          autofocus: true,
                          style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w900),
                          decoration: InputDecoration(
                            hintText: '???',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            contentPadding: const EdgeInsets.symmetric(vertical: 24),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppTheme.secondaryColor, width: 2.5),
                            ),
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
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondaryColor.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _checkAnswer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: Text(
                              AppLocalizations.get('puzzle_check', locale),
                              style: const TextStyle(fontSize: 20, letterSpacing: 3, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SafeArea(child: BannerAdWidget()),
            ],
          ),
        ),
      ),
    );
  }
}
