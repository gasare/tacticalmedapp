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

  @HiveField(4, defaultValue: '')
  final String firstName;

  @HiveField(5, defaultValue: '')
  final String lastName;

  @HiveField(6, defaultValue: '')
  final String phoneNumber;

  UserAccount({
    required this.username,
    required this.hashedPassword,
    this.isAdmin = false,
    this.biometricsEnabled = false,
    this.firstName = '',
    this.lastName = '',
    this.phoneNumber = '',
  });
}
