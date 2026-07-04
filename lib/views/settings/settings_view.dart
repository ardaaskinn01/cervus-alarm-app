import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_localizations.dart';
import '../../core/app_theme.dart';
import '../../services/local_storage_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import '../components/banner_ad_widget.dart';
import '../../services/revenuecat_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class SettingsView extends ConsumerStatefulWidget {

  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> with WidgetsBindingObserver {
  late bool _vibrate;
  late int _puzzleCount;
  late int _mathDifficulty;
  late List<Map<String, dynamic>> _customQuestions;
  late List<Map<String, dynamic>> _customSounds;
  final InAppReview _inAppReview = InAppReview.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final storage = ref.read(localStorageServiceProvider);
    _vibrate = storage.getGlobalVibrate();
    _puzzleCount = storage.getPuzzleQuestionCount();
    _mathDifficulty = storage.getMathDifficulty();
    _customQuestions = storage.getCustomQuestions();
    _customSounds = storage.getCustomSounds();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama durumu değişiklikleri burada izlenebilir
  }

  Future<void> _rateApp() async {
    const String appStoreId = '6761625063';
    try {
      await _inAppReview.openStoreListing(appStoreId: appStoreId);
    } catch (e) {
      debugPrint('Rate app failed: $e');
      final url = Uri.parse(
        Platform.isAndroid
            ? "https://play.google.com/store/apps/details?id=com.cervus.alarmly"
            : "https://apps.apple.com/app/id6761625063",
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
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

  void _showPremiumDialog() {
    final locale = ref.read(localeProvider);
    final isTr = locale == 'tr';
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 60, color: Colors.amber),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.get('premium_popup_title', locale),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildPremiumFeatureRow(Icons.music_note, AppLocalizations.get('premium_popup_feature_1', locale)),
                _buildPremiumFeatureRow(Icons.extension, AppLocalizations.get('premium_popup_feature_2', locale)),
                _buildPremiumFeatureRow(Icons.block, AppLocalizations.get('premium_popup_feature_3', locale)),
                const SizedBox(height: 24),
                
                FutureBuilder<Offerings?>(
                  future: RevenueCatService.getOfferings(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator(color: Colors.amber)),
                      );
                    }

                    if (snapshot.hasError || snapshot.data == null) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppLocalizations.get('premium_load_fail', locale),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      );
                    }

                    final offerings = snapshot.data;
                    final packages = offerings?.current?.availablePackages ?? [];

                    if (packages.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppLocalizations.get('premium_no_packages', locale), 
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                    
                    final monthly = packages.where((p) => p.packageType == PackageType.monthly).firstOrNull ?? 
                                   packages.where((p) => p.identifier.toLowerCase().contains('monthly')).firstOrNull;
                    final yearly = packages.where((p) => p.packageType == PackageType.annual).firstOrNull ?? 
                                  packages.where((p) => p.identifier.toLowerCase().contains('year') || p.identifier.toLowerCase().contains('ann')).firstOrNull;
                    final lifetime = packages.where((p) => p.packageType == PackageType.lifetime).firstOrNull ?? 
                                    packages.where((p) => p.identifier.toLowerCase().contains('life') || p.identifier.toLowerCase().contains('pro')).firstOrNull;

                    return Column(
                      children: [
                        if (monthly != null)
                          _buildSubscriptionCard(
                            ctx,
                            package: monthly,
                            title: AppLocalizations.get('premium_monthly_title', locale),
                            price: monthly.storeProduct.priceString,
                            subtitle: AppLocalizations.get('premium_monthly_subtitle', locale),
                            locale: locale,
                          ),
                        if (yearly != null)
                          _buildSubscriptionCard(
                            ctx,
                            package: yearly,
                            title: AppLocalizations.get('premium_yearly_title', locale),
                            price: yearly.storeProduct.priceString,
                            originalPrice: isTr ? "₺599.99" : "\$35.99",
                            subtitle: AppLocalizations.get('premium_yearly_subtitle', locale),
                            isPopular: true,
                            locale: locale,
                          ),
                        if (lifetime != null)
                          _buildSubscriptionCard(
                            ctx,
                            package: lifetime,
                            title: AppLocalizations.get('premium_lifetime_title', locale),
                            price: lifetime.storeProduct.priceString,
                            subtitle: AppLocalizations.get('premium_lifetime_subtitle', locale),
                            locale: locale,
                          ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 12),
                // Apple-Required Legal Links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => launchUrl(Uri.parse("https://cervusdigital.com/alarmly/privacy-policy/")),
                      child: Text(AppLocalizations.get('premium_privacy', locale), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ),
                    const Text("|", style: TextStyle(color: Colors.white38)),
                    TextButton(
                      onPressed: () => launchUrl(Uri.parse("https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")),
                      child: Text(AppLocalizations.get('premium_terms', locale), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ),
                  ],
                ),
                Text(
                  AppLocalizations.get('premium_auto_renew_desc_full', locale),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
                
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await RevenueCatService.restorePurchases(ref, context);
                  },
                  child: Text(AppLocalizations.get('premium_popup_restore', locale), style: const TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.get('premium_popup_cancel', locale), style: const TextStyle(color: Colors.white54)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext dialogContext, {
    required Package package,
    required String title,
    required String price,
    String? originalPrice,
    required String subtitle,
    required String locale,
    bool isPopular = false,
  }) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(dialogContext);
        await RevenueCatService.purchasePackage(ref, context, package);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isPopular ? Colors.amber.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          border: Border.all(color: isPopular ? Colors.amber : Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            AppLocalizations.get('premium_popular_badge', locale), 
                            style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (originalPrice != null)
                  Text(
                    originalPrice,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  price,
                  style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
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
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.get('math_zero_error', ref.read(localeProvider))), backgroundColor: Colors.red));
                        return;
                      }
                      if (n1 % n2 != 0) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.get('math_remainder_error', ref.read(localeProvider))), backgroundColor: Colors.red));
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

  void _showCustomSoundDialog() {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
       _showPremiumDialog();
       return;
    }
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final locale = ref.read(localeProvider);
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: Text(AppLocalizations.get('custom_sound_title', locale), style: const TextStyle(color: Colors.white)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_customSounds.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(AppLocalizations.get('custom_sound_empty', locale), style: const TextStyle(color: Colors.white54)),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _customSounds.length,
                          itemBuilder: (context, index) {
                            final sound = _customSounds[index];
                            return ListTile(
                              leading: const Icon(Icons.music_note, color: Colors.amber),
                              title: Text(sound['name'] ?? '', style: const TextStyle(color: Colors.white)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                                onPressed: () async {
                                  await ref.read(localStorageServiceProvider).removeCustomSound(index);
                                  setState(() {
                                    _customSounds = ref.read(localStorageServiceProvider).getCustomSounds();
                                  });
                                  setDialogState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.get('custom_sound_add', locale)),
                      onPressed: () async {
                        try {
                          // iOS'ta kitlenme hissini önlemek için çoklu tıklamayı engelleyebiliriz
                          // ve sıkıştırmayı kapatabiliriz (hız kazandırır)
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.audio,
                            allowCompression: false, // iOS'ta işlemi hızlandırır
                          );
                          
                          if (result != null && result.files.single.path != null) {
                            File file = File(result.files.single.path!);
                            String name = result.files.single.name;
                            final directory = await getApplicationDocumentsDirectory();
                            final String newPath = '${directory.path}/$name';
                            await file.copy(newPath);
                            await ref.read(localStorageServiceProvider).addCustomSound(name, newPath);
                            setState(() {
                              _customSounds = ref.read(localStorageServiceProvider).getCustomSounds();
                            });
                            setDialogState(() {});
                          }
                        } catch (e) {
                          debugPrint("Hata: $e");
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.get('custom_sound_close', locale), style: const TextStyle(color: Colors.white54)),
                )
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
    final isPremium = ref.watch(isPremiumProvider);

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
              
              if (!isPremium)
                _buildGoldenProTile(
                  title: AppLocalizations.get('settings_premium_title', locale),
                  subtitle: AppLocalizations.get('settings_premium_subtitle', locale),
                  onTap: _showPremiumDialog,
                )
              else
                _buildSettingTile(
                  icon: Icons.star_rounded,
                  title: 'Alarmly Pro',
                  subtitle: AppLocalizations.get('settings_premium_active', locale),
                  iconColor: Colors.amber,
                  trailing: const Icon(Icons.check_circle_rounded, color: Colors.amber),
                ),
              _buildSettingTile(
                icon: Icons.queue_music_rounded,
                title: AppLocalizations.get('custom_sound_title', locale),
                subtitle: AppLocalizations.get('custom_sound_subtitle', locale),
                iconColor: AppTheme.primaryColor,
                onTap: _showCustomSoundDialog,
                trailing: !isPremium ? const Icon(Icons.lock, color: Colors.amber, size: 20) : null,
              ),
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
                icon: Icons.speed_rounded,
                title: AppLocalizations.get('settings_math_difficulty_title', locale),
                subtitle: AppLocalizations.get('settings_math_difficulty_subtitle', locale),
                iconColor: Colors.orangeAccent,
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _mathDifficulty,
                    dropdownColor: AppTheme.cardColor,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    onChanged: (int? newValue) async {
                      if (newValue != null) {
                        setState(() => _mathDifficulty = newValue);
                        await ref.read(localStorageServiceProvider).setMathDifficulty(newValue);
                      }
                    },
                    items: [
                      DropdownMenuItem(value: 1, child: Text(AppLocalizations.get('difficulty_easy', locale))),
                      DropdownMenuItem(value: 2, child: Text(AppLocalizations.get('difficulty_medium', locale))),
                      DropdownMenuItem(value: 3, child: Text(AppLocalizations.get('difficulty_hard', locale))),
                    ],
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
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(AppLocalizations.get('settings_no_custom_q', locale), style: const TextStyle(color: Colors.white54)),
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
                onTap: _rateApp,
              ),
              _buildSettingTile(
                icon: Icons.language_outlined,
                title: AppLocalizations.get('settings_language_title', locale),
                subtitle: AppLocalizations.get('settings_language_subtitle', locale),
                iconColor: Colors.blueAccent,
                onTap: _toggleLanguage,
              ),
              _buildSettingTile(
                icon: Icons.apps_rounded,
                title: AppLocalizations.get('settings_more_apps_title', locale),
                subtitle: AppLocalizations.get('settings_more_apps_subtitle', locale),
                iconColor: Colors.deepPurpleAccent,
                onTap: () async {
                  final url = Uri.parse(
                    Platform.isAndroid
                        ? "https://play.google.com/store/apps/developer?id=Cervus+App+Studio"
                        : "https://apps.apple.com/tr/developer/cervus-digital/id1889669486",
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
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
      bottomNavigationBar: const SafeArea(child: BannerAdWidget(type: BannerType.settings)),
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

  Widget _buildGoldenProTile({
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade400,
            Colors.amber.shade700,
            Colors.orange.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle ?? '',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

