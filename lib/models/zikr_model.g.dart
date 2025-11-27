// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zikr_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ZikrModelAdapter extends TypeAdapter<ZikrModel> {
  @override
  final int typeId = 0;

  @override
  ZikrModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ZikrModel(
      id: fields[0] as String,
      name: fields[1] as String,
      targetCount: fields[2] as int,
      currentCount: fields[3] as int,
      ayahText: fields[4] as String?,
      ayahImagePath: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      lastUpdated: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ZikrModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.targetCount)
      ..writeByte(3)
      ..write(obj.currentCount)
      ..writeByte(4)
      ..write(obj.ayahText)
      ..writeByte(5)
      ..write(obj.ayahImagePath)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZikrModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
