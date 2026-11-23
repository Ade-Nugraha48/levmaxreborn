import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences Session Manager
/// Conforms to `docs/database_schema.md` Section 1.
class SessionService {
  SessionService._();

  static SharedPreferences? _prefs;

  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyActiveUsername = 'activeUsername';
  static const String _keyDailyReminderEnabled = 'dailyReminderEnabled';
  static const String _keyIsDemoMode = 'isDemoMode';
  static const String _keySkipRestTimer = 'skipRestTimer';

  /// Inisialisasi SharedPreferences saat pertama kali app start di main.dart
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Cek apakah user sudah login di perangkat ini
  static bool get isLoggedIn => _prefs?.getBool(_keyIsLoggedIn) ?? false;
  static Future<void> setIsLoggedIn(bool value) async {
    await _prefs?.setBool(_keyIsLoggedIn, value);
  }

  // Simpan & ambil username yang sedang aktif digunakan
  static String get activeUsername => _prefs?.getString(_keyActiveUsername) ?? '';
  static Future<void> setActiveUsername(String value) async {
    await _prefs?.setString(_keyActiveUsername, value);
  }

  // Pengaturan notifikasi harian jam 19:00 malam
  static bool get dailyReminderEnabled =>
      _prefs?.getBool(_keyDailyReminderEnabled) ?? true;
  static Future<void> setDailyReminderEnabled(bool value) async {
    await _prefs?.setBool(_keyDailyReminderEnabled, value);
  }

  // Mode developer demo untuk mempermudah pengujian saat presentasi
  static bool get isDemoMode => _prefs?.getBool(_keyIsDemoMode) ?? false;
  static Future<void> setIsDemoMode(bool value) async {
    await _prefs?.setBool(_keyIsDemoMode, value);
  }

  /// Toggle for skipping Rest Timer during workout in Demo Mode
  static bool get skipRestTimer => _prefs?.getBool(_keySkipRestTimer) ?? false;
  static Future<void> setSkipRestTimer(bool value) async {
    await _prefs?.setBool(_keySkipRestTimer, value);
  }

  /// Clears active session credentials on logout
  static Future<void> clearSession() async {
    await setIsLoggedIn(false);
    await setActiveUsername('');
  }

  // =========================================================================
  // Lifetime historical accumulators for Sejarah tab
  // (Preserves lifetime calculations even when logs are purged from archive list)
  // =========================================================================

  static int getLifetimeQuestsCleared(String username) =>
      _prefs?.getInt('sejarah_lifetime_quests_$username') ?? 0;
  static Future<void> setLifetimeQuestsCleared(String username, int value) async {
    await _prefs?.setInt('sejarah_lifetime_quests_$username', value);
  }

  static double getLifetimeCardioKm(String username) =>
      _prefs?.getDouble('sejarah_lifetime_cardio_$username') ?? 0.0;
  static Future<void> setLifetimeCardioKm(String username, double value) async {
    await _prefs?.setDouble('sejarah_lifetime_cardio_$username', value);
  }

  static int getLifetimeStudyMinutes(String username) =>
      _prefs?.getInt('sejarah_lifetime_study_$username') ?? 0;
  static Future<void> setLifetimeStudyMinutes(String username, int value) async {
    await _prefs?.setInt('sejarah_lifetime_study_$username', value);
  }

  static int getLifetimeWorkoutReps(String username, String exercise) =>
      _prefs?.getInt('sejarah_lifetime_reps_${username}_$exercise') ?? 0;
  static Future<void> setLifetimeWorkoutReps(
      String username, String exercise, int value) async {
    await _prefs?.setInt('sejarah_lifetime_reps_${username}_$exercise', value);
  }
}
