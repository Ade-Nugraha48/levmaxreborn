import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/game_config.dart';
import '../core/utils/stat_calculator.dart';
import '../model/weather_model.dart';
import '../service/api_service.dart';
import '../service/location_service.dart';
import 'quest_controller.dart';
import 'user_controller.dart';

/// Cardio Controller
/// Manages LBS GPS tracking, Open-Meteo real-time weather integration,
/// pace & distance telemetry calculations, anti-cheat protection (<= 24 km/h),
/// demo mode simulation (+500m), and quest completion.
/// Conforms to `docs/roadmap.md` (Phase 6) and `docs/api_spec.md`.
class CardioController extends GetxController {
  static CardioController get to => Get.find<CardioController>();

  final ApiService _apiService = ApiService();

  // Reactive State
  final RxBool isTracking = false.obs;
  final RxBool isPaused = false.obs;
  final RxDouble distanceMeters = 0.0.obs;
  final RxInt durationSeconds = 0.obs;
  final RxList<LatLng> routePoints = <LatLng>[].obs;
  final RxDouble avgPace = 0.0.obs;
  final Rxn<WeatherModel> weather = Rxn<WeatherModel>();
  final RxBool isLoadingWeather = false.obs;
  final Rxn<Position> currentPosition = Rxn<Position>();
  final RxString locationStatusMessage = ''.obs;
  final RxBool antiCheatWarning = false.obs;

  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastWaypointTime;

  @override
  void onInit() {
    super.onInit();
    fetchWeather();
    _initInitialPosition();
  }

  @override
  void onClose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    super.onClose();
  }

  // ==========================================
  // COMPUTED TELEMETRY GETTERS
  // ==========================================

  double get distanceKm => distanceMeters.value / 1000.0;

  String get userRank {
    if (Get.isRegistered<UserController>()) {
      return UserController.to.rank;
    }
    return 'Novice';
  }

  double get targetKm {
    final target = GameConfig.rankTargets[userRank];
    return target?.cardioDistanceKm ?? 1.0;
  }

  double get progressRatio {
    if (targetKm == 0) return 1.0;
    return (distanceKm / targetKm).clamp(0.0, 1.0);
  }

  int get percentage => (progressRatio * 100).round();

  double get remainingKm => (targetKm - distanceKm).clamp(0.0, targetKm);

  bool get isTargetMet => distanceKm >= targetKm;

  bool get isAlreadyCompletedToday {
    if (Get.isRegistered<QuestController>()) {
      return QuestController.to.dailyQuest.value?.cardioCompleted ?? false;
    }
    return false;
  }

  String get formattedPace => StatCalculator.formatPace(avgPace.value);

  String get formattedDuration {
    final mins = durationSeconds.value ~/ 60;
    final secs = durationSeconds.value % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // ==========================================
  // WEATHER INTEGRATION (Open-Meteo REST API)
  // ==========================================

  Future<void> fetchWeather({double? lat, double? lon}) async {
    isLoadingWeather.value = true;
    try {
      final double latitude = lat ?? currentPosition.value?.latitude ?? -7.7828;
      final double longitude = lon ?? currentPosition.value?.longitude ?? 110.3670;
      final result = await _apiService.fetchCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );
      weather.value = result;
    } catch (_) {
      weather.value = WeatherModel.fallback();
    } finally {
      isLoadingWeather.value = false;
    }
  }

  Future<void> _initInitialPosition() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        currentPosition.value = pos;
        if (routePoints.isEmpty) {
          routePoints.add(LatLng(pos.latitude, pos.longitude));
        }
      }
    } catch (_) {}
  }

  // ==========================================
  // CARDIO TRACKING CONTROLS (Module 7: LBS)
  // ==========================================

  /// Initiates Cardio tracking session with GPS validation
  Future<bool> startCardio() async {
    // 1. Verify Location Service (GPS) is enabled
    final serviceEnabled = await LocationService.isServiceEnabled();
    if (!serviceEnabled) {
      if (!Get.testMode && Get.context != null) {
        Get.snackbar(
          'GPS PROTOCOL INACTIVE',
          'Please enable device Location/GPS services to initiate Cardio Tracking.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surfaceElevated,
          colorText: AppColors.errorRed,
        );
      }
      locationStatusMessage.value = 'GPS DISABLED';
      return false;
    }

    // 2. Verify and request location permission
    final permission = await LocationService.checkAndRequestPermission();
    if (!LocationService.isPermissionGranted(permission)) {
      if (!Get.testMode && Get.context != null) {
        Get.snackbar(
          'LBS PERMISSION DENIED',
          'Location access is required for geodesic route tracking and telemetry.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surfaceElevated,
          colorText: AppColors.errorRed,
        );
      }
      locationStatusMessage.value = 'PERMISSION DENIED';
      return false;
    }

    // 3. Reset session parameters
    distanceMeters.value = 0.0;
    durationSeconds.value = 0;
    avgPace.value = 0.0;
    routePoints.clear();
    antiCheatWarning.value = false;
    locationStatusMessage.value = 'TRACKING ACTIVE';

    // 4. Start active tracking state
    isTracking.value = true;
    isPaused.value = false;
    _lastWaypointTime = DateTime.now();

    // 5. Start Duration Timer
    if (!Get.testMode) {
      _startTimer();
    }

    // 6. Start GPS Position Stream
    _startPositionStream();

    return true;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPaused.value) {
        durationSeconds.value++;
        if (distanceKm > 0.01) {
          avgPace.value = StatCalculator.calculatePace(
            distanceKm,
            durationSeconds.value,
          );
        }
      }
    });
  }

  void _startPositionStream() {
    _positionSubscription?.cancel();
    try {
      // Dengarkan perubahan titik GPS HP setiap pergerakan minimal 5 meter
      _positionSubscription = LocationService.getPositionStream(distanceFilter: 5)
          .listen((position) {
        if (!isTracking.value || isPaused.value) return;

        // Filter anti-cheat: tolak koordinat kalau kecepatan di atas 24 km/jam (curiga naik kendaraan)
        if (!LocationService.isValidSpeed(position.speed)) {
          antiCheatWarning.value = true;
          return; // Abaikan titik GPS yang melebihi batas lari manusia
        }

        final newPoint = LatLng(position.latitude, position.longitude);
        currentPosition.value = position;

        if (routePoints.isEmpty) {
          routePoints.add(newPoint);
          _lastWaypointTime = DateTime.now();
          return;
        }

        final lastPoint = routePoints.last;
        // Hitung jarak antara titik sebelumnya ke titik baru dengan rumus geodetic
        final stepDistance = LocationService.distanceBetween(
          lastPoint.latitude,
          lastPoint.longitude,
          newPoint.latitude,
          newPoint.longitude,
        );

        // Abaikan goyangan GPS kecil (< 1 meter) biar gak nambah jarak palsu saat diam
        if (stepDistance >= 1.0) {
          final now = DateTime.now();
          final elapsed = _lastWaypointTime != null
              ? now.difference(_lastWaypointTime!).inSeconds
              : 1;

          // Verifikasi anti-cheat kecepatan per step interval
          if (LocationService.isValidStep(
            distanceMeters: stepDistance,
            elapsedSeconds: elapsed,
          )) {
            distanceMeters.value += stepDistance;
            routePoints.add(newPoint);
            _lastWaypointTime = now;

            if (durationSeconds.value > 0) {
              avgPace.value = StatCalculator.calculatePace(
                distanceKm,
                durationSeconds.value,
              );
            }
          } else {
            antiCheatWarning.value = true;
          }
        }
      });
    } catch (_) {}
  }

  /// Toggles between tracking and paused state
  void togglePause() {
    isPaused.value = !isPaused.value;
  }

  /// Demo Mode Simulation: Adds simulated distance (+500m default) with realistic duration (+180s per +500m)
  void simulateAddDistance({double meters = 500.0}) {
    distanceMeters.value += meters;
    // Scaled proportional duration: 500m per 180s (3.0 mins) simulates realistic pace of 6:00 /km
    final addedSeconds = ((meters / 500.0) * 180).round();
    durationSeconds.value += addedSeconds;

    // Simulate route extension visually on map
    final baseLat = routePoints.isNotEmpty
        ? routePoints.last.latitude
        : (currentPosition.value?.latitude ?? -7.7828);
    final baseLon = routePoints.isNotEmpty
        ? routePoints.last.longitude
        : (currentPosition.value?.longitude ?? 110.3670);

    final offsetStep = (meters / 111000.0); // Rough degrees latitude offset
    final simulatedPoint = LatLng(
      baseLat + (offsetStep * (routePoints.length.isEven ? 1 : 0.8)),
      baseLon + (offsetStep * (routePoints.length.isOdd ? 1 : 0.6)),
    );
    routePoints.add(simulatedPoint);

    avgPace.value = StatCalculator.calculatePace(
      distanceKm,
      durationSeconds.value,
    );
  }

  /// Cancels active cardio tracking session without completing quest or awarding rewards
  void cancelRun() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    isTracking.value = false;
    isPaused.value = false;
    distanceMeters.value = 0.0;
    durationSeconds.value = 0;
    avgPace.value = 0.0;
    routePoints.clear();
    antiCheatWarning.value = false;
    locationStatusMessage.value = 'TRACKING CANCELLED';
  }

  /// Terminates run, awards END and SPD stats, logs to Hive, checks achievements.
  /// Strictly requires distanceKm >= targetKm AND durationSeconds > 0.
  Future<QuestCompletionResult?> finishRun() async {
    // Guard clause: strictly enforce target distance and duration before completing
    if (!isTargetMet || durationSeconds.value <= 0) {
      return null;
    }

    _timer?.cancel();
    _positionSubscription?.cancel();

    final double finalDistance = distanceKm;
    final double finalPace = avgPace.value;
    final int finalDurationMins = (durationSeconds.value / 60).ceil();

    isTracking.value = false;
    isPaused.value = false;

    // Complete quest through QuestController
    final result = await QuestController.to.completeQuest(
      type: QuestType.cardio,
      distanceKm: finalDistance,
      paceMinPerKm: finalPace,
      durationMinutes: finalDurationMins,
    );

    return result;
  }
}
