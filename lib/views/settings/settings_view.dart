import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../services/local_storage_service.dart';
import '../../core/app_localizations.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  late bool _vibrate;

  @override
  void initState() {
    super.initState();
    _vibrate = ref.read(localStorageServiceProvider).getGlobalVibrate();
  }

  void _toggleVibrate(bool value) async {
    setState(() => _vibrate = value);
    await ref.read(localStorageServiceProvider).setGlobalVibrate(value);
  }

  void _toggleLanguage() {
    // Dil sistemi tamamen söküldü
  }

  @override
  Widget build(BuildContext context) {
    final locale = 'tr'; // localeProvider kaldırıldı

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
              Color(0xff130e39),
              Color(0xff110732),
              Color(0xff1b0122),
            ],
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
                icon: Icons.star_outline_rounded,
                title: AppLocalizations.get('settings_rate_title', locale),
                subtitle: AppLocalizations.get('settings_rate_subtitle', locale),
                iconColor: Colors.amber,
                onTap: () {},
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
                onTap: () {},
              ),
              const SizedBox(height: 60),
              
              const Center(
                child: Text(
                  'Created by Cervus Team',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(0, 8),
            blurRadius: 15,
          ),
        ],
      ),
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
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
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
    );
  }
}
