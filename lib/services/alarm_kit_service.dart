import 'package:flutter/services.dart';
import 'dart:io';

class AlarmKitService {
  static final MethodChannel _channel = const MethodChannel('com.app/alarm_kit');
  static Function(String)? _onAlarmTappedCallback;

  static void init(Function(String) onTapped) {
    _onAlarmTappedCallback = onTapped;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAlarmTapped') {
        final String? alarmId = call.arguments as String?;
        if (alarmId != null) _onAlarmTappedCallback?.call(alarmId);
      }
    });
  }

  static Future<String?> getLaunchedAlarmId() async {
    if (!Platform.isIOS) return null;
    return await _channel.invokeMethod('getLaunchedAlarmId');
  }

  static Future<bool> requestAuthorization() async {
    if (!Platform.isIOS) return true;
    try {
      final bool success = await _channel.invokeMethod('requestAuthorization');
      return success;
    } on PlatformException catch (e) {
      print("AlarmKit Auth Error: ${e.message}");
      return false;
    }
  }

  static Future<void> scheduleAlarm({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required List<int> repeats,
    String? sound,
  }) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('scheduleAlarm', {
        'id': id.toString(),
        'hour': hour,
        'minute': minute,
        'title': title,
        'repeats': repeats,
        'sound': sound,
      });
    } on PlatformException catch (e) {
      print("AlarmKit Schedule Error: ${e.message}");
    }
  }

  static Future<void> stopAlarm(int id) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('stopAlarm', {
        'id': id.toString(),
      });
    } on PlatformException catch (e) {
      print("AlarmKit Stop Error: ${e.message}");
    }
  }

  // --- Android Specific ---

  static Future<bool> checkExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod('checkExactAlarmPermission');
    } catch (e) {
      return true;
    }
  }

  static Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openExactAlarmSettings');
    } catch (e) {}
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {}
  }
}
