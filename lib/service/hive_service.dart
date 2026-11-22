import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/hive_boxes.dart';
import '../model/user_model.dart';
import '../model/quest_log_model.dart';
import '../model/grooming_item_model.dart';
import '../model/daily_quest_state_model.dart';

/// Hive Local Database Service
/// Handles initialization, adapter registration, and box access.
/// Conforms to `docs/database_schema.md`.
class HiveService {
  HiveService._();

  /// Initializes Hive and registers all 4 type adapters
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register TypeAdapters (Ids 0..3)
    if (!Hive.isAdapterRegistered(HiveBoxes.userTypeId)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveBoxes.questLogTypeId)) {
      Hive.registerAdapter(QuestLogModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveBoxes.groomingItemTypeId)) {
      Hive.registerAdapter(GroomingItemModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveBoxes.dailyQuestStateTypeId)) {
      Hive.registerAdapter(DailyQuestStateModelAdapter());
    }

    // Open all 4 boxes
    await Hive.openBox<UserModel>(HiveBoxes.users);
    await Hive.openBox<QuestLogModel>(HiveBoxes.questLogs);
    await Hive.openBox<GroomingItemModel>(HiveBoxes.groomingItems);
    await Hive.openBox<DailyQuestStateModel>(HiveBoxes.dailyQuestStates);
  }

  // Box Getters
  static Box<UserModel> get usersBox => Hive.box<UserModel>(HiveBoxes.users);
  static Box<QuestLogModel> get questLogsBox =>
      Hive.box<QuestLogModel>(HiveBoxes.questLogs);
  static Box<GroomingItemModel> get groomingItemsBox =>
      Hive.box<GroomingItemModel>(HiveBoxes.groomingItems);
  static Box<DailyQuestStateModel> get dailyQuestStatesBox =>
      Hive.box<DailyQuestStateModel>(HiveBoxes.dailyQuestStates);

  /// Closes all open Hive boxes
  static Future<void> closeAll() async {
    await Hive.close();
  }
}
