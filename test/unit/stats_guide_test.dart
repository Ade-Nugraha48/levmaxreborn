import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:levmaxreborn/controller/stats_controller.dart';
import 'package:levmaxreborn/controller/user_controller.dart';
import 'package:levmaxreborn/core/constants/hive_boxes.dart';
import 'package:levmaxreborn/model/daily_quest_state_model.dart';
import 'package:levmaxreborn/model/grooming_item_model.dart';
import 'package:levmaxreborn/model/quest_log_model.dart';
import 'package:levmaxreborn/model/user_model.dart';
import 'package:levmaxreborn/view/pages/guide_page.dart';
import 'package:levmaxreborn/view/widgets/growth_line_chart.dart';
import 'package:levmaxreborn/view/widgets/stat_radar_chart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late UserController userController;
  late StatsController statsController;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('stats_guide_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(QuestLogModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(GroomingItemModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DailyQuestStateModelAdapter());

    await Hive.openBox<UserModel>(HiveBoxes.users);
    await Hive.openBox<QuestLogModel>(HiveBoxes.questLogs);
    await Hive.openBox<GroomingItemModel>(HiveBoxes.groomingItems);
    await Hive.openBox<DailyQuestStateModel>(HiveBoxes.dailyQuestStates);

    Get.testMode = true;
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    Get.reset();
    await Hive.box<UserModel>(HiveBoxes.users).clear();
    await Hive.box<QuestLogModel>(HiveBoxes.questLogs).clear();

    userController = Get.put(UserController());
  });

  group('1. Radar Chart & Line Chart Safety (0 Stats / Day 1 Account)', () {
    testWidgets('StatRadarChart renders safely with zero errors when all 6 stats are 0',
        (tester) async {
      final brandNewUser = UserModel(
        username: 'novice_zero',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        strength: 0,
        endurance: 0,
        speed: 0,
        intelligence: 0,
        willpower: 0,
        appearance: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatRadarChart(user: brandNewUser),
          ),
        ),
      );

      // Verify widget builds without any exception
      expect(find.byType(StatRadarChart), findsOneWidget);
      expect(find.text('HEXAGONAL MATRIX'), findsOneWidget);
      expect(find.text('SCALE: 0-100'), findsOneWidget);
    });

    testWidgets('GrowthLineChart renders safely with 0 snapshots or single Day 1 snapshot',
        (tester) async {
      // Test A: Empty snapshots
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GrowthLineChart(snapshots: []),
          ),
        ),
      );
      expect(find.byType(GrowthLineChart), findsOneWidget);

      // Test B: Single Day 1 snapshot with 0 stats
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GrowthLineChart(
              snapshots: [MapEntry('2026-11-22', 0)],
            ),
          ),
        ),
      );
      expect(find.byType(GrowthLineChart), findsOneWidget);
    });

    testWidgets('GrowthLineChart renders properly with multi-day trajectory',
        (tester) async {
      final snapshots = [
        const MapEntry('2026-11-20', 0),
        const MapEntry('2026-11-21', 12),
        const MapEntry('2026-11-22', 36),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GrowthLineChart(snapshots: snapshots),
          ),
        ),
      );
      expect(find.byType(GrowthLineChart), findsOneWidget);
    });
  });

  group('2. Sub-Tab SEJARAH: Authentic Aggregations from Hive', () {
    test('Calculates lifetime records and cumulative reps accurately from Hive', () async {
      final user = UserModel(
        username: 'veteran_hunter',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now().subtract(const Duration(days: 48)),
        streakDays: 14,
        longestStreak: 21,
        strength: 120,
        endurance: 95,
        speed: 105,
        intelligence: 110,
        willpower: 140,
        appearance: 144,
        growthSnapshots: {
          '2026-10-05': 0,
          '2026-10-24': 200,
          '2026-11-08': 300,
          '2026-11-20': 714,
        },
        rankHistory: {
          'Novice': '2026-10-05',
          'Rookie': '2026-10-24',
          'Enlighted': '2026-11-08',
          'Saint': '2026-11-20',
        },
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('veteran_hunter');

      // Seed 6 diverse quest logs
      final logs = [
        QuestLogModel(
          id: 'log_w1',
          username: 'veteran_hunter',
          questType: 'workout',
          title: 'PUSH UPS',
          completedAt: DateTime.now().subtract(const Duration(hours: 5)),
          metricSummary: '3 SETS x 15 REPS',
          repsCount: 45,
          exerciseName: 'Push Ups',
        ),
        QuestLogModel(
          id: 'log_w2',
          username: 'veteran_hunter',
          questType: 'workout',
          title: 'SQUATS',
          completedAt: DateTime.now().subtract(const Duration(hours: 4)),
          metricSummary: '3 SETS x 20 REPS',
          repsCount: 60,
          exerciseName: 'Squats',
        ),
        QuestLogModel(
          id: 'log_w3',
          username: 'veteran_hunter',
          questType: 'workout',
          title: 'SIT UPS',
          completedAt: DateTime.now().subtract(const Duration(hours: 3)),
          metricSummary: '3 SETS x 10 REPS',
          repsCount: 30,
          exerciseName: 'Sit Ups',
        ),
        QuestLogModel(
          id: 'log_w4',
          username: 'veteran_hunter',
          questType: 'workout',
          title: 'PULL UPS',
          completedAt: DateTime.now().subtract(const Duration(hours: 2)),
          metricSummary: '3 SETS x 5 REPS',
          repsCount: 15,
          exerciseName: 'Pull Ups',
        ),
        QuestLogModel(
          id: 'log_c1',
          username: 'veteran_hunter',
          questType: 'cardio',
          title: 'CARDIO RUN',
          completedAt: DateTime.now().subtract(const Duration(hours: 1)),
          metricSummary: '5.5 KM · 4:48 /KM',
          distanceKm: 5.5,
          paceMinPerKm: 4.8,
        ),
        QuestLogModel(
          id: 'log_s1',
          username: 'veteran_hunter',
          questType: 'study',
          title: 'STUDY LOCK-IN',
          completedAt: DateTime.now(),
          metricSummary: '90 MINS',
          durationMinutes: 90,
        ),
      ];

      for (final l in logs) {
        await Hive.box<QuestLogModel>(HiveBoxes.questLogs).put(l.id, l);
      }

      statsController = Get.put(StatsController());
      statsController.loadQuestLogs();

      // Check lifetime records
      expect(statsController.longestStreak, equals(21));
      expect(statsController.totalCardioKm, equals(5.5));
      expect(statsController.totalStudyHours, equals(1.5)); // 90 mins / 60
      expect(statsController.totalQuestsCleared, equals(6));

      // Check cumulative workout breakdown
      final reps = statsController.cumulativeWorkoutReps;
      expect(reps['Push Ups'], equals(45));
      expect(reps['Squats'], equals(60));
      expect(reps['Sit Ups'], equals(30));
      expect(reps['Pull Ups'], equals(15));
      expect(statsController.maxWorkoutReps, equals(60));

      // Check Rank Chronicle
      final chronicle = statsController.rankChronicle;
      expect(chronicle.length, equals(4));
      // First node is Saint (Active Current)
      expect(chronicle[0].rank, equals('Saint'));
      expect(chronicle[0].isCurrent, isTrue);
      expect(chronicle[0].dateAchieved, equals('2026-11-20'));
      // Following nodes in reverse chronological order
      expect(chronicle[1].rank, equals('Enlighted'));
      expect(chronicle[1].isCurrent, isFalse);
      expect(chronicle[2].rank, equals('Rookie'));
      expect(chronicle[3].rank, equals('Novice'));
    });
  });

  group('3. Quest Log Permanent Deletion in Hive', () {
    test('deleteQuestLog permanently deletes log from Hive and reactive list', () async {
      final user = UserModel(
        username: 'cleaner',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('cleaner');

      final log1 = QuestLogModel(
        id: 'cleaner_log_1',
        username: 'cleaner',
        questType: 'workout',
        title: 'PUSH UPS',
        completedAt: DateTime.now(),
        metricSummary: '20 REPS',
      );
      final log2 = QuestLogModel(
        id: 'cleaner_log_2',
        username: 'cleaner',
        questType: 'cardio',
        title: 'CARDIO RUN',
        completedAt: DateTime.now(),
        metricSummary: '3.0 KM',
      );

      await Hive.box<QuestLogModel>(HiveBoxes.questLogs).put(log1.id, log1);
      await Hive.box<QuestLogModel>(HiveBoxes.questLogs).put(log2.id, log2);

      statsController = Get.put(StatsController());
      statsController.loadQuestLogs();

      expect(statsController.questLogs.length, equals(2));
      expect(Hive.box<QuestLogModel>(HiveBoxes.questLogs).containsKey('cleaner_log_1'), isTrue);

      // Delete log 1
      await statsController.deleteQuestLog('cleaner_log_1');

      // Verify Hive deletion
      expect(Hive.box<QuestLogModel>(HiveBoxes.questLogs).containsKey('cleaner_log_1'), isFalse);
      expect(Hive.box<QuestLogModel>(HiveBoxes.questLogs).containsKey('cleaner_log_2'), isTrue);

      // Verify reactive list update
      expect(statsController.questLogs.length, equals(1));
      expect(statsController.questLogs.first.id, equals('cleaner_log_2'));
    });
  });

  group('4. Sub-Tab Switcher State', () {
    test('changeTab switches between ATTRIBUTES (0) and SEJARAH (1)', () {
      statsController = Get.put(StatsController());
      expect(statsController.selectedTab.value, equals(0));

      statsController.changeTab(1);
      expect(statsController.selectedTab.value, equals(1));

      statsController.changeTab(0);
      expect(statsController.selectedTab.value, equals(0));
    });
  });

  group('5. System Codex (GuidePage)', () {
    testWidgets('GuidePage renders all 4 sections with 6 stats (SPD), ranks, strata, and penalties',
        (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: GuidePage(),
        ),
      );

      // Header
      expect(find.text('SYSTEM CODEX'), findsOneWidget);

      // Section 1: Stat Acquisition
      expect(find.text('STAT ACQUISITION'), findsOneWidget);
      expect(find.text('STRENGTH'), findsOneWidget);
      expect(find.text('ENDURANCE'), findsOneWidget);
      expect(find.text('SPEED'), findsOneWidget);
      expect(find.text('(SPD)'), findsOneWidget);
      expect(find.text('INTELLECT'), findsOneWidget);
      expect(find.text('ALLURE'), findsOneWidget);
      expect(find.text('WILLPOWER'), findsOneWidget);

      // Section 2: Rank Progression
      expect(find.text('RANK PROGRESSION'), findsOneWidget);
      expect(find.text('APOSTLE'), findsOneWidget);
      expect(find.text('PREACHER'), findsOneWidget);
      expect(find.text('SAINT'), findsOneWidget);
      expect(find.text('ENLIGHTED'), findsOneWidget);
      expect(find.text('ROOKIE'), findsOneWidget);
      expect(find.text('BEGINNER'), findsOneWidget);
      expect(find.text('NOVICE'), findsOneWidget);

      // Section 3: Strata Tiers
      expect(find.text('STRATA TIERS'), findsOneWidget);
      expect(find.text('SSS'), findsOneWidget);
      expect(find.text('SS'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      expect(find.text('E'), findsOneWidget);

      // Section 4: Inactivity Penalty Protocol
      expect(find.text('INACTIVITY PENALTY PROTOCOL'), findsOneWidget);
    });
  });
}
