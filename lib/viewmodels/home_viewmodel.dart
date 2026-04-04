import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm_model.dart';
import '../services/local_storage_service.dart';
import '../services/alarm_service.dart';

class HomeViewModel extends Notifier<List<AlarmModel>> {
  @override
  List<AlarmModel> build() {
    state = ref.read(localStorageServiceProvider).getAlarms();
    return state;
  }

  Future<void> addAlarm(AlarmModel newAlarm) async {
    final storage = ref.read(localStorageServiceProvider);
    final alarmService = ref.read(alarmServiceProvider);
    
    await storage.saveAlarm(newAlarm);
    if (newAlarm.isActive) {
      await alarmService.scheduleAlarm(newAlarm);
    }
    
    state = [...storage.getAlarms()]; // Yeni liste referansı ile UI'ı zorla yenile
  }

  Future<void> editAlarm(AlarmModel updatedAlarm) async {
    final storage = ref.read(localStorageServiceProvider);
    final alarmService = ref.read(alarmServiceProvider);
    
    await storage.updateAlarm(updatedAlarm);
    await alarmService.cancelAlarm(updatedAlarm.id);
    
    if (updatedAlarm.isActive) {
      await alarmService.scheduleAlarm(updatedAlarm);
    }
    
    state = [...storage.getAlarms()];
  }

  Future<void> toggleAlarm(AlarmModel alarm, bool isActive) async {
    final storage = ref.read(localStorageServiceProvider);
    final alarmService = ref.read(alarmServiceProvider);
    
    final updatedAlarm = alarm.copyWith(isActive: isActive);
    await storage.updateAlarm(updatedAlarm);
    
    if (isActive) {
      await alarmService.scheduleAlarm(updatedAlarm);
    } else {
      await alarmService.cancelAlarm(updatedAlarm.id);
    }
    
    state = [...storage.getAlarms()];
  }

  Future<void> snoozeAlarm(int id) async {
    final storage = ref.read(localStorageServiceProvider);
    final alarmService = ref.read(alarmServiceProvider);
    
    final alarmList = storage.getAlarms();
    try {
      final targetAlarm = alarmList.firstWhere((x) => x.id == id);
      // Wait for 10 minutes from now
      final newTime = DateTime.now().add(const Duration(minutes: 10));
      final snoozedAlarm = targetAlarm.copyWith(hour: newTime.hour, minute: newTime.minute, isActive: true);
      
      await alarmService.cancelAlarm(id);
      await storage.updateAlarm(snoozedAlarm);
      await alarmService.scheduleAlarm(snoozedAlarm);
      
      state = [...storage.getAlarms()];
    } catch (_) {}
  }

  Future<void> deleteAlarm(int id) async {
    final storage = ref.read(localStorageServiceProvider);
    final alarmService = ref.read(alarmServiceProvider);
    
    await alarmService.cancelAlarm(id);
    await storage.deleteAlarm(id);
    state = [...storage.getAlarms()];
  }
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, List<AlarmModel>>(() {
  return HomeViewModel();
});
