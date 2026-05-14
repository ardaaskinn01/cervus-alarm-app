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
    final methodsUnlocked = isPremium || _rewardUnlockedThisSession;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sayfa Tutamacı
                Container(
                  width: 45,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                
                // Başlık
                Text(
                  widget.existingAlarm != null ? AppLocalizations.get('add_edit_title', locale) : AppLocalizations.get('add_new_title', locale),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                
                // Zaman Seçici
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.dark,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: true,
                      initialDateTime: selectedTime,
                      onDateTimeChanged: (DateTime newTime) => setState(() => selectedTime = newTime),
                    ),
                  ),
                ),
                
                const SizedBox(height: 28),

                // Alarm Etiketi
                _buildSectionHeader(AppLocalizations.get('add_label', locale)),
                const SizedBox(height: 12),
                TextField(
                  controller: labelController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: widget.existingAlarm != null ? '' : AppLocalizations.get('home_title', locale),
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),

                const SizedBox(height: 28),

                // Tekrarlama (Haftalık Hücreler)
                _buildSectionHeader(AppLocalizations.get('add_repeat', locale)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final isSelected = selectedDays.contains(day);
                    return GestureDetector(
                      onTap: () => toggleDay(day),
                      child: Container(
                        width: (MediaQuery.of(context).size.width - 76) / 7,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isSelected ? Colors.white24 : Colors.transparent),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          AppLocalizations.get('day_$index', locale),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white38,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 28),

                // Melodi Seçimi (Carousel)
                _buildSectionHeader(AppLocalizations.get('add_melody', locale)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _melodyItem(AppLocalizations.get('melody_hard', locale), 'assets/audio/hard_alarm.mp3', Icons.volume_up, false),
                      _melodyItem(AppLocalizations.get('melody_soft', locale), 'assets/audio/soft_alarm.mp3', Icons.notifications_active_outlined, false),
                      _melodyItem(AppLocalizations.get('melody_modern', locale), 'assets/audio/modern_alarm.mp3', Icons.music_note_outlined, false),
                      ..._customSounds.map((s) => _melodyItem(s['name'] ?? '', s['path'] ?? '', Icons.my_library_music_outlined, true)),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Durdurma Yöntemi (Tek Sıra)
                _buildSectionHeader(AppLocalizations.get('add_stop_method', locale)),
                const SizedBox(height: 12),
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

                if (!methodsUnlocked) ...[
                  const SizedBox(height: 16),
                  _buildTryOnceButton(),
                ],

                const SizedBox(height: 40),

                // Kaydet Butonu (Premium Look)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: saveAlarm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      shadowColor: AppTheme.secondaryColor.withOpacity(0.5),
                    ),
                    child: Text(
                      AppLocalizations.get('add_save', locale).toUpperCase(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2),
      ),
    );
  }

  Widget _melodyItem(String label, String path, IconData icon, bool isCustom) {
    final bool isSelected = selectedSound == path;
    return GestureDetector(
      onTap: () async {
        setState(() => selectedSound = path);
        try {
          await FlutterRingtonePlayer().stop();
          await _audioPlayer.stop();
          if (isCustom) {
            await _audioPlayer.play(DeviceFileSource(path));
          } else {
            await FlutterRingtonePlayer().play(fromAsset: path, looping: false, volume: 0.8);
          }
        } catch (e) {
          debugPrint("Ses çalınamadı: $e");
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.white30 : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white24, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodChip(String label, String value, bool isUnlocked) {
    final isSelected = selectedStopMethod == value;
    final bool showProBadge = !isUnlocked && value != 'math';

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          if (!isUnlocked && value != 'math') {
            _showPremiumLock(context);
            return;
          }
          setState(() => selectedStopMethod = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.white24 : (showProBadge ? Colors.amber.withOpacity(0.3) : Colors.transparent),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : (showProBadge ? Colors.white38 : Colors.white60),
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                ),
              ),
              if (showProBadge) ...[
                const SizedBox(width: 8),
                const Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.amber),
              ],
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_filled_rounded, size: 20, color: Colors.amber),
            const SizedBox(width: 8),
            _isLoadingAd
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber))
              : Text(
                  "${AppLocalizations.get('reward_try_once', locale)} ${AppLocalizations.get('reward_try_once_desc', locale)}",
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                ),
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
