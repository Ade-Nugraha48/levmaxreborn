import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:levmaxreborn/core/constants/hive_boxes.dart';
import 'package:levmaxreborn/core/constants/game_config.dart';
import 'package:levmaxreborn/controller/grooming_controller.dart';
import 'package:levmaxreborn/controller/quest_controller.dart';
import 'package:levmaxreborn/controller/user_controller.dart';
import 'package:levmaxreborn/model/daily_quest_state_model.dart';
import 'package:levmaxreborn/model/grooming_item_model.dart';
import 'package:levmaxreborn/model/quest_log_model.dart';
import 'package:levmaxreborn/model/user_model.dart';
import 'package:levmaxreborn/service/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late UserController userController;
  late QuestController questController;
  late GroomingController groomingController;

  setUpAll(() async {
    Get.testMode = true;
    tempDir = await Directory.systemTemp.createTemp('hive_grooming_test_');
    Hive.init(tempDir.path);

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

    await Hive.openBox<UserModel>(HiveBoxes.users);
    await Hive.openBox<QuestLogModel>(HiveBoxes.questLogs);
    await Hive.openBox<GroomingItemModel>(HiveBoxes.groomingItems);
    await Hive.openBox<DailyQuestStateModel>(HiveBoxes.dailyQuestStates);

    SharedPreferences.setMockInitialValues({});
    await SessionService.init();

    userController = Get.put<UserController>(UserController(), permanent: true);
    questController = Get.put<QuestController>(QuestController());
    groomingController = Get.put<GroomingController>(GroomingController());
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    Get.reset();
  });

  setUp(() async {
    await Hive.box<UserModel>(HiveBoxes.users).clear();
    await Hive.box<DailyQuestStateModel>(HiveBoxes.dailyQuestStates).clear();
    await Hive.box<QuestLogModel>(HiveBoxes.questLogs).clear();
    await Hive.box<GroomingItemModel>(HiveBoxes.groomingItems).clear();
    groomingController.items.clear();
  });

  group('1. Full Hive CRUD Operations for GroomingItemModel', () {
    test('Create, Read, Update (toggle & edit), and Delete items persist in Hive', () async {
      final user = UserModel(
        username: 'cyber_agent',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('cyber_agent');

      groomingController.loadItems();
      expect(groomingController.items.length, 5); // Default 5 items seeded

      // [CREATE]: Add custom item
      final created = await groomingController.addItem('Cold Face Plunge');
      expect(created.title, 'Cold Face Plunge');
      expect(created.username, 'cyber_agent');
      expect(groomingController.items.length, 6);

      // Verify persisted in Hive
      final box = Hive.box<GroomingItemModel>(HiveBoxes.groomingItems);
      expect(box.values.any((i) => i.title == 'Cold Face Plunge'), isTrue);

      // [UPDATE - Toggle]: Check item
      expect(created.isChecked, isFalse);
      await groomingController.toggleItem(created);
      expect(created.isChecked, isTrue);

      // Verify toggle persisted in Hive
      final itemInBox = box.values.firstWhere((i) => i.title == 'Cold Face Plunge');
      expect(itemInBox.isChecked, isTrue);

      // [UPDATE - Edit Title]: Rename item
      await groomingController.editItem(created, 'Ice Cold Plunge');
      expect(created.title, 'Ice Cold Plunge');
      expect(itemInBox.title, 'Ice Cold Plunge');

      // [DELETE]: Delete item
      await groomingController.deleteItem(created);
      expect(groomingController.items.length, 5);
      expect(box.values.any((i) => i.title == 'Ice Cold Plunge'), isFalse);
    });
  });

  group('2. Rank-Based Minimum Grooming Requirement', () {
    test('Novice user requires 3 items; blocks submit if fewer than 3 checked', () async {
      final user = UserModel(
        username: 'novice_user',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        strength: 5,
        appearance: 5,
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('novice_user');

      final state = DailyQuestStateModel(
        username: 'novice_user',
        date: '2026-11-22',
        workoutExercises: ['Push Ups', 'Squats'],
      );
      await Hive.box<DailyQuestStateModel>(HiveBoxes.dailyQuestStates)
          .put('novice_user_2026-11-22', state);
      questController.dailyQuest.value = state;

      groomingController.loadItems();
      expect(groomingController.minRequiredItems, 3);
      expect(groomingController.isThresholdMet, isFalse);

      // Check only 2 items
      await groomingController.toggleItem(groomingController.items[0]);
      await groomingController.toggleItem(groomingController.items[1]);
      expect(groomingController.completedCount, 2);
      expect(groomingController.isThresholdMet, isFalse);

      // Submit should fail / return null
      final result = await groomingController.submitGrooming();
      expect(result, isNull);
      expect(state.groomingCompleted, isFalse);
    });

    test('Higher rank requirements follow GameConfig correctly', () async {
      expect(GameConfig.rankTargets['Novice']!.minGroomingItems, 3);
      expect(GameConfig.rankTargets['Beginner']!.minGroomingItems, 4);
      expect(GameConfig.rankTargets['Rookie']!.minGroomingItems, 5);
      expect(GameConfig.rankTargets['Enlighted']!.minGroomingItems, 6);
      expect(GameConfig.rankTargets['Saint']!.minGroomingItems, 7);
      expect(GameConfig.rankTargets['Preacher']!.minGroomingItems, 7);
      expect(GameConfig.rankTargets['Apostle']!.minGroomingItems, 8);
    });
  });

  group('3. Grooming Quest Execution & Rewards', () {
    test('Submitting grooming awards +3 APP, +25 EXP and writes QuestLogModel', () async {
      final user = UserModel(
        username: 'slick_player',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        appearance: 10,
        exp: 0,
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('slick_player');

      final state = DailyQuestStateModel(
        username: 'slick_player',
        date: '2026-11-22',
        workoutExercises: ['Push Ups', 'Squats'],
      );
      await Hive.box<DailyQuestStateModel>(HiveBoxes.dailyQuestStates)
          .put('slick_player_2026-11-22', state);
      questController.dailyQuest.value = state;

      groomingController.loadItems();

      // Check 3 items to satisfy Novice threshold
      await groomingController.toggleItem(groomingController.items[0]);
      await groomingController.toggleItem(groomingController.items[1]);
      await groomingController.toggleItem(groomingController.items[2]);
      expect(groomingController.isThresholdMet, isTrue);

      // Submit
      final result = await groomingController.submitGrooming();
      expect(result, isNotNull);

      // Verify Stat rewards (+3 APP, +25 EXP)
      expect(user.appearance, 13);
      expect(user.exp, 25);
      expect(result!.statRewards['APP'], 3);

      // Verify DailyQuestState updated
      expect(questController.dailyQuest.value!.groomingCompleted, isTrue);
      expect(groomingController.isAlreadySubmitted, isTrue);

      // Verify QuestLogModel written to Hive
      final logs = Hive.box<QuestLogModel>(HiveBoxes.questLogs).values.toList();
      expect(logs.any((l) => l.questType == 'grooming'), isTrue);
      final groomingLog = logs.firstWhere((l) => l.questType == 'grooming');
      expect(groomingLog.username, 'slick_player');
      expect(groomingLog.title, 'DAILY GROOMING');
      expect(groomingLog.expGained, 25);
      expect(groomingLog.statRewards['APP'], 3);
      expect(groomingLog.metricSummary, '3 ITEMS PROTOCOL');

      // Attempting to submit again returns null
      final duplicateResult = await groomingController.submitGrooming();
      expect(duplicateResult, isNull);
    });
  });

  group('4. Grooming Completion as 5th Quest Triggers Full Clear', () {
    test('Grooming as 5th quest awards Full Clear bonus (+50 EXP, +2 WIL)', () async {
      final user = UserModel(
        username: 'completer',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        appearance: 10,
        willpower: 10,
        exp: 0,
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('completer');

      // 4 quests already done
      final state = DailyQuestStateModel(
        username: 'completer',
        date: '2026-11-22',
        workoutExercises: ['Push Ups', 'Squats'],
        workoutCompleted: [true, true],
        studyCompleted: true,
        cardioCompleted: true,
        groomingCompleted: false, // 5th quest
      );
      await Hive.box<DailyQuestStateModel>(HiveBoxes.dailyQuestStates)
          .put('completer_2026-11-22', state);
      questController.dailyQuest.value = state;

      groomingController.loadItems();
      await groomingController.toggleItem(groomingController.items[0]);
      await groomingController.toggleItem(groomingController.items[1]);
      await groomingController.toggleItem(groomingController.items[2]);

      final result = await groomingController.submitGrooming();
      expect(result, isNotNull);
      expect(result!.fullClearAchieved, isTrue);
      expect(state.fullClearClaimed, isTrue);

      // +3 APP (grooming)
      expect(user.appearance, 13);
      // +2 WIL (full clear bonus)
      expect(user.willpower, 12);
      // 25 (grooming) + 50 (full clear) = 75 EXP
      expect(user.exp, 75);
    });
  });
}
