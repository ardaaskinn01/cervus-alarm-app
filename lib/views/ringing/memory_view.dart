import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_localizations.dart';
import '../../core/app_theme.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../services/alarm_service.dart';
import '../home/success_view.dart';
import '../../core/ad_helper.dart';
import '../../services/revenuecat_service.dart';
import 'dart:math';

class MemoryView extends ConsumerStatefulWidget {
  final int alarmId;
  final bool isSnooze;

  const MemoryView({super.key, required this.alarmId, this.isSnooze = false});

  @override
  ConsumerState<MemoryView> createState() => _MemoryViewState();
}

class _MemoryViewState extends ConsumerState<MemoryView> {
  final List<String> _emojis = ['🍎', '🍌', '🍇', '🍉', '🍓', '🍒'];
  late List<String> _cards;
  late List<bool> _cardFlips;
  late List<bool> _cardMatches;

  int? _firstSelectedIndex;
  bool _isProcessing = false;
  int _matchCount = 0;

  @override
  void initState() {
    super.initState();
    _initGame();
    // REKLAMI ÖNCEDEN YÜKLE
    if (!ref.read(isPremiumProvider)) {
      AdHelper.preloadInterstitialAd();
    }
  }

  void _initGame() {
    _cards = [..._emojis, ..._emojis]; // 6 çift kart
    _cards.shuffle(Random());
    _cardFlips = List.generate(12, (index) => false);
    _cardMatches = List.generate(12, (index) => false);
    _matchCount = 0;
  }

  Future<void> _onCardTap(int index) async {
    if (_isProcessing || _cardFlips[index] || _cardMatches[index]) return;

    setState(() {
      _cardFlips[index] = true;
    });

    if (_firstSelectedIndex == null) {
      _firstSelectedIndex = index;
    } else {
      _isProcessing = true;
      final int firstIndex = _firstSelectedIndex!;
      final int secondIndex = index;

      if (_cards[firstIndex] == _cards[secondIndex]) {
        // Eşleşme başarılı
        _cardMatches[firstIndex] = true;
        _cardMatches[secondIndex] = true;
        _matchCount++;

        if (_matchCount == _emojis.length) {
          _finishTask();
        }
        _isProcessing = false;
      } else {
        // Eşleşme başarısız
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          setState(() {
            _cardFlips[firstIndex] = false;
            _cardFlips[secondIndex] = false;
          });
        }
        _isProcessing = false;
      }
      _firstSelectedIndex = null;
    }
  }

  Future<void> _finishTask() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
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
          title: Text(AppLocalizations.get('memory_title', locale), style: const TextStyle(fontWeight: FontWeight.bold)),
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
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    AppLocalizations.get('memory_subtitle', locale),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppLocalizations.get('memory_match', locale)}$_matchCount / ${_emojis.length}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final isFlipped = _cardFlips[index] || _cardMatches[index];
                      return GestureDetector(
                        onTap: () => _onCardTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: isFlipped 
                                ? (_cardMatches[index] ? Colors.green.withOpacity(0.3) : Colors.white)
                                : AppTheme.primaryColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isFlipped ? Colors.white24 : Colors.white12,
                              width: 2,
                            ),
                            boxShadow: isFlipped
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                          ),
                          child: Center(
                            child: isFlipped
                                ? Text(
                                    _cards[index],
                                    style: const TextStyle(fontSize: 40),
                                  )
                                : const Icon(
                                    Icons.question_mark_rounded,
                                    color: Colors.white54,
                                    size: 32,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
