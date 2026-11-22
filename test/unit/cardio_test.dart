import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:levmaxreborn/controller/cardio_controller.dart';
import 'package:levmaxreborn/controller/quest_controller.dart';
import 'package:levmaxreborn/controller/user_controller.dart';
import 'package:levmaxreborn/core/constants/hive_boxes.dart';
import 'package:levmaxreborn/core/utils/stat_calculator.dart';
import 'package:levmaxreborn/model/achievement_model.dart';
import 'package:levmaxreborn/model/daily_quest_state_model.dart';
import 'package:levmaxreborn/model/grooming_item_model.dart';
import 'package:levmaxreborn/model/quest_log_model.dart';
import 'package:levmaxreborn/model/user_model.dart';
import 'package:levmaxreborn/model/weather_model.dart';
import 'package:levmaxreborn/service/api_service.dart';
import 'package:levmaxreborn/service/location_service.dart';
import 'package:levmaxreborn/service/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late UserController userController;
  late QuestController questController;
  late CardioController cardioController;

  setUpAll(() async {
    Get.testMode = true;
    tempDir = await Directory.systemTemp.createTemp('hive_cardio_test_');
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
    cardioController = Get.put<CardioController>(CardioController());
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
    cardioController.routePoints.clear();
    cardioController.distanceMeters.value = 0.0;
    cardioController.durationSeconds.value = 0;
    cardioController.avgPace.value = 0.0;
    cardioController.isTracking.value = false;
    cardioController.isPaused.value = false;
  });

  group('1. Weather Model & Open-Meteo REST API', () {
    test('WeatherModel.fromJson deserializes Open-Meteo response accurately', () {
      final json = {
        'current_weather': {
          'temperature': 28.4,
          'windspeed': 11.2,
          'weathercode': 2,
          'is_day': 1,
          'time': '2026-11-22T14:00',
        }
      };

      final weather = WeatherModel.fromJson(json);
      expect(weather.temperature, 28.4);
      expect(weather.windSpeed, 11.2);
      expect(weather.weatherCode, 2);
      expect(weather.conditionLabel, 'CLOUDY');
      expect(weather.displayTelemetry, '28°C · CLOUDY');
      expect(weather.isOffline, isFalse);
    });

    test('WMO interpretation maps weather codes to correct cyberpunk labels', () {
      expect(const WeatherModel(temperature: 20, windSpeed: 5, weatherCode: 0, isDay: 1, time: '').conditionLabel, 'CLEAR SKY');
      expect(const WeatherModel(temperature: 20, windSpeed: 5, weatherCode: 2, isDay: 1, time: '').conditionLabel, 'CLOUDY');
      expect(const WeatherModel(temperature: 20, windSpeed: 5, weatherCode: 45, isDay: 1, time: '').conditionLabel, 'FOGGY');
      expect(const WeatherModel(temperature: 20, windSpeed: 5, weatherCode: 61, isDay: 1, time: '').conditionLabel, 'RAIN');
      expect(const WeatherModel(temperature: 20, windSpeed: 5, weatherCode: 95, isDay: 1, time: '').conditionLabel, 'STORM');
    });

    test('ApiService.fetchCurrentWeather parses API result and uses fallback on failure', () async {
      final apiService = ApiService();

      // Mock 200 OK
      final mockClientSuccess = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'current_weather': {
              'temperature': 29.0,
              'windspeed': 8.5,
              'weathercode': 0,
              'is_day': 1,
              'time': '2026-11-22T12:00',
            }
          }),
          200,
        );
      });

      final successWeather = await apiService.fetchCurrentWeather(client: mockClientSuccess);
      expect(successWeather.temperature, 29.0);
      expect(successWeather.conditionLabel, 'CLEAR SKY');

      // Mock 500 Server Error
      final mockClientError = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final fallbackWeather = await apiService.fetchCurrentWeather(client: mockClientError);
      expect(fallbackWeather.isOffline, isTrue);
      expect(fallbackWeather.temperature, 28.0);
    });
  });

  group('2. LocationService & Anti-Cheat Validation', () {
    test('Anti-cheat detects and rejects speeds exceeding 24 km/h (6.67 m/s)', () {
      // 12 km/h running speed (~3.33 m/s) -> VALID
      const runningSpeedMps = 12.0 / 3.6;
      expect(LocationService.isValidSpeed(runningSpeedMps), isTrue);

      // 36 km/h vehicle speed (10.0 m/s) -> INVALID (Anti-Cheat triggered)
      const vehicleSpeedMps = 36.0 / 3.6;
      expect(LocationService.isValidSpeed(vehicleSpeedMps), isFalse);

      // 60 km/h car speed (16.67 m/s) -> INVALID
      const carSpeedMps = 60.0 / 3.6;
      expect(LocationService.isValidSpeed(carSpeedMps), isFalse);
    });

    test('Step interval speed validation identifies abnormal velocity bursts', () {
      // 20 meters in 4 seconds = 5 m/s = 18 km/h -> VALID
      expect(LocationService.isValidStep(distanceMeters: 20, elapsedSeconds: 4), isTrue);

      // 100 meters in 5 seconds = 20 m/s = 72 km/h -> INVALID
      expect(LocationService.isValidStep(distanceMeters: 100, elapsedSeconds: 5), isFalse);
    });
  });

  group('3. Cardio Telemetry & Dynamic SPD Calculation', () {
    test('Pace thresholds award correct SPD (+1 to +4)', () {
      // Pace < 5.5 min/km -> +4 SPD
      expect(StatCalculator.calculateCardioSpdReward(4.5), 4);
      expect(StatCalculator.calculateCardioSpdReward(5.2), 4);

      // Pace 5.5 to 6.99 min/km -> +3 SPD
      expect(StatCalculator.calculateCardioSpdReward(5.5), 3);
      expect(StatCalculator.calculateCardioSpdReward(6.3), 3);

      // Pace 7.0 to 9.0 min/km -> +2 SPD
      expect(StatCalculator.calculateCardioSpdReward(7.0), 2);
      expect(StatCalculator.calculateCardioSpdReward(8.5), 2);

      // Pace > 9.0 min/km -> +1 SPD
      expect(StatCalculator.calculateCardioSpdReward(9.5), 1);
      expect(StatCalculator.calculateCardioSpdReward(12.0), 1);
    });

    test('Demo simulation boosts distance and updates pace and progress dynamically', () {
      expect(cardioController.distanceKm, 0.0);
      expect(cardioController.durationSeconds.value, 0);

      // Simulate +500m
      cardioController.simulateAddDistance(meters: 500.0);
      expect(cardioController.distanceKm, 0.5);
      expect(cardioController.durationSeconds.value, 150);
      // Pace: (150s / 60s) / 0.5km = 2.5 / 0.5 = 5.0 min/km
      expect(cardioController.avgPace.value, 5.0);
      expect(cardioController.formattedPace, '5:00 /km');

      // Simulate another +500m (total 1.0 km in 300s)
      cardioController.simulateAddDistance(meters: 500.0);
      expect(cardioController.distanceKm, 1.0);
      expect(cardioController.durationSeconds.value, 300);
      expect(cardioController.avgPace.value, 5.0);
    });
  });

  group('4. Cardio Quest Execution, Logging & Achievements', () {
    test('Finishing run awards +2 END, pace-based SPD, +25 EXP, and logs to Hive', () async {
      final user = UserModel(
        username: 'strider',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
        endurance: 10,
        speed: 10,
        exp: 0,
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('strider');

      final state = DailyQuestStateModel(
        username: 'strider',
        date: '2026-11-22',
        workoutExercises: ['Push Ups', 'Squats'],
      );
      await Hive.box<DailyQuestStateModel>(HiveBoxes.dailyQuestStates)
          .put('strider_2026-11-22', state);
      questController.dailyQuest.value = state;

      // Simulate 1.0 km at 5:00 min/km pace
      cardioController.simulateAddDistance(meters: 1000.0);
      expect(cardioController.distanceKm, 1.0);
      expect(cardioController.avgPace.value, 5.0);

      final result = await cardioController.finishRun();
      expect(result, isNotNull);

      // 5:00 min/km pace (< 5.5) yields +4 SPD and +2 END
      expect(user.endurance, 12); // 10 + 2 END
      expect(user.speed, 14); // 10 + 4 SPD
      expect(user.exp, 25); // +25 EXP

      // DailyQuestState updated
      expect(questController.dailyQuest.value!.cardioCompleted, isTrue);

      // QuestLogModel saved in Hive with distance and pace
      final logs = Hive.box<QuestLogModel>(HiveBoxes.questLogs).values.toList();
      expect(logs.any((l) => l.questType == 'cardio'), isTrue);
      final cardioLog = logs.firstWhere((l) => l.questType == 'cardio');
      expect(cardioLog.username, 'strider');
      expect(cardioLog.distanceKm, 1.0);
      expect(cardioLog.paceMinPerKm, 5.0);
      expect(cardioLog.statRewards['END'], 2);
      expect(cardioLog.statRewards['SPD'], 4);
    });

    test('PHANTOM VELOCITY achievement unlocks when pace <= 3:59 min/km', () async {
      final user = UserModel(
        username: 'speedster',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('speedster');

      // Fast pace: 3:30 min/km (3.5 min/km <= 3.99)
      final fastLog = QuestLogModel(
        id: 'fast_cardio_1',
        username: 'speedster',
        questType: 'cardio',
        title: 'CARDIO RUN',
        completedAt: DateTime.now(),
        expGained: 25,
        statRewards: {'END': 2, 'SPD': 4},
        metricSummary: '2.0 KM · 3:30 /km',
        distanceKm: 2.0,
        paceMinPerKm: 3.5,
      );
      await Hive.box<QuestLogModel>(HiveBoxes.questLogs).put(fastLog.id, fastLog);

      final unlocked = await userController.checkAchievements([fastLog]);
      expect(unlocked.contains('PHANTOM VELOCITY'), isTrue);
      expect(user.unlockedAchievements.containsKey('phantom_velocity'), isTrue);

      final achievements = AchievementModel.evaluateAll(
        user: user,
        logs: [fastLog],
      );

      final phantomVelocity = achievements.firstWhere((a) => a.id == 'phantom_velocity');
      expect(phantomVelocity.isUnlocked, isTrue);
    });

    test('WAYFARER achievement tracks cumulative distance towards 50.0 km', () async {
      final user = UserModel(
        username: 'marathoner',
        password: 'password123',
        lastActiveDate: '2026-11-22',
        createdAt: DateTime.now(),
      );
      await Hive.box<UserModel>(HiveBoxes.users).put(user.username, user);
      userController.loadUser('marathoner');

      // 5 runs of 10.0 km each = 50.0 km
      final logs = List.generate(
        5,
        (i) => QuestLogModel(
          id: 'cardio_log_$i',
          username: 'marathoner',
          questType: 'cardio',
          title: 'CARDIO RUN',
          completedAt: DateTime.now(),
          expGained: 25,
          statRewards: {'END': 2, 'SPD': 2},
          metricSummary: '10.0 KM',
          distanceKm: 10.0,
          paceMinPerKm: 6.0,
        ),
      );

      for (final log in logs) {
        await Hive.box<QuestLogModel>(HiveBoxes.questLogs).put(log.id, log);
      }

      final unlocked = await userController.checkAchievements(logs);
      expect(unlocked.contains('WAYFARER'), isTrue);
      expect(user.unlockedAchievements.containsKey('wayfarer'), isTrue);

      final achievements = AchievementModel.evaluateAll(
        user: user,
        logs: logs,
      );

      final wayfarer = achievements.firstWhere((a) => a.id == 'wayfarer');
      expect(wayfarer.isUnlocked, isTrue);
      expect(wayfarer.currentProgress, 50.0);
    });
  });
}
