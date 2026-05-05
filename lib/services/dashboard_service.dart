import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DashboardService with WidgetsBindingObserver {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  FirebaseApp? _dashboardApp;
  FirebaseFirestore? _firestore;
  bool _isInitialized = false;

  // Session tracking variables
  DateTime? _sessionStartTime;
  String? _deviceId;
  String? _currentVisitId;
  int _totalSecondsThisSession = 0;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Manual Firebase initialization for the Dashboard project
      _dashboardApp = Firebase.apps.any((app) => app.name == 'dashboard')
          ? Firebase.app('dashboard')
          : await Firebase.initializeApp(
              name: 'dashboard',
              options: const FirebaseOptions(
                apiKey: "AIzaSyBPOS5L2Qdoi0kVXgyQnCoWuAdbUfh_YAo",
                authDomain: "dashboard-baf3f.firebaseapp.com",
                projectId: "dashboard-baf3f",
                storageBucket: "dashboard-baf3f.firebasestorage.app",
                messagingSenderId: "607527844560",
                appId: "1:607527844560:web:2415525d9fa986fdc03cd5",
                measurementId: "G-5CN9G1FZ0B",
              ),
            );

      _firestore = FirebaseFirestore.instanceFor(app: _dashboardApp!);
      _isInitialized = true;
      
      // Setup lifecycle observer
      if (WidgetsBinding.instance.lifecycleState != null) {
        WidgetsBinding.instance.addObserver(this);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          WidgetsBinding.instance.addObserver(this);
        });
      }
      
      debugPrint('✅ Dashboard Service connected (alarmly)');
    } catch (e) {
      debugPrint('❌ Dashboard Service Init Error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _updateCurrentSessionDuration();
    } else if (state == AppLifecycleState.resumed) {
      _sessionStartTime = DateTime.now();
    }
  }

  Future<void> logVisit() async {
    if (!_isInitialized || _firestore == null) await init();
    if (!_isInitialized) return;

    try {
      // Get Device ID
      _deviceId = await _getDeviceId();
      
      // Get App Version
      final packageInfo = await PackageInfo.fromPlatform();
      final String version = packageInfo.version;
      final String buildNumber = packageInfo.buildNumber;

      final now = DateTime.now();
      _currentVisitId = now.millisecondsSinceEpoch.toString();
      _sessionStartTime = now;
      _totalSecondsThisSession = 0;

      // Log to users collection
      final userRef = _firestore!.collection('users').doc(_deviceId);
      await userRef.set({
        'lastVisit': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'iOS' : 'Android',
        'appId': 'alarmly',
        'lastVersion': '$version+$buildNumber',
      }, SetOptions(merge: true));

      // Log specific visit
      await userRef.collection('visits').doc(_currentVisitId).set({
        'appVersion': '$version+$buildNumber',
        'platform': Platform.isIOS ? 'iOS' : 'Android',
        'dateTime': now.toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
        'durationSeconds': 0,
        'appId': 'alarmly',
      });

    } catch (e) {
      debugPrint('⚠️ Log Visit Error: $e');
    }
  }

  Future<void> _updateCurrentSessionDuration() async {
    if (!_isInitialized || _sessionStartTime == null || _deviceId == null || _currentVisitId == null) return;

    final now = DateTime.now();
    final int elapsedSeconds = now.difference(_sessionStartTime!).inSeconds;
    _totalSecondsThisSession += elapsedSeconds;
    _sessionStartTime = now;

    try {
      await _firestore!
          .collection('users')
          .doc(_deviceId)
          .collection('visits')
          .doc(_currentVisitId)
          .update({
        'durationSeconds': _totalSecondsThisSession,
        'lastUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Session Update Error: $e');
    }
  }

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Correct way to get ID on Android
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    }
    return 'unknown_platform';
  }

  FirebaseFirestore? get firestore => _firestore;
}
