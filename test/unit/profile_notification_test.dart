import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:levmaxreborn/controller/user_controller.dart';
import 'package:levmaxreborn/core/constants/hive_boxes.dart';
import 'package:levmaxreborn/model/daily_quest_state_model.dart';
import 'package:levmaxreborn/model/grooming_item_model.dart';
import 'package:levmaxreborn/model/quest_log_model.dart';
import 'package:levmaxreborn/model/user_model.dart';
import 'package:levmaxreborn/service/notification_service.dart';
import 'package:levmaxreborn/service/session_service.dart';
import 'package:levmaxreborn/view/pages/achievements_page.dart';
import 'package:levmaxreborn/view/widgets/streak_flame_badge.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late UserController userController;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('profile_notif_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(QuestLogModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(GroomingItemModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DailyQuestStateModelAdapter());

    await Hive.openBox<UserModel>(HiveBoxes.users);
    await Hive.openBox<QuestLogModel>(HiveBoxes.questLogs);
    await Hive.openBox<GroomingItemModel>(HiveBoxes.groomingItems);
    await Hive.openBox<DailyQuestStateModel>(HiveBoxes.dailyQuestStates);

    SharedPreferences.setMockInitialValues({});
    NotificationService.isTestMode = true;
    await SessionService.init();
    await NotificationService.init();

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
    NotificationService.clearHistory();
    await Hive.box<UserModel>(HiveBoxes.users).clear();
    await Hive.box<QuestLogModel>(HiveBoxes.questLogs).clear();
    await SessionService.clearSession();

    userController = Get.put(UserController());
  });

  group('1. Notification System (Immediate & Scheduled)', () {
    test('NotificationService records Immediate Quest, Level Up, Rank Up, and Achievement notifications',
        () async {
      await NotificationService.showQuestCompleted(
        questTitle: 'PUSH UPS',
        expGained: 25,
      );
      await NotificationService.showLevelUp(newLevel: 2);
      await NotificationService.showRankUp(newRank: 'Beginner');
      await NotificationService.showAchievementUnlocked(
        achievementTitle: 'THE AWAKENING',
      );
      await NotificationService.showProfileUpdated(
        username: 'SOLO_HUNTER',
      );

      final history = NotificationService.sentHistory;
      expect(history.length, equals(5));

      // Quest Complete
      expect(history[0].id, equals(NotificationService.idQuestCompleted));
      expect(history[0].title, contains('PUSH UPS'));
      expect(history[0].body, contains('25 EXP'));

      // Level Up
      expect(history[1].id, equals(NotificationService.idLevelUp));
      expect(history[1].title, contains('LV. 2'));

      // Rank Up
      expect(history[2].id, equals(NotificationService.idRankUp));
      expect(history[2].title, contains('BEGINNER'));

      // Achievement
      expect(history[3].id, equals(NotificationService.idAchievement));
      expect(history[3].title, contains('THE AWAKENING'));

      // Profile Updated
      expect(history[4].id, equals(NotificationService.idProfileUpdated));
      expect(history[4].title, contains('SOLO_HUNTER'));
      expect(history[4].body, contains('recalibrated'));
    });

    test('NotificationService arms and disarms 19:00 Scheduled Daily Reminder',
        () async {
      await NotificationService.scheduleDailyReminder(hour: 19, minute: 0);

      final scheduled = NotificationService.sentHistory
          .where((n) => n.id == NotificationService.idDailyReminder)
          .toList();
      expect(scheduled.isNotEmpty, isTrue);
      expect(scheduled.first.isScheduled, isTrue);
      expect(scheduled.first.title, contains('DAILY SYSTEM REMINDER'));

      // Cancel reminder
      await NotificationService.cancelDailyReminder();
    });
  });

  group('2. Edit Profile & Hive / SharedPreferences Synchronization', () {
    test('updateProfile updates photo, username, and password persistently',
        () async {
      final user = UserModel(
        username: 'old_codename',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      await SessionService.setActiveUsername('old_codename');
      await SessionService.setIsLoggedIn(true);

      userController.loadUser('old_codename');

      // Update to new codename & new photo
      await userController.updateProfile(
        photoPath: '/storage/avatar_mock.png',
        newUsername: 'shadow_stalker',
        newPassword: 'new_secret_password',
      );

      // Verify Hive old key deleted and new key created
      final usersBox = Hive.box<UserModel>(HiveBoxes.users);
      expect(usersBox.containsKey('old_codename'), isFalse);
      expect(usersBox.containsKey('shadow_stalker'), isTrue);

      final updated = usersBox.get('shadow_stalker');
      expect(updated?.photoPath, equals('/storage/avatar_mock.png'));
      expect(updated?.password, equals('new_secret_password'));

      // Verify SharedPreferences updated active username
      expect(SessionService.activeUsername, equals('shadow_stalker'));

      // Verify NotificationService fired profile update notification
      final profileNotifs = NotificationService.sentHistory
          .where((n) => n.id == NotificationService.idProfileUpdated)
          .toList();
      expect(profileNotifs.isNotEmpty, isTrue);
      expect(profileNotifs.last.title, contains('SHADOW_STALKER'));
    });
  });

  group('3. Developer Demo Mode Controls in UserController', () {
    test('+3 Days Penalty drops all 6 stats by 1 strata, resets HP to 100 and streak to 0',
        () async {
      final user = UserModel(
        username: 'penalized_user',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        hp: 34,
        streakDays: 12,
        strength: 120, // Strata S -> drops to 99
        endurance: 85, // Strata A -> drops to 79
        speed: 75, // Strata B -> drops to 69
        intelligence: 55, // Strata C -> drops to 49
        willpower: 35, // Strata D -> drops to 29
        appearance: 20, // Strata E -> drops to 0
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('penalized_user');

      await userController.applyThreeDayPenalty();

      final u = userController.currentUser!;
      expect(u.hp, equals(100));
      expect(u.streakDays, equals(0));
      expect(u.strength, equals(99));
      expect(u.endurance, equals(79));
      expect(u.speed, equals(69));
      expect(u.intelligence, equals(49));
      expect(u.willpower, equals(29));
      expect(u.appearance, equals(0));
    });

    test('deductHp reduces HP and triggers penalty when hitting 0', () async {
      final user = UserModel(
        username: 'hp_test_user',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        hp: 100,
        streakDays: 5,
        strength: 55, // Strata C (50-69)
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('hp_test_user');

      // 1. Deduct 34 HP (Missed 1 day)
      await userController.deductHp(34);
      expect(userController.currentUser!.hp, equals(66));
      expect(userController.currentUser!.streakDays, equals(0));

      // 2. Deduct 34 HP again (Missed 2nd day)
      await userController.deductHp(34);
      expect(userController.currentUser!.hp, equals(32));

      // 3. Deduct 34 HP again (Hits 0 HP -> triggers 3-day penalty, drops strata to D 49, restores HP to 100)
      await userController.deductHp(34);
      expect(userController.currentUser!.hp, equals(100));
      expect(userController.currentUser!.strength, equals(49));
    });

    test('+50 All Stats increases all 6 attributes and triggers rank recalculation',
        () async {
      final user = UserModel(
        username: 'boosted_hunter',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        strength: 10,
        endurance: 10,
        speed: 10,
        intelligence: 10,
        willpower: 10,
        appearance: 10,
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('boosted_hunter');

      expect(userController.currentUser!.totalStats, equals(60));
      expect(userController.currentUser!.rank, equals('Novice'));

      // Add +50 to all 6 stats (Total +300 points -> 360 total -> Enlighted rank)
      await userController.addStatsToAll(50);

      final u = userController.currentUser!;
      expect(u.strength, equals(60));
      expect(u.endurance, equals(60));
      expect(u.speed, equals(60));
      expect(u.intelligence, equals(60));
      expect(u.willpower, equals(60));
      expect(u.appearance, equals(60));
      expect(u.totalStats, equals(360));
      expect(u.rank, equals('Enlighted'));
      expect(u.rankHistory.containsKey('Enlighted'), isTrue);
    });

    test('+300 EXP triggers Level Up (+2 all stats) and sends Level Up notification',
        () async {
      final user = UserModel(
        username: 'exp_tester',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        level: 1,
        exp: 0,
        strength: 10,
        endurance: 10,
        speed: 10,
        intelligence: 10,
        willpower: 10,
        appearance: 10,
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('exp_tester');

      final result = await userController.addExp(300);

      expect(result.didLevelUp, isTrue);
      expect(result.newLevel, greaterThan(1));
      // Level Up awards +2 to all 6 stats per level gained
      expect(userController.currentUser!.strength, greaterThan(10));
      expect(userController.currentUser!.endurance, greaterThan(10));

      final levelUpNotif = NotificationService.sentHistory
          .where((n) => n.id == NotificationService.idLevelUp);
      expect(levelUpNotif.isNotEmpty, isTrue);
    });

    test('Skip Rest Timer and Daily Reminder preferences persist in SessionService',
        () async {
      await SessionService.setSkipRestTimer(true);
      expect(SessionService.skipRestTimer, isTrue);

      await SessionService.setSkipRestTimer(false);
      expect(SessionService.skipRestTimer, isFalse);

      await SessionService.setDailyReminderEnabled(false);
      expect(SessionService.dailyReminderEnabled, isFalse);

      await SessionService.setDailyReminderEnabled(true);
      expect(SessionService.dailyReminderEnabled, isTrue);
    });
  });

  group('4. Achievements Page Rendering & Evaluation', () {
    testWidgets('AchievementsPage renders Summary HUD, Unlocked, Unlocked Rare, and Locked items',
        (tester) async {
      final user = UserModel(
        username: 'achiever',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        unlockedAchievements: {
          'the_awakening': '2026-11-22',
          'phantom_velocity': '2026-11-22', // Rare achievement
        },
      );
      await tester.runAsync(() async {
        await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      });
      userController.loadUser('achiever');
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsPage(),
        ),
      );

      // Header & HUD
      expect(find.text('ACHIEVEMENTS'), findsOneWidget);
      expect(find.text('HONORS UNLOCKED'), findsOneWidget);
      expect(find.text('02'), findsOneWidget); // 2 unlocked
      expect(find.text(' / 08'), findsOneWidget);

      // Verify specific achievements
      expect(find.text('THE AWAKENING'), findsOneWidget);
      expect(find.text('PHANTOM VELOCITY'), findsOneWidget);
      expect(find.text('CENTURION'), findsOneWidget);
      expect(find.text('UNBROKEN'), findsOneWidget);
    });
  });

  group('5. StreakFlameBadge Tiered Vector Colors', () {
    testWidgets('StreakFlameBadge colors adapt according to streak tiers',
        (tester) async {
      // 0 days: Muted
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StreakFlameBadge(streakDays: 0))),
      );
      expect(find.text('0D STREAK'), findsOneWidget);

      // 5 days: Yellow
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StreakFlameBadge(streakDays: 5))),
      );
      expect(find.text('5D STREAK'), findsOneWidget);

      // 10 days: Orange
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StreakFlameBadge(streakDays: 10))),
      );
      expect(find.text('10D STREAK'), findsOneWidget);

      // 20 days: Red
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StreakFlameBadge(streakDays: 20))),
      );
      expect(find.text('20D STREAK'), findsOneWidget);

      // 35 days: Purple
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StreakFlameBadge(streakDays: 35))),
      );
      expect(find.text('35D STREAK'), findsOneWidget);
    });
  });
}
