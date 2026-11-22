import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:levmaxreborn/core/constants/app_colors.dart';
import 'package:levmaxreborn/core/constants/hive_boxes.dart';
import 'package:levmaxreborn/core/utils/date_helper.dart';
import 'package:levmaxreborn/controller/navigation_controller.dart';
import 'package:levmaxreborn/controller/quest_controller.dart';
import 'package:levmaxreborn/controller/quote_controller.dart';
import 'package:levmaxreborn/controller/user_controller.dart';
import 'package:levmaxreborn/model/daily_quest_state_model.dart';
import 'package:levmaxreborn/model/grooming_item_model.dart';
import 'package:levmaxreborn/model/quest_log_model.dart';
import 'package:levmaxreborn/model/quote_model.dart';
import 'package:levmaxreborn/model/user_model.dart';
import 'package:levmaxreborn/service/api_service.dart';
import 'package:levmaxreborn/service/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late UserController userController;
  late NavigationController navController;
  late QuestController questController;
  late QuoteController quoteController;

  setUpAll(() async {
    Get.testMode = true;
    tempDir = await Directory.systemTemp.createTemp('hive_home_quest_test_');
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
    navController = Get.put<NavigationController>(NavigationController());
    quoteController = Get.put<QuoteController>(QuoteController());
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
    await Hive.box<GroomingItemModel>(HiveBoxes.groomingItems).clear();
  });

  group('1. NavigationController Tab Switching', () {
    test('Default tab is 0 (HOME)', () {
      expect(navController.currentIndex.value, 0);
    });

    test('changeTab switches between 0, 1, 2, 3', () {
      navController.changeTab(1);
      expect(navController.currentIndex.value, 1);

      navController.changeTab(2);
      expect(navController.currentIndex.value, 2);

      navController.changeTab(3);
      expect(navController.currentIndex.value, 3);

      navController.changeTab(0);
      expect(navController.currentIndex.value, 0);
    });

    test('Convenience navigation methods work correctly', () {
      navController.switchToProfile();
      expect(navController.currentIndex.value, 3);

      navController.switchToMap();
      expect(navController.currentIndex.value, 1);

      navController.switchToStats();
      expect(navController.currentIndex.value, 2);

      navController.switchToHome();
      expect(navController.currentIndex.value, 0);
    });
  });

  group('2. Quote Model & API Offline Fallback', () {
    test('QuoteModel.fromJson deserializes correctly', () {
      final json = {
        'id': 14,
        'quote': 'Discipline is freedom.',
        'author': 'Jocko Willink',
      };
      final model = QuoteModel.fromJson(json);
      expect(model.id, 14);
      expect(model.quote, 'Discipline is freedom.');
      expect(model.author, 'Jocko Willink');
    });

    test('ApiService has at least 5 fallback quotes', () {
      expect(ApiService.fallbackQuotes.length, greaterThanOrEqualTo(5));
      for (final q in ApiService.fallbackQuotes) {
        expect(q.quote.isNotEmpty, isTrue);
        expect(q.author.isNotEmpty, isTrue);
      }
    });

    test('getRandomFallbackQuote returns valid quote', () {
      final q = ApiService.getRandomFallbackQuote();
      expect(q.quote.isNotEmpty, isTrue);
      expect(q.author.isNotEmpty, isTrue);
    });

    test('QuoteController initializes and manages quote state', () async {
      await quoteController.fetchQuote();
      expect(quoteController.quote.value, isNotNull);
      expect(quoteController.isLoading.value, isFalse);
    });
  });

  group('3. QuestController Daily Reset & Penalties', () {
    test('First login sets lastActiveDate and initial daily quest state', () async {
      final user = UserModel(
        username: 'hunter',
        password: 'password123',
        lastActiveDate: '',
        createdAt: DateTime.now(),
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('hunter');

      await questController.runDailyResetCheck();

      expect(user.lastActiveDate, DateHelper.todayString());
      expect(questController.dailyQuest.value, isNotNull);
      expect(questController.dailyQuest.value!.workoutExercises.length, 2);
    });

    test('Consecutive day with >= 1 quest increments streak and adds +1 WIL', () async {
      final today = DateHelper.todayString();
      final yesterday = DateHelper.formatDate(
          DateHelper.parseDate(today).subtract(const Duration(days: 1)));

      final user = UserModel(
        username: 'slayer',
        password: 'password123',
        lastActiveDate: yesterday,
        createdAt: DateTime.now(),
        streakDays: 6,
        longestStreak: 6,
        willpower: 10,
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('slayer');

      // Yesterday had 1 completed quest
      final yesterdayState = DailyQuestStateModel(
        username: 'slayer',
        date: yesterday,
        workoutExercises: ['Push Ups', 'Squats'],
        studyCompleted: true,
      );
      await Hive.box<DailyQuestStateModel>(HiveBoxes.dailyQuestStates)
          .put('slayer_$yesterday', yesterdayState);

      await questController.runDailyResetCheck();

      // Streak becomes 7 (hits 7-day milestone: +1 WIL daily login + 1 bonus WIL = +2)
      expect(user.streakDays, 7);
      expect(user.longestStreak, 7);
      expect(user.willpower, 12);
      expect(user.lastActiveDate, today);
    });

    test('Consecutive day with 0 quests resets streakDays to 0', () async {
      final today = DateHelper.todayString();
      final yesterday = DateHelper.formatDate(
          DateHelper.parseDate(today).subtract(const Duration(days: 1)));

      final user = UserModel(
        username: 'slacker',
        password: 'password123',
        lastActiveDate: yesterday,
        createdAt: DateTime.now(),
        streakDays: 14,
        longestStreak: 14,
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('slacker');

      // Yesterday had 0 completed quests
      final yesterdayState = DailyQuestStateModel(
        username: 'slacker',
        date: yesterday,
        workoutExercises: ['Push Ups', 'Squats'],
      );
      await Hive.box<DailyQuestStateModel>(HiveBoxes.dailyQuestStates)
          .put('slacker_$yesterday', yesterdayState);

      await questController.runDailyResetCheck();

      expect(user.streakDays, 0);
      expect(user.longestStreak, 14); // Longest streak preserved
    });

    test('deltaDays == 2 deducts 34 HP and breaks streak', () async {
      final today = DateHelper.todayString();
      final twoDaysAgo = DateHelper.formatDate(
          DateHelper.parseDate(today).subtract(const Duration(days: 2)));

      final user = UserModel(
        username: 'absentee',
        password: 'password123',
        lastActiveDate: twoDaysAgo,
        createdAt: DateTime.now(),
        hp: 100,
        streakDays: 5,
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('absentee');

      await questController.runDailyResetCheck();

      expect(user.hp, 66); // 100 - 34
      expect(user.streakDays, 0);
      expect(questController.hasHpWarning.value, isTrue);
      expect(questController.hpDeductionAmount, 34);
    });

    test('deltaDays >= 3 triggers 3-day inactivity penalty', () async {
      final today = DateHelper.todayString();
      final fourDaysAgo = DateHelper.formatDate(
          DateHelper.parseDate(today).subtract(const Duration(days: 4)));

      final user = UserModel(
        username: 'dormant',
        password: 'password123',
        lastActiveDate: fourDaysAgo,
        createdAt: DateTime.now(),
        hp: 50,
        streakDays: 10,
        strength: 55, // Strata B (50-74) -> Should drop to Strata C (49)
        endurance: 30, // Strata C (25-49) -> Should drop to Strata D (24)
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('dormant');

      await questController.runDailyResetCheck();

      expect(user.hp, 100); // Restored to 100 after penalty
      expect(user.streakDays, 0);
      expect(user.strength, 49);
      expect(user.endurance, 29);
      expect(questController.hasPenaltyNotice.value, isTrue);
    });

    test('Workout exercises rotate to distinct exercises', () async {
      final today = DateHelper.todayString();
      final yesterday = DateHelper.formatDate(
          DateHelper.parseDate(today).subtract(const Duration(days: 1)));

      final user = UserModel(
        username: 'athlete',
        password: 'password123',
        lastActiveDate: yesterday,
        createdAt: DateTime.now(),
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('athlete');

      // Yesterday had Push Ups & Squats
      final yesterdayState = DailyQuestStateModel(
        username: 'athlete',
        date: yesterday,
        workoutExercises: ['Push Ups', 'Squats'],
        studyCompleted: true,
      );
      await Hive.box<DailyQuestStateModel>(HiveBoxes.dailyQuestStates)
          .put('athlete_$yesterday', yesterdayState);

      // Pre-set questController's dailyQuest so previousExercises can be read
      questController.dailyQuest.value = yesterdayState;

      await questController.runDailyResetCheck();

      final todayExercises = questController.dailyQuest.value!.workoutExercises;
      expect(todayExercises.contains('Push Ups'), isFalse);
      expect(todayExercises.contains('Squats'), isFalse);
      expect(todayExercises.contains('Pull Ups'), isTrue);
      expect(todayExercises.contains('Sit Ups'), isTrue);
    });

    test('Grooming checklist resets on daily reset', () async {
      final today = DateHelper.todayString();
      final yesterday = DateHelper.formatDate(
          DateHelper.parseDate(today).subtract(const Duration(days: 1)));

      final user = UserModel(
        username: 'groomed_user',
        password: 'password123',
        lastActiveDate: yesterday,
        createdAt: DateTime.now(),
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('groomed_user');

      // Seed 2 checked grooming items
      final item1 = GroomingItemModel(
        id: 'g1',
        username: 'groomed_user',
        title: 'Morning Wash',
        isChecked: true,
      );
      final item2 = GroomingItemModel(
        id: 'g2',
        username: 'groomed_user',
        title: 'Brush Teeth',
        isChecked: true,
      );
      await Hive.box<GroomingItemModel>(HiveBoxes.groomingItems).put(item1.id, item1);
      await Hive.box<GroomingItemModel>(HiveBoxes.groomingItems).put(item2.id, item2);

      await questController.runDailyResetCheck();

      final reloadedItem1 =
          Hive.box<GroomingItemModel>(HiveBoxes.groomingItems).get('g1');
      final reloadedItem2 =
          Hive.box<GroomingItemModel>(HiveBoxes.groomingItems).get('g2');

      expect(reloadedItem1!.isChecked, isFalse);
      expect(reloadedItem2!.isChecked, isFalse);
    });
  });

  group('4. Active-First Quest Sorting & Separated Badges', () {
    test('Unfinished quests sort before completed quests', () async {
      final today = DateHelper.todayString();
      final user = UserModel(
        username: 'quest_tester',
        password: 'password123',
        lastActiveDate: today,
        createdAt: DateTime.now(),
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('quest_tester');

      // Workout 1 done, Workout 2 undone, Study done, Cardio undone, Grooming undone
      final state = DailyQuestStateModel(
        username: 'quest_tester',
        date: today,
        workoutExercises: ['Push Ups', 'Squats'],
        workoutCompleted: [true, false], // Push Ups DONE, Squats ACTIVE
        studyCompleted: true, // Study DONE
        cardioCompleted: false, // Cardio ACTIVE
        groomingCompleted: false, // Grooming ACTIVE
      );
      questController.dailyQuest.value = state;

      final sorted = questController.sortedQuests;
      expect(sorted.length, 5);

      // First 3 quests MUST be active (!isDone)
      expect(sorted[0].isDone, isFalse);
      expect(sorted[1].isDone, isFalse);
      expect(sorted[2].isDone, isFalse);

      // Last 2 quests MUST be completed (isDone)
      expect(sorted[3].isDone, isTrue);
      expect(sorted[4].isDone, isTrue);

      expect(questController.completedCount, 2);
      expect(questController.isAllCompleted, isFalse);
    });

    test('Multi-stat rewards have separated individual badges', () {
      final sorted = questController.sortedQuests;

      // Workout quests have 2 separated badges (+2 STR & +1 END)
      final workoutQuests =
          sorted.where((q) => q.type == QuestType.workout).toList();
      for (final w in workoutQuests) {
        expect(w.rewardBadges.length, 2);
        expect(w.rewardBadges[0].label, '+2 STR');
        expect(w.rewardBadges[0].color, AppColors.str);
        expect(w.rewardBadges[1].label, '+1 END');
        expect(w.rewardBadges[1].color, AppColors.end);
      }

      // Cardio quest has 2 separated badges (+2 END & +1 SPD) -> ALWAYS SPD!
      final cardio = sorted.firstWhere((q) => q.type == QuestType.cardio);
      expect(cardio.rewardBadges.length, 2);
      expect(cardio.rewardBadges[0].label, '+2 END');
      expect(cardio.rewardBadges[0].color, AppColors.end);
      expect(cardio.rewardBadges[1].label, '+1 SPD');
      expect(cardio.rewardBadges[1].color, AppColors.spd);
      expect(cardio.rewardBadges[1].label.contains('AGI'), isFalse);

      // Study has INT badge
      final study = sorted.firstWhere((q) => q.type == QuestType.study);
      expect(study.rewardBadges.length, 1);
      expect(study.rewardBadges[0].label, '+3 INT');
      expect(study.rewardBadges[0].color, AppColors.intel);

      // Grooming has APP badge
      final grooming = sorted.firstWhere((q) => q.type == QuestType.grooming);
      expect(grooming.rewardBadges.length, 1);
      expect(grooming.rewardBadges[0].label, '+3 APP');
      expect(grooming.rewardBadges[0].color, AppColors.app);
    });
  });
}
