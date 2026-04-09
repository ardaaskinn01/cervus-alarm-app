import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
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
    // alarm paketini başlat
    await Alarm.init();

    // Timezone ve Yedek Bildirim başlatılması (iOS için Hayati Hile)
    tz.initializeTimeZones();
    if (Platform.isIOS || Platform.isAndroid) {
      try {
        final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      } catch (e) {
        debugPrint("Timezone ayarlanamadı: $e");
      }
    }

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true, 
      requestBadgePermission: true, 
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      iOS: initializationSettingsIOS,
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
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
        stopButton: null,
        icon: null,
      ),
    );

    try {
      await Alarm.set(alarmSettings: alarmSettings);

      // ==========================================
      // YEDEK BİLDİRİM HİLESİ (SADECE iOS İÇİN)
      // ==========================================
      if (Platform.isIOS) {
        final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        final baseId = (alarm.id % 100000) * 10;
        
        // Öncekileri temizle
        for (int i = 0; i < 5; i++) {
          await flutterLocalNotificationsPlugin.cancel(baseId + i);
        }

        const platformChannelSpecifics = NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        );

        // Tam alarm anından başlayarak her 30 saniyede bir bildirim (Toplam 5 kez)
        for (int i = 0; i < 5; i++) {
          final scheduledDate = tz.TZDateTime.from(alarmTime, tz.local).add(Duration(seconds: 30 * i));
          
          await flutterLocalNotificationsPlugin.zonedSchedule(
            baseId + i,
            alarmSettings.notificationSettings.title,
            alarmSettings.notificationSettings.body,
            scheduledDate,
            platformChannelSpecifics,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      }
    } catch (e) {
      debugPrint("Alarm kurulamadı: $e");
    }
  }

  Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
    _cancelFallbackNotifications(id);
  }

  Future<void> cancelAlarm(int id) async {
    await Alarm.stop(id);
    _cancelFallbackNotifications(id);
  }

  Future<void> _cancelFallbackNotifications(int id) async {
    if (Platform.isIOS) {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      final baseId = (id % 100000) * 10;
      for (int i = 0; i < 5; i++) {
        await flutterLocalNotificationsPlugin.cancel(baseId + i);
      }
    }
  }
}
