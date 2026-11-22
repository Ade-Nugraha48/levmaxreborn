/// Definition for Rank Progressive Overload targets
class RankOverloadTarget {
  final String rank;
  final int workoutSets;
  final Map<String, int> repsPerExercise; // Push Ups, Pull Ups, Squats, Sit Ups
  final double cardioDistanceKm;
  final int studyDurationMinutes;
  final int minGroomingItems;

  const RankOverloadTarget({
    required this.rank,
    required this.workoutSets,
    required this.repsPerExercise,
    required this.cardioDistanceKm,
    required this.studyDurationMinutes,
    required this.minGroomingItems,
  });
}

/// Static Achievement Definition
class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final double targetValue;
  final bool isRare;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    this.targetValue = 0,
    this.isRare = false,
  });
}

/// Game Configuration & Balancing Table
/// Single Source of Truth for EXP, Ranks, Strata, and Progressive Overload (`docs/prd.md`).
class GameConfig {
  GameConfig._();

  // EXP & Leveling
  static const int expPerQuest = 25;
  static const int fullClearBonusExp = 50;
  static const int maxDailyExp = 175;
  static const int statBoostPerLevel = 2; // +2 to ALL 6 stats on level up

  // HP & Penalty
  static const int maxHp = 100;
  static const int dailyHpDeduction = 34; // -34 HP per full day missed
  static const int penaltyInactivityDays = 3; // Trigger penalty on 3 consecutive days missed

  // Available Workout Exercises
  static const List<String> workoutExercises = [
    'Push Ups',
    'Pull Ups',
    'Squats',
    'Sit Ups',
  ];

  // Default Grooming Items for New User
  static const List<String> defaultGroomingItems = [
    'MORNING FACIAL WASH',
    'BRUSH TEETH 2X',
    'SHOWER & DEODORANT',
    'DRINK 2L WATER',
    'APPLY SUNSCREEN',
  ];

  // Rank Names in Progression Order
  static const List<String> rankProgression = [
    'Novice',
    'Beginner',
    'Rookie',
    'Enlighted',
    'Saint',
    'Preacher',
    'Apostle',
  ];

  // Rank Overload Specifications
  static const Map<String, RankOverloadTarget> rankTargets = {
    'Novice': RankOverloadTarget(
      rank: 'Novice',
      workoutSets: 2,
      repsPerExercise: {
        'Push Ups': 8,
        'Pull Ups': 2,
        'Squats': 12,
        'Sit Ups': 10,
      },
      cardioDistanceKm: 1.0,
      studyDurationMinutes: 25,
      minGroomingItems: 3,
    ),
    'Beginner': RankOverloadTarget(
      rank: 'Beginner',
      workoutSets: 3,
      repsPerExercise: {
        'Push Ups': 10,
        'Pull Ups': 3,
        'Squats': 15,
        'Sit Ups': 12,
      },
      cardioDistanceKm: 1.5,
      studyDurationMinutes: 35,
      minGroomingItems: 4,
    ),
    'Rookie': RankOverloadTarget(
      rank: 'Rookie',
      workoutSets: 3,
      repsPerExercise: {
        'Push Ups': 15,
        'Pull Ups': 5,
        'Squats': 20,
        'Sit Ups': 15,
      },
      cardioDistanceKm: 2.0,
      studyDurationMinutes: 45,
      minGroomingItems: 5,
    ),
    'Enlighted': RankOverloadTarget(
      rank: 'Enlighted',
      workoutSets: 3,
      repsPerExercise: {
        'Push Ups': 20,
        'Pull Ups': 7,
        'Squats': 25,
        'Sit Ups': 20,
      },
      cardioDistanceKm: 3.0,
      studyDurationMinutes: 60,
      minGroomingItems: 6,
    ),
    'Saint': RankOverloadTarget(
      rank: 'Saint',
      workoutSets: 4,
      repsPerExercise: {
        'Push Ups': 25,
        'Pull Ups': 10,
        'Squats': 30,
        'Sit Ups': 25,
      },
      cardioDistanceKm: 4.0,
      studyDurationMinutes: 75,
      minGroomingItems: 7,
    ),
    'Preacher': RankOverloadTarget(
      rank: 'Preacher',
      workoutSets: 4,
      repsPerExercise: {
        'Push Ups': 30,
        'Pull Ups': 12,
        'Squats': 40,
        'Sit Ups': 30,
      },
      cardioDistanceKm: 5.0,
      studyDurationMinutes: 90,
      minGroomingItems: 7,
    ),
    'Apostle': RankOverloadTarget(
      rank: 'Apostle',
      workoutSets: 5,
      repsPerExercise: {
        'Push Ups': 35,
        'Pull Ups': 15,
        'Squats': 50,
        'Sit Ups': 40,
      },
      cardioDistanceKm: 7.0,
      studyDurationMinutes: 120,
      minGroomingItems: 8,
    ),
  };

  // 8 Achievements Definitions
  static const List<AchievementDefinition> achievements = [
    AchievementDefinition(
      id: 'the_awakening',
      title: 'THE AWAKENING',
      description: 'Joined LevMax and initiated the system.',
      targetValue: 1,
      isRare: false,
    ),
    AchievementDefinition(
      id: 'first_blood',
      title: 'FIRST INITIATION',
      description: 'Complete your first daily quest.',
      targetValue: 1,
      isRare: false,
    ),
    AchievementDefinition(
      id: 'iron_vessel',
      title: 'IRON VESSEL',
      description: 'Accumulate 1,000 total workout reps.',
      targetValue: 1000,
      isRare: false,
    ),
    AchievementDefinition(
      id: 'wayfarer',
      title: 'WAYFARER',
      description: 'Cover 50 km total cardio distance.',
      targetValue: 50.0,
      isRare: false,
    ),
    AchievementDefinition(
      id: 'phantom_velocity',
      title: 'PHANTOM VELOCITY',
      description: 'Reached Pace 3:59 /km or faster in Cardio.',
      targetValue: 1.0,
      isRare: true,
    ),
    AchievementDefinition(
      id: 'scholar_sanctum',
      title: 'SCHOLAR OF SANCTUM',
      description: 'Accumulate 1,200 total study minutes (20 hours).',
      targetValue: 1200,
      isRare: false,
    ),
    AchievementDefinition(
      id: 'centurion',
      title: 'CENTURION',
      description: 'Complete 100 total daily quests.',
      targetValue: 100,
      isRare: false,
    ),
    AchievementDefinition(
      id: 'unbroken',
      title: 'UNBROKEN',
      description: 'Maintain a 30-day consecutive login streak.',
      targetValue: 30,
      isRare: true,
    ),
  ];
}
