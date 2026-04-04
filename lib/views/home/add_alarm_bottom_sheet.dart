import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../../core/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../models/alarm_model.dart';
import '../../viewmodels/home_viewmodel.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.existingAlarm != null) {
      final now = DateTime.now();
      selectedTime = DateTime(now.year, now.month, now.day, widget.existingAlarm!.hour, widget.existingAlarm!.minute);
      selectedDays = List.from(widget.existingAlarm!.repeatDays);
      selectedSound = widget.existingAlarm!.soundPath;
    } else {
      selectedTime = DateTime.now();
      selectedDays = [];
      selectedSound = 'assets/audio/soft_alarm.mp3';
    }
  }

  @override
  void dispose() {
    // FlutterRingtonePlayer().stop();
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

  void saveAlarm() {
    if (widget.existingAlarm != null) {
      final updatedAlarm = widget.existingAlarm!.copyWith(
        hour: selectedTime.hour,
        minute: selectedTime.minute,
        repeatDays: selectedDays,
        soundPath: selectedSound,
        isActive: true,
      );
      ref.read(homeViewModelProvider.notifier).editAlarm(updatedAlarm);
    } else {
      final newAlarm = AlarmModel(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        hour: selectedTime.hour,
        minute: selectedTime.minute,
        isActive: true,
        repeatDays: selectedDays,
        soundPath: selectedSound,
      );
      ref.read(homeViewModelProvider.notifier).addAlarm(newAlarm);
    }
    // FlutterRingtonePlayer().stop();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final locale = 'tr'; // localeProvider kaldırıldı

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull Handle
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
              // Cupertino Time Picker
              SizedBox(
                height: 200,
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
              const SizedBox(height: 24),
              // Days Selector
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
              // Sound Selector
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.get('add_sound', locale),
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _buildSoundOption('assets/audio/soft_alarm.mp3', AppLocalizations.get('sound_soft', locale), Icons.notifications_none),
                    _buildSoundOption('assets/audio/hard_alarm.mp3', AppLocalizations.get('sound_hard', locale), Icons.notifications_active),
                    _buildSoundOption('assets/audio/modern_alarm.mp3', AppLocalizations.get('sound_modern', locale), Icons.access_alarm),
                  ],
                ),
              ),
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
    );
  }

  // _getDayChar method removed as it's handled by AppLocalizations

  Widget _buildSoundOption(String path, String name, IconData icon) {
    bool isSelected = selectedSound == path;
    return InkWell(
      onTap: () {
        setState(() => selectedSound = path);
        // Önizleme çal
        // FlutterRingtonePlayer().stop(); // Varsa eskiyi durdur
        /*
        FlutterRingtonePlayer().play(
          fromAsset: path,
          volume: 0.5,
          looping: false,
        );
        */
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.secondaryColor : Colors.white38, size: 20),
            const SizedBox(width: 16),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.secondaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}
