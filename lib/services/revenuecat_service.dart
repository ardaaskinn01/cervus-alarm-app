import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_localizations.dart';
export 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';


final isPremiumProvider = StateProvider<bool>((ref) => false);

class RevenueCatService {
  static Future<void> init(WidgetRef ref) async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration("goog_CdKPYBXhbZiLNyviaUoCHkeooJx"); 
    } else {
      configuration = PurchasesConfiguration("appl_zMfQsclGkpPBQeXPmcfJbTIpWch");
    }
    await Purchases.configure(configuration);

    CustomerInfo customerInfo = await Purchases.getCustomerInfo();
    final isPro = customerInfo.entitlements.all["pro"]?.isActive ?? false;
    ref.read(isPremiumProvider.notifier).state = isPro;
  }

  static Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint("Offerings hatası: $e");
      return null;
    }
  }

  static Future<bool> purchasePackage(WidgetRef ref, BuildContext context, Package package) async {
    try {
      final purchaseResult = await Purchases.purchasePackage(package);
      final customerInfo = purchaseResult.customerInfo;
      final isPro = customerInfo.entitlements.all["pro"]?.isActive ?? false;
      ref.read(isPremiumProvider.notifier).state = isPro;
      
      if (isPro) {
        if (context.mounted) {
          final locale = ref.read(localeProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.get('rc_success', locale)), backgroundColor: Colors.green),
          );
        }
      }
      return isPro;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint("Satın alma kullanıcı tarafından iptal edildi.");
        return false;
      }
      debugPrint("Satın alma hatası: $e");
      if (context.mounted) {
        final locale = ref.read(localeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.get('rc_fail', locale)), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("Beklenmedik satın alma hatası: $e");
      if (context.mounted) {
        final locale = ref.read(localeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.get('rc_error', locale)}${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
    return false;
  }
  
  static Future<bool> restorePurchases(WidgetRef ref, BuildContext context) async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      final isPro = customerInfo.entitlements.all["pro"]?.isActive ?? false;
      ref.read(isPremiumProvider.notifier).state = isPro;
      
      if (context.mounted) {
        final locale = ref.read(localeProvider);
        if (isPro) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.get('rc_restore_success', locale)), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.get('rc_restore_none', locale)), backgroundColor: Colors.orange),
          );
        }
      }
      return isPro;
    } catch (e) {
      debugPrint("Geri yükleme hatası: $e");
      if (context.mounted) {
        final locale = ref.read(localeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.get('rc_restore_fail', locale)), backgroundColor: Colors.red),
        );
      }
    }
    return false;
  }
}
