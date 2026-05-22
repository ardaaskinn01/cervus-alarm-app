import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm_model.dart';
import '../services/local_storage_service.dart';
import '../services/alarm_service.dart';
import '../core/app_localizations.dart';

import 'package:alarm/alarm.dart';

class HomeViewModel extends Notifier<List<AlarmModel>> {
  @override
  List<AlarmModel> build() {
    final alarms = ref.read(localStorageServiceProvider).getAlarms();
    // Uygulama açıldığında sistemdeki kurulu alarmlar ile 
    // bizim veritabanımızı senkronize et.
    Future.microtask(() => syncWithSystem());
    
    return alarms;
  }

  /// Sistemdeki (Alarm package) alarmlar ile yerel veritabanını 
  /// tam senkronize eder. 'Açık görünüp aslında çalmayan' bug'ını çözer.
  Future<void> syncWithSystem() async {
    final storage = ref.read(localStorageServiceProvider);
    final alarmService = ref.read(alarmServiceProvider);
    final locale = ref.read(localeProvider);
    
    bool changed = false;
    final currentAlarms = List<AlarmModel>.from(state);
    final systemAlarms = await Alarm.getAlarms(); 

    for (int i = 0; i < currentAlarms.length; i++) {
        final alarm = currentAlarms[i];
        
        // 1. Durum: Bizde AKTİF ama Sistemde YOK (Kritik Bug Çözümü)
        // Eğer sistemde bu ID ile bir alarm yoksa ve biz aktif biliyorsak:
        final existsInSystem = systemAlarms.any((a) => a.id == alarm.id);
        
        if (alarm.isActive && !existsInSystem) {
          // Eğer saati henüz geçmediyse veya tekrarlayan bir alarm ise YENİDEN KUR
          final now = DateTime.now();
          final alarmTime = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
          
          if (alarm.repeatDays.isNotEmpty || alarmTime.isAfter(now)) {
            debugPrint("⚠️ Bug detected: Alarm ${alarm.id} was active in DB but missing in System. Re-scheduling...");
            try {
              await alarmService.scheduleAlarm(alarm, locale);
            } catch (e) {
              debugPrint("Reschedule error: $e");
            }
          } else {
            // Saati geçmiş ve tek seferlikse PASİF yap.
            final updated = alarm.copyWith(isActive: false);
            await storage.updateAlarm(updated);
            currentAlarms[i] = updated;
            changed = true;
          }
        }
        
        // 2. Durum: Bizde PASİF ama Sistemde HALA VAR (Nadiren olur, temizlik amaçlı)
        if (!alarm.isActive && existsInSystem) {
          await alarmService.cancelAlarm(alarm.id);
        }
    }

    if (changed) {
      state = currentAlarms;
    }
  }

  List<AlarmModel> _getSortedAlarms() {
    final alarms = ref.read(localStorageServiceProvider).getAlarms();
    alarms.sort((a, b) {
      if (a.hour != b.hour) return a.hour.compareTo(b.hour);
      return a.minute.compareTo(b.minute);
    });
    return alarms;
  }

  Future<void> addAlarm(AlarmModel newAlarm) async {
    final storage = ref.read(localStorageServiceProvider);
    final alarmService = ref.read(alarmServiceProvider);

    // 1. Önce veritabanına kaydet
    await storage.saveAlarm(newAlarm);

    // 2. UI'ı HER DURUMDA hemen güncelle
    state = _getSortedAlarms();

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
    state = _getSortedAlarms();

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

  /// Sadece veritabanını ve UI'ı günceller, alarm servisini (sesi) kurcalamaz.
  Future<void> silentEditAlarm(AlarmModel updatedAlarm) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.updateAlarm(updatedAlarm);
    state = _getSortedAlarms();
  }

  Future<void> toggleAlarm(AlarmModel alarm, bool isActive) async {
    final storage = ref.read(localStorageServiceProvider);
    final alarmService = ref.read(alarmServiceProvider);

    final updatedAlarm = alarm.copyWith(isActive: isActive);

    // 1. Önce veritabanına kaydet
    await storage.updateAlarm(updatedAlarm);

    // 2. UI'ı HER DURUMDA hemen güncelle
    state = _getSortedAlarms();

    // 3. Alarm servisini ayrı try-catch'te çalıştır
    try {
      if (isActive) {
        final locale = ref.read(localeProvider);
        await alarmService.scheduleAlarm(updatedAlarm, locale);
      } else {
        await alarmService.cancelAlarm(updatedAlarm.id);
        await alarmService.stopForegroundRinging(); // Görev bittiğinde sesi sustur
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
      state = _getSortedAlarms();

      try {
        final locale = ref.read(localeProvider);
        await alarmService.cancelAlarm(id);
        await alarmService.scheduleAlarm(snoozedAlarm, locale);
        await alarmService.stopForegroundRinging(); // Erteleyince sesi sustur
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
    state = _getSortedAlarms();

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
