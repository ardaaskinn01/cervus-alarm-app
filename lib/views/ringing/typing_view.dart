import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../core/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../services/alarm_service.dart';
import '../home/success_view.dart';
import '../../views/components/banner_ad_widget.dart';
import '../../core/ad_helper.dart';
import '../../services/revenuecat_service.dart';

class TypingView extends ConsumerStatefulWidget {
  final int alarmId;
  final bool isSnooze;

  const TypingView({super.key, required this.alarmId, this.isSnooze = false});

  @override
  ConsumerState<TypingView> createState() => _TypingViewState();
}

class _TypingViewState extends ConsumerState<TypingView> {
  final TextEditingController _textController = TextEditingController();
  late String _targetSentence;
  bool _isMatched = false;

  final List<String> _trSentences = [
    "Bugün ertelemeyeceğim ve hedeflerime ulaşacağım!",
    "Her yeni gün, yeni bir başlangıçtır.",
    "Uyan ve dünkü senden daha iyi ol.",
    "Güneşle birlikte uyanmak bana güç veriyor.",
    "Büyük hayaller uyanıkken gerçekleşir.",
    "Bugün kendimin en iyi versiyonu olacağım.",
    "Zorluklar beni yıldırmaz, beni güçlendirir.",
    "Zamanımı en verimli şekilde kullanacağım.",
  ];

  final List<String> _enSentences = [
    "I will not snooze today and I will reach my goals!",
    "Every new day is a new beginning.",
    "Wake up and be better than your yesterday.",
    "Waking up with the sun gives me strength.",
    "Big dreams are realized while you are awake.",
    "Today I will be the best version of myself.",
    "Challenges do not discourage me, they make me stronger.",
    "I will use my time in the most efficient way.",
  ];

  @override
  void initState() {
    super.initState();
    // REKLAMI ÖNCEDEN YÜKLE
    if (!ref.read(isPremiumProvider)) {
      AdHelper.preloadInterstitialAd();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_textController.text.isEmpty) {
      final locale = ref.read(localeProvider);
      final random = Random();
      if (locale == 'tr') {
        _targetSentence = _trSentences[random.nextInt(_trSentences.length)];
      } else {
        _targetSentence = _enSentences[random.nextInt(_enSentences.length)];
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    if (value == _targetSentence && !_isMatched) {
      setState(() {
        _isMatched = true;
      });
      _finishTask();
    }
  }

  Future<void> _finishTask() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (widget.isSnooze) {
      await ref.read(homeViewModelProvider.notifier).snoozeAlarm(widget.alarmId);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(AppLocalizations.get('typing_title', locale), style: const TextStyle(fontWeight: FontWeight.bold)),
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
              stops: [0.0, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Icon(Icons.keyboard_outlined, size: 80, color: Colors.white),
                const SizedBox(height: 32),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: Text(
                      _targetSentence,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    AppLocalizations.get('typing_hint_2', locale),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 48),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TextField(
                    controller: _textController,
                    onChanged: _onTextChanged,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    maxLines: 3,
                    minLines: 1,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.get('typing_textfield_hint', locale),
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const SafeArea(child: BannerAdWidget(type: BannerType.puzzle)),
      ),
    );
  }
}
