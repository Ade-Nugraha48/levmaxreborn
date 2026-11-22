// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      username: fields[0] as String,
      password: fields[1] as String,
      photoPath: fields[2] as String?,
      level: fields[3] as int,
      exp: fields[4] as int,
      hp: fields[5] as int,
      strength: fields[6] as int,
      endurance: fields[7] as int,
      speed: fields[8] as int,
      intelligence: fields[9] as int,
      willpower: fields[10] as int,
      appearance: fields[11] as int,
      streakDays: fields[12] as int,
      lastActiveDate: fields[13] as String,
      createdAt: fields[14] as DateTime,
      longestStreak: fields[15] as int,
      rankHistory: (fields[16] as Map?)?.cast<String, String>(),
      unlockedAchievements: (fields[17] as Map?)?.cast<String, String>(),
      growthSnapshots: (fields[18] as Map?)?.cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.username)
      ..writeByte(1)
      ..write(obj.password)
      ..writeByte(2)
      ..write(obj.photoPath)
      ..writeByte(3)
      ..write(obj.level)
      ..writeByte(4)
      ..write(obj.exp)
      ..writeByte(5)
      ..write(obj.hp)
      ..writeByte(6)
      ..write(obj.strength)
      ..writeByte(7)
      ..write(obj.endurance)
      ..writeByte(8)
      ..write(obj.speed)
      ..writeByte(9)
      ..write(obj.intelligence)
      ..writeByte(10)
      ..write(obj.willpower)
      ..writeByte(11)
      ..write(obj.appearance)
      ..writeByte(12)
      ..write(obj.streakDays)
      ..writeByte(13)
      ..write(obj.lastActiveDate)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.longestStreak)
      ..writeByte(16)
      ..write(obj.rankHistory)
      ..writeByte(17)
      ..write(obj.unlockedAchievements)
      ..writeByte(18)
      ..write(obj.growthSnapshots);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
