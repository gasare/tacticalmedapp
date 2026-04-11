// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimelineEventAdapter extends TypeAdapter<TimelineEvent> {
  @override
  final int typeId = 4;

  @override
  TimelineEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimelineEvent(
      action: fields[0] as String,
      timestamp: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TimelineEvent obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.action)
      ..writeByte(1)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
