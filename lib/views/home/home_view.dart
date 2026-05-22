import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../models/alarm_model.dart';
import '../../viewmodels/home_viewmodel.dart';
import 'add_alarm_bottom_sheet.dart';
import '../settings/settings_view.dart';
import '../../core/app_localizations.dart';
import '../components/banner_ad_widget.dart';
import '../../services/dashboard_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/alarm_kit_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  @override
  void initState() {
    super.initState();
    _initBackgroundTasks();
  }

  Future<void> _initBackgroundTasks() async {
    // Splash ekranını hızlandırmak için buraya taşınan işlemler
    try {
      final storageService = ref.read(localStorageServiceProvider);
      final String installationId = await storageService.getInstallationId();
      
      // Dashboard & Log (Hata fırlatmadan arka planda çalışsın)
      DashboardService().init(installationId).then((_) {
        DashboardService().logVisit();
      }).catchError((e) => debugPrint("Dashboard init error: $e"));

      // Versiyon Kontrolü
      _checkForUpdate();

      // Android Spesifik İzinler (Pil Tasarrufu ve Kesin Saat Ayarı)
      if (Platform.isAndroid) {
        AlarmKitService.requestIgnoreBatteryOptimizations();
        final hasExactAlarm = await AlarmKitService.checkExactAlarmPermission();
        if (!hasExactAlarm && mounted) {
           _showExactAlarmDialog();
        }
      }
    } catch (e) {
      debugPrint("Background tasks error: $e");
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final config = await DashboardService().getVersionConfig();
      if (config == null) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final int currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      final int latestBuild = int.tryParse(config['buildNumber']?.toString() ?? "") ?? currentBuild;

      if (latestBuild > currentBuild) {
        if (!mounted) return;
        _showUpdateDialog(
          config['androidUrl']?.toString() ?? "https://play.google.com/store/apps/details?id=com.cervus.alarmly",
          config['iosUrl']?.toString() ?? "https://apps.apple.com/app/id6761625063",
        );
      }
    } catch (e) {
      debugPrint("Update check error: $e");
    }
  }

  void _showExactAlarmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Kesin Alarm İzni", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "Alarmların tam zamanında çalabilmesi için 'Kesin Alarm' izni gereklidir. Lütfen ayarlardan bu izni verin.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Daha Sonra", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () {
              Navigator.pop(ctx);
              AlarmKitService.openExactAlarmSettings();
            },
            child: const Text("Ayarlara Git", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(String androidUrl, String iosUrl) {
    final locale = ref.read(localeProvider);
    final isTr = locale == 'tr';

    showDialog(
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

  void _showAddAlarmSheet(BuildContext context, {AlarmModel? existingAlarm}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAlarmBottomSheet(existingAlarm: existingAlarm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alarms = ref.watch(homeViewModelProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.get('home_title', locale)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsView()),
              );
            },
          )
        ],
      ),
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
              AppTheme.backgroundColor,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: alarms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppTheme.primaryColor.withOpacity(0.2), blurRadius: 40, spreadRadius: 10),
                          ],
                        ),
                        child: Icon(Icons.wb_twilight_rounded,
                            size: 100, color: AppTheme.secondaryColor.withOpacity(0.9)),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        AppLocalizations.get('home_empty_title', locale),
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.get('home_empty_subtitle', locale),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white54,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alarms.length,
                  itemBuilder: (context, index) {
                    final alarm = alarms[index];
                    final timeStr =
                        '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Dismissible(
                        key: Key(alarm.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
                        ),
                        onDismissed: (direction) {
                          ref.read(homeViewModelProvider.notifier).deleteAlarm(alarm.id);
                        },
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => _showAddAlarmSheet(context, existingAlarm: alarm),
                          onLongPress: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppTheme.cardColor,
                                title: Text(AppLocalizations.get('home_delete_title', locale), style: const TextStyle(color: Colors.white)),
                                content: Text(AppLocalizations.get('home_delete_content', locale), style: const TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(AppLocalizations.get('home_delete_cancel', locale), style: const TextStyle(color: Colors.white54)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ref.read(homeViewModelProvider.notifier).deleteAlarm(alarm.id);
                                      Navigator.pop(ctx);
                                    },
                                    child: Text(AppLocalizations.get('home_delete_confirm', locale), style: const TextStyle(color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: AlarmCard(alarm: alarm, timeStr: timeStr, locale: locale),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: FloatingActionButton(
            onPressed: () => _showAddAlarmSheet(context),
            backgroundColor: AppTheme.secondaryColor,
            child: const Icon(Icons.add, size: 32, color: Colors.white),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        bottomNavigationBar: const SafeArea(child: BannerAdWidget(type: BannerType.home)),
      );
    }
  }

class AlarmCard extends ConsumerWidget {
  final AlarmModel alarm;
  final String timeStr;
  final String locale;

  const AlarmCard({
    Key? key,
    required this.alarm,
    required this.timeStr,
    required this.locale,
  }) : super(key: key);

  String _formatDays(List<int> days) {
    if (days.isEmpty) return AppLocalizations.get('home_card_once', locale);
    if (days.length == 7) return AppLocalizations.get('home_card_everyday', locale);
    
    return days.map((d) => AppLocalizations.get('day_${d-1}', locale)).join(', ');
  }

  String _getTimeUntil() {
    final now = DateTime.now();
    DateTime alarmTime = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
    
    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }
    
    final diff = alarmTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    
    if (locale == 'tr') {
      return '$hours sa $minutes dk sonra çalacak';
    }
    return 'Rings in $hours h $minutes m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isActive = alarm.isActive;
    
    // Pasif durum için şık bir lacivert/mor tonu
    final Color cardBg = isActive 
        ? Colors.white.withOpacity(0.08) 
        : const Color(0xFF1E1E2E).withOpacity(0.4);
    
    final Color borderColor = isActive 
        ? AppTheme.primaryColor.withOpacity(0.5) 
        : Colors.white.withOpacity(0.05);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cardBg,
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (alarm.label.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              alarm.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                color: isActive ? AppTheme.secondaryColor : Colors.white30,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: isActive ? Colors.white : Colors.white24,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: CupertinoSwitch(
                      value: isActive,
                      activeColor: AppTheme.primaryColor,
                      trackColor: Colors.white.withOpacity(0.08),
                      onChanged: (val) {
                        ref.read(homeViewModelProvider.notifier).toggleAlarm(alarm, val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDays(alarm.repeatDays),
                          style: TextStyle(
                            fontSize: 13,
                            color: isActive ? Colors.white60 : Colors.white24,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (isActive)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              _getTimeUntil(),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryColor.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Icon(
                      alarm.stopMethod == 'math' ? Icons.calculate_outlined : Icons.extension_outlined,
                      size: 18,
                      color: Colors.white24,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
