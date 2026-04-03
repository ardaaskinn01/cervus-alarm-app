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

  AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    this.isActive = true,
    this.repeatDays = const [],
    this.soundPath = 'default',
    this.vibrate = true,
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
      soundPath: json['soundPath'] ?? 'default',
      vibrate: json['vibrate'] ?? true,
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
  }) {
    return AlarmModel(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isActive: isActive ?? this.isActive,
      repeatDays: repeatDays ?? this.repeatDays,
      soundPath: soundPath ?? this.soundPath,
      vibrate: vibrate ?? this.vibrate,
    );
  }
}
