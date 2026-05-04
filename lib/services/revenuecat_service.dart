import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  static Future<bool> purchasePremium(WidgetRef ref, BuildContext context) async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        // Tek seferlik ödeme için 'lifetime' paketini önceliklendiriyoruz
        final package = offerings.current!.lifetime ?? offerings.current!.availablePackages.first;
        
        final purchaseResult = await Purchases.purchasePackage(package);
        final customerInfo = purchaseResult.customerInfo;
        final isPro = customerInfo.entitlements.all["pro"]?.isActive ?? false;
        ref.read(isPremiumProvider.notifier).state = isPro;
        
        if (isPro) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Premium aktif edildi! 🎉"), backgroundColor: Colors.green),
          );
        }
        return isPro;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Satın alınacak paket bulunamadı. Lütfen offerings ayarlarını kontrol edin."), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      debugPrint("Satın alma hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${e.toString()}"), backgroundColor: Colors.red),
      );
    }
    return false;
  }
  
  static Future<bool> restorePurchases(WidgetRef ref) async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      final isPro = customerInfo.entitlements.all["pro"]?.isActive ?? false;
      ref.read(isPremiumProvider.notifier).state = isPro;
      return isPro;
    } catch (e) {
       debugPrint("Geri yükleme hatası: $e");
    }
    return false;
  }
}
