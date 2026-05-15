import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class DashboardService with WidgetsBindingObserver {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final String _projectId = "dashboard-baf3f";
  final String _apiKey = "AIzaSyBPOS5L2Qdoi0kVXgyQnCoWuAdbUfh_YAo";
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
      _updateCurrentSessionDuration();
      _heartbeatTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _sessionStartTime = DateTime.now();
      _startHeartbeat();
    }
  }

  Future<void> logVisit() async {
    if (!_isInitialized || _deviceId == null || _deviceId!.isEmpty) return;
    
    // iOS için bağlantı stabilitesi adına kısa bir gecikme
    if (Platform.isIOS) {
      await Future.delayed(const Duration(seconds: 2));
    }

    try {
      final now = DateTime.now();
      final String date = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final String time = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String appVersion = "${packageInfo.version}+${packageInfo.buildNumber}";

      // Doğru platform ismini kesinleştir
      String platformName = 'Other';
      if (Platform.isIOS) {
        platformName = 'iOS';
      } else if (Platform.isAndroid) {
        platformName = 'Android';
      }

      // 1. ADIM: Kullanıcı Senkronizasyonu
      final userPath = "users/$_deviceId";
      await _setDocument(userPath, {
        "originalName": {"stringValue": ""},
        "age": {"integerValue": "0"}, 
        "platform": {"stringValue": platformName},
        "appId": {"stringValue": _appId},
        "createdAt": {"timestampValue": now.toUtc().toIso8601String()},
        "lastVisit": {"stringValue": "$date $time"},
        "appVersion": {"stringValue": appVersion},
      });

      // 2. ADIM: Ziyaret Kaydı
      _currentVisitId = "${date}_${time.replaceAll(':', '-')}";
      _sessionStartTime = now;
      _totalSecondsThisSession = 0;

      final visitPath = "users/$_deviceId/visits/$_currentVisitId";
      final bool ok = await _setDocument(visitPath, {
        "date": {"stringValue": date},
        "time": {"stringValue": time},
        "platform": {"stringValue": platformName},
        "appId": {"stringValue": _appId},
        "appVersion": {"stringValue": appVersion},
        "timestamp": {"timestampValue": now.toUtc().toIso8601String()},
        "durationSeconds": {"integerValue": "0"},
      });

      if (ok) {
        _startHeartbeat();
        debugPrint("📊 Dashboard visit log success: $_currentVisitId");
      }
    } catch (e) {
      debugPrint("📊 Dashboard logVisit error: $e");
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) => _updateCurrentSessionDuration());
  }

  Future<void> _updateCurrentSessionDuration() async {
    if (_sessionStartTime == null || _deviceId == null || _currentVisitId == null) return;

    final now = DateTime.now();
    final int elapsed = now.difference(_sessionStartTime!).inSeconds;
    _totalSecondsThisSession += elapsed;
    _sessionStartTime = now;

    final path = "users/$_deviceId/visits/$_currentVisitId";
    await _patchDocument(path, {
      "durationSeconds": {"integerValue": _totalSecondsThisSession.toString()},
      "lastUpdate": {"timestampValue": now.toUtc().toIso8601String()},
    });
  }

  // -----------------------------------------------------------
  // REST HELPERS (DRINKLY'DEN ALINDI - iOS'ta ÇALIŞAN YÖNTEM)
  // -----------------------------------------------------------

  Future<bool> _setDocument(String path, Map<String, dynamic> fields) async {
    try {
      final url = "https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/$path?key=$_apiKey";
      final res = await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': fields}),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<void> _patchDocument(String path, Map<String, dynamic> fields) async {
    try {
      final updateMask = fields.keys.map((k) => 'updateMask.fieldPaths=$k').join('&');
      final url = "https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/$path?key=$_apiKey&$updateMask";
      await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': fields}),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {}
  }

  Future<Map<String, dynamic>?> getVersionConfig() async {
    try {
      final url = "https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/settings/app_config?key=$_apiKey";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _simplifyFields(data['fields']);
      }
    } catch (e) {}
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
