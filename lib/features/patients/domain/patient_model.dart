import 'package:hive/hive.dart';

part 'patient_model.g.dart';

@HiveType(typeId: 0)
class Patient {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int age;

  @HiveField(3)
  final String gender;

  @HiveField(4)
  final String? gpsLocation;

  @HiveField(5)
  final String? base64Photo;

  @HiveField(6)
  final String injuries;

  @HiveField(7)
  final String medicalHistory;

  @HiveField(8)
  final DateTime registeredAt;

  @HiveField(9)
  final String severity;

  @HiveField(10)
  final String? unit;

  @HiveField(11)
  final String? base64WoundPhoto;

  @HiveField(12, defaultValue: false)
  final bool isSynced;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.gpsLocation,
    this.base64Photo,
    required this.injuries,
    required this.medicalHistory,
    required this.registeredAt,
    required this.severity,
    this.unit,
    this.base64WoundPhoto,
    this.isSynced = false,
  });
}
