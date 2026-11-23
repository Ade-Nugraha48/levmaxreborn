import 'package:get/get.dart';
import '../model/user_model.dart';
import '../model/quest_log_model.dart';
import '../model/achievement_model.dart';
import '../service/hive_service.dart';
import '../service/session_service.dart';
import '../service/notification_service.dart';
import '../core/utils/stat_calculator.dart';
import '../core/utils/date_helper.dart';
import 'stats_controller.dart';

/// User Controller - Core Reactive Game State & Progression Engine
/// Manages User Profile, 6 Stats (STR, END, SPD, INT, WIL, APP), EXP Curve,
/// Multi-Level Up, Rank Progression, and Achievements.
class UserController extends GetxController {
  static UserController get to => Get.find<UserController>();

  final Rxn<UserModel> user = Rxn<UserModel>();

  UserModel? get currentUser => user.value;
  bool get hasUser => user.value != null;

  // Convenience reactive getters
  String get username => user.value?.username ?? '';
  int get level => user.value?.level ?? 1;
  int get exp => user.value?.exp ?? 0;
  int get hp => user.value?.hp ?? 100;
  int get strength => user.value?.strength ?? 0;
  int get endurance => user.value?.endurance ?? 0;
  int get speed => user.value?.speed ?? 0;
  int get intelligence => user.value?.intelligence ?? 0;
  int get willpower => user.value?.willpower ?? 0;
  int get appearance => user.value?.appearance ?? 0;
  int get streakDays => user.value?.streakDays ?? 0;
  int get longestStreak => user.value?.longestStreak ?? 0;
  String get rank => user.value?.rank ?? 'Novice';
  int get totalStats => user.value?.totalStats ?? 0;
  String get lastActiveDate => user.value?.lastActiveDate ?? '';
  String? get photoPath => user.value?.photoPath;

  Map<String, int> get statsMap => user.value?.statsMap ?? {
        'STR': 0,
        'END': 0,
        'SPD': 0,
        'INT': 0,
        'WIL': 0,
        'APP': 0,
      };

  /// Loads user from Hive users box
  void loadUser(String username) {
    final existingUser = HiveService.usersBox.get(username);
    if (existingUser != null) {
      user.value = existingUser;
    }
  }

  /// Saves current user changes to Hive box and refreshes reactive listeners
  Future<void> saveUser() async {
    if (user.value != null) {
      await user.value!.save();
      user.refresh();
    }
  }

  /// Applies rewards from completing a quest
  /// 1. Adds stat rewards directly
  /// 2. Adds EXP gained
  /// 3. Checks Level Up via quadratic formula (with while loop for multi-level up)
  /// 4. Checks Rank progression and records in rankHistory
  /// 5. Records growth trajectory snapshot
  Future<LevelUpResult> applyQuestReward({
    required int expGained,
    Map<String, int>? statRewards,
  }) async {
    final u = user.value;
    if (u == null) {
      return const LevelUpResult(
        newLevel: 1,
        remainingExp: 0,
        levelsGained: 0,
        updatedStats: {},
      );
    }

    final oldRank = u.rank;

    // 1. Tambah poin atribut langsung dari reward quest (misal: Workout nambah STR & END)
    if (statRewards != null) {
      u.strength += statRewards['STR'] ?? 0;
      u.endurance += statRewards['END'] ?? 0;
      u.speed += statRewards['SPD'] ?? 0;
      u.intelligence += statRewards['INT'] ?? 0;
      u.willpower += statRewards['WIL'] ?? 0;
      u.appearance += statRewards['APP'] ?? 0;
    }

    // 2. Tambah EXP dari quest
    final totalExp = u.exp + expGained;

    // 3. Cek apakah EXP cukup buat naik level (pakai rumus kuadratik)
    final levelUpResult = StatCalculator.calculateLevelUp(
      currentLevel: u.level,
      currentExp: totalExp,
      currentStats: u.statsMap,
    );

    if (levelUpResult.didLevelUp) {
      u.level = levelUpResult.newLevel;
      u.exp = levelUpResult.remainingExp;

      // Bonus naik level: otomatis nambah +2 ke semua 6 atribut stat
      u.strength = levelUpResult.updatedStats['STR'] ?? u.strength;
      u.endurance = levelUpResult.updatedStats['END'] ?? u.endurance;
      u.speed = levelUpResult.updatedStats['SPD'] ?? u.speed;
      u.intelligence = levelUpResult.updatedStats['INT'] ?? u.intelligence;
      u.willpower = levelUpResult.updatedStats['WIL'] ?? u.willpower;
      u.appearance = levelUpResult.updatedStats['APP'] ?? u.appearance;

      await NotificationService.showLevelUp(newLevel: levelUpResult.newLevel);
    } else {
      u.exp = totalExp;
    }

    // 4. Cek kenaikan rank (Novice -> Awakened -> Pioneer -> Ascendant -> Preacher -> Apostle)
    final newRank = u.rank;
    if (!u.rankHistory.containsKey(newRank)) {
      u.rankHistory[newRank] = DateHelper.todayString();
      if (newRank != oldRank) {
        await NotificationService.showRankUp(newRank: newRank);
      }
    }

    // 5. Catat titik grafik pertumbuhan hari ini buat grafik di tab Sejarah
    final today = DateHelper.todayString();
    u.growthSnapshots[today] = u.totalStats;

    await saveUser();
    user.refresh();

    if (Get.isRegistered<StatsController>()) {
      StatsController.to.refreshStats();
    }
    return levelUpResult;
  }

  /// Unlocks an achievement if not already unlocked
  /// Returns true if newly unlocked
  Future<bool> unlockAchievement(String achievementId) async {
    final u = user.value;
    if (u == null) return false;

    if (!u.unlockedAchievements.containsKey(achievementId)) {
      u.unlockedAchievements[achievementId] = DateHelper.todayString();
      await saveUser();
      return true;
    }
    return false;
  }

  /// Evaluates all 8 achievements against current user and logs, unlocking any newly eligible
  Future<List<String>> checkAchievements(List<QuestLogModel> logs) async {
    final u = user.value;
    if (u == null) return [];

    final newlyUnlocked = <String>[];
    final evaluated = AchievementModel.evaluateAll(user: u, logs: logs);

    for (final ach in evaluated) {
      if (!ach.isUnlocked && ach.currentProgress >= ach.targetValue && ach.targetValue > 0) {
        final success = await unlockAchievement(ach.id);
        if (success) {
          newlyUnlocked.add(ach.title);
          await NotificationService.showAchievementUnlocked(
            achievementTitle: ach.title,
          );
        }
      }
    }
    return newlyUnlocked;
  }

  /// Applies 3-day inactivity penalty: stats drop 1 strata, rank recalculates, HP resets to 100
  Future<void> applyThreeDayPenalty() async {
    final u = user.value;
    if (u == null) return;

    // Penalti bolos 3 hari: kurangi 5 poin di setiap atribut stat
    final penalized = StatCalculator.applyThreeDayPenalty(u.statsMap);
    u.strength = penalized['STR'] ?? 0;
    u.endurance = penalized['END'] ?? 0;
    u.speed = penalized['SPD'] ?? 0;
    u.intelligence = penalized['INT'] ?? 0;
    u.willpower = penalized['WIL'] ?? 0;
    u.appearance = penalized['APP'] ?? 0;

    // Reset HP balik ke 100 dan streak diputus jadi 0
    u.hp = 100;
    u.streakDays = 0;

    // Update snapshot grafik pertumbuhan hari ini dengan stat yang sudah dipotong
    final today = DateHelper.todayString();
    u.growthSnapshots[today] = u.totalStats;

    await saveUser();
    user.refresh();

    if (Get.isRegistered<StatsController>()) {
      StatsController.to.refreshStats();
    }
  }

  /// Deducts HP (Developer Demo Mode simulation for 1 missed day: -34 HP)
  Future<void> deductHp(int amount) async {
    final u = user.value;
    if (u == null) return;

    final newHp = (u.hp - amount).clamp(0, 100);
    if (newHp <= 0) {
      await applyThreeDayPenalty();
    } else {
      u.hp = newHp;
      u.streakDays = 0;
      await saveUser();
      user.refresh();
    }
  }

  /// Restores user HP to 100 (Developer Demo Mode)
  Future<void> restoreHp() async {
    final u = user.value;
    if (u == null) return;
    u.hp = 100;
    await saveUser();
    user.refresh();
  }

  /// Adds EXP directly (e.g. for Developer Demo Mode)
  Future<LevelUpResult> addExp(int expToAdd) async {
    return applyQuestReward(expGained: expToAdd);
  }

  /// Adds bonus points to all 6 core attributes (Developer Demo Mode)
  Future<void> addStatsToAll(int amount) async {
    final u = user.value;
    if (u == null) return;

    final oldRank = u.rank;
    u.strength += amount;
    u.endurance += amount;
    u.speed += amount;
    u.intelligence += amount;
    u.willpower += amount;
    u.appearance += amount;

    final newRank = u.rank;
    if (!u.rankHistory.containsKey(newRank)) {
      u.rankHistory[newRank] = DateHelper.todayString();
      if (newRank != oldRank) {
        await NotificationService.showRankUp(newRank: newRank);
      }
    }

    final today = DateHelper.todayString();
    u.growthSnapshots[today] = u.totalStats;

    await saveUser();
    user.refresh();

    if (Get.isRegistered<StatsController>()) {
      StatsController.to.refreshStats();
    }
  }

  /// Updates user profile details (photo, username, password)
  Future<void> updateProfile({
    String? photoPath,
    String? newUsername,
    String? newPassword,
  }) async {
    final u = user.value;
    if (u == null) return;

    if (photoPath != null) {
      u.photoPath = photoPath;
    }
    if (newPassword != null && newPassword.isNotEmpty) {
      u.password = newPassword;
    }
    if (newUsername != null && newUsername.isNotEmpty && newUsername != u.username) {
      // Re-key in Hive if username changed
      await HiveService.usersBox.delete(u.username);
      u.username = newUsername;
      await HiveService.usersBox.put(newUsername, u);
      await SessionService.setActiveUsername(newUsername);
    } else {
      await saveUser();
    }
    user.refresh();
    await NotificationService.showProfileUpdated(
      username: newUsername ?? u.username,
    );
  }
}
