import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../models/alarm_model.dart';
import '../../viewmodels/home_viewmodel.dart';
import 'add_alarm_bottom_sheet.dart';
import '../settings/settings_view.dart';
import '../../core/app_localizations.dart';
import '../components/banner_ad_widget.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  void _showAddAlarmSheet(BuildContext context, {AlarmModel? existingAlarm}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAlarmBottomSheet(existingAlarm: existingAlarm),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
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

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      return Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withOpacity(alarm.isActive ? 0.05 : 0.02),
          border: Border.all(color: Colors.white.withOpacity(alarm.isActive ? 0.15 : 0.05), width: 1.5),
          boxShadow: alarm.isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 25,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (alarm.label.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text(
                          alarm.label,
                          style: TextStyle(
                            fontSize: 15,
                            color: alarm.isActive ? Colors.white70 : Colors.white30,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: alarm.isActive ? Colors.white : Colors.white24,
                        shadows: alarm.isActive ? [
                          Shadow(color: Colors.white.withOpacity(0.3), blurRadius: 10)
                        ] : [],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDays(alarm.repeatDays),
                      style: TextStyle(
                        fontSize: 14,
                        color: alarm.isActive ? AppTheme.secondaryColor : Colors.white24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: alarm.isActive,
                  onChanged: (val) {
                    ref.read(homeViewModelProvider.notifier).toggleAlarm(alarm, val);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
