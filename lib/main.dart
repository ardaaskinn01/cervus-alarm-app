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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final storageService = LocalStorageService();
  await storageService.init();

  final alarmService = AlarmService(storageService);
  await alarmService.init();

  await MobileAds.instance.initialize();

  // Dinleyici: Eğer alarm çalarsa Ringing ekranına atar.
  Alarm.ringing.listen((alarmSet) {
    // AlarmSet birden fazla alarm içerebilir, ilkini kullanıyoruz.
    final ringAlarm = alarmSet.alarms.firstOrNull;
    if (ringAlarm != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => RingingView(alarmId: ringAlarm.id),
        ),
      );
    }
  });

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storageService),
        alarmServiceProvider.overrideWithValue(alarmService),
      ],
      child: const AlarmApp(),
    ),
  );
}

class AlarmApp extends ConsumerWidget {
  const AlarmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Uygulamanın dil değişikliğini dinlemesi için (böylece tüm widget ağacı rebuild edilir)
    ref.watch(localeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Zorlu Alarm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeView(),
    );
  }
}
