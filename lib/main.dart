import 'package:alarm/alarm.dart';
import 'package:cervusalarm/viewmodels/home_viewmodel.dart';
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
import 'views/onboarding/initial_setup_view.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'services/revenuecat_service.dart';
import 'services/dashboard_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'core/navigator_key.dart';

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

class _AlarmAppState extends ConsumerState<AlarmApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAlarmListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Uygulama ön plana geldiğinde (arka planda çalmış bitmiş) stale alarmları temizle
      ref.read(homeViewModelProvider.notifier).checkStaleAlarms();
    }
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

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeApp();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();
    // ... rest of the method logic remains the same ...
    final storageService = ref.read(localStorageServiceProvider);
    final locale = storageService.getLanguage();

    try {
      await ref.read(alarmServiceProvider).init();
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      
      void onNotificationTap(NotificationResponse response) {
        if (response.payload != null) {
          final int? alarmId = int.tryParse(response.payload!);
          if (alarmId != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (context) => RingingView(alarmId: alarmId)),
            );
          }
        }
      }

      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/launcher_icon'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: onNotificationTap,
      );

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

      if (permissionGranted == false && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Row(
              children: [
                const Icon(Icons.notifications_off_rounded, color: Color(0xFFF59E0B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.get('battery_dialog_title', locale),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              AppLocalizations.get('battery_dialog_content', locale),
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.get('battery_dialog_now_not', locale), style: const TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.get('battery_snack_bar', locale),
                          style: const TextStyle(fontSize: 13),
                        ),
                        backgroundColor: const Color(0xFF1E3A8A),
                        duration: const Duration(seconds: 6),
                      ),
                    );
                  }
                },
                child: Text(AppLocalizations.get('battery_dialog_open_settings', locale), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }

      await Firebase.initializeApp().catchError((e) => debugPrint("Firebase: $e"));
      await RevenueCatService.init(ref);

      if (Platform.isIOS) {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      }

      final String installationId = await storageService.getInstallationId();
      await DashboardService().init(installationId);
      
      if (Platform.isIOS) {
        await DashboardService().logVisit();
      } else {
        DashboardService().logVisit();
      }
      
      await MobileAds.instance.initialize();
      ref.read(localeProvider.notifier).setLocaleSync(storageService.getLanguage());

      // 🎯 MİNİMUM SPLASH SÜRESİNİ 3.5 SANİYEYE ÇIKARDIK
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime.inMilliseconds < 3500) {
        await Future.delayed(Duration(milliseconds: 3500 - elapsedTime.inMilliseconds));
      }

      bool isPrivacyAccepted = storageService.getPrivacyPolicyAccepted();
      Widget nextView = isPrivacyAccepted ? const HomeView() : const InitialSetupView();
      final NotificationAppLaunchDetails? launchDetails = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null) {
          final int? alarmId = int.tryParse(payload);
          if (alarmId != null) nextView = RingingView(alarmId: alarmId);
        }
      }

      await _checkForUpdate();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => nextView),
        );
        isAppReady.value = true;
      }
    } catch (e) {
      debugPrint("Başlatma hatası: $e");
      if (mounted) {
        bool isPrivacyAccepted = ref.read(localStorageServiceProvider).getPrivacyPolicyAccepted();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => isPrivacyAccepted ? const HomeView() : const InitialSetupView()),
        );
        isAppReady.value = true;
      }
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final config = await DashboardService().getVersionConfig();
      if (config == null) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final int currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      final int latestBuild = int.tryParse(config['buildNumber']?.toString() ?? "") ?? currentBuild;

      debugPrint("🔍 Version Check: Device=$currentBuild, Market=$latestBuild");

      if (latestBuild > currentBuild) {
        if (!mounted) return;
        await _showUpdateDialog(
          config['androidUrl']?.toString() ?? "https://play.google.com/store/apps/details?id=com.cervus.alarmly",
          config['iosUrl']?.toString() ?? "https://apps.apple.com/app/id6761625063",
        );
      }
    } catch (e) {
      debugPrint("Versiyon kontrol hatası: $e");
    }
  }

  Future<void> _showUpdateDialog(String androidUrl, String iosUrl) async {
    final locale = ref.read(localeProvider);
    final isTr = locale == 'tr';

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isTr ? "Güncelleme Mevcut" : "Update Available",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isTr 
            ? "Uygulamanın yeni bir sürümü mevcut. En iyi deneyim için lütfen güncelleyin." 
            : "A new version of the app is available. Please update for the best experience.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isTr ? "Şimdi Değil" : "Not Now",
              style: const TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final url = Uri.parse(Platform.isAndroid ? androidUrl : iosUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(
              isTr ? "Güncelle" : "Update",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final isTr = locale == 'tr';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.gradientEndColor,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/Alarmly.PNG',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Alarmly',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'UYANDIRAN ALARM',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 4.0,
              ),
            ),
            const Spacer(),
            const CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 2,
            ),
            const SizedBox(height: 48),
            Text(
              isTr ? 'Uyandıran Alarm Uygulaması' : 'Wakes You Up Every Morning',
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

