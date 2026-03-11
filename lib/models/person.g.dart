// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GPersonAdapter extends TypeAdapter<GPerson> {
  @override
  final int typeId = 4;

  @override
  GPerson read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GPerson(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      whatsappNumber: fields[3] as String,
      role: fields[4] as String,
      messageTemplate: fields[5] as String,
      lastSelectedAt: fields[6] as DateTime?,
      timesSelected: fields[7] as int,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GPerson obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.whatsappNumber)
      ..writeByte(4)
      ..write(obj.role)
      ..writeByte(5)
      ..write(obj.messageTemplate)
      ..writeByte(6)
      ..write(obj.lastSelectedAt)
      ..writeByte(7)
      ..write(obj.timesSelected)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GPersonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
