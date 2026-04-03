import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'views/home/home_view.dart';
import 'views/ringing/ringing_view.dart';
import 'core/app_theme.dart';
import 'services/local_storage_service.dart';
import 'services/alarm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/app_localizations.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: AlarmApp(),
    ),
  );
}

class AlarmApp extends ConsumerWidget {
  const AlarmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Cervus Alarm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

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
    // İlk karenin çizildiğinden emin olmak için çok kısa bir bekleme
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // 1. Firebase (Options ile ve Timeout ekli)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 8));

      // 2. Local Storage (Hive)
      final storageService = ref.read(localStorageServiceProvider);
      await storageService.init().timeout(const Duration(seconds: 5));

      // 3. Alarm Service
      final alarmService = ref.read(alarmServiceProvider);
      await alarmService.init().timeout(const Duration(seconds: 5));

      // 4. AdMob (Async)
      MobileAds.instance.initialize();

      // 5. Alarm Dinleyicisi
      Alarm.ringing.listen((alarmSet) {
        final ringAlarm = alarmSet.alarms.firstOrNull;
        if (ringAlarm != null && mounted) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => RingingView(alarmId: ringAlarm.id),
            ),
          );
        }
      });

      // Her şey hazır!
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeView()),
        );
      }
    } catch (e) {
      debugPrint("⚠️ Başlatma sırasında bir sorun çıktı: $e");
      // Hata olsa bile ana sayfaya düşür ki beyaz ekran kalmasın
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeView()),
        );
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
