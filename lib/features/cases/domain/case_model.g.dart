// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'case_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CaseRecordAdapter extends TypeAdapter<CaseRecord> {
  @override
  final int typeId = 1;

  @override
  CaseRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CaseRecord(
      id: fields[0] as String,
      patientId: fields[1] as String,
      noteType: fields[2] as String,
      description: fields[3] as String,
      timestamp: fields[4] as DateTime,
      providerName: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CaseRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.noteType)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.providerName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
