// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GUserAdapter extends TypeAdapter<GUser> {
  @override
  final int typeId = 0;

  @override
  GUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GUser(
      id: fields[0] as String,
      email: fields[1] as String,
      displayName: fields[2] as String,
      timezone: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      lastSeen: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GUser obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.timezone)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastSeen);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
