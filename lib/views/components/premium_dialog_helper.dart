import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_localizations.dart';
import '../../core/app_theme.dart';
import '../../services/revenuecat_service.dart';

class PremiumDialogHelper {
  static void show(BuildContext context, WidgetRef ref) {
    final locale = ref.read(localeProvider);
    
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.amber, Colors.orangeAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Text(
                    AppLocalizations.get('premium_trial_banner', locale),
                    style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.extrabold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
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
                          AppLocalizations.get('premium_load_fail', locale),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      );
                    }

                    final packages = snapshot.data?.current?.availablePackages ?? [];
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
                            context,
                            ref,
                            ctx,
                            package: monthly,
                            title: AppLocalizations.get('premium_monthly_title', locale),
                            subtitle: AppLocalizations.get('premium_monthly_subtitle', locale),
                            locale: locale,
                            isTrial: true,
                          ),
                        if (yearly != null)
                          _buildSubscriptionCard(
                            context,
                            ref,
                            ctx,
                            package: yearly,
                            title: AppLocalizations.get('premium_yearly_title', locale),
                            subtitle: AppLocalizations.get('premium_yearly_subtitle', locale),
                            locale: locale,
                            isPopular: true,
                          ),
                        if (lifetime != null)
                          _buildSubscriptionCard(
                            context,
                            ref,
                            ctx,
                            package: lifetime,
                            title: AppLocalizations.get('premium_lifetime_title', locale),
                            subtitle: AppLocalizations.get('premium_lifetime_subtitle', locale),
                            locale: locale,
                          ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 12),
                _buildLegalLinks(locale),
                
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

  static Widget _buildSubscriptionCard(
    BuildContext originalContext,
    WidgetRef ref,
    BuildContext dialogContext, {
    required Package package,
    required String title,
    required String subtitle,
    required String locale,
    bool isPopular = false,
    bool isTrial = false,
  }) {
    final borderColor = isTrial 
        ? Colors.greenAccent 
        : (isPopular ? Colors.amber : Colors.white12);
    final bgColor = isTrial 
        ? Colors.greenAccent.withOpacity(0.12) 
        : (isPopular ? Colors.amber.withOpacity(0.1) : Colors.white.withOpacity(0.05));

    return GestureDetector(
      onTap: () async {
        Navigator.pop(dialogContext);
        await RevenueCatService.purchasePackage(ref, originalContext, package);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: isTrial || isPopular ? 1.5 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      if (isTrial) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.greenAccent, Colors.teal]),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AppLocalizations.get('premium_trial_badge', locale), 
                            style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.extrabold),
                          ),
                        ),
                      ] else if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            AppLocalizations.get('premium_popular_badge', locale), 
                            style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle, 
                    style: TextStyle(
                      color: isTrial ? Colors.greenAccent.shade100 : Colors.white.withOpacity(0.5), 
                      fontSize: 11,
                      fontWeight: isTrial ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(package.storeProduct.priceString, style: TextStyle(color: isTrial ? Colors.greenAccent : Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  static Widget _buildLegalLinks(String locale) {
    return Column(
      children: [
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
          AppLocalizations.get('premium_auto_renew_desc', locale),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white24, fontSize: 10),
        ),
      ],
    );
  }
}
