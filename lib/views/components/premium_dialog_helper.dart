import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/models/offering_wrapper.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_localizations.dart';
import '../../core/app_theme.dart';
import '../../services/revenuecat_service.dart';

class PremiumDialogHelper {
  static void show(BuildContext context, WidgetRef ref) {
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
                _buildFeatureRow(Icons.music_note, AppLocalizations.get('premium_popup_feature_1', locale)),
                _buildFeatureRow(Icons.extension, AppLocalizations.get('premium_popup_feature_2', locale)),
                _buildFeatureRow(Icons.block, AppLocalizations.get('premium_popup_feature_3', locale)),
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
                          isTr ? "Paketler yüklenemedi." : "Offerings could not be loaded.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      );
                    }

                    final packages = snapshot.data?.current?.availablePackages ?? [];
                    if (packages.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(isTr ? "Paket bulunamadı." : "No packages found.", style: const TextStyle(color: Colors.white70)),
                      );
                    }
                    
                    // Priority sorting or standard listing
                    return Column(
                      children: packages.map((pkg) => _buildSubscriptionCard(
                        context,
                        ref,
                        ctx,
                        package: pkg,
                        isTr: isTr,
                      )).toList(),
                    );
                  },
                ),
                
                const SizedBox(height: 12),
                _buildLegalLinks(isTr),
                
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

  static Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14))),
        ],
      ),
    );
  }

  static Widget _buildSubscriptionCard(BuildContext originalContext, WidgetRef ref, BuildContext dialogContext, {required Package package, required bool isTr}) {
    final title = package.packageType == PackageType.monthly ? (isTr ? "Aylık" : "Monthly") : 
                  (package.packageType == PackageType.annual ? (isTr ? "Yıllık" : "Annual") : 
                  (isTr ? "Ömür Boyu" : "Lifetime"));
    
    final isPopular = package.packageType == PackageType.annual;

    return GestureDetector(
      onTap: () async {
        Navigator.pop(dialogContext);
        await RevenueCatService.purchasePackage(ref, originalContext, package);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPopular ? Colors.amber.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          border: Border.all(color: isPopular ? Colors.amber : Colors.white12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                if (isPopular) Text(isTr ? "EN POPÜLER" : "MOST POPULAR", style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900)),
              ],
            ),
            Text(package.storeProduct.priceString, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  static Widget _buildLegalLinks(bool isTr) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => launchUrl(Uri.parse("https://cervusdigital.com/alarmly/privacy-policy/")),
              child: Text(isTr ? "Gizlilik" : "Privacy", style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ),
            const Text("|", style: TextStyle(color: Colors.white38)),
            TextButton(
              onPressed: () => launchUrl(Uri.parse("https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")),
              child: Text(isTr ? "Koşullar" : "Terms", style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ),
          ],
        ),
        Text(
          isTr ? "Abonelikler otomatik yenilenir." : "Subscriptions renew automatically.",
          style: const TextStyle(color: Colors.white24, fontSize: 10),
        ),
      ],
    );
  }
}
