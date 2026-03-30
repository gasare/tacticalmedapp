import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 2)
class UserSettings {
  @HiveField(0)
  final String providerName;

  @HiveField(1)
  final String rank;

  @HiveField(2)
  final String unit;

  @HiveField(3)
  final String role;

  UserSettings({
    required this.providerName,
    required this.rank,
    required this.unit,
    required this.role,
  });
}
