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

  /// Daha güvenilir zincirleme bildirim yöntemi.
  /// fireDate: Alarmın tam tetikleneceği an (Unix timestamp, saniye cinsinden)
  static Future<void> scheduleAlarmChain({
    required int id,
    required DateTime fireDate,
    required String title,
    String sound = 'hard_alarm.mp3',
    int count = 20,
    int intervalSeconds = 15,
  }) async {
    if (!Platform.isIOS) return;
    try {
      // fireDate'i epoch saniyesine çevir
      final fireDateEpoch = fireDate.millisecondsSinceEpoch / 1000.0;
      await _channel.invokeMethod('scheduleAlarmChain', {
        'id': id.toString(),
        'fireDate': fireDateEpoch,
        'title': title,
        'sound': sound,
        'count': count,
        'intervalSeconds': intervalSeconds,
      });
    } on PlatformException catch (e) {
      print("AlarmKit Chain Error: ${e.message}");
    }
  }

  static Future<void> setSystemVolume(double volume) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('setSystemVolume', {'volume': volume});
    } catch (e) {
      print("Set Volume Error: $e");
    }
  }

  static Future<void> startVolumeEnforcement({double volume = 1.0}) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('startVolumeEnforcement', {'volume': volume});
    } catch (e) {
      print("Start Volume Enforcement Error: $e");
    }
  }

  static Future<void> stopVolumeEnforcement() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('stopVolumeEnforcement');
    } catch (e) {
      print("Stop Volume Enforcement Error: $e");
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
