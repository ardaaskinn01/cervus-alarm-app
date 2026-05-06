import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DashboardService with WidgetsBindingObserver {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final String _projectId = "dashboard-baf3f";
  final String _apiKey = "AIzaSyBPOS5L2Qdoi0kVXgyQnCoWuAdbUfh_YAo";
  final String _appId = "alarmly";

  bool _isInitialized = false;

  // Session tracking variables
  DateTime? _sessionStartTime;
  String? _deviceId;
  String? _currentVisitId;
  int _totalSecondsThisSession = 0;
  Timer? _heartbeatTimer;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _deviceId = await _getDeviceId();
      _isInitialized = true;
      
      // Setup lifecycle observer
      if (WidgetsBinding.instance.lifecycleState != null) {
        WidgetsBinding.instance.addObserver(this);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          WidgetsBinding.instance.addObserver(this);
        });
      }
      
      debugPrint('✅ Dashboard Service initialized via REST (alarmly)');
    } catch (e) {
      debugPrint('❌ Dashboard Service Init Error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopHeartbeat();
      _updateCurrentSessionDuration();
    } else if (state == AppLifecycleState.resumed) {
      _sessionStartTime = DateTime.now();
      _startHeartbeat();
    }
  }

  Future<void> logVisit() async {
    if (!_isInitialized) await init();
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final String version = "${packageInfo.version}+${packageInfo.buildNumber}";
      final now = DateTime.now();
      
      _currentVisitId = now.millisecondsSinceEpoch.toString();
      _sessionStartTime = now;
      _totalSecondsThisSession = 0;

      // 1. Update User Last Visit
      final userPath = "users/$_deviceId";
      await _setDocument(userPath, {
        "lastVisit": {"stringValue": now.toIso8601String()},
        "platform": {"stringValue": Platform.isIOS ? 'iOS' : 'Android'},
        "appId": {"stringValue": _appId},
        "lastVersion": {"stringValue": version},
      }, merge: true);

      // 2. Create Visit Document
      final visitPath = "users/$_deviceId/visits/$_currentVisitId";
      await _setDocument(visitPath, {
        "appVersion": {"stringValue": version},
        "platform": {"stringValue": Platform.isIOS ? 'iOS' : 'Android'},
        "dateTime": {"stringValue": now.toIso8601String()},
        "timestamp": {"stringValue": now.toIso8601String()},
        "durationSeconds": {"integerValue": "0"},
        "appId": {"stringValue": _appId},
      });

      _startHeartbeat();
    } catch (e) {
      debugPrint('⚠️ Log Visit Error: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _updateCurrentSessionDuration();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _updateCurrentSessionDuration() async {
    if (!_isInitialized || _sessionStartTime == null || _deviceId == null || _currentVisitId == null) return;

    final now = DateTime.now();
    final int elapsedSeconds = now.difference(_sessionStartTime!).inSeconds;
    _totalSecondsThisSession += elapsedSeconds;
    _sessionStartTime = now;

    try {
      final visitPath = "users/$_deviceId/visits/$_currentVisitId";
      await _setDocument(visitPath, {
        "durationSeconds": {"integerValue": _totalSecondsThisSession.toString()},
        "lastUpdate": {"stringValue": now.toIso8601String()},
      }, merge: true, updateMask: ["durationSeconds", "lastUpdate"]);
    } catch (e) {
      debugPrint('⚠️ Session Update Error: $e');
    }
  }

  Future<Map<String, dynamic>?> getVersionConfig() async {
    try {
      // Path: settings/app_config
      final url = "https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/settings/app_config?key=$_apiKey";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _simplifyFields(data['fields']);
      }
    } catch (e) {
      debugPrint('⚠️ Version Check Error: $e');
    }
    return null;
  }

  // --- REST Helpers ---

  Future<void> _setDocument(String path, Map<String, dynamic> fields, {bool merge = false, List<String>? updateMask}) async {
    // Firestore REST uses PATCH for both create and update if you want to use the document ID in the path
    String url = "https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/$path?key=$_apiKey";
    
    if (updateMask != null) {
      for (var field in updateMask) {
        url += "&updateMask.fieldPaths=$field";
      }
    } else if (merge) {
      for (var field in fields.keys) {
        url += "&updateMask.fieldPaths=$field";
      }
    }

    await http.patch(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"fields": fields}),
    );
  }

  Map<String, dynamic> _simplifyFields(Map<String, dynamic> fields) {
    final result = <String, dynamic>{};
    fields.forEach((key, value) {
      if (value is Map) {
        if (value.containsKey('stringValue')) result[key] = value['stringValue'];
        else if (value.containsKey('integerValue')) result[key] = int.tryParse(value['integerValue'].toString());
        else if (value.containsKey('doubleValue')) result[key] = double.tryParse(value['doubleValue'].toString());
        else if (value.containsKey('booleanValue')) result[key] = value['booleanValue'];
      }
    });
    return result;
  }

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    }
    return 'unknown_platform';
  }
}
