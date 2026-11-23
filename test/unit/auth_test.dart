import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:levmaxreborn/core/constants/hive_boxes.dart';
import 'package:levmaxreborn/model/user_model.dart';
import 'package:levmaxreborn/model/quest_log_model.dart';
import 'package:levmaxreborn/model/grooming_item_model.dart';
import 'package:levmaxreborn/model/daily_quest_state_model.dart';
import 'package:levmaxreborn/controller/user_controller.dart';
import 'package:levmaxreborn/controller/auth_controller.dart';
import 'package:levmaxreborn/service/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late AuthController authController;
  late UserController userController;

  setUpAll(() async {
    Get.testMode = true;
    tempDir = await Directory.systemTemp.createTemp('hive_auth_test_');
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
    authController = Get.put<AuthController>(AuthController());
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
    await Hive.box<GroomingItemModel>(HiveBoxes.groomingItems).clear();
    await SessionService.clearSession();
    authController.clearInputs();
  });

  group('AuthController - Registration Validation', () {
    test('fails when username is empty', () async {
      authController.usernameController.text = '';
      authController.passwordController.text = 'password123';
      authController.confirmPasswordController.text = 'password123';
      authController.consentAgreed.value = true;

      final success = await authController.register();
      expect(success, isFalse);
      expect(authController.errorMessage.value, contains('IDENTIFIER CANNOT BE EMPTY'));
    });

    test('fails when password is less than 6 characters', () async {
      authController.usernameController.text = 'solo_hunter';
      authController.passwordController.text = '12345';
      authController.confirmPasswordController.text = '12345';
      authController.consentAgreed.value = true;

      final success = await authController.register();
      expect(success, isFalse);
      expect(authController.errorMessage.value, contains('AT LEAST 6 CHARACTERS'));
    });

    test('fails when confirm password does not match', () async {
      authController.usernameController.text = 'solo_hunter';
      authController.passwordController.text = 'password123';
      authController.confirmPasswordController.text = 'password999';
      authController.consentAgreed.value = true;

      final success = await authController.register();
      expect(success, isFalse);
      expect(authController.errorMessage.value, contains('DOES NOT MATCH'));
    });

    test('fails when consent checkbox is not checked', () async {
      authController.usernameController.text = 'solo_hunter';
      authController.passwordController.text = 'password123';
      authController.confirmPasswordController.text = 'password123';
      authController.consentAgreed.value = false; // not checked!

      final success = await authController.register();
      expect(success, isFalse);
      expect(authController.errorMessage.value, contains('COVENANTS MUST BE ACCEPTED'));
    });

    test('fails when username is already registered (unique username)', () async {
      final existing = UserModel(
        username: 'existing_hunter',
        password: 'pass123456',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
      );
      await Hive.box<UserModel>(HiveBoxes.users).put('existing_hunter', existing);

      authController.usernameController.text = 'existing_hunter';
      authController.passwordController.text = 'newpass123';
      authController.confirmPasswordController.text = 'newpass123';
      authController.consentAgreed.value = true;

      final success = await authController.register();
      expect(success, isFalse);
      expect(authController.errorMessage.value, contains('ALREADY REGISTERED'));
    });
  });

  group('AuthController - Successful Registration & Auto-Seed', () {
    test('successful registration auto-seeds 5 grooming items, rankHistory, growthSnapshots, and THE AWAKENING', () async {
      authController.usernameController.text = 'sung_jinwoo';
      authController.passwordController.text = 'shadowmonarch';
      authController.confirmPasswordController.text = 'shadowmonarch';
      authController.consentAgreed.value = true;

      final success = await authController.register();
      expect(success, isTrue);

      // Verify UserModel in Hive
      final user = Hive.box<UserModel>(HiveBoxes.users).get('sung_jinwoo');
      expect(user, isNotNull);
      expect(user!.username, equals('sung_jinwoo'));
      expect(user.level, equals(1));
      expect(user.exp, equals(0));
      expect(user.hp, equals(100));

      // 1. rankHistory['Novice']
      expect(user.rankHistory.containsKey('Novice'), isTrue);

      // 2. growthSnapshots
      expect(user.growthSnapshots.values.first, equals(0));

      // 3. THE AWAKENING achievement unlocked
      expect(user.unlockedAchievements.containsKey('the_awakening'), isTrue);

      // 4. 5 default grooming items seeded in Hive
      final groomingBox = Hive.box<GroomingItemModel>(HiveBoxes.groomingItems);
      final userGrooming = groomingBox.values.where((item) => item.username == 'sung_jinwoo').toList();
      expect(userGrooming.length, equals(5));
      expect(userGrooming.any((item) => item.title == 'MORNING FACIAL WASH'), isTrue);
      expect(userGrooming.any((item) => item.title == 'BRUSH TEETH 2X'), isTrue);
      expect(userGrooming.any((item) => item.title == 'SHOWER & DEODORANT'), isTrue);
      expect(userGrooming.any((item) => item.title == 'DRINK 2L WATER'), isTrue);
      expect(userGrooming.any((item) => item.title == 'APPLY SUNSCREEN'), isTrue);

      // 5. Session remains logged out so user enters login page
      expect(SessionService.isLoggedIn, isFalse);

      // 6. User can now manually log in
      authController.usernameController.text = 'sung_jinwoo';
      authController.passwordController.text = 'shadowmonarch';
      final loginSuccess = await authController.login();
      expect(loginSuccess, isTrue);
      expect(SessionService.isLoggedIn, isTrue);
      expect(SessionService.activeUsername, equals('sung_jinwoo'));
      expect(userController.hasUser, isTrue);
      expect(userController.username, equals('sung_jinwoo'));
    });
  });

  group('AuthController - Login & Logout Session', () {
    test('login with valid credentials updates session and loads user', () async {
      // Seed user
      final user = UserModel(
        username: 'cyber_knight',
        password: 'securePassword',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
      );
      await Hive.box<UserModel>(HiveBoxes.users).put('cyber_knight', user);

      authController.usernameController.text = 'cyber_knight';
      authController.passwordController.text = 'securePassword';

      final success = await authController.login();
      expect(success, isTrue);
      expect(SessionService.isLoggedIn, isTrue);
      expect(SessionService.activeUsername, equals('cyber_knight'));
      expect(userController.username, equals('cyber_knight'));
    });

    test('login with wrong password fails', () async {
      final user = UserModel(
        username: 'cyber_knight',
        password: 'securePassword',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
      );
      await Hive.box<UserModel>(HiveBoxes.users).put('cyber_knight', user);

      authController.usernameController.text = 'cyber_knight';
      authController.passwordController.text = 'wrongPassword';

      final success = await authController.login();
      expect(success, isFalse);
      expect(authController.errorMessage.value, contains('INVALID CREDENTIALS'));
      expect(SessionService.isLoggedIn, isFalse);
    });

    test('logout clears SharedPreferences and resets UserController', () async {
      await SessionService.setIsLoggedIn(true);
      await SessionService.setActiveUsername('cyber_knight');
      userController.loadUser('cyber_knight');

      await authController.logout();

      expect(SessionService.isLoggedIn, isFalse);
      expect(SessionService.activeUsername, equals(''));
      expect(userController.user.value, isNull);
    });
  });
}
