import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:levmaxreborn/core/constants/hive_boxes.dart';
import 'package:levmaxreborn/model/user_model.dart';
import 'package:levmaxreborn/model/quest_log_model.dart';
import 'package:levmaxreborn/model/grooming_item_model.dart';
import 'package:levmaxreborn/model/daily_quest_state_model.dart';
import 'package:levmaxreborn/model/achievement_model.dart';
import 'package:levmaxreborn/service/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);

    // Register 4 Hive Adapters
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

    // Set mock initial values for SharedPreferences
    SharedPreferences.setMockInitialValues({});
    await SessionService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Hive TypeId Registry Verification', () {
    test('TypeIds match database_schema.md strictly (0..3)', () {
      expect(UserModelAdapter().typeId, equals(0));
      expect(QuestLogModelAdapter().typeId, equals(1));
      expect(GroomingItemModelAdapter().typeId, equals(2));
      expect(DailyQuestStateModelAdapter().typeId, equals(3));

      expect(HiveBoxes.userTypeId, equals(0));
      expect(HiveBoxes.questLogTypeId, equals(1));
      expect(HiveBoxes.groomingItemTypeId, equals(2));
      expect(HiveBoxes.dailyQuestStateTypeId, equals(3));
    });
  });

  group('Hive Box Operations & Full CRUD', () {
    test('can open all 4 Hive boxes without error', () async {
      final usersBox = await Hive.openBox<UserModel>(HiveBoxes.users);
      final questLogsBox = await Hive.openBox<QuestLogModel>(HiveBoxes.questLogs);
      final groomingBox = await Hive.openBox<GroomingItemModel>(HiveBoxes.groomingItems);
      final dailyBox = await Hive.openBox<DailyQuestStateModel>(HiveBoxes.dailyQuestStates);

      expect(usersBox.isOpen, isTrue);
      expect(questLogsBox.isOpen, isTrue);
      expect(groomingBox.isOpen, isTrue);
      expect(dailyBox.isOpen, isTrue);
    });

    test('UserModel Create, Read, Update, Delete', () async {
      final box = Hive.box<UserModel>(HiveBoxes.users);

      final user = UserModel(
        username: 'cyber_hunter',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        rankHistory: {'Novice': '2026-11-22'},
        unlockedAchievements: {'the_awakening': '2026-11-22'},
        growthSnapshots: {'2026-11-22': 0},
      );

      // Create
      await box.put(user.username, user);
      expect(box.containsKey('cyber_hunter'), isTrue);

      // Read
      final retrieved = box.get('cyber_hunter');
      expect(retrieved, isNotNull);
      expect(retrieved!.username, equals('cyber_hunter'));
      expect(retrieved.level, equals(1));
      expect(retrieved.hp, equals(100));
      expect(retrieved.rank, equals('Novice'));

      // Update
      retrieved.strength = 100;
      retrieved.exp = 50;
      await retrieved.save();

      final updated = box.get('cyber_hunter');
      expect(updated!.strength, equals(100));
      expect(updated.rank, equals('Beginner'));

      // Delete
      await retrieved.delete();
      expect(box.containsKey('cyber_hunter'), isFalse);
    });

    test('QuestLogModel Create, Read, and Delete', () async {
      final box = Hive.box<QuestLogModel>(HiveBoxes.questLogs);

      final log = QuestLogModel(
        id: 'log_001',
        username: 'hunter_one',
        questType: 'workout',
        title: 'PUSH UPS',
        completedAt: DateTime.now(),
        expGained: 25,
        statRewards: {'STR': 2, 'END': 1},
        metricSummary: '30 reps',
        exerciseName: 'Push Ups',
        repsCount: 30,
      );

      final key = await box.add(log);
      expect(box.containsKey(key), isTrue);

      final retrieved = box.get(key);
      expect(retrieved!.title, equals('PUSH UPS'));
      expect(retrieved.repsCount, equals(30));

      await retrieved.delete();
      expect(box.containsKey(key), isFalse);
    });

    test('GroomingItemModel Create, Toggle, and Delete', () async {
      final box = Hive.box<GroomingItemModel>(HiveBoxes.groomingItems);

      final item = GroomingItemModel(
        id: 'groom_01',
        username: 'hunter_one',
        title: 'MORNING FACIAL WASH',
        isChecked: false,
        isDefault: true,
      );

      final key = await box.add(item);
      final retrieved = box.get(key);
      expect(retrieved!.isChecked, isFalse);

      retrieved.isChecked = true;
      await retrieved.save();
      expect(box.get(key)!.isChecked, isTrue);

      await retrieved.delete();
      expect(box.containsKey(key), isFalse);
    });

    test('DailyQuestStateModel completion calculations', () async {
      final box = Hive.box<DailyQuestStateModel>(HiveBoxes.dailyQuestStates);

      final state = DailyQuestStateModel(
        username: 'hunter_one',
        date: '2026-11-22',
        workoutExercises: ['Push Ups', 'Squats'],
      );

      await box.put(state.username, state);
      final retrieved = box.get('hunter_one')!;
      expect(retrieved.completedCount, equals(0));
      expect(retrieved.isAllCompleted, isFalse);

      retrieved.workoutCompleted = [true, true];
      retrieved.studyCompleted = true;
      retrieved.cardioCompleted = true;
      retrieved.groomingCompleted = true;
      await retrieved.save();

      expect(box.get('hunter_one')!.completedCount, equals(5));
      expect(box.get('hunter_one')!.isAllCompleted, isTrue);
    });
  });

  group('SessionService (SharedPreferences)', () {
    test('default session values match database_schema.md', () {
      expect(SessionService.isLoggedIn, isFalse);
      expect(SessionService.activeUsername, equals(''));
      expect(SessionService.dailyReminderEnabled, isTrue);
      expect(SessionService.isDemoMode, isFalse);
      expect(SessionService.skipRestTimer, isFalse);
    });

    test('updates session values and clears on logout', () async {
      await SessionService.setIsLoggedIn(true);
      await SessionService.setActiveUsername('soloing_apostle');
      await SessionService.setIsDemoMode(true);
      await SessionService.setSkipRestTimer(true);

      expect(SessionService.isLoggedIn, isTrue);
      expect(SessionService.activeUsername, equals('soloing_apostle'));
      expect(SessionService.isDemoMode, isTrue);
      expect(SessionService.skipRestTimer, isTrue);

      await SessionService.clearSession();
      expect(SessionService.isLoggedIn, isFalse);
      expect(SessionService.activeUsername, equals(''));
    });
  });

  group('AchievementModel Evaluation Engine', () {
    test('evaluates all 8 achievements dynamically from user and logs', () {
      final user = UserModel(
        username: 'test_hunter',
        password: 'pass',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        streakDays: 30,
        longestStreak: 30,
        unlockedAchievements: {
          'the_awakening': '2026-11-22',
        },
      );

      final logs = [
        QuestLogModel(
          id: '1',
          username: 'test_hunter',
          questType: 'workout',
          title: 'PUSH UPS',
          completedAt: DateTime.now(),
          metricSummary: '500 reps',
          repsCount: 500,
        ),
        QuestLogModel(
          id: '2',
          username: 'test_hunter',
          questType: 'workout',
          title: 'SQUATS',
          completedAt: DateTime.now(),
          metricSummary: '500 reps',
          repsCount: 500,
        ),
        QuestLogModel(
          id: '3',
          username: 'test_hunter',
          questType: 'cardio',
          title: 'CARDIO',
          completedAt: DateTime.now(),
          metricSummary: '10.0 km',
          distanceKm: 10.0,
          paceMinPerKm: 3.8, // Faster than 3:59 -> Phantom Velocity!
        ),
        QuestLogModel(
          id: '4',
          username: 'test_hunter',
          questType: 'study',
          title: 'STUDY',
          completedAt: DateTime.now(),
          metricSummary: '600 mins',
          durationMinutes: 600,
        ),
      ];

      final evaluated = AchievementModel.evaluateAll(user: user, logs: logs);
      expect(evaluated.length, equals(8));

      final awakening = evaluated.firstWhere((a) => a.id == 'the_awakening');
      expect(awakening.isUnlocked, isTrue);

      final firstBlood = evaluated.firstWhere((a) => a.id == 'first_blood');
      expect(firstBlood.currentProgress, equals(1.0));

      final ironVessel = evaluated.firstWhere((a) => a.id == 'iron_vessel');
      expect(ironVessel.currentProgress, equals(1000.0));
      expect(ironVessel.progressRatio, equals(1.0));

      final phantom = evaluated.firstWhere((a) => a.id == 'phantom_velocity');
      expect(phantom.currentProgress, equals(1.0));

      final scholar = evaluated.firstWhere((a) => a.id == 'scholar_sanctum');
      expect(scholar.currentProgress, equals(600.0));
      expect(scholar.progressRatio, equals(0.5));

      final unbroken = evaluated.firstWhere((a) => a.id == 'unbroken');
      expect(unbroken.currentProgress, equals(30.0));
      expect(unbroken.progressRatio, equals(1.0));
    });
  });
}
