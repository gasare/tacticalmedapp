import 'package:hive/hive.dart';

part 'case_model.g.dart';

@HiveType(typeId: 1)
class CaseRecord {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String patientId;

  @HiveField(2)
  final String noteType;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String? providerName;

  @HiveField(6, defaultValue: false)
  final bool isSynced;

  CaseRecord({
    required this.id,
    required this.patientId,
    required this.noteType,
    required this.description,
    required this.timestamp,
    this.providerName,
    this.isSynced = false,
  });
}
