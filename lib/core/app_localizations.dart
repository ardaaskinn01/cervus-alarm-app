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
      'success_task_title': 'BUGÜNKÜ GÖREVİN',
      'success_start': 'GÜNE BAŞLA',
      'alarm_saved_warning': 'Alarm kuruldu! Çalabilmesi için uygulamayı TAMAMEN KAPATMAYIN, arka planda (ana ekranda) bırakın.',
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
      'success_task_title': 'TODAY\'S TASK',
      'success_start': 'START THE DAY',
      'alarm_saved_warning': 'Alarm saved! To ensure it rings, DO NOT FULLY KILL the app; leave it in the background.',
    },
  };

  static String get(String key, String locale) {
    return _localizedValues[locale]?[key] ?? _localizedValues['tr']?[key] ?? key;
  }
}
