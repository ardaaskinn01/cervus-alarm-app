import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'models/alarm_model.dart';
import 'views/home/home_view.dart';
import 'views/ringing/ringing_view.dart';
import 'core/app_theme.dart';
import 'services/local_storage_service.dart';
import 'services/alarm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_localizations.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. ALARM PAKETİNİ EN ÖNCE BAŞLAT (stream dinleyicisinden önce hazır olmalı)
  await Alarm.init();

  // 2. SADECE EN KRİTİK VERİTABANINI BAŞLAT: (Bloklanmayı önlemek için)
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(AlarmModelAdapter());
  }
  await Hive.openBox<AlarmModel>('alarmsBox');
  await Hive.openBox('settingsBox');

  runApp(
    const ProviderScope(
      child: AlarmApp(),
    ),
  );
}

final ValueNotifier<bool> isAppReady = ValueNotifier<bool>(false);

// ==========================================
// 🚀 GLOBAL ALARM DİNLEYİCİSİ BURAYA TAŞINDI
// ==========================================
class AlarmApp extends ConsumerStatefulWidget {
  const AlarmApp({super.key});

  @override
  ConsumerState<AlarmApp> createState() => _AlarmAppState();
}

class _AddAlarmBottomSheetState {} // Unused but preventing delete

class _AlarmAppState extends ConsumerState<AlarmApp> {
  @override
  void initState() {
    super.initState();
    _setupAlarmListener();
  }

  void _setupAlarmListener() {
    // Dinleyici ekleme fonksiyonunu ayırıyoruz
    void attachStream() {
      Alarm.ringing.listen((alarmSet) {
        final ringAlarm = alarmSet.alarms.firstOrNull;
        if (ringAlarm != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => RingingView(alarmId: ringAlarm.id),
            ),
          );
        }
      });
    }

    // 🔔 UYGULAMA BOYUNCA HAYATTA KALACAK DİNLEYİCİ
    // Uygulama tam açılmadan önce (örn. SplashScreen bitmeden) yönlendirme yapmamak için bekliyoruz.
    if (isAppReady.value) {
      attachStream();
    } else {
      isAppReady.addListener(() {
        if (isAppReady.value) {
          attachStream();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dil değişikliklerini dinle
    ref.watch(localeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Zorlu Alarm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

// ==========================================
// 🚀 ZERO-BLOCKING SPLASH SCREEN
// ==========================================
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // İlk karenin çizilmesi için native motora zaman tanı
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      // 2. FIREBASE BAŞLATMA
      await Firebase.initializeApp();

      // 3. ADMOB BAŞLATMA
      await MobileAds.instance.initialize();

      // 4. BİLDİRİM VE TİMEZONE BAŞLATMA (Çok kritik, aksi halde izinler ve yedek bildirimler çalışmaz)
      await ref.read(alarmServiceProvider).init();

      // 5. BİLDİRİM İZİNLERİNİ İSTE (iOS arka plan alarmları için güvence)
      if (Platform.isIOS) {
        final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }

      // Dil senkronizasyonu
      final storageService = ref.read(localStorageServiceProvider);
      final savedLanguage = storageService.getLanguage();
      ref.read(localeProvider.notifier).setLocaleSync(savedLanguage);

      // Her şey yüklendi, ana ekrana geç.
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeView()),
        );
        isAppReady.value = true;
      }
    } catch (e) {
      debugPrint("Başlatma sırasında hata: $e");
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeView()),
        );
        isAppReady.value = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

