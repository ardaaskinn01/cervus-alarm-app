import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../core/ad_helper.dart';
import '../../models/alarm_model.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../services/revenuecat_service.dart';
import '../../services/local_storage_service.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AddAlarmBottomSheet extends ConsumerStatefulWidget {
  final AlarmModel? existingAlarm;

  const AddAlarmBottomSheet({Key? key, this.existingAlarm}) : super(key: key);

  @override
  ConsumerState<AddAlarmBottomSheet> createState() => _AddAlarmBottomSheetState();
}

class _AddAlarmBottomSheetState extends ConsumerState<AddAlarmBottomSheet> {
  late DateTime selectedTime;
  late List<int> selectedDays;
  late String selectedSound;
  late String selectedStopMethod;
  late TextEditingController labelController;
  late List<Map<String, dynamic>> _customSounds;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Ödüllü reklam
  RewardedAd? _rewardedAd;
  bool _isLoadingAd = false;

  // Bu bottom sheet oturumunda reklam izlenip kilit açıldı mı?
  bool _rewardUnlockedThisSession = false;

  @override
  void initState() {
    super.initState();;
    _customSounds = ref.read(localStorageServiceProvider).getCustomSounds();
    if (widget.existingAlarm != null) {
      final now = DateTime.now();
      selectedTime = DateTime(now.year, now.month, now.day, widget.existingAlarm!.hour, widget.existingAlarm!.minute);
      selectedDays = List.from(widget.existingAlarm!.repeatDays);
      selectedSound = widget.existingAlarm!.soundPath;
      selectedStopMethod = widget.existingAlarm!.stopMethod;
      labelController = TextEditingController(text: widget.existingAlarm!.label);
      // Mevcut alarmda kilit açık kalabilir (reklam daha önce izlendiyse)
      _rewardUnlockedThisSession = widget.existingAlarm!.rewardUnlocked;
    } else {
      selectedTime = DateTime.now();
      selectedDays = [];
      selectedSound = 'assets/audio/hard_alarm.mp3';
      selectedStopMethod = 'math';
      labelController = TextEditingController();
      _rewardUnlockedThisSession = false;
    }

    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isLoadingAd = false;
          });
          debugPrint('RewardedAd loaded.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          setState(() {
            _rewardedAd = null;
            _isLoadingAd = false;
          });
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.get('reward_failed_toast', ref.read(localeProvider))), backgroundColor: Colors.orange),
      );
      _loadRewardedAd();
      return;
    }

    setState(() => _isLoadingAd = true);

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        setState(() => _isLoadingAd = false);
        _loadRewardedAd(); // Sonraki kullanım için önceden yükle
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _rewardedAd = null;
        setState(() => _isLoadingAd = false);
        debugPrint('RewardedAd failed to show: $err');
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        // Kullanıcı reklamı tamamladı → kilidi geçici aç
        setState(() {
          _rewardUnlockedThisSession = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('reward_unlocked_toast', ref.read(localeProvider))),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
    _rewardedAd = null;
  }

  @override
  void dispose() {
    FlutterRingtonePlayer().stop();
    _audioPlayer.dispose();
    labelController.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  void toggleDay(int day) {
    setState(() {
      if (selectedDays.contains(day)) {
        selectedDays.remove(day);
      } else {
        selectedDays.add(day);
      }
    });
  }

  Future<void> saveAlarm() async {
    final locale = ref.read(localeProvider);
    if (widget.existingAlarm != null) {
      final updatedAlarm = widget.existingAlarm!.copyWith(
        hour: selectedTime.hour,
        minute: selectedTime.minute,
        repeatDays: selectedDays,
        soundPath: selectedSound,
        isActive: true,
        label: labelController.text,
        stopMethod: selectedStopMethod,
        rewardUnlocked: _rewardUnlockedThisSession,
      );
      await ref.read(homeViewModelProvider.notifier).editAlarm(updatedAlarm);
    } else {
      final newAlarm = AlarmModel(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        hour: selectedTime.hour,
        minute: selectedTime.minute,
        isActive: true,
        repeatDays: selectedDays,
        soundPath: selectedSound,
        label: labelController.text,
        stopMethod: selectedStopMethod,
        rewardUnlocked: _rewardUnlockedThisSession,
      );
      await ref.read(homeViewModelProvider.notifier).addAlarm(newAlarm);
    }

    FlutterRingtonePlayer().stop();
    await _audioPlayer.stop();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.get('alarm_saved_warning', locale),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final isPremium = ref.watch(isPremiumProvider);
    // Yöntemler kilitli mi? Premium yoksa VE bu oturumda reklam ödülü de kazanılmadıysa kilitli
    final methodsUnlocked = isPremium || _rewardUnlockedThisSession;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  widget.existingAlarm != null ? AppLocalizations.get('add_edit_title', locale) : AppLocalizations.get('add_new_title', locale),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.dark,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: true,
                      initialDateTime: selectedTime,
                      onDateTimeChanged: (DateTime newTime) {
                        setState(() {
                          selectedTime = newTime;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.get('add_label', locale),
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: labelController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: widget.existingAlarm != null ? '' : AppLocalizations.get('home_title', locale),
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.get('add_repeat', locale),
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 1; i <= 7; i++)
                      GestureDetector(
                        onTap: () => toggleDay(i),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selectedDays.contains(i)
                                ? AppTheme.secondaryColor
                                : Colors.white12,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            AppLocalizations.get('day_${i-1}', locale),
                            style: TextStyle(
                              color: selectedDays.contains(i)
                                  ? Colors.white
                                  : Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.get('add_melody', locale),
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _melodyChip(AppLocalizations.get('melody_hard', locale), 'assets/audio/hard_alarm.mp3', false),
                      const SizedBox(width: 8),
                      _melodyChip(AppLocalizations.get('melody_soft', locale), 'assets/audio/soft_alarm.mp3', false),
                      const SizedBox(width: 8),
                      _melodyChip(AppLocalizations.get('melody_modern', locale), 'assets/audio/modern_alarm.mp3', false),
                      ..._customSounds.map((s) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: _melodyChip(s['name'] ?? AppLocalizations.get('melody_custom', locale), s['path'] ?? '', true),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.get('add_stop_method', locale),
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                // Stop methods — matematik her zaman açık, diğerleri kilitli veya açık
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _methodChip(AppLocalizations.get('method_math', locale), 'math', true),
                      _methodChip(AppLocalizations.get('method_shake', locale), 'shake', methodsUnlocked),
                      _methodChip(AppLocalizations.get('method_typing', locale), 'typing', methodsUnlocked),
                      _methodChip(AppLocalizations.get('method_memory', locale), 'memory', methodsUnlocked),
                      _methodChip(AppLocalizations.get('method_qr', locale), 'qr', methodsUnlocked),
                    ],
                  ),
                ),
                // Kilitli ise "Bir Kez Dene" butonu
                if (!methodsUnlocked) ...[
                  const SizedBox(height: 12),
                  _buildTryOnceButton(),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saveAlarm,
                    child: Text(AppLocalizations.get('add_save', locale)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTryOnceButton() {
    final locale = ref.read(localeProvider);
    return GestureDetector(

      onTap: _isLoadingAd ? null : _showRewardedAd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 18, color: Colors.amber),
            const SizedBox(width: 8),
                  _isLoadingAd
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber))
                : Text(
                    AppLocalizations.get('reward_try_once', locale),
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.get('reward_try_once_desc', locale),
              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _melodyChip(String label, String path, bool isCustom) {
    final bool isSelected = selectedSound == path;
    return GestureDetector(
      onTap: () async {
        setState(() {
          selectedSound = path;
        });
        try {
          await FlutterRingtonePlayer().stop();
          await _audioPlayer.stop();

          if (isCustom) {
            await _audioPlayer.play(DeviceFileSource(path));
          } else {
            await FlutterRingtonePlayer().play(
              fromAsset: path,
              looping: false,
              volume: 0.8,
            );
          }
        } catch (e) {
          debugPrint("Ses çalınamadı: $e");
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryColor : Colors.white12,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white24 : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _methodChip(String label, String value, bool isUnlocked) {
    final bool isSelected = selectedStopMethod == value;
    final bool isMath = value == 'math';
    final bool showProBadge = !isUnlocked && !isMath;

    return GestureDetector(
      onTap: () {
        if (!isUnlocked) {
          // Kilitli — tıklamayı engelle (buton zaten açıklamayı sağlıyor)
          return;
        }
        setState(() {
          selectedStopMethod = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor 
              : (showProBadge ? Colors.white.withOpacity(0.03) : Colors.white12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? Colors.white24 
                : (showProBadge ? Colors.amber.withOpacity(0.3) : Colors.transparent),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : (showProBadge ? Colors.white.withOpacity(0.4) : Colors.white70),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (showProBadge) ...[
              const SizedBox(width: 6),
              const Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.amber),
            ],
          ],
        ),
      ),
    );
  }

  void _showPremiumLock(BuildContext context) {
    final locale = ref.read(localeProvider);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text(AppLocalizations.get('premium_lock_title', locale), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(AppLocalizations.get('premium_lock_desc', locale), style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Text(AppLocalizations.get('premium_lock_btn', locale)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
