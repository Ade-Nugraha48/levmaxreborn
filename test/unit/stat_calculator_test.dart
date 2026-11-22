import 'package:flutter_test/flutter_test.dart';
import 'package:levmaxreborn/core/utils/stat_calculator.dart';
import 'package:levmaxreborn/core/utils/date_helper.dart';

void main() {
  group('StatCalculator - Quadratic EXP Curve', () {
    test('targetExpForLevel calculates quadratic values matching PRD', () {
      expect(StatCalculator.targetExpForLevel(1), equals(100));
      expect(StatCalculator.targetExpForLevel(2), equals(250));
      expect(StatCalculator.targetExpForLevel(3), equals(450));
      expect(StatCalculator.targetExpForLevel(4), equals(700));
      expect(StatCalculator.targetExpForLevel(5), equals(1000));
      expect(StatCalculator.targetExpForLevel(10), equals(3250));
      expect(StatCalculator.targetExpForLevel(12), equals(4500));
    });
  });

  group('StatCalculator - Multi-Level Up (+2 to all 6 stats)', () {
    test('single level up gives +2 to all 6 stats and carries remainder EXP', () {
      final initialStats = {
        'STR': 10,
        'END': 10,
        'SPD': 10,
        'INT': 10,
        'WIL': 10,
        'APP': 10,
      };

      final result = StatCalculator.calculateLevelUp(
        currentLevel: 1,
        currentExp: 150, // 100 needed for Lv 2, 50 left over
        currentStats: initialStats,
      );

      expect(result.didLevelUp, isTrue);
      expect(result.newLevel, equals(2));
      expect(result.remainingExp, equals(50));
      expect(result.levelsGained, equals(1));

      // Each stat must increase by exactly +2
      expect(result.updatedStats['STR'], equals(12));
      expect(result.updatedStats['END'], equals(12));
      expect(result.updatedStats['SPD'], equals(12));
      expect(result.updatedStats['INT'], equals(12));
      expect(result.updatedStats['WIL'], equals(12));
      expect(result.updatedStats['APP'], equals(12));
    });

    test('multi level up advances through while loop with +2 per level gained', () {
      final initialStats = {
        'STR': 0,
        'END': 0,
        'SPD': 0,
        'INT': 0,
        'WIL': 0,
        'APP': 0,
      };

      // Lv 1->2 needs 100, Lv 2->3 needs 250. Total 350 EXP for Lv 3.
      final result = StatCalculator.calculateLevelUp(
        currentLevel: 1,
        currentExp: 375, // Reaches Lv 3 with 25 remainder
        currentStats: initialStats,
      );

      expect(result.newLevel, equals(3));
      expect(result.levelsGained, equals(2));
      expect(result.remainingExp, equals(25));

      // Gained 2 levels -> +4 to all 6 stats
      expect(result.updatedStats['STR'], equals(4));
      expect(result.updatedStats['END'], equals(4));
      expect(result.updatedStats['SPD'], equals(4));
      expect(result.updatedStats['INT'], equals(4));
      expect(result.updatedStats['WIL'], equals(4));
      expect(result.updatedStats['APP'], equals(4));
    });

    test('not enough EXP returns same level and stats', () {
      final initialStats = {'STR': 5, 'END': 5, 'SPD': 5, 'INT': 5, 'WIL': 5, 'APP': 5};
      final result = StatCalculator.calculateLevelUp(
        currentLevel: 1,
        currentExp: 80,
        currentStats: initialStats,
      );

      expect(result.didLevelUp, isFalse);
      expect(result.newLevel, equals(1));
      expect(result.remainingExp, equals(80));
      expect(result.levelsGained, equals(0));
      expect(result.updatedStats['STR'], equals(5));
    });
  });

  group('StatCalculator - Strata Tiers (E to SSS)', () {
    test('classifies stat values into correct Strata tiers', () {
      expect(StatCalculator.getStrata(0), equals('E'));
      expect(StatCalculator.getStrata(29), equals('E'));
      expect(StatCalculator.getStrata(30), equals('D'));
      expect(StatCalculator.getStrata(49), equals('D'));
      expect(StatCalculator.getStrata(50), equals('C'));
      expect(StatCalculator.getStrata(69), equals('C'));
      expect(StatCalculator.getStrata(70), equals('B'));
      expect(StatCalculator.getStrata(79), equals('B'));
      expect(StatCalculator.getStrata(80), equals('A'));
      expect(StatCalculator.getStrata(99), equals('A'));
      expect(StatCalculator.getStrata(100), equals('S'));
      expect(StatCalculator.getStrata(149), equals('S'));
      expect(StatCalculator.getStrata(150), equals('SS'));
      expect(StatCalculator.getStrata(199), equals('SS'));
      expect(StatCalculator.getStrata(200), equals('SSS'));
      expect(StatCalculator.getStrata(999), equals('SSS'));
    });
  });

  group('StatCalculator - 3-Day Inactivity Penalty', () {
    test('drops all 6 stats by 1 strata to lower upper bound', () {
      final prePenaltyStats = {
        'STR': 210, // SSS -> drops to SS upper bound (149)
        'END': 160, // SS -> drops to S upper bound (99)
        'SPD': 120, // S -> drops to A upper bound (79)
        'INT': 85,  // A -> drops to B upper bound (69)
        'WIL': 75,  // B -> drops to C upper bound (49)
        'APP': 40,  // D -> drops to E upper bound (29)
      };

      final penalized = StatCalculator.applyThreeDayPenalty(prePenaltyStats);

      expect(penalized['STR'], equals(199)); // SSS drops to SS upper bound: 199
      expect(penalized['END'], equals(149)); // SS drops to S upper bound: 149
      expect(penalized['SPD'], equals(99));  // S drops to A upper bound: 99
      expect(penalized['INT'], equals(79));  // A drops to B upper bound: 79
      expect(penalized['WIL'], equals(69));  // B drops to C upper bound: 69
      expect(penalized['APP'], equals(29));  // D drops to E upper bound: 29
    });

    test('strata E drops to 0', () {
      final stats = {'STR': 15, 'END': 0, 'SPD': 0, 'INT': 0, 'WIL': 0, 'APP': 0};
      final penalized = StatCalculator.applyThreeDayPenalty(stats);
      expect(penalized['STR'], equals(0));
    });
  });

  group('StatCalculator - Rank Progression (Novice to Apostle)', () {
    test('Novice for new account (0 stats)', () {
      final stats = {'STR': 0, 'END': 0, 'SPD': 0, 'INT': 0, 'WIL': 0, 'APP': 0};
      expect(StatCalculator.calculateRank(stats), equals('Novice'));
    });

    test('Beginner when total stats >= 100', () {
      final stats = {'STR': 20, 'END': 20, 'SPD': 20, 'INT': 20, 'WIL': 10, 'APP': 10};
      expect(StatCalculator.calculateRank(stats), equals('Beginner'));
    });

    test('Rookie when total stats >= 200', () {
      final stats = {'STR': 40, 'END': 40, 'SPD': 40, 'INT': 40, 'WIL': 20, 'APP': 20};
      expect(StatCalculator.calculateRank(stats), equals('Rookie'));
    });

    test('Enlighted when total stats >= 300', () {
      final stats = {'STR': 60, 'END': 60, 'SPD': 60, 'INT': 60, 'WIL': 30, 'APP': 30};
      expect(StatCalculator.calculateRank(stats), equals('Enlighted'));
    });

    test('Saint requires total >= 400 AND min 1 Stat S (>= 100)', () {
      // Total 400, but max stat is 90 (Strata A) -> stays Enlighted
      final noS = {'STR': 90, 'END': 90, 'SPD': 80, 'INT': 80, 'WIL': 30, 'APP': 30};
      expect(StatCalculator.calculateRank(noS), equals('Enlighted'));

      // Total 400 with STR = 100 (Strata S) -> Saint
      final withS = {'STR': 100, 'END': 80, 'SPD': 80, 'INT': 80, 'WIL': 30, 'APP': 30};
      expect(StatCalculator.calculateRank(withS), equals('Saint'));
    });

    test('Preacher requires total >= 600 AND min 1 Stat SS (>= 150)', () {
      // Total 600, with max stat 140 (Strata S) -> stays Saint
      final noSS = {'STR': 140, 'END': 120, 'SPD': 120, 'INT': 120, 'WIL': 50, 'APP': 50};
      expect(StatCalculator.calculateRank(noSS), equals('Saint'));

      // Total 600 with STR = 150 (Strata SS) -> Preacher
      final withSS = {'STR': 150, 'END': 110, 'SPD': 110, 'INT': 110, 'WIL': 60, 'APP': 60};
      expect(StatCalculator.calculateRank(withSS), equals('Preacher'));
    });

    test('Apostle requires total >= 900 AND min 1 Stat SSS (>= 200)', () {
      // Total 900 with max stat 190 (Strata SS) -> stays Preacher
      final noSSS = {'STR': 190, 'END': 180, 'SPD': 180, 'INT': 180, 'WIL': 85, 'APP': 85};
      expect(StatCalculator.calculateRank(noSSS), equals('Preacher'));

      // Total 900 with STR = 200 (Strata SSS) -> Apostle
      final withSSS = {'STR': 200, 'END': 175, 'SPD': 175, 'INT': 175, 'WIL': 90, 'APP': 85};
      expect(StatCalculator.calculateRank(withSSS), equals('Apostle'));
    });
  });

  group('StatCalculator - Cardio Pace & SPD Reward Calculation', () {
    test('calculateCardioSpdReward assigns rewards based on pace thresholds', () {
      expect(StatCalculator.calculateCardioSpdReward(10.5), equals(1)); // > 9.0 -> +1 SPD
      expect(StatCalculator.calculateCardioSpdReward(9.5), equals(1));  // > 9.0 -> +1 SPD
      expect(StatCalculator.calculateCardioSpdReward(8.5), equals(2));  // 7.0 - 9.0 -> +2 SPD
      expect(StatCalculator.calculateCardioSpdReward(7.0), equals(2));  // 7.0 - 9.0 -> +2 SPD
      expect(StatCalculator.calculateCardioSpdReward(6.2), equals(3));  // 5.5 - 6.99 -> +3 SPD
      expect(StatCalculator.calculateCardioSpdReward(5.5), equals(3));  // 5.5 - 6.99 -> +3 SPD
      expect(StatCalculator.calculateCardioSpdReward(4.8), equals(4));  // < 5.5 -> +4 SPD
      expect(StatCalculator.calculateCardioSpdReward(3.5), equals(4));  // < 5.5 -> +4 SPD
    });

    test('calculatePace computes minutes per km accurately', () {
      // 5 km in 25 mins (1500 secs) = 5.0 min/km
      final pace = StatCalculator.calculatePace(5.0, 1500);
      expect(pace, closeTo(5.0, 0.001));

      // 2 km in 12 mins (720 secs) = 6.0 min/km
      final pace2 = StatCalculator.calculatePace(2.0, 720);
      expect(pace2, closeTo(6.0, 0.001));
    });

    test('formatPace outputs readable string with zero-padded seconds', () {
      expect(StatCalculator.formatPace(5.5), equals('5:30 /km'));
      expect(StatCalculator.formatPace(4.05), equals('4:03 /km'));
      expect(StatCalculator.formatPace(0.0), equals('--:-- /km'));
    });
  });

  group('DateHelper Tests', () {
    test('daysBetween computes day differences accurately', () {
      expect(DateHelper.daysBetween('2026-11-20', '2026-11-22'), equals(2));
      expect(DateHelper.daysBetween('2026-11-22', '2026-11-22'), equals(0));
      expect(DateHelper.daysBetween('2026-11-22', '2026-11-21'), equals(-1));
    });

    test('isConsecutiveDay identifies consecutive dates', () {
      expect(DateHelper.isConsecutiveDay('2026-11-21', '2026-11-22'), isTrue);
      expect(DateHelper.isConsecutiveDay('2026-11-20', '2026-11-22'), isFalse);
    });
  });
}
