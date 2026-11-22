import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences Session Manager
/// Conforms to `docs/database_schema.md` Section 1.
class SessionService {
  SessionService._();

  static late SharedPreferences _prefs;

  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyActiveUsername = 'activeUsername';
  static const String _keyDailyReminderEnabled = 'dailyReminderEnabled';
  static const String _keyIsDemoMode = 'isDemoMode';
  static const String _keySkipRestTimer = 'skipRestTimer';

  /// Initializes SharedPreferences instance
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Whether user session is currently logged in
  static bool get isLoggedIn => _prefs.getBool(_keyIsLoggedIn) ?? false;
  static Future<void> setIsLoggedIn(bool value) async {
    await _prefs.setBool(_keyIsLoggedIn, value);
  }

  /// Active username lookup key for Hive
  static String get activeUsername => _prefs.getString(_keyActiveUsername) ?? '';
  static Future<void> setActiveUsername(String value) async {
    await _prefs.setString(_keyActiveUsername, value);
  }

  /// Toggle for Scheduled Daily Notification (19:00)
  static bool get dailyReminderEnabled =>
      _prefs.getBool(_keyDailyReminderEnabled) ?? true;
  static Future<void> setDailyReminderEnabled(bool value) async {
    await _prefs.setBool(_keyDailyReminderEnabled, value);
  }

  /// Toggle for Developer Demo Console
  static bool get isDemoMode => _prefs.getBool(_keyIsDemoMode) ?? false;
  static Future<void> setIsDemoMode(bool value) async {
    await _prefs.setBool(_keyIsDemoMode, value);
  }

  /// Toggle for skipping Rest Timer during workout in Demo Mode
  static bool get skipRestTimer => _prefs.getBool(_keySkipRestTimer) ?? false;
  static Future<void> setSkipRestTimer(bool value) async {
    await _prefs.setBool(_keySkipRestTimer, value);
  }

  /// Clears active session credentials on logout
  static Future<void> clearSession() async {
    await setIsLoggedIn(false);
    await setActiveUsername('');
  }
}
