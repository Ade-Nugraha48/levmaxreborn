// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_quest_state_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyQuestStateModelAdapter extends TypeAdapter<DailyQuestStateModel> {
  @override
  final int typeId = 3;

  @override
  DailyQuestStateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyQuestStateModel(
      username: fields[0] as String,
      date: fields[1] as String,
      workoutExercises: (fields[2] as List).cast<String>(),
      workoutCompleted: (fields[3] as List?)?.cast<bool>(),
      studyCompleted: fields[4] as bool,
      cardioCompleted: fields[5] as bool,
      groomingCompleted: fields[6] as bool,
      fullClearClaimed: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DailyQuestStateModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.username)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.workoutExercises)
      ..writeByte(3)
      ..write(obj.workoutCompleted)
      ..writeByte(4)
      ..write(obj.studyCompleted)
      ..writeByte(5)
      ..write(obj.cardioCompleted)
      ..writeByte(6)
      ..write(obj.groomingCompleted)
      ..writeByte(7)
      ..write(obj.fullClearClaimed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyQuestStateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
