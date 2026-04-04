import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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

  // 1. SADECE EN KRİTİK VERİTABANINI BAŞLAT: (Bloklanmayı önlemek için)
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

class AlarmApp extends ConsumerWidget {
  const AlarmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
// 🚀 ZERO-BLOCKING SPLASH SCREEN EKLENDİ
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

      // 4. ALARM SERVİS BAŞLATMA
      final alarmService = ref.read(alarmServiceProvider);
      await alarmService.init();

      // 5. ALARM DİNLEYİCİ KAYDI
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

      // Dil senkronizasyonu
      final storageService = ref.read(localStorageServiceProvider);
      final savedLanguage = storageService.getLanguage();
      ref.read(localeProvider.notifier).setLocaleSync(savedLanguage);

      // Her şey yüklendi, ana ekrana geç.
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeView()),
        );
      }
    } catch (e) {
      debugPrint("Başlatma sırasında hata: $e");
      // Fallback: Hata olursa bile en azından uygulamaya gir
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
