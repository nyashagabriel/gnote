// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GTaskAdapter extends TypeAdapter<GTask> {
  @override
  final int typeId = 1;

  @override
  GTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GTask(
      id: fields[0] as String,
      userId: fields[1] as String,
      what: fields[2] as String,
      doneWhen: fields[3] as String,
      by: fields[4] as DateTime,
      category: fields[5] as String,
      isDone: fields[6] as bool,
      isCapture: fields[7] as bool,
      createdAt: fields[8] as DateTime,
      completedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, GTask obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.what)
      ..writeByte(3)
      ..write(obj.doneWhen)
      ..writeByte(4)
      ..write(obj.by)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.isDone)
      ..writeByte(7)
      ..write(obj.isCapture)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
