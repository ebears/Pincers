// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thread_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ThreadModelAdapter extends TypeAdapter<ThreadModel> {
  @override
  final int typeId = 0;

  @override
  ThreadModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThreadModel(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime,
      sessionId: fields[4] as String?,
      preview: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ThreadModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.sessionId)
      ..writeByte(5)
      ..write(obj.preview);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThreadModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
