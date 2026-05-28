import 'package:hive/hive.dart';

part 'alarm_model.g.dart';

@HiveType(typeId: 0)
class AlarmModel extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int hour;

  @HiveField(2)
  int minute;

  @HiveField(3)
  bool isActive;

  @HiveField(4)
  List<int> repeatDays; // e.g., 1 for Monday, 7 for Sunday

  @HiveField(5)
  String soundPath;

  @HiveField(6)
  bool vibrate;

  @HiveField(7)
  String label;

  @HiveField(8, defaultValue: 'math')
  String stopMethod;

  /// Ödüllü reklam izlenerek kapatma yöntemleri geçici olarak açıldı mı?
  /// Alarm çaldıktan sonra false'a döner.
  @HiveField(9, defaultValue: false)
  bool rewardUnlocked;

  AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    this.isActive = true,
    this.repeatDays = const [],
    this.soundPath = 'assets/audio/bg_alarm.mp3',
    this.vibrate = true,
    this.label = '',
    this.stopMethod = 'math',
    this.rewardUnlocked = false,
  });

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'isActive': isActive,
      'repeatDays': repeatDays,
      'soundPath': soundPath,
      'vibrate': vibrate,
      'label': label,
      'stopMethod': stopMethod,
      'rewardUnlocked': rewardUnlocked,
    };
  }

  // From JSON
  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'],
      hour: json['hour'],
      minute: json['minute'],
      isActive: json['isActive'],
      repeatDays: List<int>.from(json['repeatDays'] ?? []),
      soundPath: json['soundPath'] ?? 'assets/audio/bg_alarm.mp3',
      vibrate: json['vibrate'] ?? true,
      label: json['label'] ?? '',
      stopMethod: json['stopMethod'] ?? 'math',
      rewardUnlocked: json['rewardUnlocked'] ?? false,
    );
  }

  AlarmModel copyWith({
    int? id,
    int? hour,
    int? minute,
    bool? isActive,
    List<int>? repeatDays,
    String? soundPath,
    bool? vibrate,
    String? label,
    String? stopMethod,
    bool? rewardUnlocked,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isActive: isActive ?? this.isActive,
      repeatDays: repeatDays ?? this.repeatDays,
      soundPath: soundPath ?? this.soundPath,
      vibrate: vibrate ?? this.vibrate,
      label: label ?? this.label,
      stopMethod: stopMethod ?? this.stopMethod,
      rewardUnlocked: rewardUnlocked ?? this.rewardUnlocked,
    );
  }
}

