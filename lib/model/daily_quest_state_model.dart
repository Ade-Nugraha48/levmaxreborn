import 'package:hive/hive.dart';
import '../core/constants/hive_boxes.dart';

part 'daily_quest_state_model.g.dart';

@HiveType(typeId: HiveBoxes.dailyQuestStateTypeId)
class DailyQuestStateModel extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  String date; // YYYY-MM-DD

  @HiveField(2)
  List<String> workoutExercises; // 2 gerakan hari ini

  @HiveField(3)
  List<bool> workoutCompleted; // [false, false]

  @HiveField(4)
  bool studyCompleted;

  @HiveField(5)
  bool cardioCompleted;

  @HiveField(6)
  bool groomingCompleted;

  @HiveField(7)
  bool fullClearClaimed;

  DailyQuestStateModel({
    required this.username,
    required this.date,
    required this.workoutExercises,
    List<bool>? workoutCompleted,
    this.studyCompleted = false,
    this.cardioCompleted = false,
    this.groomingCompleted = false,
    this.fullClearClaimed = false,
  }) : workoutCompleted = workoutCompleted ?? [false, false];

  /// Total count of completed quests today (0 to 5)
  int get completedCount {
    int count = 0;
    if (workoutCompleted.isNotEmpty && workoutCompleted[0]) count++;
    if (workoutCompleted.length > 1 && workoutCompleted[1]) count++;
    if (studyCompleted) count++;
    if (cardioCompleted) count++;
    if (groomingCompleted) count++;
    return count;
  }

  /// Whether all 5 daily quests are completed
  bool get isAllCompleted => completedCount == 5;
}
