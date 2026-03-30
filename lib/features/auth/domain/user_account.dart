import 'package:hive/hive.dart';

part 'user_account.g.dart';

@HiveType(typeId: 3)
class UserAccount {
  @HiveField(0)
  final String username;

  @HiveField(1)
  final String hashedPassword;

  @HiveField(2)
  final bool isAdmin;

  @HiveField(3)
  final bool biometricsEnabled;

  UserAccount({
    required this.username,
    required this.hashedPassword,
    this.isAdmin = false,
    this.biometricsEnabled = false,
  });
}
