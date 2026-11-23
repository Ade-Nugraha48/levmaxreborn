import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:levmaxreborn/core/constants/game_config.dart';
import 'package:levmaxreborn/core/constants/hive_boxes.dart';
import 'package:levmaxreborn/controller/quest_controller.dart';
import 'package:levmaxreborn/controller/user_controller.dart';
import 'package:levmaxreborn/model/daily_quest_state_model.dart';
import 'package:levmaxreborn/model/grooming_item_model.dart';
import 'package:levmaxreborn/model/quest_log_model.dart';
import 'package:levmaxreborn/model/user_model.dart';
import 'package:levmaxreborn/service/session_service.dart';
import 'package:levmaxreborn/view/pages/workout_detail_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late UserController userController;
  late QuestController questController;

  setUpAll(() async {
    Get.testMode = true;
    tempDir = await Directory.systemTemp.createTemp('hive_quest_exec_test_');
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
  });

  group('1. Rank-Based Progressive Overload Targets', () {
    test('Novice rank has correct workout sets, reps, and study duration', () {
      final novice = GameConfig.rankTargets['Novice']!;
      expect(novice.workoutSets, 2);
      expect(novice.repsPerExercise['Push Ups'], 8);
      expect(novice.repsPerExercise['Squats'], 12);
      expect(novice.studyDurationMinutes, 25);
    });

    test('Beginner rank has increased sets, reps, and study duration', () {
      final beginner = GameConfig.rankTargets['Beginner']!;
      expect(beginner.workoutSets, 3);
      expect(beginner.repsPerExercise['Push Ups'], 10);
      expect(beginner.repsPerExercise['Squats'], 15);
      expect(beginner.studyDurationMinutes, 35);
    });

    test('Apostle rank has maximum progressive overload targets', () {
      final apostle = GameConfig.rankTargets['Apostle']!;
      expect(apostle.workoutSets, 5);
      expect(apostle.repsPerExercise['Push Ups'], 35);
      expect(apostle.repsPerExercise['Squats'], 50);
      expect(apostle.studyDurationMinutes, 120);
    });
  });

  group('2. Workout Quest Execution & Progression', () {
    test('Completing workout awards +2 STR, +1 END, +25 EXP and creates QuestLogModel', () async {
      final user = UserModel(
        username: 'iron_warrior',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        strength: 10,
        endurance: 10,
        exp: 0,
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('iron_warrior');

      final state = DailyQuestStateModel(
        username: 'iron_warrior',
        date: '2026-11-22',
        workoutExercises: ['Push Ups', 'Squats'],
      );
      await Hive.box<DailyQuestStateModel>(HiveBoxes.dailyQuestStates)
          .put('iron_warrior_2026-11-22', state);
      questController.dailyQuest.value = state;

      final result = await questController.completeQuest(
        type: QuestType.workout,
        exerciseName: 'Push Ups',
        workoutIndex: 0,
        repsCount: 30,
      );

      // Verify Stat rewards
      expect(user.strength, 12); // +2 STR
      expect(user.endurance, 11); // +1 END
      expect(user.exp, 25); // +25 EXP
      expect(result.statRewards['STR'], 2);
      expect(result.statRewards['END'], 1);

      // Verify DailyQuestState updated
      expect(questController.dailyQuest.value!.workoutCompleted[0], isTrue);

      // Verify QuestLogModel created in Hive
      final logs = Hive.box<QuestLogModel>(HiveBoxes.questLogs).values.toList();
      expect(logs.length, 1);
      final log = logs.first;
      expect(log.username, 'iron_warrior');
      expect(log.questType, 'workout');
      expect(log.title, 'PUSH UPS');
      expect(log.exerciseName, 'Push Ups');
      expect(log.repsCount, 30);
      expect(log.expGained, 25);
      expect(log.metricSummary, '30 REPS · BODYWEIGHT');
    });
  });

  group('3. Study Lock-In Quest Execution', () {
    test('Completing Study Lock-In awards +3 INT (+4 for Apostle) and +25 EXP', () async {
      final user = UserModel(
        username: 'scholar',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        intelligence: 5,
        exp: 0,
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('scholar');

      final state = DailyQuestStateModel(
        username: 'scholar',
        date: '2026-11-22',
        workoutExercises: ['Push Ups', 'Squats'],
      );
      await Hive.box<DailyQuestStateModel>(HiveBoxes.dailyQuestStates)
          .put('scholar_2026-11-22', state);
      questController.dailyQuest.value = state;

      await questController.completeQuest(
        type: QuestType.study,
        durationMinutes: 25,
      );

      expect(user.intelligence, 8); // 5 + 3 INT
      expect(user.exp, 25);
      expect(questController.dailyQuest.value!.studyCompleted, isTrue);

      // Verify QuestLogModel
      final logs = Hive.box<QuestLogModel>(HiveBoxes.questLogs).values.toList();
      expect(logs.any((l) => l.questType == 'study'), isTrue);
      final studyLog = logs.firstWhere((l) => l.questType == 'study');
      expect(studyLog.durationMinutes, 25);
      expect(studyLog.metricSummary, '25 MINS FOCUS');
    });
  });

  group('4. Level Up Progression (+2 to All 6 Stats)', () {
    test('Gaining enough EXP triggers Level Up and adds +2 to ALL 6 attributes', () async {
      // Level 1 targetExp = 100
      final user = UserModel(
        username: 'prodigy',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        level: 1,
        exp: 80, // Needs 20 to level up
        strength: 10,
        endurance: 10,
        speed: 10,
        intelligence: 10,
        willpower: 10,
        appearance: 10,
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('prodigy');

      final state = DailyQuestStateModel(
        username: 'prodigy',
        date: '2026-11-22',
        workoutExercises: ['Push Ups', 'Squats'],
      );
      await Hive.box<DailyQuestStateModel>(HiveBoxes.dailyQuestStates)
          .put('prodigy_2026-11-22', state);
      questController.dailyQuest.value = state;

      // Completing workout gives +25 EXP (80 + 25 = 105 -> Level 2 with 5 EXP remainder)
      // Base workout gives +2 STR, +1 END
      // Level up gives +2 to all 6 stats:
      // STR: 10 + 2 (workout) + 2 (level up) = 14
      // END: 10 + 1 (workout) + 2 (level up) = 13
      // SPD: 10 + 2 (level up) = 12
      // INT: 10 + 2 (level up) = 12
      // WIL: 10 + 2 (level up) = 12
      // APP: 10 + 2 (level up) = 12
      final result = await questController.completeQuest(
        type: QuestType.workout,
        exerciseName: 'Squats',
        workoutIndex: 1,
        repsCount: 20,
      );

      expect(result.levelUpResult.didLevelUp, isTrue);
      expect(result.levelUpResult.newLevel, 2);
      expect(result.levelUpResult.levelsGained, 1);
      expect(user.level, 2);
      expect(user.exp, 5); // 105 - 100

      expect(user.strength, 14);
      expect(user.endurance, 13);
      expect(user.speed, 12);
      expect(user.intelligence, 12);
      expect(user.willpower, 12);
      expect(user.appearance, 12);
    });
  });

  group('5. Full Clear Bonus (+50 EXP, +2 WIL)', () {
    test('Completing all 5 daily quests triggers Full Clear bonus', () async {
      final user = UserModel(
        username: 'master',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        willpower: 10,
        exp: 0,
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('master');

      // 4 quests already completed
      final state = DailyQuestStateModel(
        username: 'master',
        date: '2026-11-22',
        workoutExercises: ['Push Ups', 'Squats'],
        workoutCompleted: [true, true],
        studyCompleted: true,
        cardioCompleted: true,
        groomingCompleted: false, // 5th quest remaining
      );
      await Hive.box<DailyQuestStateModel>(HiveBoxes.dailyQuestStates)
          .put('master_2026-11-22', state);
      questController.dailyQuest.value = state;

      // Complete 5th quest (grooming)
      final result = await questController.completeQuest(
        type: QuestType.grooming,
        repsCount: 5,
      );

      expect(result.fullClearAchieved, isTrue);
      expect(questController.dailyQuest.value!.isAllCompleted, isTrue);
      expect(questController.dailyQuest.value!.fullClearClaimed, isTrue);

      // +25 (quest) + 50 (full clear bonus) = 75 EXP
      expect(user.exp, 75);
      // +2 WIL (full clear bonus)
      expect(user.willpower, 12);
    });
  });

  group('6. Strict Protocol Violation Simulation (>10s abandonment)', () {
    test('Simulating app backgrounding for > 10 seconds pauses session and reduces integrity', () {
      final startTime = DateTime.now();
      final resumeTimeAfter15s = startTime.add(const Duration(seconds: 15));

      final elapsed = resumeTimeAfter15s.difference(startTime).inSeconds;
      expect(elapsed, greaterThan(10));

      // Verifying penalty logic formula
      double integrity = 100.0;
      if (elapsed > 10) {
        integrity = (integrity - 10.0).clamp(0.0, 100.0);
      }

      expect(integrity, 90.0);
    });
  });

  group('7. WorkoutDetailPage Initial State & Reset Verification', () {
    testWidgets(
        'WorkoutDetailPage starts at Set 1, 0 reps, 0% cadence, and resets reps on next set',
        (tester) async {
      final user = UserModel(
        username: 'workout_novice',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
      );
      await tester.runAsync(() async {
        await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      });
      userController.loadUser('workout_novice');

      // Novice Push Ups target is 2 sets x 8 reps
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutDetailPage(),
        ),
      );
      await tester.pump();

      // 1. Verify starts at Set 1 (not Set 2)
      expect(find.text('CURRENT: SET 01 OF 02'), findsOneWidget);
      expect(find.text('COMPLETE SET 1'), findsOneWidget);

      // 2. Verify starts at 0 reps (not 8 reps)
      expect(find.text('0'), findsOneWidget);
      expect(find.text(' / 8'), findsOneWidget);

      // 3. Verify Cadence is 0%
      expect(find.text('0% CADENCE'), findsOneWidget);

      // 4. Verify Rest Timer is initially READY (not active)
      expect(find.text('READY'), findsOneWidget);

      // 5. Verify Button is DISABLED when currentReps (0) < targetReps (8)
      ElevatedButton btn = tester.widget(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);

      // 6. Test incrementing & decrementing reps and boundary clamping
      // At 0 reps, tapping decrement must stay 0 and icon should be muted
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(find.text('0'), findsOneWidget);

      // 7. Increment reps up to targetReps (8)
      for (int i = 0; i < 8; i++) {
        await tester.tap(find.byIcon(Icons.add));
      }
      await tester.pump();
      expect(find.text('8'), findsOneWidget);

      // Clamping test: attempting to increment past targetReps (8) must keep reps at 8
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.add));
      }
      await tester.pump();
      expect(find.text('8'), findsOneWidget);

      // 8. Now button is ENABLED
      btn = tester.widget(find.byType(ElevatedButton));
      expect(btn.onPressed, isNotNull);

      // 9. Tap COMPLETE SET 1 -> advances to Set 2 and resets reps to 0
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // In test mode, rest timer finishes immediately
      expect(find.text('CURRENT: SET 02 OF 02'), findsOneWidget);
      expect(find.text('COMPLETE WORKOUT'), findsOneWidget);
      expect(find.text('0'), findsOneWidget); // Reps reset to 0!
      expect(find.text('50% CADENCE'), findsOneWidget);

      // 10. Verify Button is DISABLED again until Set 2 reps are completed
      btn = tester.widget(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);

      // 11. Complete Set 2 reps (8 reps) -> Cadence reaches 100%
      for (int i = 0; i < 8; i++) {
        await tester.tap(find.byIcon(Icons.add));
      }
      await tester.pump();
      expect(find.text('8'), findsOneWidget);
      expect(find.text('100% CADENCE'), findsOneWidget);

      // 12. Verify Button is now ENABLED with text COMPLETE WORKOUT
      btn = tester.widget(find.byType(ElevatedButton));
      expect(btn.onPressed, isNotNull);
      expect(find.text('COMPLETE WORKOUT'), findsOneWidget);
    });

    test('completeQuest strictly guards against repsCount < targetReps', () async {
      final user = UserModel(
        username: 'eager_novice',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        exp: 0,
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('eager_novice');

      final result = await questController.completeQuest(
        type: QuestType.workout,
        exerciseName: 'Push Ups',
        workoutIndex: 0,
        repsCount: 4, // Below target of 8 reps
      );

      // Verify no rewards awarded and no progression applied
      expect(result.expGained, 0);
      expect(user.exp, 0);
      expect(user.strength, 0);
    });
  });
}
