import 'package:alarm/alarm.dart';
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
    // alarm paketinin init işlemini yapıyoruz.
    // iOS tarafında arkaplan yetkilerini kendi içinden Apple API'siyle sarmalar.
    await Alarm.init();
    
    // iOS için bildirim (notification) isteği atalım.
    if (Alarm.android) {
       // Android implementation details here if we ever deploy it.
    } else {
       // Request permission for iOS mostly, handled natively by Alarm.hasSystemAlertWindowPermission
       // Actually Alarm handles most checks automatically on `set`.
    }
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

    // Seçilen melodi ismini al, boşsa veya default ise hard_alarm.mp3'e düş
    String audioPathAsset = 'assets/audio/hard_alarm.mp3';
    if (alarm.soundPath == 'soft_alarm' || alarm.soundPath == 'assets/audio/soft_alarm.mp3') {
       audioPathAsset = 'assets/audio/soft_alarm.mp3';
    } else if (alarm.soundPath == 'modern_alarm' || alarm.soundPath == 'assets/audio/modern_alarm.mp3') {
       audioPathAsset = 'assets/audio/modern_alarm.mp3';
    }

    final alarmSettings = AlarmSettings(
      id: alarm.id,
      dateTime: alarmTime,
      assetAudioPath: audioPathAsset, // Dinamik melodi seçimi
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: const Duration(seconds: 3),
        volumeEnforced: true,
      ),
      vibrate: _storage.getGlobalVibrate(),
      warningNotificationOnKill: true, // Uygulama öldürülürse uyarı bildirimi gönder
      notificationSettings: const NotificationSettings(
        title: "Zorlu Alarm - Uyanma Vakti!",
        body: "Günün başlıyor, hadi ayılma vakti!",
        stopButton: null, // Sorun ihtimalini azaltmak için butonu kaldırıyoruz
        icon: null, // Varsayılan uygulama ikonunu kullanması için null bıraktık
      ),
    );

    try {
      await Alarm.set(alarmSettings: alarmSettings);
    } catch (e) {
      if (kDebugMode) {
        print("Alarm kurulamadı: \$e");
      }
    }
  }

  Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
  }

  // Bir alarm henüz çalmadıysa ama iptal listesindeyse silmek için
  Future<void> cancelAlarm(int id) async {
    await Alarm.stop(id);
  }
}
