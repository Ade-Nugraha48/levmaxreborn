// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestLogModelAdapter extends TypeAdapter<QuestLogModel> {
  @override
  final int typeId = 1;

  @override
  QuestLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestLogModel(
      id: fields[0] as String,
      username: fields[1] as String,
      questType: fields[2] as String,
      title: fields[3] as String,
      completedAt: fields[4] as DateTime,
      expGained: fields[5] as int,
      statRewards: (fields[6] as Map?)?.cast<String, int>(),
      metricSummary: fields[7] as String,
      exerciseName: fields[8] as String?,
      repsCount: fields[9] as int,
      distanceKm: fields[10] as double,
      durationMinutes: fields[11] as int,
      paceMinPerKm: fields[12] as double,
    );
  }

  @override
  void write(BinaryWriter writer, QuestLogModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.questType)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.completedAt)
      ..writeByte(5)
      ..write(obj.expGained)
      ..writeByte(6)
      ..write(obj.statRewards)
      ..writeByte(7)
      ..write(obj.metricSummary)
      ..writeByte(8)
      ..write(obj.exerciseName)
      ..writeByte(9)
      ..write(obj.repsCount)
      ..writeByte(10)
      ..write(obj.distanceKm)
      ..writeByte(11)
      ..write(obj.durationMinutes)
      ..writeByte(12)
      ..write(obj.paceMinPerKm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
