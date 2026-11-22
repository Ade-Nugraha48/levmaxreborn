import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/hive_boxes.dart';
import '../../core/utils/date_helper.dart';
import '../../model/quest_log_model.dart';
import '../../model/user_model.dart';
import '../../service/hive_service.dart';
import '../../service/session_service.dart';
import 'user_controller.dart';

/// Controller for Screen 5 & 6: Stats (Attributes & Sejarah)
class StatsController extends GetxController {
  static StatsController get to => Get.find<StatsController>();

  final UserController _userController = Get.find<UserController>();

  /// Sub-tab navigation index: 0 = ATTRIBUTES, 1 = SEJARAH
  final RxInt selectedTab = 0.obs;

  /// Reactive list of user's quest logs from Hive
  final RxList<QuestLogModel> questLogs = <QuestLogModel>[].obs;

  /// Reactive state for SEJARAH metrics (.obs / RxList / RxMap)
  final RxInt longestStreak = 0.obs;
  final RxDouble totalCardioKm = 0.0.obs;
  final RxDouble totalStudyHours = 0.0.obs;
  final RxInt totalQuestsCleared = 0.obs;
  final RxMap<String, int> cumulativeWorkoutReps = <String, int>{
    'Push Ups': 0,
    'Squats': 0,
    'Sit Ups': 0,
    'Pull Ups': 0,
  }.obs;
  final RxInt maxWorkoutReps = 0.obs;
  final RxList<MapEntry<String, int>> sortedGrowthSnapshots =
      <MapEntry<String, int>>[].obs;
  final RxList<RankChronicleEntry> rankChronicle =
      <RankChronicleEntry>[].obs;

  StreamSubscription? _questLogsSub;
  StreamSubscription? _usersSub;

  @override
  void onInit() {
    super.onInit();
    refreshStats();
    // Re-calculate whenever user profile updates in GetX
    ever(_userController.user, (_) => refreshStats());

    // Watch Hive box changes directly for real-time reactivity
    try {
      if (Hive.isBoxOpen(HiveBoxes.questLogs)) {
        _questLogsSub =
            HiveService.questLogsBox.watch().listen((_) => refreshStats());
      }
      if (Hive.isBoxOpen(HiveBoxes.users)) {
        _usersSub =
            HiveService.usersBox.watch().listen((_) => refreshStats());
      }
    } catch (_) {}
  }

  @override
  void onClose() {
    _questLogsSub?.cancel();
    _usersSub?.cancel();
    super.onClose();
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

  /// Recalculates and updates all reactive SEJARAH metrics and quest logs from Hive
  void refreshStats() {
    loadQuestLogs();

    final activeUser = _userController.user.value;
    if (activeUser == null) {
      longestStreak.value = 0;
      totalCardioKm.value = 0.0;
      totalStudyHours.value = 0.0;
      totalQuestsCleared.value = 0;
      cumulativeWorkoutReps.assignAll({
        'Push Ups': 0,
        'Squats': 0,
        'Sit Ups': 0,
        'Pull Ups': 0,
      });
      maxWorkoutReps.value = 0;
      sortedGrowthSnapshots.clear();
      rankChronicle.clear();
      return;
    }

    // 1. Longest Streak
    longestStreak.value = max(activeUser.longestStreak, activeUser.streakDays);

    final username = activeUser.username;

    // 2. Total Cardio KM
    double cardioDistFromLogs = 0.0;
    for (final log in questLogs) {
      if (log.questType == 'cardio') {
        cardioDistFromLogs += log.distanceKm;
      }
    }
    final historicalCardio = SessionService.getLifetimeCardioKm(username);
    final resolvedCardio = max(historicalCardio, cardioDistFromLogs);
    if (resolvedCardio > historicalCardio) {
      SessionService.setLifetimeCardioKm(username, resolvedCardio);
    }
    totalCardioKm.value = resolvedCardio;

    // 3. Total Study Hours
    int studyMinsFromLogs = 0;
    for (final log in questLogs) {
      if (log.questType == 'study') {
        studyMinsFromLogs += log.durationMinutes;
      }
    }
    final historicalStudyMins = SessionService.getLifetimeStudyMinutes(username);
    final resolvedStudyMins = max(historicalStudyMins, studyMinsFromLogs);
    if (resolvedStudyMins > historicalStudyMins) {
      SessionService.setLifetimeStudyMinutes(username, resolvedStudyMins);
    }
    totalStudyHours.value = resolvedStudyMins / 60.0;

    // 4. Quests Cleared
    final historicalQuests = SessionService.getLifetimeQuestsCleared(username);
    final resolvedQuests = max(historicalQuests, questLogs.length);
    if (resolvedQuests > historicalQuests) {
      SessionService.setLifetimeQuestsCleared(username, resolvedQuests);
    }
    totalQuestsCleared.value = resolvedQuests;

    // 5. Cumulative Workout Reps
    final repsFromLogs = <String, int>{
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
          repsFromLogs['Push Ups'] = (repsFromLogs['Push Ups'] ?? 0) + reps;
        } else if (exercise.toLowerCase().contains('squat') ||
            title.toLowerCase().contains('squat')) {
          repsFromLogs['Squats'] = (repsFromLogs['Squats'] ?? 0) + reps;
        } else if (exercise.toLowerCase().contains('sit') ||
            title.toLowerCase().contains('sit')) {
          repsFromLogs['Sit Ups'] = (repsFromLogs['Sit Ups'] ?? 0) + reps;
        } else if (exercise.toLowerCase().contains('pull') ||
            title.toLowerCase().contains('pull')) {
          repsFromLogs['Pull Ups'] = (repsFromLogs['Pull Ups'] ?? 0) + reps;
        }
      }
    }
    final mergedBreakdown = <String, int>{};
    for (final key in ['Push Ups', 'Squats', 'Sit Ups', 'Pull Ups']) {
      final historicalReps =
          SessionService.getLifetimeWorkoutReps(username, key);
      final resolvedReps = max(historicalReps, repsFromLogs[key] ?? 0);
      if (resolvedReps > historicalReps) {
        SessionService.setLifetimeWorkoutReps(username, key, resolvedReps);
      }
      mergedBreakdown[key] = resolvedReps;
    }
    cumulativeWorkoutReps.assignAll(mergedBreakdown);
    maxWorkoutReps.value =
        mergedBreakdown.values.isEmpty ? 0 : mergedBreakdown.values.reduce(max);

    // 6. Growth Snapshots
    if (activeUser.growthSnapshots.isEmpty) {
      sortedGrowthSnapshots.assignAll([
        MapEntry(DateHelper.todayString(), activeUser.totalStats),
      ]);
    } else {
      final entries = activeUser.growthSnapshots.entries.toList();
      entries.sort((a, b) => a.key.compareTo(b.key));
      sortedGrowthSnapshots.assignAll(entries);
    }

    // 7. Rank Chronicle
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
    final chronicleList = <RankChronicleEntry>[];
    for (final rank in rankOrder) {
      if (activeUser.rankHistory.containsKey(rank)) {
        chronicleList.add(
          RankChronicleEntry(
            rank: rank,
            tierLabel: rankTiers[rank] ?? 'TIER UNKNOWN',
            dateAchieved: activeUser.rankHistory[rank] ?? '',
            isCurrent: rank == activeUser.rank,
          ),
        );
      }
    }
    rankChronicle.assignAll(chronicleList);
  }

  /// Permanently deletes a quest log from Hive and updates the reactive list
  Future<void> deleteQuestLog(String logId) async {
    await HiveService.questLogsBox.delete(logId);
    refreshStats();

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

  UserModel? get currentUser => _userController.user.value;
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
