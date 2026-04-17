import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../services/local_storage_service.dart';
import '../home/home_view.dart';

class InitialSetupView extends ConsumerStatefulWidget {
  const InitialSetupView({super.key});

  @override
  ConsumerState<InitialSetupView> createState() => _InitialSetupViewState();
}

class _InitialSetupViewState extends ConsumerState<InitialSetupView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLanguageSelection();
    });
  }

  void _showLanguageSelection() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Select Language\nDil Seçimi',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(ctx, 'English', 'en'),
            const SizedBox(height: 12),
            _buildLanguageOption(ctx, 'Türkçe', 'tr'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext ctx, String label, String langCode) {
    return InkWell(
      onTap: () async {
        await ref.read(localeProvider.notifier).setLocale(langCode);
        Navigator.pop(ctx);
        _showPrivacyPolicy(langCode);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy(String langCode) {
    final prefix = langCode == 'tr' ? 'Devam etmek için lütfen ' : 'To continue, please read and accept our ';
    final linkText = langCode == 'tr' ? 'Gizlilik Politikası' : 'Privacy Policy';
    final suffix = langCode == 'tr' ? "'nı okuyun ve onaylayın." : '.';
    final acceptBtn = langCode == 'tr' ? 'Kabul Ediyorum' : 'I Accept';
    final title = langCode == 'tr' ? 'Gizlilik Onayı' : 'Privacy Policy Consent';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            children: [
              TextSpan(text: prefix),
              TextSpan(
                text: linkText,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    final url = Uri.parse("https://cervusdigital.com/alarmly/privacy-policy/");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
              ),
              TextSpan(text: suffix),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await ref.read(localStorageServiceProvider).setPrivacyPolicyAccepted(true);
              Navigator.pop(ctx);
              _finishSetup();
            },
            child: Text(
              acceptBtn,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  void _finishSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Hero(
          tag: 'app_logo',
          child: Image.asset(
            'assets/images/Alarmly.PNG',
            width: 140,
            height: 140,
          ),
        ),
      ),
    );
  }
}
