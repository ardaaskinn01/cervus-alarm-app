import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm_model.dart';
import '../services/local_storage_service.dart';
import '../services/alarm_service.dart';
import '../core/app_localizations.dart';

class HomeViewModel extends Notifier<List<AlarmModel>> {
  @override
  List<AlarmModel> build() {
    return ref.read(localStorageServiceProvider).getAlarms();
  }

  Future<void> addAlarm(AlarmModel newAlarm) async {
    final storage = ref.read(localStorageServiceProvider);
    final alarmService = ref.read(alarmServiceProvider);

    // 1. Önce veritabanına kaydet
    await storage.saveAlarm(newAlarm);

    // 2. UI'ı HER DURUMDA hemen güncelle (alarm servisi hata verse bile)
    state = List.from(storage.getAlarms());

    // 3. Alarm servisini ayrı try-catch'te çalıştır
    if (newAlarm.isActive) {
      try {
        final locale = ref.read(localeProvider);
        await alarmService.scheduleAlarm(newAlarm, locale);
      } catch (e) {
        debugPrint('Alarm zamanlama hatası: $e');
      }
    }
  }

  Future<void> editAlarm(AlarmModel updatedAlarm) async {
    final storage = ref.read(localStorageServiceProvider);
    final alarmService = ref.read(alarmServiceProvider);

    // 1. Önce veritabanına kaydet
    await storage.updateAlarm(updatedAlarm);

    // 2. UI'ı HER DURUMDA hemen güncelle
    state = List.from(storage.getAlarms());

    // 3. Alarm servisini ayrı try-catch'te çalıştır
    try {
      await alarmService.cancelAlarm(updatedAlarm.id);
      if (updatedAlarm.isActive) {
        final locale = ref.read(localeProvider);
        await alarmService.scheduleAlarm(updatedAlarm, locale);
      }
    } catch (e) {
      debugPrint('Alarm güncelleme hatası: $e');
    }
  }

  Future<void> toggleAlarm(AlarmModel alarm, bool isActive) async {
    final storage = ref.read(localStorageServiceProvider);
    final alarmService = ref.read(alarmServiceProvider);

    final updatedAlarm = alarm.copyWith(isActive: isActive);

    // 1. Önce veritabanına kaydet
    await storage.updateAlarm(updatedAlarm);

    // 2. UI'ı HER DURUMDA hemen güncelle
    state = List.from(storage.getAlarms());

    // 3. Alarm servisini ayrı try-catch'te çalıştır
    try {
      if (isActive) {
        final locale = ref.read(localeProvider);
        await alarmService.scheduleAlarm(updatedAlarm, locale);
      } else {
        await alarmService.cancelAlarm(updatedAlarm.id);
      }
    } catch (e) {
      debugPrint('Alarm toggle hatası: $e');
    }
  }

  Future<void> snoozeAlarm(int id) async {
    final storage = ref.read(localStorageServiceProvider);
    final alarmService = ref.read(alarmServiceProvider);

    final alarmList = storage.getAlarms();
    try {
      final targetAlarm = alarmList.firstWhere((x) => x.id == id);
      final newTime = DateTime.now().add(const Duration(minutes: 10));
      final snoozedAlarm = targetAlarm.copyWith(
        hour: newTime.hour,
        minute: newTime.minute,
        isActive: true,
      );

      await storage.updateAlarm(snoozedAlarm);
      state = List.from(storage.getAlarms());

      try {
        final locale = ref.read(localeProvider);
        await alarmService.cancelAlarm(id);
        await alarmService.scheduleAlarm(snoozedAlarm, locale);
      } catch (e) {
        debugPrint('Snooze alarm hatası: $e');
      }
    } catch (_) {}
  }

  Future<void> deleteAlarm(int id) async {
    final storage = ref.read(localStorageServiceProvider);
    final alarmService = ref.read(alarmServiceProvider);

    // 1. Veritabanından sil
    await storage.deleteAlarm(id);

    // 2. UI'ı HER DURUMDA hemen güncelle
    state = List.from(storage.getAlarms());

    // 3. Alarm servisini ayrı try-catch'te çalıştır
    try {
      await alarmService.cancelAlarm(id);
    } catch (e) {
      debugPrint('Alarm iptal hatası: $e');
    }
  }
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, List<AlarmModel>>(() {
  return HomeViewModel();
});
