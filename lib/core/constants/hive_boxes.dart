/// Hive Box Names & TypeId Registry
/// Strict single source of truth for Hive Storage layer as locked in `docs/database_schema.md`.
class HiveBoxes {
  HiveBoxes._();

  // Box Names
  static const String users = 'users';
  static const String questLogs = 'quest_logs';
  static const String groomingItems = 'grooming_items';
  static const String dailyQuestStates = 'daily_quest_states';

  // TypeIds (STRICT - DO NOT CHANGE OR DUPLICATE)
  static const int userTypeId = 0;
  static const int questLogTypeId = 1;
  static const int groomingItemTypeId = 2;
  static const int dailyQuestStateTypeId = 3;
}
