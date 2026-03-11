// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GHabitAdapter extends TypeAdapter<GHabit> {
  @override
  final int typeId = 3;

  @override
  GHabit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GHabit(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      streak: fields[3] as int,
      lastChecked: fields[4] as DateTime?,
      isActive: fields[5] as bool,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GHabit obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.streak)
      ..writeByte(4)
      ..write(obj.lastChecked)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GHabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
