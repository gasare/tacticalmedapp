// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_account.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAccountAdapter extends TypeAdapter<UserAccount> {
  @override
  final int typeId = 3;

  @override
  UserAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserAccount(
      username: fields[0] as String,
      hashedPassword: fields[1] as String,
      isAdmin: fields[2] as bool,
      biometricsEnabled: fields[3] as bool,
      firstName: fields[4] == null ? '' : fields[4] as String,
      lastName: fields[5] == null ? '' : fields[5] as String,
      phoneNumber: fields[6] == null ? '' : fields[6] as String,
      isApproved: fields[7] == null ? false : fields[7] as bool,
      isSynced: fields[8] == null ? false : fields[8] as bool,
      profilePhotoBase64: fields[9] == null ? '' : fields[9] as String,
      identificationType: fields[10] == null ? 'Soldier' : fields[10] as String,
      rank: fields[11] == null ? '' : fields[11] as String,
      unit: fields[12] == null ? '' : fields[12] as String,
      role: fields[13] == null ? '' : fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserAccount obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.username)
      ..writeByte(1)
      ..write(obj.hashedPassword)
      ..writeByte(2)
      ..write(obj.isAdmin)
      ..writeByte(3)
      ..write(obj.biometricsEnabled)
      ..writeByte(4)
      ..write(obj.firstName)
      ..writeByte(5)
      ..write(obj.lastName)
      ..writeByte(6)
      ..write(obj.phoneNumber)
      ..writeByte(7)
      ..write(obj.isApproved)
      ..writeByte(8)
      ..write(obj.isSynced)
      ..writeByte(9)
      ..write(obj.profilePhotoBase64)
      ..writeByte(10)
      ..write(obj.identificationType)
      ..writeByte(11)
      ..write(obj.rank)
      ..writeByte(12)
      ..write(obj.unit)
      ..writeByte(13)
      ..write(obj.role);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
