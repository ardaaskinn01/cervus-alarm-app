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
    try {
      // 1. Firebase (Max 5 saniye bekletiyoruz)
      await Firebase.initializeApp().timeout(const Duration(seconds: 5));

      // 2. Local Storage (Hive)
      final storageService = ref.read(localStorageServiceProvider);
      await storageService.init();

      // 3. Alarm Service
      final alarmService = ref.read(alarmServiceProvider);
      await alarmService.init();

      // 4. AdMob (Hızlı geçmesi için async bırakıyoruz)
      MobileAds.instance.initialize();

      // 5. Alarm Dinleyicisi
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

      // Her şey tamam! Ana sayfaya geçiyoruz.
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeView()),
        );
      }
    } catch (e) {
      debugPrint("Kritik Başlatma Hatası: $e");
      // Hata olsa bile kullanıcıyı ana sayfaya gönderelim ki beyaz ekranda kalmasın
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
