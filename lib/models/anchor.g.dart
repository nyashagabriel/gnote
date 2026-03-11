// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anchor.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GAnchorAdapter extends TypeAdapter<GAnchor> {
  @override
  final int typeId = 2;

  @override
  GAnchor read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GAnchor(
      id: fields[0] as String,
      userId: fields[1] as String,
      content: fields[2] as String,
      date: fields[3] as DateTime,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GAnchor obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GAnchorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
