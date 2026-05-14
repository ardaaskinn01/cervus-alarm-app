import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../core/navigator_key.dart';

class DashboardService with WidgetsBindingObserver {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final String _projectId = "dashboard-baf3f";
  final String _appId = "alarmly";

  bool _isInitialized = false;
  String? _deviceId;
  String? _currentVisitId;
  DateTime? _sessionStartTime;
  int _totalSecondsThisSession = 0;
  Timer? _heartbeatTimer;

  Future<void> init(String deviceId) async {
    if (_isInitialized) return;
    _deviceId = deviceId;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _updateDuration();
      _heartbeatTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _sessionStartTime = DateTime.now();
      _startHeartbeat();
    }
  }

  Future<void> logVisit() async {
    if (!_isInitialized || _deviceId == null || _deviceId!.isEmpty) {
      debugPrint("⚠️ Dashboard logVisit: Service not initialized or deviceId is empty.");
      return;
    }
    
    if (Platform.isIOS) {
      await Future.delayed(const Duration(seconds: 2));
    }

    try {
      final now = DateTime.now();
      final String date = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final String time = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String appVersion = "${packageInfo.version} (Build ${packageInfo.buildNumber})";

      // 1. ADIM: Kullanıcı Senkronizasyonu (Drinkly/Quitly tarzı - Eksik alanlar eklendi)
      final String userUrl = "https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/users/$_deviceId";
      
      await http.patch(
        Uri.parse(userUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fields": {
            "originalName": {"stringValue": ""}, // İsmi boş gönderiyoruz (Dashboard bekliyor olabilir)
            "age": {"integerValue": "0"},         // Yaş bilgisini 0 gönderiyoruz
            "lastVisit": {"stringValue": "$date $time"},
            "lastUpdate": {"timestampValue": now.toUtc().toIso8601String()},
            "platform": {"stringValue": Platform.isIOS ? 'iOS' : 'Android'},
            "appId": {"stringValue": _appId},
            "appVersion": {"stringValue": appVersion},
          }
        }),
      ).timeout(const Duration(seconds: 10));

      // 2. ADIM: Ziyaret Kaydı
      _currentVisitId = now.millisecondsSinceEpoch.toString();
      _sessionStartTime = now;
      _totalSecondsThisSession = 0;

      final String visitUrl = "https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/users/$_deviceId/visits/$_currentVisitId";
      
      final visitResponse = await http.patch(
        Uri.parse(visitUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fields": {
            'date': {'stringValue': date},
            'time': {'stringValue': time},
            'platform': {'stringValue': Platform.isIOS ? 'iOS' : 'Android'},
            'appId': {'stringValue': _appId},
            'appVersion': {'stringValue': appVersion},
            'timestamp': {'timestampValue': now.toUtc().toIso8601String()},
            'durationSeconds': {'integerValue': '0'},
          }
        }),
      ).timeout(const Duration(seconds: 10));

      if (visitResponse.statusCode == 200) {
        _startHeartbeat();
        debugPrint("📊 Dashboard visit log success: $_currentVisitId (Device: $_deviceId)");
      } else {
        debugPrint("⚠️ Dashboard VISIT record ERROR ${visitResponse.statusCode}: ${visitResponse.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Dashboard logVisit EXCEPTION: $e");
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) => _updateDuration());
  }

  void _updateDuration() async {
    if (_sessionStartTime == null || _deviceId == null || _currentVisitId == null) return;

    final now = DateTime.now();
    final int elapsed = now.difference(_sessionStartTime!).inSeconds;
    _totalSecondsThisSession += elapsed;
    _sessionStartTime = now;

    try {
      final String url = "https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/users/$_deviceId/visits/$_currentVisitId?updateMask.fieldPaths=durationSeconds&updateMask.fieldPaths=lastUpdate";
      
      final response = await http.patch(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fields": {
            "durationSeconds": {"integerValue": _totalSecondsThisSession.toString()},
            "lastUpdate": {"timestampValue": now.toUtc().toIso8601String()},
          }
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("⚠️ Dashboard updateDuration ERROR ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Dashboard _updateDuration EXCEPTION: $e");
    }
  }

  Future<Map<String, dynamic>?> getVersionConfig() async {
    try {
      final url = "https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/settings/app_config";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _simplifyFields(data['fields']);
      } else {
        debugPrint("⚠️ Dashboard getVersionConfig ERROR ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Dashboard getVersionConfig EXCEPTION: $e");
    }
    return null;
  }

  Map<String, dynamic> _simplifyFields(Map<String, dynamic> fields) {
    final result = <String, dynamic>{};
    fields.forEach((key, value) {
      if (value is Map) {
        if (value.containsKey('stringValue')) {
          result[key] = value['stringValue'].toString();
        } else if (value.containsKey('integerValue')) {
          result[key] = int.tryParse(value['integerValue'].toString());
        } else if (value.containsKey('doubleValue')) {
          result[key] = double.tryParse(value['doubleValue'].toString());
        } else if (value.containsKey('booleanValue')) {
          result[key] = value['booleanValue'] as bool;
        }
      }
    });
    return result;
  }
}
