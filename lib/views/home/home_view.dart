import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../models/alarm_model.dart';
import '../../viewmodels/home_viewmodel.dart';
import 'add_alarm_bottom_sheet.dart';
import '../settings/settings_view.dart';
import '../../core/app_localizations.dart';

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
      body: alarms.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.wb_twilight_rounded,
                        size: 100, color: AppTheme.secondaryColor.withOpacity(0.8)),
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
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
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
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAlarmSheet(context),
        backgroundColor: AppTheme.secondaryColor,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: alarm.isActive ? Colors.white : Colors.white54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDays(alarm.repeatDays),
                  style: TextStyle(
                    fontSize: 14,
                    color: alarm.isActive ? AppTheme.secondaryColor : Colors.white38,
                    fontWeight: FontWeight.w600,
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
    );
  }
}
