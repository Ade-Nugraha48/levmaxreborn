import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/game_config.dart';
import '../core/utils/date_helper.dart';
import '../core/utils/stat_calculator.dart';
import '../model/daily_quest_state_model.dart';
import '../model/quest_log_model.dart';
import '../routes/app_routes.dart';
import '../service/hive_service.dart';
import '../service/notification_service.dart';
import 'navigation_controller.dart';
import 'user_controller.dart';
import 'stats_controller.dart';

/// Quest Completion Result Container
class QuestCompletionResult {
  final LevelUpResult levelUpResult;
  final bool fullClearAchieved;
  final int expGained;
  final Map<String, int> statRewards;
  final List<String> newAchievements;

  const QuestCompletionResult({
    required this.levelUpResult,
    required this.fullClearAchieved,
    required this.expGained,
    required this.statRewards,
    this.newAchievements = const [],
  });
}

/// Quest Type Enumeration
enum QuestType { workout, study, cardio, grooming }

/// Separated Reward Badge Data Object
class QuestRewardBadge {
  final String label;
  final Color color;

  const QuestRewardBadge({
    required this.label,
    required this.color,
  });
}

/// Unified Quest Display Data for Home HUD & Quest Cards
class QuestItemData {
  final String id;
  final String title;
  final String subtitle;
  final bool isDone;
  final List<QuestRewardBadge> rewardBadges;
  final QuestType type;
  final int workoutIndex;
  final String route;
  final dynamic routeArguments;

  const QuestItemData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.rewardBadges,
    required this.type,
    this.workoutIndex = 0,
    required this.route,
    this.routeArguments,
  });
}

/// Quest Controller - Manages Daily Reset, Workout Rotation,
/// Active-First Quest Sorting, HP & Inactivity Penalty Checks, and Countdown Timer.
/// Conforms to `docs/user_flow.md` and `docs/design_blueprint.md`.
class QuestController extends GetxController {
  static QuestController get to => Get.find<QuestController>();

  final Rxn<DailyQuestStateModel> dailyQuest = Rxn<DailyQuestStateModel>();
  final RxString resetCountdown = 'RESET 00:00:00'.obs;
  final RxBool hasHpWarning = false.obs;
  final RxBool hasPenaltyNotice = false.obs;
  int hpDeductionAmount = 0;

  Timer? _countdownTimer;

  @override
  void onInit() {
    super.onInit();
    runDailyResetCheck();
    _startCountdownTimer();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }

  /// Calculates dynamic countdown until midnight (00:00:00)
  void _startCountdownTimer() {
    _updateCountdownString();
    if (Get.testMode) return;
    _countdownTimer?.cancel();
    // Update sisa waktu mundur setiap detik
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdownString();
    });
  }

  void _updateCountdownString() {
    // Hitung selisih waktu dari detik sekarang menuju jam 00:00 tengah malam
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final remaining = tomorrow.difference(now);
    final h = remaining.inHours.toString().padLeft(2, '0');
    final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    resetCountdown.value = 'RESET $h:$m:$s';
  }

  /// Executes daily reset check comparing current date with user's lastActiveDate
  /// Follows specification in `docs/user_flow.md` Section 2.
  Future<void> runDailyResetCheck() async {
    final user = UserController.to.currentUser;
    if (user == null) return;

    final today = DateHelper.todayString();

    if (user.lastActiveDate.isEmpty) {
      // User baru registrasi atau pertama kali buka app
      user.lastActiveDate = today;
      final initialExercises = [
        GameConfig.workoutExercises[0],
        GameConfig.workoutExercises[2],
      ];
      final state = DailyQuestStateModel(
        username: user.username,
        date: today,
        workoutExercises: initialExercises,
      );
      await HiveService.dailyQuestStatesBox.put('${user.username}_$today', state);
      dailyQuest.value = state;
      await UserController.to.saveUser();
      return;
    }

    // Hitung berapa hari user gak login / selisih hari dari terakhir aktif
    final deltaDays = DateHelper.daysBetween(user.lastActiveDate, today);

    if (deltaDays == 0) {
      // Masih di hari yang sama: langsung buka quest harian yang sudah ada
      var state =
          HiveService.dailyQuestStatesBox.get('${user.username}_$today');
      if (state == null) {
        state = DailyQuestStateModel(
          username: user.username,
          date: today,
          workoutExercises: [
            GameConfig.workoutExercises[0],
            GameConfig.workoutExercises[2],
          ],
        );
        await HiveService.dailyQuestStatesBox.put('${user.username}_$today', state);
      }
      dailyQuest.value = state;
    } else {
      // deltaDays >= 1: ganti hari, evaluasi streak, pengurangan HP, atau penalti
      if (deltaDays == 1) {
        // Cek apakah kemarin nyelesaiin minimal 1 quest
        final yesterday = DateHelper.formatDate(
            DateHelper.parseDate(today).subtract(const Duration(days: 1)));
        final yesterdayState =
            HiveService.dailyQuestStatesBox.get('${user.username}_$yesterday');
        final bool hadCompletedQuest =
            yesterdayState != null && yesterdayState.completedCount >= 1;

        if (hadCompletedQuest) {
          user.streakDays += 1;
          if (user.streakDays > user.longestStreak) {
            user.longestStreak = user.streakDays;
          }
          // Reward login berturut-turut: +1 Willpower (WIL)
          user.willpower += 1;
          // Bonus tambahan setiap streak 7 hari berturut-turut
          if (user.streakDays > 0 && user.streakDays % 7 == 0) {
            user.willpower += 1;
          }
        } else {
          // Kemarin gak ada quest beres, streak hangus jadi 0
          user.streakDays = 0;
        }
      } else if (deltaDays == 2) {
        // Bolos 1 hari penuh: HP dipotong 34 poin, streak putus
        user.hp = (user.hp - GameConfig.dailyHpDeduction).clamp(0, 100);
        user.streakDays = 0;
        hasHpWarning.value = true;
        hpDeductionAmount = GameConfig.dailyHpDeduction;
      } else {
        // Bolos 3 hari atau lebih: picu penalti berat (HP habis, turun rank, stat minus)
        user.hp = 0;
        await UserController.to.applyThreeDayPenalty();
        hasPenaltyNotice.value = true;
      }

      // Rotasi 2 jenis gerakan workout agar beda dari gerakan kemarin
      final List<String> previousExercises = dailyQuest.value?.workoutExercises ??
          [GameConfig.workoutExercises[0], GameConfig.workoutExercises[2]];

      final rotatedExercises = GameConfig.workoutExercises
          .where((ex) => !previousExercises.contains(ex))
          .take(2)
          .toList();

      if (rotatedExercises.length < 2) {
        rotatedExercises.clear();
        rotatedExercises.addAll([
          GameConfig.workoutExercises[1],
          GameConfig.workoutExercises[3],
        ]);
      }

      // Buat state quest baru untuk hari ini di Hive
      final newState = DailyQuestStateModel(
        username: user.username,
        date: today,
        workoutExercises: rotatedExercises,
        workoutCompleted: [false, false],
        studyCompleted: false,
        cardioCompleted: false,
        groomingCompleted: false,
        fullClearClaimed: false,
      );
      await HiveService.dailyQuestStatesBox.put('${user.username}_$today', newState);
      dailyQuest.value = newState;

      // Reset centang grooming harian milik user
      for (final item in HiveService.groomingItemsBox.values) {
        if (item.username == user.username && item.isChecked) {
          item.isChecked = false;
          await item.save();
        }
      }

      // Simpan riwayat grafik pertumbuhan hari ini dan perbarui tanggal terakhir aktif
      user.growthSnapshots[today] = user.totalStats;
      user.lastActiveDate = today;
      await UserController.to.saveUser();
    }

    UserController.to.user.refresh();
    dailyQuest.refresh();
  }

  /// Total count of completed quests today (0 to 5)
  int get completedCount => dailyQuest.value?.completedCount ?? 0;

  /// Whether all 5 quests are completed today
  bool get isAllCompleted => dailyQuest.value?.isAllCompleted ?? false;

  /// Active-first sorted quests getter:
  /// Active quests (!isDone) are sorted to the top with broken-white stick bar,
  /// completed quests (isDone) sink to the bottom with dimmed grey styling.
  List<QuestItemData> get sortedQuests {
    final state = dailyQuest.value;
    final user = UserController.to.currentUser;
    final rank = user?.rank ?? 'Novice';
    final rankTarget =
        GameConfig.rankTargets[rank] ?? GameConfig.rankTargets['Novice']!;

    final exercises = (state != null && state.workoutExercises.isNotEmpty)
        ? state.workoutExercises
        : [GameConfig.workoutExercises[0], GameConfig.workoutExercises[2]];

    final ex0 = exercises[0];
    final ex1 = exercises.length > 1 ? exercises[1] : GameConfig.workoutExercises[1];

    final reps0 = rankTarget.repsPerExercise[ex0] ?? 10;
    final reps1 = rankTarget.repsPerExercise[ex1] ?? 15;

    final bool workout0Done =
        state != null && state.workoutCompleted.isNotEmpty && state.workoutCompleted[0];
    final bool workout1Done =
        state != null && state.workoutCompleted.length > 1 && state.workoutCompleted[1];
    final bool studyDone = state?.studyCompleted ?? false;
    final bool cardioDone = state?.cardioCompleted ?? false;
    final bool groomingDone = state?.groomingCompleted ?? false;

    final int studyIntReward = (rank == 'Apostle') ? 4 : 3;

    final allQuests = [
      // 1. Workout Quest 1
      QuestItemData(
        id: 'workout_0',
        title: ex0,
        subtitle: '${rankTarget.workoutSets} Sets × $reps0 Reps',
        isDone: workout0Done,
        rewardBadges: const [
          QuestRewardBadge(label: '+2 STR', color: AppColors.str),
          QuestRewardBadge(label: '+1 END', color: AppColors.end),
        ],
        type: QuestType.workout,
        workoutIndex: 0,
        route: AppRoutes.workoutDetail,
        routeArguments: {'exercise': ex0, 'exerciseIndex': 0},
      ),
      // 2. Workout Quest 2
      QuestItemData(
        id: 'workout_1',
        title: ex1,
        subtitle: '${rankTarget.workoutSets} Sets × $reps1 Reps',
        isDone: workout1Done,
        rewardBadges: const [
          QuestRewardBadge(label: '+2 STR', color: AppColors.str),
          QuestRewardBadge(label: '+1 END', color: AppColors.end),
        ],
        type: QuestType.workout,
        workoutIndex: 1,
        route: AppRoutes.workoutDetail,
        routeArguments: {'exercise': ex1, 'exerciseIndex': 1},
      ),
      // 3. Study Lock-In
      QuestItemData(
        id: 'study',
        title: 'Lock-In Study',
        subtitle: '${rankTarget.studyDurationMinutes} Minutes Deep Terminal',
        isDone: studyDone,
        rewardBadges: [
          QuestRewardBadge(
            label: '+$studyIntReward INT',
            color: AppColors.intel,
          ),
        ],
        type: QuestType.study,
        route: AppRoutes.studyDetail,
      ),
      // 4. Cardio Run
      QuestItemData(
        id: 'cardio',
        title: 'Cardio Run',
        subtitle:
            '${rankTarget.cardioDistanceKm.toStringAsFixed(1)} km Target Velocity',
        isDone: cardioDone,
        rewardBadges: const [
          QuestRewardBadge(label: '+2 END', color: AppColors.end),
          QuestRewardBadge(label: '+1 SPD', color: AppColors.spd), // ALWAYS SPD!
        ],
        type: QuestType.cardio,
        route: AppRoutes.main, // Handled by NavigationController Tab 1
      ),
      // 5. Daily Grooming
      QuestItemData(
        id: 'grooming',
        title: 'Daily Grooming',
        subtitle: '${rankTarget.minGroomingItems} Items Protocol Minimum',
        isDone: groomingDone,
        rewardBadges: const [
          QuestRewardBadge(label: '+3 APP', color: AppColors.app),
        ],
        type: QuestType.grooming,
        route: AppRoutes.groomingDetail,
      ),
    ];

    // Partition: Active quests first, Completed (DONE) quests at the bottom
    final active = allQuests.where((q) => !q.isDone).toList();
    final completed = allQuests.where((q) => q.isDone).toList();

    return [...active, ...completed];
  }

  /// Dispatches navigation based on quest card tap
  void handleQuestTap(QuestItemData quest) {
    if (quest.type == QuestType.cardio) {
      NavigationController.to.switchToMap();
    } else {
      Get.toNamed(quest.route, arguments: quest.routeArguments);
    }
  }

  /// Completes a quest according to `docs/user_flow.md` Section 4
  /// 1. Adds stat rewards and EXP
  /// 2. Saves QuestLogModel to Hive
  /// 3. Marks quest complete in DailyQuestStateModel and checks Full Clear
  /// 4. Executes Level Up (+2 all stats) and Rank Up progression
  /// 5. Evaluates Achievements
  /// 6. Returns QuestCompletionResult
  Future<QuestCompletionResult> completeQuest({
    required QuestType type,
    String? exerciseName,
    int? workoutIndex,
    int repsCount = 0,
    int durationMinutes = 0,
    double distanceKm = 0.0,
    double paceMinPerKm = 0.0,
  }) async {
    final user = UserController.to.currentUser;
    if (user == null) {
      return const QuestCompletionResult(
        levelUpResult: LevelUpResult(
          newLevel: 1,
          remainingExp: 0,
          levelsGained: 0,
          updatedStats: {},
        ),
        fullClearAchieved: false,
        expGained: 0,
        statRewards: {},
      );
    }

    String title = '';
    String metricSummary = '';
    final Map<String, int> statRewards = {};
    int expGained = GameConfig.expPerQuest; // 25

    switch (type) {
      case QuestType.workout:
        // Guard clause: strictly require full target reps completed before awarding quest
        final rank = user.rank;
        final rankTarget =
            GameConfig.rankTargets[rank] ?? GameConfig.rankTargets['Novice']!;
        final minTargetReps = rankTarget.repsPerExercise[exerciseName] ?? 8;
        if (repsCount < minTargetReps) {
          return const QuestCompletionResult(
            levelUpResult: LevelUpResult(
              newLevel: 1,
              remainingExp: 0,
              levelsGained: 0,
              updatedStats: {},
            ),
            fullClearAchieved: false,
            expGained: 0,
            statRewards: {},
          );
        }

        title = exerciseName ?? 'Push Ups';
        metricSummary = '$repsCount REPS · BODYWEIGHT';
        statRewards['STR'] = 2;
        statRewards['END'] = 1;
        if (workoutIndex != null &&
            dailyQuest.value != null &&
            workoutIndex < dailyQuest.value!.workoutCompleted.length) {
          dailyQuest.value!.workoutCompleted[workoutIndex] = true;
        }
        break;

      case QuestType.study:
        title = 'Lock-In Study';
        metricSummary = '$durationMinutes MINS FOCUS';
        final int intReward = (user.rank == 'Apostle') ? 4 : 3;
        statRewards['INT'] = intReward;
        if (dailyQuest.value != null) {
          dailyQuest.value!.studyCompleted = true;
        }
        break;

      case QuestType.cardio:
        // Guard clause: strictly require full target distance and duration before awarding quest
        final rank = user.rank;
        final rankTarget =
            GameConfig.rankTargets[rank] ?? GameConfig.rankTargets['Novice']!;
        final minTargetKm = rankTarget.cardioDistanceKm;
        if (distanceKm < minTargetKm || (durationMinutes <= 0 && paceMinPerKm <= 0)) {
          return const QuestCompletionResult(
            levelUpResult: LevelUpResult(
              newLevel: 1,
              remainingExp: 0,
              levelsGained: 0,
              updatedStats: {},
            ),
            fullClearAchieved: false,
            expGained: 0,
            statRewards: {},
          );
        }

        title = 'Cardio Run';
        final int spdReward = StatCalculator.calculateCardioSpdReward(paceMinPerKm);
        final String paceStr = StatCalculator.formatPace(paceMinPerKm);
        metricSummary = '${distanceKm.toStringAsFixed(2)} KM · $paceStr';
        statRewards['END'] = 2;
        statRewards['SPD'] = spdReward;
        if (dailyQuest.value != null) {
          dailyQuest.value!.cardioCompleted = true;
        }
        break;

      case QuestType.grooming:
        title = 'Daily Grooming';
        metricSummary = '$repsCount ITEMS PROTOCOL';
        statRewards['APP'] = 3;
        if (dailyQuest.value != null) {
          dailyQuest.value!.groomingCompleted = true;
        }
        break;
    }

    // Check Full Clear (5/5 completed)
    bool fullClearAchieved = false;
    if (dailyQuest.value != null) {
      if (dailyQuest.value!.completedCount == 5 &&
          !dailyQuest.value!.fullClearClaimed) {
        dailyQuest.value!.fullClearClaimed = true;
        fullClearAchieved = true;
        expGained += GameConfig.fullClearBonusExp; // +50 EXP
        statRewards['WIL'] = (statRewards['WIL'] ?? 0) + 2; // +2 WIL
      }
      if (dailyQuest.value!.isInBox) {
        await dailyQuest.value!.save();
      } else {
        final boxKey = '${dailyQuest.value!.username}_${dailyQuest.value!.date}';
        await HiveService.dailyQuestStatesBox.put(boxKey, dailyQuest.value!);
      }
    }

    // Process Level Up & Progression
    final levelUpResult = await UserController.to.applyQuestReward(
      expGained: expGained,
      statRewards: statRewards,
    );

    // Simpan riwayat quest ke Hive questLogsBox buat arsip dan tab Sejarah
    final log = QuestLogModel(
      id: '${user.username}_${DateTime.now().millisecondsSinceEpoch}',
      username: user.username,
      questType: type.name,
      title: title.toUpperCase(),
      completedAt: DateTime.now(),
      expGained: expGained,
      statRewards: statRewards,
      metricSummary: metricSummary,
      exerciseName: exerciseName,
      repsCount: repsCount,
      durationMinutes: durationMinutes,
      distanceKm: distanceKm,
      paceMinPerKm: paceMinPerKm,
    );
    await HiveService.questLogsBox.put(log.id, log);

    // Refresh data statistik di tab Sejarah & Attributes secara real-time
    if (Get.isRegistered<StatsController>()) {
      StatsController.to.refreshStats();
    }

    // Cek apakah ada badge achievement baru yang terbuka
    final userLogs = HiveService.questLogsBox.values
        .where((l) => l.username == user.username)
        .toList();
    final newAchievements =
        await UserController.to.checkAchievements(userLogs);

    // Tampilkan notifikasi lokal di status bar HP kalau quest berhasil selesai
    await NotificationService.showQuestCompleted(
      questTitle: title,
      expGained: expGained,
    );

    // Refresh UI
    dailyQuest.refresh();

    return QuestCompletionResult(
      levelUpResult: levelUpResult,
      fullClearAchieved: fullClearAchieved,
      expGained: expGained,
      statRewards: statRewards,
      newAchievements: newAchievements,
    );
  }
}
