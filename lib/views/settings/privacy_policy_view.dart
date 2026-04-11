import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrivacyPolicyView extends ConsumerWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isTr = locale == 'tr';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.get('settings_privacy_title', locale)),
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
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTr ? "Gizlilik Politikası" : "Privacy Policy",
                    style: const TextStyle(
                      color: AppTheme.secondaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isTr ? _policyTr : _policyEn,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),
                  const Text(
                    "Contact / İletişim:",
                    style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "alarmly@cervusdigital.com",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const String _policyEn = """
Alarmly respects your privacy.

We do not collect, store, or share any personal data without your consent.
The app may request access to certain device features (such as notifications or alarms) strictly to provide its core functionality.

All data remains on your device unless explicitly stated.
We do not sell, rent, or share your personal information with third parties.
  """;

  static const String _policyTr = """
Alarmly gizliliğinize saygı duyar.

Açık izniniz olmadan hiçbir kişisel veriniz toplanmaz, saklanmaz veya paylaşılmaz.
Uygulama, yalnızca temel işlevlerini yerine getirmek için bazı cihaz özelliklerine (bildirimler, alarmlar vb.) erişim isteyebilir.

Tüm veriler, aksi belirtilmedikçe cihazınızda kalır.
Kişisel verileriniz üçüncü taraflarla paylaşılmaz veya satılmaz.
  """;
}
