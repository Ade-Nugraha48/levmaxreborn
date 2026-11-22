import 'package:hive/hive.dart';
import '../core/constants/hive_boxes.dart';
import '../core/utils/stat_calculator.dart';

part 'user_model.g.dart';

@HiveType(typeId: HiveBoxes.userTypeId)
class UserModel extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  String password;

  @HiveField(2)
  String? photoPath;

  @HiveField(3)
  int level;

  @HiveField(4)
  int exp;

  @HiveField(5)
  int hp;

  @HiveField(6)
  int strength; // STR

  @HiveField(7)
  int endurance; // END

  @HiveField(8)
  int speed; // SPD

  @HiveField(9)
  int intelligence; // INT

  @HiveField(10)
  int willpower; // WIL

  @HiveField(11)
  int appearance; // APP

  @HiveField(12)
  int streakDays;

  @HiveField(13)
  String lastActiveDate; // YYYY-MM-DD

  @HiveField(14)
  DateTime createdAt;

  @HiveField(15)
  int longestStreak;

  @HiveField(16)
  Map<String, String> rankHistory; // {'Novice': '2026-11-22', ...}

  @HiveField(17)
  Map<String, String> unlockedAchievements; // {'the_awakening': '2026-11-22', ...}

  @HiveField(18)
  Map<String, int> growthSnapshots; // {'2026-11-22': 0, ...}

  UserModel({
    required this.username,
    required this.password,
    this.photoPath,
    this.level = 1,
    this.exp = 0,
    this.hp = 100,
    this.strength = 0,
    this.endurance = 0,
    this.speed = 0,
    this.intelligence = 0,
    this.willpower = 0,
    this.appearance = 0,
    this.streakDays = 0,
    required this.lastActiveDate,
    required this.createdAt,
    this.longestStreak = 0,
    Map<String, String>? rankHistory,
    Map<String, String>? unlockedAchievements,
    Map<String, int>? growthSnapshots,
  })  : rankHistory = rankHistory ?? {},
        unlockedAchievements = unlockedAchievements ?? {},
        growthSnapshots = growthSnapshots ?? {};

  /// Helper map of all 6 attributes
  Map<String, int> get statsMap => {
        'STR': strength,
        'END': endurance,
        'SPD': speed,
        'INT': intelligence,
        'WIL': willpower,
        'APP': appearance,
      };

  /// Total sum of all 6 attributes
  int get totalStats =>
      strength + endurance + speed + intelligence + willpower + appearance;

  /// Dynamic rank based on stats
  String get rank => StatCalculator.calculateRank(statsMap);

  /// Target EXP needed to reach the next level
  int get nextLevelTargetExp => StatCalculator.targetExpForLevel(level);

  /// EXP progress ratio (0.0 to 1.0)
  double get expProgressRatio {
    final target = nextLevelTargetExp;
    if (target <= 0) return 0.0;
    return (exp / target).clamp(0.0, 1.0);
  }

  /// HP progress ratio (0.0 to 1.0)
  double get hpProgressRatio => (hp / 100.0).clamp(0.0, 1.0);

  /// Creates a copy with optional updated fields
  UserModel copyWith({
    String? username,
    String? password,
    String? photoPath,
    int? level,
    int? exp,
    int? hp,
    int? strength,
    int? endurance,
    int? speed,
    int? intelligence,
    int? willpower,
    int? appearance,
    int? streakDays,
    String? lastActiveDate,
    DateTime? createdAt,
    int? longestStreak,
    Map<String, String>? rankHistory,
    Map<String, String>? unlockedAchievements,
    Map<String, int>? growthSnapshots,
  }) {
    return UserModel(
      username: username ?? this.username,
      password: password ?? this.password,
      photoPath: photoPath ?? this.photoPath,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      hp: hp ?? this.hp,
      strength: strength ?? this.strength,
      endurance: endurance ?? this.endurance,
      speed: speed ?? this.speed,
      intelligence: intelligence ?? this.intelligence,
      willpower: willpower ?? this.willpower,
      appearance: appearance ?? this.appearance,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      createdAt: createdAt ?? this.createdAt,
      longestStreak: longestStreak ?? this.longestStreak,
      rankHistory: rankHistory != null ? Map.from(rankHistory) : Map.from(this.rankHistory),
      unlockedAchievements: unlockedAchievements != null
          ? Map.from(unlockedAchievements)
          : Map.from(this.unlockedAchievements),
      growthSnapshots: growthSnapshots != null
          ? Map.from(growthSnapshots)
          : Map.from(this.growthSnapshots),
    );
  }
}
