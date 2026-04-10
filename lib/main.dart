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
      title: 'Alarmly - Uyandıran Alarm',
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
    final startTime = DateTime.now();
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      // 1. ALARM + BİLDİRİM + TIMEZONE (Hepsini EN ÖNCE başlat — izin sorulmadan firebase beklememeli)
      await ref.read(alarmServiceProvider).init();

      // 2. BİLDİRİM İZNİNİ EKRANA GETİR
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      bool? permissionGranted;

      if (Platform.isIOS) {
        permissionGranted = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      } else if (Platform.isAndroid) {
        permissionGranted = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      // 3. İZİN VERİLMEDİYSE AYARLAR'A YÖNLENDİR
      if (permissionGranted == false && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Row(
              children: [
                Icon(Icons.notifications_off_rounded, color: Color(0xFFF59E0B)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bildirim İzni Gerekli',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Alarmların çalabilmesi için bildirim iznine ihtiyaç var.\n\nLütfen Ayarlar\'dan bildirimlere izin verin.',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Şimdi Değil', style: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  // Kullanıcıya ayarlara nasıl gideceğini göster
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Ayarlar > Bildirimler > Alarmly yolunu izleyin ve bildirimleri açın.',
                          style: TextStyle(fontSize: 13),
                        ),
                        backgroundColor: Color(0xFF1E3A8A),
                        duration: Duration(seconds: 6),
                      ),
                    );
                  }
                },
                child: const Text('Ayarları Aç', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }

      // 4. FIREBASE VE ADMOB (Arka planda, bloklamadan)
      Firebase.initializeApp().catchError((e) => debugPrint("Firebase: $e"));
      MobileAds.instance.initialize().catchError((e) => debugPrint("AdMob: $e"));

      // 5. DİL SENKRONIZASYONU
      final storageService = ref.read(localStorageServiceProvider);
      final savedLanguage = storageService.getLanguage();
      ref.read(localeProvider.notifier).setLocaleSync(savedLanguage);

      // 6. MİNİMUM SPLASH SÜRESİNİ TAMAMLA
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime.inMilliseconds < 2500) {
        await Future.delayed(Duration(milliseconds: 2500 - elapsedTime.inMilliseconds));
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeView()),
        );
        isAppReady.value = true;
      }
    } catch (e) {
      debugPrint("Başlatma hatası: $e");
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/images/Alarmly.PNG',
                width: 140,
                height: 140,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Alarmly - Uyandıran Alarm',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Developed by Cervus Team',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}

