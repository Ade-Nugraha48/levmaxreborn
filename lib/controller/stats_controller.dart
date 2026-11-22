import 'dart:math';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../model/quest_log_model.dart';
import '../../model/user_model.dart';
import '../../service/hive_service.dart';
import 'user_controller.dart';

/// Controller for Screen 5 & 6: Stats (Attributes & Sejarah)
class StatsController extends GetxController {
  final UserController _userController = Get.find<UserController>();

  /// Sub-tab navigation index: 0 = ATTRIBUTES, 1 = SEJARAH
  final RxInt selectedTab = 0.obs;

  /// Reactive list of user's quest logs from Hive
  final RxList<QuestLogModel> questLogs = <QuestLogModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadQuestLogs();
    // Re-load logs whenever user profile updates
    ever(_userController.user, (_) => loadQuestLogs());
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }

  /// Loads quest logs from Hive for the active user, sorted descending by completion date
  void loadQuestLogs() {
    final activeUser = _userController.user.value;
    if (activeUser == null) {
      questLogs.clear();
      return;
    }

    final allLogs = HiveService.questLogsBox.values
        .where((log) => log.username == activeUser.username)
        .toList();

    allLogs.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    questLogs.assignAll(allLogs);
  }

  /// Permanently deletes a quest log from Hive and updates the reactive list
  Future<void> deleteQuestLog(String logId) async {
    await HiveService.questLogsBox.delete(logId);
    questLogs.removeWhere((log) => log.id == logId);

    if (Get.context != null) {
      try {
        Get.snackbar(
          'LOG PURGED',
          'Quest record removed from archive.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surfaceElevated,
          colorText: AppColors.textPrimary,
          borderColor: AppColors.primary,
          borderWidth: 1,
          duration: const Duration(seconds: 2),
        );
      } catch (_) {}
    }
  }

  // --- SEJARAH Aggregation Metrics ---

  UserModel? get currentUser => _userController.user.value;

  /// Longest streak in days
  int get longestStreak {
    final u = currentUser;
    if (u == null) return 0;
    return max(u.longestStreak, u.streakDays);
  }

  /// Total cardio distance covered in km
  double get totalCardioKm {
    double total = 0.0;
    for (final log in questLogs) {
      if (log.questType == 'cardio') {
        total += log.distanceKm;
      }
    }
    return total;
  }

  /// Total study duration in hours
  double get totalStudyHours {
    int totalMinutes = 0;
    for (final log in questLogs) {
      if (log.questType == 'study') {
        totalMinutes += log.durationMinutes;
      }
    }
    return totalMinutes / 60.0;
  }

  /// Total daily quests cleared
  int get totalQuestsCleared => questLogs.length;

  /// Cumulative reps per exercise for WORKOUT CUMULATIVE breakdown
  Map<String, int> get cumulativeWorkoutReps {
    final breakdown = <String, int>{
      'Push Ups': 0,
      'Squats': 0,
      'Sit Ups': 0,
      'Pull Ups': 0,
    };

    for (final log in questLogs) {
      if (log.questType == 'workout') {
        final exercise = log.exerciseName ?? '';
        final title = log.title;
        final reps = log.repsCount;

        if (exercise.toLowerCase().contains('push') ||
            title.toLowerCase().contains('push')) {
          breakdown['Push Ups'] = (breakdown['Push Ups'] ?? 0) + reps;
        } else if (exercise.toLowerCase().contains('squat') ||
            title.toLowerCase().contains('squat')) {
          breakdown['Squats'] = (breakdown['Squats'] ?? 0) + reps;
        } else if (exercise.toLowerCase().contains('sit') ||
            title.toLowerCase().contains('sit')) {
          breakdown['Sit Ups'] = (breakdown['Sit Ups'] ?? 0) + reps;
        } else if (exercise.toLowerCase().contains('pull') ||
            title.toLowerCase().contains('pull')) {
          breakdown['Pull Ups'] = (breakdown['Pull Ups'] ?? 0) + reps;
        }
      }
    }

    return breakdown;
  }

  /// Max reps among the 4 exercises (used for proportional bar widths)
  int get maxWorkoutReps {
    final reps = cumulativeWorkoutReps.values;
    if (reps.isEmpty) return 0;
    return reps.reduce(max);
  }

  /// Chronological list of growth snapshots: (dateString, totalStats)
  List<MapEntry<String, int>> get sortedGrowthSnapshots {
    final u = currentUser;
    if (u == null || u.growthSnapshots.isEmpty) {
      return [MapEntry(DateHelper.todayString(), u?.totalStats ?? 0)];
    }

    final entries = u.growthSnapshots.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  /// Rank chronicle list in reverse chronological order (highest active rank down to Novice)
  List<RankChronicleEntry> get rankChronicle {
    final u = currentUser;
    if (u == null) return [];

    // Order of ranks from Apostle to Novice
    const rankOrder = [
      'Apostle',
      'Preacher',
      'Saint',
      'Enlighted',
      'Rookie',
      'Beginner',
      'Novice',
    ];

    const rankTiers = {
      'Apostle': 'TIER SSS · SUPREME',
      'Preacher': 'TIER SS · ASCENDED',
      'Saint': 'TIER S · ASCENDED',
      'Enlighted': 'TIER A · VERIFIED',
      'Rookie': 'TIER B · AWAKENED',
      'Beginner': 'TIER C · INITIATED',
      'Novice': 'INITIATION ROOT',
    };

    final list = <RankChronicleEntry>[];
    final history = u.rankHistory;

    for (final rank in rankOrder) {
      if (history.containsKey(rank)) {
        final isCurrent = rank == u.rank;
        list.add(
          RankChronicleEntry(
            rank: rank,
            tierLabel: rankTiers[rank] ?? 'TIER UNKNOWN',
            dateAchieved: history[rank] ?? '',
            isCurrent: isCurrent,
          ),
        );
      }
    }

    return list;
  }
}

/// Data class representing a node in the Rank Chronicle timeline
class RankChronicleEntry {
  final String rank;
  final String tierLabel;
  final String dateAchieved;
  final bool isCurrent;

  const RankChronicleEntry({
    required this.rank,
    required this.tierLabel,
    required this.dateAchieved,
    required this.isCurrent,
  });
}
