// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grooming_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroomingItemModelAdapter extends TypeAdapter<GroomingItemModel> {
  @override
  final int typeId = 2;

  @override
  GroomingItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroomingItemModel(
      id: fields[0] as String,
      username: fields[1] as String,
      title: fields[2] as String,
      isChecked: fields[3] as bool,
      isDefault: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, GroomingItemModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.isChecked)
      ..writeByte(4)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroomingItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
