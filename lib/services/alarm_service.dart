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
    // alarm paketini iOS ve Android için hazırla
    // Paketin bu sürümü izinleri Alarm.set sırasında veya init içinde halleder
    await Alarm.init();
  }

  Future<void> scheduleAlarm(AlarmModel alarm) async {
    // Mevcut zamana göre bir sonraki alarm anını hesapla
    DateTime now = DateTime.now();
    DateTime alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.hour,
      alarm.minute,
    );

    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    // Melodi seçimini belirle
    String audioPathAsset = 'assets/audio/hard_alarm.mp3';
    if (alarm.soundPath == 'soft_alarm' || alarm.soundPath == 'assets/audio/soft_alarm.mp3') {
       audioPathAsset = 'assets/audio/soft_alarm.mp3';
    } else if (alarm.soundPath == 'modern_alarm' || alarm.soundPath == 'assets/audio/modern_alarm.mp3') {
       audioPathAsset = 'assets/audio/modern_alarm.mp3';
    }

    final alarmSettings = AlarmSettings(
      id: alarm.id,
      dateTime: alarmTime,
      assetAudioPath: audioPathAsset,
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: const Duration(seconds: 3),
        volumeEnforced: false, // iOS'ta true kullanmak ses sistemini bloklayabiliyor
      ),
      vibrate: _storage.getGlobalVibrate(),
      warningNotificationOnKill: true,
      notificationSettings: const NotificationSettings(
        title: "Zorlu Alarm - Uyanma Vakti!",
        body: "Günün başlıyor, hadi ayılma vakti!",
        stopButton: "Durdur", // iOS'ta null bırakmak notification kurulumunu bozabilir
        icon: null,
      ),
    );

    try {
      await Alarm.set(alarmSettings: alarmSettings);
    } catch (e) {
      debugPrint("Alarm kurulamadı: $e");
    }
  }

  Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
  }

  Future<void> cancelAlarm(int id) async {
    await Alarm.stop(id);
  }
}
