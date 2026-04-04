// import 'package:alarm/alarm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm_model.dart';
import 'package:flutter/foundation.dart';

import 'local_storage_service.dart';

final alarmServiceProvider = Provider<AlarmService>((ref) {
  final storage = ref.read(localStorageServiceProvider);
  return AlarmService(storage);
});

class AlarmService {
  final LocalStorageService _storage;

  AlarmService(this._storage);
  Future<void> init() async {
    // await Alarm.init();
    
    // Geçmişte kalmış alarmları temizle (Bildirimlerin sonsuz kalmaması için)
    // final allAlarms = await Alarm.getAlarms();
    // final now = DateTime.now();
    // for (var alarm in allAlarms) {
    //   if (alarm.dateTime.isBefore(now)) {
    //     await Alarm.stop(alarm.id);
    //   }
    // }
  }

  Future<void> scheduleAlarm(AlarmModel alarm) async {
    // Calculate the next occurrence based on the alarm's hour, minute
    DateTime now = DateTime.now();
    DateTime alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.hour,
      alarm.minute,
    );

    // If the time already passed today, set it for the next day
    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    // TODO: repeatDays logic for scheduling (skipping non-selected days) 
    // This is a basic schedule for the very exact next occurrence.

    final String alarmSound = alarm.soundPath == 'default' || alarm.soundPath.isEmpty
        ? 'assets/audio/soft_alarm.mp3'
        : alarm.soundPath;

    /*
    final alarmSettings = AlarmSettings(
      id: alarm.id,
      dateTime: alarmTime,
      assetAudioPath: alarmSound,
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: const Duration(seconds: 3),
        volumeEnforced: true,
      ),
      vibrate: _storage.getGlobalVibrate(),
      notificationSettings: const NotificationSettings(
        title: "Uyanma Vakti!",
        body: "Bu alarmı ertelemek veya kapatmak için soru çözmen gerek.",
      ),
    );

    try {
      await Alarm.set(alarmSettings: alarmSettings);
    } catch (e) {
      if (kDebugMode) {
        print("Alarm kurulamadı: $e");
      }
    }
    */
  }

  Future<void> stopAlarm(int id) async {
    // await Alarm.stop(id);
    // iOS'ta bildirimlerin temizlenmesi için kısa bir gecikme sonrası garanti durdurma
    // Future.delayed(const Duration(milliseconds: 500), () async {
    //   if (await Alarm.isRinging(id)) {
    //     await Alarm.stop(id);
    //   }
    // });
  }

  // Bir alarm henüz çalmadıysa ama iptal listesindeyse silmek için
  Future<void> cancelAlarm(int id) async {
    // await Alarm.stop(id);
  }
}
