// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocabulary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VocabularyAdapter extends TypeAdapter<Vocabulary> {
  @override
  final int typeId = 0;

  @override
  Vocabulary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Vocabulary(
      id: fields[0] as String,
      english: fields[1] as String,
      japanese: fields[2] as String,
      createdAt: fields[3] as DateTime,
      correctCount: fields[4] as int,
      wrongCount: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Vocabulary obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.english)
      ..writeByte(2)
      ..write(obj.japanese)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.correctCount)
      ..writeByte(5)
      ..write(obj.wrongCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
