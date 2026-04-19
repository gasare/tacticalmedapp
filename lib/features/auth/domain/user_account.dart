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

  @HiveField(7, defaultValue: false)
  final bool isApproved;

  @HiveField(8, defaultValue: false)
  final bool isSynced;

  @HiveField(9, defaultValue: '')
  final String profilePhotoBase64;

  @HiveField(10, defaultValue: 'Soldier')
  final String identificationType;

  @HiveField(11, defaultValue: '')
  final String rank;

  @HiveField(12, defaultValue: '')
  final String unit;

  @HiveField(13, defaultValue: '')
  final String role;

  UserAccount({
    required this.username,
    required this.hashedPassword,
    this.isAdmin = false,
    this.biometricsEnabled = false,
    this.firstName = '',
    this.lastName = '',
    this.phoneNumber = '',
    this.isApproved = false,
    this.isSynced = false,
    this.profilePhotoBase64 = '',
    this.identificationType = 'Soldier',
    this.rank = '',
    this.unit = '',
    this.role = '',
  });
}
