import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_localizations.dart';
import '../../core/app_theme.dart';
import '../../services/local_storage_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/banner_ad_widget.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  late bool _vibrate;
  late int _puzzleCount;
  late List<Map<String, dynamic>> _customQuestions;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(localStorageServiceProvider);
    _vibrate = storage.getGlobalVibrate();
    _puzzleCount = storage.getPuzzleQuestionCount();
    _customQuestions = storage.getCustomQuestions();
  }

  void _toggleVibrate(bool value) async {
    setState(() => _vibrate = value);
    await ref.read(localStorageServiceProvider).setGlobalVibrate(value);
  }

  void _toggleLanguage() {
    final current = ref.read(localeProvider);
    final newLang = current == 'tr' ? 'en' : 'tr';
    ref.read(localeProvider.notifier).setLocale(newLang);
  }

  void _showCustomQuestionDialog() {
    final locale = ref.read(localeProvider);
    final num1Controller = TextEditingController();
    final num2Controller = TextEditingController();
    String selectedOperator = '+';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: Text(AppLocalizations.get('custom_q_add_title', locale), style: const TextStyle(color: Colors.white)),
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: TextField(
                      controller: num1Controller,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: '0',
                        filled: true,
                        fillColor: Colors.white12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedOperator,
                    dropdownColor: AppTheme.cardColor,
                    items: ['+', '-', '*', '/'].map((String val) {
                      return DropdownMenuItem<String>(
                        value: val,
                        child: Text(val, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedOperator = val);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: num2Controller,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: '0',
                        filled: true,
                        fillColor: Colors.white12,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.get('custom_q_cancel', locale), style: const TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () async {
                    final n1 = int.tryParse(num1Controller.text.trim());
                    final n2 = int.tryParse(num2Controller.text.trim());
                    if (n1 == null || n2 == null) return;

                    if (selectedOperator == '/') {
                      if (n2 == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sıfıra bölünemez! / Cannot divide by zero'), backgroundColor: Colors.red));
                        return;
                      }
                      if (n1 % n2 != 0) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tam bölünmüyor! Lütfen kalansız bölünecek sayılar girin. (Örn: 10 / 2)'), backgroundColor: Colors.red));
                        return;
                      }
                    }

                    int answer;
                    switch (selectedOperator) {
                      case '+': answer = n1 + n2; break;
                      case '-': answer = n1 - n2; break;
                      case '*': answer = n1 * n2; break;
                      case '/': answer = n1 ~/ n2; break;
                      default: answer = n1 + n2;
                    }
                    String question = "$n1 $selectedOperator $n2";

                    await ref.read(localStorageServiceProvider).addCustomQuestion(question, answer);
                    setState(() {
                      _customQuestions = ref.read(localStorageServiceProvider).getCustomQuestions();
                    });
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: Text(AppLocalizations.get('custom_q_save', locale), style: const TextStyle(color: AppTheme.primaryColor)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.get('settings_title', locale), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.gradientEndColor,
              AppTheme.backgroundColor,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              const SizedBox(height: 10),
              _buildSettingTile(
                icon: Icons.vibration,
                title: AppLocalizations.get('settings_vibration_title', locale),
                subtitle: AppLocalizations.get('settings_vibration_subtitle', locale),
                trailing: Switch(
                  value: _vibrate,
                  activeColor: AppTheme.primaryColor,
                  onChanged: _toggleVibrate,
                ),
              ),
              _buildSettingTile(
                icon: Icons.calculate_outlined,
                title: AppLocalizations.get('settings_puzzle_count_title', locale),
                subtitle: AppLocalizations.get('settings_puzzle_count_subtitle', locale),
                iconColor: AppTheme.secondaryColor,
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _puzzleCount,
                    dropdownColor: AppTheme.cardColor,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    onChanged: (int? newValue) async {
                      if (newValue != null) {
                        setState(() => _puzzleCount = newValue);
                        await ref.read(localStorageServiceProvider).setPuzzleQuestionCount(newValue);
                      }
                    },
                    items: List.generate(10, (index) => index + 1).map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                  ),
                ),
              ),
              _buildSettingTile(
                icon: Icons.edit_note_rounded,
                title: AppLocalizations.get('settings_custom_q_title', locale),
                subtitle: AppLocalizations.get('settings_custom_q_subtitle', locale) + " (${_customQuestions.length})",
                iconColor: AppTheme.primaryColor,
                onTap: () {
                  // Show bottom sheet to manage existing Custom Questions + Add button
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppTheme.cardColor,
                    builder: (ctx) => StatefulBuilder(
                      builder: (BuildContext context, StateSetter setSheetState) {
                        return Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(AppLocalizations.get('settings_custom_q_title', locale), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              if (_customQuestions.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text("Henüz özel soru yok / No custom questions", style: TextStyle(color: Colors.white54)),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _customQuestions.length,
                                  itemBuilder: (ctx, idx) {
                                    final q = _customQuestions[idx];
                                    return ListTile(
                                      title: Text(q['q'].toString(), style: const TextStyle(color: Colors.white)),
                                      subtitle: Text('= ${q['a']}', style: const TextStyle(color: Colors.white54)),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () async {
                                          await ref.read(localStorageServiceProvider).removeCustomQuestion(idx);
                                          setState(() => _customQuestions = ref.read(localStorageServiceProvider).getCustomQuestions());
                                          setSheetState(() {});
                                        },
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showCustomQuestionDialog();
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                                child: Text(AppLocalizations.get('custom_q_add_title', locale), style: const TextStyle(color: Colors.white)),
                              )
                            ],
                          ),
                        );
                      }
                    ),
                  );
                },
              ),
              _buildSettingTile(
                icon: Icons.star_outline_rounded,
                title: AppLocalizations.get('settings_rate_title', locale),
                subtitle: AppLocalizations.get('settings_rate_subtitle', locale),
                iconColor: Colors.amber,
                onTap: () async {
                  final url = Uri.parse(
                    Platform.isAndroid
                        ? "https://play.google.com/store/apps/details?id=com.cervus.alarmly"
                        : "https://apps.apple.com/tr/app/alarmly-wake-force-alarm/id6761625063",
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              _buildSettingTile(
                icon: Icons.language_outlined,
                title: AppLocalizations.get('settings_language_title', locale),
                subtitle: AppLocalizations.get('settings_language_subtitle', locale),
                iconColor: Colors.blueAccent,
                onTap: _toggleLanguage,
              ),
              _buildSettingTile(
                icon: Icons.shield_outlined,
                title: AppLocalizations.get('settings_privacy_title', locale),
                subtitle: AppLocalizations.get('settings_privacy_subtitle', locale),
                iconColor: Colors.greenAccent,
                onTap: () async {
                  final url = Uri.parse("https://cervusdigital.com/alarmly/privacy-policy/");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              const SizedBox(height: 60),
          ],
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color iconColor = Colors.white70,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing else Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.2), size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
