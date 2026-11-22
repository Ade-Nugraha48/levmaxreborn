import '../core/constants/game_config.dart';
import 'user_model.dart';
import 'quest_log_model.dart';

/// Achievement Model for Profile & Achievements Page
class AchievementModel {
  final String id;
  final String title;
  final String description;
  final double targetValue;
  final bool isRare;
  final bool isUnlocked;
  final String? unlockedDate;
  final double currentProgress;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.isRare,
    required this.isUnlocked,
    this.unlockedDate,
    required this.currentProgress,
  });

  /// Progress ratio from 0.0 to 1.0
  double get progressRatio {
    if (isUnlocked) return 1.0;
    if (targetValue <= 0) return 0.0;
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }

  /// Label for progress display, e.g. "50 / 100" or "Unlocked"
  String get progressLabel {
    if (isUnlocked) return 'UNLOCKED';
    if (id == 'phantom_velocity') {
      return 'PACE <= 3:59';
    }
    if (targetValue == targetValue.roundToDouble()) {
      return '${currentProgress.toInt()} / ${targetValue.toInt()}';
    }
    return '${currentProgress.toStringAsFixed(1)} / ${targetValue.toStringAsFixed(1)}';
  }

  /// Evaluates and generates all 8 achievements for a given user and their quest logs
  static List<AchievementModel> evaluateAll({
    required UserModel user,
    required List<QuestLogModel> logs,
  }) {
    // 1. Calculate aggregated metrics from quest logs
    int totalWorkoutReps = 0;
    double totalCardioKm = 0.0;
    int totalStudyMinutes = 0;
    int totalQuestsCleared = logs.length;
    bool hasPhantomVelocity = false;

    for (final log in logs) {
      if (log.questType == 'workout') {
        totalWorkoutReps += log.repsCount;
      } else if (log.questType == 'cardio') {
        totalCardioKm += log.distanceKm;
        // Check phantom velocity: pace > 0 and pace <= 3:59 (3.9833 min/km)
        if (log.paceMinPerKm > 0 && log.paceMinPerKm <= 3.99) {
          hasPhantomVelocity = true;
        }
      } else if (log.questType == 'study') {
        totalStudyMinutes += log.durationMinutes;
      }
    }

    final streak = user.longestStreak > user.streakDays
        ? user.longestStreak
        : user.streakDays;

    return GameConfig.achievements.map((def) {
      final isUnlocked = user.unlockedAchievements.containsKey(def.id);
      final unlockedDate = user.unlockedAchievements[def.id];
      double progress = 0.0;

      switch (def.id) {
        case 'the_awakening':
          progress = isUnlocked ? 1.0 : 0.0;
          break;
        case 'first_blood':
          progress = totalQuestsCleared >= 1 ? 1.0 : 0.0;
          break;
        case 'iron_vessel':
          progress = totalWorkoutReps.toDouble();
          break;
        case 'wayfarer':
          progress = totalCardioKm;
          break;
        case 'phantom_velocity':
          progress = (hasPhantomVelocity || isUnlocked) ? 1.0 : 0.0;
          break;
        case 'scholar_sanctum':
          progress = totalStudyMinutes.toDouble();
          break;
        case 'centurion':
          progress = totalQuestsCleared.toDouble();
          break;
        case 'unbroken':
          progress = streak.toDouble();
          break;
      }

      return AchievementModel(
        id: def.id,
        title: def.title,
        description: def.description,
        targetValue: def.targetValue,
        isRare: def.isRare,
        isUnlocked: isUnlocked,
        unlockedDate: unlockedDate,
        currentProgress: progress,
      );
    }).toList();
  }
}
