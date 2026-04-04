import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm_model.dart';

// Riverpod provider for LocalStorageService
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

class LocalStorageService {
  static const String _alarmsBoxName = 'alarmsBox';
  static const String _settingsBoxName = 'settingsBox';

  Future<void> init() async {
    await Hive.initFlutter();
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AlarmModelAdapter());
    }
    
    
    // Open the boxes
    await Hive.openBox<AlarmModel>(_alarmsBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  Box<AlarmModel> get _box => Hive.box<AlarmModel>(_alarmsBoxName);

  List<AlarmModel> getAlarms() {
    return _box.values.toList();
  }

  Future<void> saveAlarm(AlarmModel alarm) async {
    // If the alarm has a specific id already in the box, we can put it there
    // For simplicity, we can just put it via the object's id
    await _box.put(alarm.id, alarm);
  }

  Future<void> updateAlarm(AlarmModel alarm) async {
    // Hive put replaces the existing item with the same key
    await _box.put(alarm.id, alarm);
  }

  Future<void> deleteAlarm(int id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  // Global Settings
  bool getGlobalVibrate() {
    return Hive.box(_settingsBoxName).get('global_vibrate', defaultValue: true);
  }

  Future<void> setGlobalVibrate(bool value) async {
    await Hive.box(_settingsBoxName).put('global_vibrate', value);
  }

  String getLanguage() {
    return Hive.box(_settingsBoxName).get('language', defaultValue: 'tr');
  }

  Future<void> setLanguage(String lang) async {
    await Hive.box(_settingsBoxName).put('language', lang);
  }
}
