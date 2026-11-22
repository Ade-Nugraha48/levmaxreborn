/// Level up result container
class LevelUpResult {
  final int newLevel;
  final int remainingExp;
  final int levelsGained;
  final Map<String, int> updatedStats;

  const LevelUpResult({
    required this.newLevel,
    required this.remainingExp,
    required this.levelsGained,
    required this.updatedStats,
  });

  bool get didLevelUp => levelsGained > 0;
}

/// Pure Game Logic & Stat Calculator
/// Single source of truth for EXP quadratic curve, Rank progression, Strata, and Penalties.
/// Conforms to `docs/prd.md`.
class StatCalculator {
  StatCalculator._();

  /// Target EXP to advance from currentLevel to (currentLevel + 1)
  /// Formula: (100 * level) + (25 * level * (level - 1))
  static int targetExpForLevel(int currentLevel) {
    if (currentLevel < 1) return 100;
    return (100 * currentLevel) + (25 * currentLevel * (currentLevel - 1));
  }

  /// Calculates potential level-ups with quadratic curve.
  /// Supports multi-level up via while loop.
  /// Each level gained adds +2 to ALL 6 stats (STR, END, SPD, INT, WIL, APP).
  static LevelUpResult calculateLevelUp({
    required int currentLevel,
    required int currentExp,
    required Map<String, int> currentStats,
  }) {
    int level = currentLevel;
    int exp = currentExp;
    int levelsGained = 0;
    final stats = Map<String, int>.from(currentStats);

    // Ensure all 6 stat keys exist
    for (final key in ['STR', 'END', 'SPD', 'INT', 'WIL', 'APP']) {
      stats.putIfAbsent(key, () => 0);
    }

    while (exp >= targetExpForLevel(level)) {
      exp -= targetExpForLevel(level);
      level += 1;
      levelsGained += 1;

      // Overall Stat Boost: +2 to all 6 stats per level
      for (final key in ['STR', 'END', 'SPD', 'INT', 'WIL', 'APP']) {
        stats[key] = (stats[key] ?? 0) + 2;
      }
    }

    return LevelUpResult(
      newLevel: level,
      remainingExp: exp,
      levelsGained: levelsGained,
      updatedStats: stats,
    );
  }

  /// Returns Strata tier string ('SSS', 'SS', 'S', 'A', 'B', 'C', 'D', 'E')
  static String getStrata(int statValue) {
    if (statValue >= 200) return 'SSS';
    if (statValue >= 150) return 'SS';
    if (statValue >= 100) return 'S';
    if (statValue >= 80) return 'A';
    if (statValue >= 70) return 'B';
    if (statValue >= 50) return 'C';
    if (statValue >= 30) return 'D';
    return 'E';
  }

  /// Returns upper bound target for penalty when dropping 1 strata
  /// SSS→199, SS→149, S→99, A→79, B→69, C→49, D→29, E→0
  static int getPenaltyTarget(int statValue) {
    final strata = getStrata(statValue);
    switch (strata) {
      case 'SSS':
        return 199;
      case 'SS':
        return 149;
      case 'S':
        return 99;
      case 'A':
        return 79;
      case 'B':
        return 69;
      case 'C':
        return 49;
      case 'D':
        return 29;
      case 'E':
      default:
        return 0;
    }
  }

  /// Applies 3-day inactivity penalty: all 6 stats drop 1 strata to lower upper bound
  static Map<String, int> applyThreeDayPenalty(Map<String, int> currentStats) {
    final newStats = <String, int>{};
    for (final key in ['STR', 'END', 'SPD', 'INT', 'WIL', 'APP']) {
      final val = currentStats[key] ?? 0;
      newStats[key] = getPenaltyTarget(val);
    }
    return newStats;
  }

  /// Calculates Rank title based on Total Stats & Strata requirements
  static String calculateRank(Map<String, int> stats) {
    int total = 0;
    bool hasSSS = false;
    bool hasSS = false;
    bool hasS = false;

    for (final key in ['STR', 'END', 'SPD', 'INT', 'WIL', 'APP']) {
      final val = stats[key] ?? 0;
      total += val;
      if (val >= 200) hasSSS = true;
      if (val >= 150) hasSS = true;
      if (val >= 100) hasS = true;
    }

    if (total >= 900 && hasSSS) return 'Apostle';
    if (total >= 600 && hasSS) return 'Preacher';
    if (total >= 400 && hasS) return 'Saint';
    if (total >= 300) return 'Enlighted';
    if (total >= 200) return 'Rookie';
    if (total >= 100) return 'Beginner';
    return 'Novice';
  }

  /// Returns total of all 6 attributes
  static int totalStats(Map<String, int> stats) {
    int total = 0;
    for (final key in ['STR', 'END', 'SPD', 'INT', 'WIL', 'APP']) {
      total += stats[key] ?? 0;
    }
    return total;
  }

  /// Calculates SPD reward from Cardio average pace (minutes per km)
  /// Pace > 9.0 -> +1 SPD
  /// Pace 7.0 - 9.0 -> +2 SPD
  /// Pace 5.5 - 6.99 -> +3 SPD
  /// Pace < 5.5 -> +4 SPD
  static int calculateCardioSpdReward(double paceMinPerKm) {
    if (paceMinPerKm <= 0 || paceMinPerKm.isInfinite || paceMinPerKm.isNaN) {
      return 1;
    }
    if (paceMinPerKm < 5.5) return 4;
    if (paceMinPerKm < 7.0) return 3;
    if (paceMinPerKm <= 9.0) return 2;
    return 1;
  }

  /// Calculates Pace in minutes per km
  static double calculatePace(double distanceKm, int durationSeconds) {
    if (distanceKm <= 0.01 || durationSeconds <= 0) return 0.0;
    final minutes = durationSeconds / 60.0;
    return minutes / distanceKm;
  }

  /// Formats pace as m:ss /km
  static String formatPace(double paceMinPerKm) {
    if (paceMinPerKm <= 0 || paceMinPerKm.isInfinite || paceMinPerKm.isNaN) {
      return '--:-- /km';
    }
    final minutes = paceMinPerKm.floor();
    final seconds = ((paceMinPerKm - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
  }
}
