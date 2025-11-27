// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zikr_chain_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChainStepAdapter extends TypeAdapter<ChainStep> {
  @override
  final int typeId = 2;

  @override
  ChainStep read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChainStep(
      name: fields[0] as String,
      targetCount: fields[1] as int,
      currentCount: fields[2] as int,
      ayahText: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChainStep obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.targetCount)
      ..writeByte(2)
      ..write(obj.currentCount)
      ..writeByte(3)
      ..write(obj.ayahText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChainStepAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ZikrChainModelAdapter extends TypeAdapter<ZikrChainModel> {
  @override
  final int typeId = 1;

  @override
  ZikrChainModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ZikrChainModel(
      id: fields[0] as String,
      name: fields[1] as String,
      steps: (fields[2] as List).cast<ChainStep>(),
      currentStepIndex: fields[3] as int,
      isBuiltIn: fields[6] as bool,
      createdAt: fields[4] as DateTime?,
      lastUpdated: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ZikrChainModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.steps)
      ..writeByte(3)
      ..write(obj.currentStepIndex)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastUpdated)
      ..writeByte(6)
      ..write(obj.isBuiltIn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZikrChainModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
