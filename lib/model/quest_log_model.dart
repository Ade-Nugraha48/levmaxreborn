import 'package:hive/hive.dart';
import '../core/constants/hive_boxes.dart';

part 'quest_log_model.g.dart';

@HiveType(typeId: HiveBoxes.questLogTypeId)
class QuestLogModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String username;

  @HiveField(2)
  String questType; // 'workout', 'study', 'cardio', 'grooming'

  @HiveField(3)
  String title; // 'PUSH UPS', 'CARDIO', 'STUDY', 'GROOMING'

  @HiveField(4)
  DateTime completedAt;

  @HiveField(5)
  int expGained;

  @HiveField(6)
  Map<String, int> statRewards; // {'STR': 2, 'END': 1}

  @HiveField(7)
  String metricSummary; // '45 reps', '2.0 km', '45 mins', '5 items'

  @HiveField(8)
  String? exerciseName; // Khusus workout: 'Push Ups', 'Pull Ups', 'Squats', 'Sit Ups'

  @HiveField(9)
  int repsCount;

  @HiveField(10)
  double distanceKm;

  @HiveField(11)
  int durationMinutes;

  @HiveField(12)
  double paceMinPerKm;

  QuestLogModel({
    required this.id,
    required this.username,
    required this.questType,
    required this.title,
    required this.completedAt,
    this.expGained = 25,
    Map<String, int>? statRewards,
    required this.metricSummary,
    this.exerciseName,
    this.repsCount = 0,
    this.distanceKm = 0.0,
    this.durationMinutes = 0,
    this.paceMinPerKm = 0.0,
  }) : statRewards = statRewards ?? {};
}
