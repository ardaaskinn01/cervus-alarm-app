import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  final storage = ref.read(localStorageServiceProvider);
  return LocaleNotifier(storage);
});

class LocaleNotifier extends StateNotifier<String> {
  final LocalStorageService _storage;

  LocaleNotifier(this._storage) : super(_storage.getLanguage());

  Future<void> setLocale(String languageCode) async {
    state = languageCode;
    await _storage.setLanguage(languageCode);
  }

  void setLocaleSync(String languageCode) {
    state = languageCode;
  }
}

class AppLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'tr': {
      'app_title': 'Alarmly - Uyandıran Alarm',
      'home_title': 'Alarm',
      'home_empty_title': 'Sakin Bir Gün...',
      'home_empty_subtitle': 'Şu an için hiç alarmın yok.\nDinlenmene bak veya yeni bir alarm kur.',
      'home_delete_title': 'Alarmı Sil',
      'home_delete_content': 'Bu alarmı silmek istediğinize emin misiniz?',
      'home_delete_cancel': 'İPTAL',
      'home_delete_confirm': 'SİL',
      'home_card_once': 'Sadece bir kez',
      'home_card_everyday': 'Her gün',
      'day_0': 'Pz', 'day_1': 'Sa', 'day_2': 'Ça', 'day_3': 'Pe', 'day_4': 'Cu', 'day_5': 'Ct', 'day_6': 'P',
      
      // Add Alarm
      'add_edit_title': 'Alarmı Düzenle',
      'add_new_title': 'Yeni Alarm',
      'add_repeat': 'Tekrarlama',
      'add_melody': 'Alarm Melodisi',
      'add_stop_method': 'Kapatma Yöntemi',
      'add_save': 'Kaydet',
      'add_label': 'Alarm Etiketi',

      // SettingsView
      'settings_title': 'Ayarlar',
      'settings_vibration_title': 'Titreşim',
      'settings_vibration_subtitle': 'Alarm çalarken güçlü titreşim',
      'settings_rate_title': 'Uygulamayı Puanla',
      'settings_rate_subtitle': 'Bize destek olmak için oy verin',
      'settings_language_title': 'Dil Seçenekleri',
      'settings_language_subtitle': 'Türkçe / English',
      'settings_privacy_title': 'Gizlilik Politikası',
      'settings_privacy_subtitle': 'Verileriniz ve gizliliğiniz',
      'settings_puzzle_count_title': 'Soru Sayısı',
      'settings_puzzle_count_subtitle': 'Alarmı kapatmak için çözülecek soru',
      'settings_custom_q_title': 'Özel Soru Ekle',
      'settings_custom_q_subtitle': 'Kendi sormak istediğin sorular',
      'settings_math_difficulty_title': 'Soru Zorluğu',
      'settings_math_difficulty_subtitle': 'Otomatik soruların basamak sayısı',
      'difficulty_easy': 'Kolay (2 Basamaklı)',
      'difficulty_medium': 'Orta (3 Basamaklı)',
      'difficulty_hard': 'Zor (4 Basamaklı)',
      'settings_premium_title': 'Alarmly Pro\'ya Geç',
      'settings_premium_subtitle': 'Reklamları kaldır ve tüm modları aç',
      'settings_premium_active': 'Pro Üyesiniz',
      'premium_popup_title': 'Alarmly Pro Ayrıcalıkları',
      'premium_popup_feature_1': 'Kendi alarm seslerini yükleyebilme',
      'premium_popup_feature_2': 'Farklı alarm kapatma yöntemleri (QR Okutma, Sallama, Hafıza Oyunu, Metin Yazma)',
      'premium_popup_feature_3': 'Reklamlar kapatılacak',
      'premium_popup_buy': 'Şimdi Al',
      'premium_popup_restore': 'Satın Almayı Geri Yükle',
      'premium_popup_cancel': 'İptal',
      'settings_more_apps_title': 'Diğer Uygulamalarımız',
      'settings_more_apps_subtitle': 'Geliştirdiğimiz diğer uygulamalara göz atın',
      'custom_q_add_title': 'Soru Ekle',
      'custom_q_q_hint': 'Soru (Örn: 15 + 45)',
      'custom_q_a_hint': 'Cevap (Örn: 60)',
      'custom_q_save': 'Kaydet',
      'custom_q_cancel': 'İptal',
      'custom_q_invalid': 'Geçerli bir soru ve sayısal cevap girin.',

      // PuzzleView
      'puzzle_wrong': 'Yanlış! Baştan başlıyoruz.',
      'puzzle_dialog_title': 'Tebrikler ama...',
      'puzzle_dialog_content': 'Hâlâ ertelemek istediğinize EMIN MİSİNİZ?',
      'puzzle_dialog_close': 'AYILDIM GEREK YOK (Kapat)',
      'puzzle_dialog_snooze': 'ERTELE',
      'puzzle_appbar': 'Ertelemek için Çöz!',
      'puzzle_question': 'Matematik Sorusu',
      'puzzle_answer': 'CEVABINIZ',
      'puzzle_check': 'KONTROL ET',

      // RingingView
      'ringing_title': 'UYANMA VAKTİ!',
      'ringing_subtitle': 'Günün seni bekliyor, geç kalma.',
      'ringing_wakeup': 'AYILDIM (Kapat)',
      'ringing_snooze': 'Biraz daha uyu (Ertele)',

      // SuccessView
      'success_morning': 'GÜNAYDIN!',
      'success_afternoon': 'TÜNAYDIN!',
      'success_evening': 'İYİ AKŞAMLAR!',
      'success_night': 'İYİ GECELER!',
      'success_title': 'BAŞARDIN!',
      'success_quote_title': 'GÜNÜN SÖZÜ',
      'success_task_title': 'BUGÜNKÜ GÖREVİN',
      'success_start': 'GÜNE BAŞLA',
      'success_back': 'ANA SAYFAYA DÖN',
      'alarm_saved_success': 'Alarm başarıyla kuruldu! 🎉',
      'alarm_saved_warning': 'Alarm kuruldu! En iyi deneyim için bildirimlerinin açık olduğundan emin ol.',
      'kill_warning_title': '⚠️ DİKKAT: Alarmınız Çalmayabilir!',
      'kill_warning_body': 'Uygulamayı tamamen kapattınız! Apple arka plan alarmlarının çalınmasını engeller. Lütfen uygulamayı ana ekrana dönerek açık bırakın.',
      'ringing_notification_title': 'Alarmly - Uyandıran Alarm',
      'ringing_notification_body': 'Günün başlıyor, hadi ayılma vakti!',

      // Custom Sounds
      'custom_sound_title': 'Özel Alarm Sesleri',
      'custom_sound_subtitle': 'Kendi müzik ve ses dosyalarını yükle',
      'custom_sound_empty': 'Henüz özel bir ses yüklemediniz.',
      'custom_sound_add': 'Yeni Ses Yükle',
      'custom_sound_close': 'Kapat',

      // Stop Methods
      'method_math': 'Matematik',
      'method_shake': 'Salla',
      'method_typing': 'Yazı',
      'method_memory': 'Hafıza',
      'method_qr': 'QR / Barkod',

      // Melody
      'melody_custom': 'Özel Ses',
      'melody_low': 'Düşük',
      'melody_medium': 'Orta',
      'melody_high': 'Yüksek',

      // Lock & Rewards
      'premium_lock_title': 'Pro Özellik',
      'premium_lock_desc': 'Farklı alarm kapatma yöntemleri sadece Alarmly Pro kullanıcılarına özeldir.',
      'premium_lock_btn': 'Proya Geç',
      'reward_try_once': 'Tek Seferlik Aç  🎬',
      'reward_try_once_desc': '— Reklam izle, tüm yöntemleri aç',
      'reward_unlocked_toast': 'Tüm kapatma yöntemleri bu alarm için açıldı! 🎉',
      'reward_failed_toast': 'Reklam yüklenemedi, lütfen tekrar deneyin.',

      // Stop Views
      'typing_title': 'Birebir Aynısını Yaz!',
      'typing_hint_2': 'Büyük/küçük harf ve noktalama işaretlerine dikkat et.',
      'typing_textfield_hint': 'Buraya yazın...',
      'shake_title': 'Ertelemek için Salla!',
      'memory_title': 'Hafıza Oyunu',
      'memory_subtitle': 'Kartları Eşleştir',
      'memory_match': 'Eşleşen: ',
      'qr_title': 'Herhangi Bir Barkod Okut',
      'qr_subtitle': 'Mutfağa gidip bir ürün barkodu\nveya rastgele bir QR kod okutun.',
      'math_zero_error': 'Sıfıra bölünemez! / Cannot divide by zero',
      'math_remainder_error': 'Tam bölünmüyor! Lütfen kalansız bölünecek sayılar girin. (Örn: 10 / 2)',
      
      // RevenueCat & System
      'rc_success': 'Premium aktif edildi! 🎉',
      'rc_fail': 'Satın alma işlemi tamamlanamadı. Lütfen tekrar deneyin.',
      'rc_error': 'Bir hata oluştu: ',
      'rc_restore_success': 'Satın alımlar başarıyla geri yüklendi! 🎉',
      'rc_restore_none': 'Geri yüklenecek aktif bir abonelik bulunamadı.',
      'rc_restore_fail': 'Geri yükleme işlemi başarısız oldu.',
      'battery_dialog_title': 'Bildirim İzni Gerekli',
      'battery_dialog_content': 'Alarmların çalabilmesi için bildirim iznine ihtiyaç var.\n\nLütfen Ayarlar\'dan bildirimlere izin verin.',
      'battery_dialog_now_not': 'Şimdi Değil',
      'battery_dialog_open_settings': 'Ayarları Aç',
      'battery_snack_bar': 'Ayarlar > Bildirimler > Alarmly yolunu izleyin ve bildirimleri açın.',
      'settings_no_custom_q': 'Henüz özel soru yok.',
      'settings_bg_sound_title': 'Arkaplan Alarm Politikası',
      'settings_bg_sound_subtitle': 'Bildirimlerdeki uyanma şiddetini seçin',
      'bg_sound_low': 'Düşük (bg_alarm_low)',
      'bg_sound_medium': 'Orta (bg_alarm)',
      'bg_sound_high': 'Yüksek (bg_alarm2)',
      'bg_sound_test': 'Dene',
      
      // Premium Subscriptions
      'premium_monthly_title': 'Aylık',
      'premium_monthly_subtitle': '1 hafta ücretsiz dene, sonra aylık',
      'premium_yearly_title': 'Yıllık',
      'premium_yearly_subtitle': 'En maliyet etkin seçim',
      'premium_lifetime_title': 'Ömür Boyu',
      'premium_lifetime_subtitle': 'Tek seferlik ödeme',
      'premium_popular_badge': 'POPÜLER',
      'premium_load_fail': 'Paketler yüklenemedi.',
      'premium_no_packages': 'Paket bulunamadı.',
      'premium_privacy': 'Gizlilik',
      'premium_terms': 'Koşullar',
      'premium_auto_renew_desc': 'Abonelikler otomatik olarak yenilenir.',
      'premium_auto_renew_desc_full': 'Abonelikler otomatik olarak yenilenir. İptal edilmediği sürece seçilen dönem sonunda ücret indirilir.',
    },
    'en': {
      'app_title': 'Alarmly - Wake Force Alarm',
      'home_title': 'Alarm',
      'home_empty_title': 'A Quiet Day...',
      'home_empty_subtitle': 'You have no alarms right now.\nTake a rest or set a new one.',
      'home_delete_title': 'Delete Alarm',
      'home_delete_content': 'Are you sure you want to delete this alarm?',
      'home_delete_cancel': 'CANCEL',
      'home_delete_confirm': 'DELETE',
      'home_card_once': 'Just once',
      'home_card_everyday': 'Every day',
      'day_0': 'Mon', 'day_1': 'Tue', 'day_2': 'Wed', 'day_3': 'Thu', 'day_4': 'Fri', 'day_5': 'Sat', 'day_6': 'Sun',

      // Add Alarm
      'add_edit_title': 'Edit Alarm',
      'add_new_title': 'New Alarm',
      'add_repeat': 'Repeat',
      'add_melody': 'Alarm Melody',
      'add_stop_method': 'Stop Method',
      'add_save': 'Save',
      'add_label': 'Alarm Label',

      // SettingsView
      'settings_title': 'Settings',
      'settings_vibration_title': 'Vibration',
      'settings_vibration_subtitle': 'Strong vibration during alarm',
      'settings_rate_title': 'Rate App',
      'settings_rate_subtitle': 'Vote to support us',
      'settings_language_title': 'Language Options',
      'settings_language_subtitle': 'English / Türkçe',
      'settings_privacy_title': 'Privacy Policy',
      'settings_privacy_subtitle': 'Your data and privacy',
      'settings_puzzle_count_title': 'Question Count',
      'settings_puzzle_count_subtitle': 'Number of questions to solve to wake up',
      'settings_custom_q_title': 'Add Custom Question',
      'settings_custom_q_subtitle': 'Your own questions',
      'settings_math_difficulty_title': 'Math Difficulty',
      'settings_math_difficulty_subtitle': 'Number of digits in questions',
      'difficulty_easy': 'Easy (2 Digits)',
      'difficulty_medium': 'Medium (3 Digits)',
      'difficulty_hard': 'Hard (4 Digits)',
      'settings_premium_title': 'Upgrade to Alarmly Pro',
      'settings_premium_subtitle': 'Remove ads and unlock all modes',
      'settings_premium_active': 'You are a Pro Member',
      'premium_popup_title': 'Alarmly Pro Benefits',
      'premium_popup_feature_1': 'Upload your own alarm sounds',
      'premium_popup_feature_2': 'Different alarm stop methods (QR Scan, Shake, Memory Game, Type Text)',
      'premium_popup_feature_3': 'No more ads',
      'premium_popup_buy': 'Buy Now',
      'premium_popup_restore': 'Restore Purchase',
      'premium_popup_cancel': 'Cancel',
      'settings_more_apps_title': 'Our Other Apps',
      'settings_more_apps_subtitle': 'Check out other apps we developed',
      'custom_q_add_title': 'Add Question',
      'custom_q_q_hint': 'Question (e.g. 15 + 45)',
      'custom_q_a_hint': 'Answer (e.g. 60)',
      'custom_q_save': 'Save',
      'custom_q_cancel': 'Cancel',
      'custom_q_invalid': 'Please enter a valid question and a numeric answer.',

      // PuzzleView
      'puzzle_wrong': 'Wrong! Let\'s start over.',
      'puzzle_dialog_title': 'Congratulations but...',
      'puzzle_dialog_content': 'ARE YOU SURE you still want to snooze?',
      'puzzle_dialog_close': 'I\'M AWAKE (Close)',
      'puzzle_dialog_snooze': 'SNOOZE',
      'puzzle_appbar': 'Solve to Snooze!',
      'puzzle_question': 'Math Question',
      'puzzle_answer': 'YOUR ANSWER',
      'puzzle_check': 'CHECK',

      // RingingView
      'ringing_title': 'WAKE UP TIME!',
      'ringing_subtitle': 'Your day is waiting, don\'t be late.',
      'ringing_wakeup': 'I\'M AWAKE (Close)',
      'ringing_snooze': 'Sleep a bit more (Snooze)',

      // SuccessView
      'success_morning': 'GOOD MORNING!',
      'success_afternoon': 'GOOD AFTERNOON!',
      'success_evening': 'GOOD EVENING!',
      'success_night': 'GOOD NIGHT!',
      'success_title': 'YOU DID IT!',
      'success_quote_title': 'DAILY QUOTE',
      'success_task_title': 'TODAY\'S TASK',
      'success_start': 'START THE DAY',
      'success_back': 'BACK TO HOME',
      'alarm_saved_success': 'Alarm saved successfully! 🎉',
      'alarm_saved_warning': 'Alarm saved! Make sure your notifications are on for the best experience.',
      'kill_warning_title': '⚠️ WARNING: Alarm May Not Ring!',
      'kill_warning_body': 'You have fully closed the app! Apple prevents background alarms from ringing if the app is killed. Please leave it in the background.',
      'ringing_notification_title': 'Alarmly - Wake Force Alarm',
      'ringing_notification_body': 'Your day is starting, time to wake up!',

      // Custom Sounds
      'custom_sound_title': 'Custom Alarm Sounds',
      'custom_sound_subtitle': 'Upload your own music and audio files',
      'custom_sound_empty': 'You haven\'t uploaded any custom sounds yet.',
      'custom_sound_add': 'Upload New Sound',
      'custom_sound_close': 'Close',

      // Stop Methods
      'method_math': 'Math',
      'method_shake': 'Shake',
      'method_typing': 'Typing',
      'method_memory': 'Memory',
      'method_qr': 'QR / Barcode',

      // Melody
      'melody_custom': 'Custom',
      'melody_low': 'Low',
      'melody_medium': 'Medium',
      'melody_high': 'High',

      // Lock & Rewards
      'premium_lock_title': 'Pro Feature',
      'premium_lock_desc': 'Different alarm stop methods are exclusive to Alarmly Pro users.',
      'premium_lock_btn': 'Upgrade to Pro',
      'reward_try_once': 'Unlock Once  🎬',
      'reward_try_once_desc': '— Watch ad to unlock all methods',
      'reward_unlocked_toast': 'All stop methods unlocked for this alarm! 🎉',
      'reward_failed_toast': 'Failed to load ad, please try again.',

      // Stop Views
      'typing_title': 'Type Exactly the Same!',
      'typing_hint_2': 'Pay attention to capitalization and punctuation.',
      'typing_textfield_hint': 'Type here...',
      'shake_title': 'Shake to Snooze!',
      'memory_title': 'Memory Game',
      'memory_subtitle': 'Match the Cards',
      'memory_match': 'Matches: ',
      'qr_title': 'Scan Any Barcode',
      'qr_subtitle': 'Go to the kitchen and scan a product barcode\nor a random QR code.',
      'math_zero_error': 'Sıfıra bölünemez! / Cannot divide by zero',
      'math_remainder_error': 'Indivisible! Please enter numbers that divide evenly. (e.g. 10 / 2)',

      // RevenueCat & System
      'rc_success': 'Premium activated! 🎉',
      'rc_fail': 'Purchase failed. Please try again.',
      'rc_error': 'An error occurred: ',
      'rc_restore_success': 'Purchases restored successfully! 🎉',
      'rc_restore_none': 'No active subscription found to restore.',
      'rc_restore_fail': 'Restore failed.',
      'battery_dialog_title': 'Notification Permission Required',
      'battery_dialog_content': 'Notification permission is required for alarms to ring.\n\nPlease allow notifications in Settings.',
      'battery_dialog_now_not': 'Not Now',
      'battery_dialog_open_settings': 'Open Settings',
      'battery_snack_bar': 'Go to Settings > Notifications > Alarmly and turn on notifications.',
      'settings_no_custom_q': 'No custom questions yet.',
      'settings_bg_sound_title': 'Background Alarm Policy',
      'settings_bg_sound_subtitle': 'Choose wake-up intensity for notifications',
      'bg_sound_low': 'Low (bg_alarm_low)',
      'bg_sound_medium': 'Medium (bg_alarm)',
      'bg_sound_high': 'High (bg_alarm2)',
      'bg_sound_test': 'Test',

      // Premium Subscriptions
      'premium_monthly_title': 'Monthly',
      'premium_monthly_subtitle': '1-week free trial, then monthly',
      'premium_yearly_title': 'Yearly',
      'premium_yearly_subtitle': 'Best value for money',
      'premium_lifetime_title': 'Lifetime',
      'premium_lifetime_subtitle': 'One-time payment',
      'premium_popular_badge': 'POPULAR',
      'premium_load_fail': 'Offerings could not be loaded.',
      'premium_no_packages': 'No packages found.',
      'premium_privacy': 'Privacy',
      'premium_terms': 'Terms',
      'premium_auto_renew_desc': 'Subscriptions renew automatically.',
      'premium_auto_renew_desc_full': 'Subscriptions renew automatically. Payment will be charged at the end of the period unless cancelled.',
    },
  };

  static String get(String key, String locale) {
    return _localizedValues[locale]?[key] ?? _localizedValues['tr']?[key] ?? key;
  }
}
