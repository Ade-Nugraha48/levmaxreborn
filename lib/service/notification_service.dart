import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'session_service.dart';

/// Recorded notification for audit, QA, and automated unit testing
class SentNotificationRecord {
  final int id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isScheduled;

  const SentNotificationRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isScheduled = false,
  });
}

/// Centralized Local Notification Service (Modul 7)
/// Manages Immediate Notifications (Quest, Level Up, Rank Up, Achievements)
/// and Scheduled Notifications (19:00 Daily Quest Reminder).
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Global flag to disable native platform channel calls during automated unit/widget tests
  static bool isTestMode = false;

  static bool get _isInTest =>
      isTestMode || Platform.environment.containsKey('FLUTTER_TEST');

  /// Audit log of sent notifications for test verification
  static final List<SentNotificationRecord> sentHistory = [];

  static const String channelId = 'levmax_protocol_channel';
  static const String channelName = 'LevMax Protocols';
  static const String channelDescription =
      'Alerts for Quest Completions, Level Ups, Rank Ascensions, and Honors';

  /// Notification IDs
  static const int idQuestCompleted = 101;
  static const int idLevelUp = 102;
  static const int idRankUp = 103;
  static const int idAchievement = 104;
  static const int idProfileUpdated = 105;
  static const int idDailyReminder = 201;

  /// Initializes plugin and timezone databases
  static Future<void> init() async {
    if (_isInitialized) return;

    if (_isInTest) {
      _isInitialized = true;
      return;
    }

    try {
      tz.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Can handle deep linking if needed
        },
      );

      // Request permissions on Android 13+ (Tiramisu)
      if (Platform.isAndroid) {
        final androidPlatform = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlatform?.requestNotificationsPermission();
      }

      _isInitialized = true;

      // Reschedule 19:00 daily reminder if enabled in session
      if (SessionService.dailyReminderEnabled) {
        await scheduleDailyReminder(hour: 19, minute: 0);
      }
    } catch (_) {
      // Graceful fallback for test environments without device hardware
      _isInitialized = true;
    }
  }

  // --- IMMEDIATE NOTIFICATIONS ---

  /// Displays an immediate notification with high priority
  static Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
  }) async {
    // Audit record for testing & logging
    sentHistory.add(
      SentNotificationRecord(
        id: id,
        title: title,
        body: body,
        timestamp: DateTime.now(),
        isScheduled: false,
      ),
    );

    if (_isInTest) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _plugin.show(id, title, body, notificationDetails);
    } catch (_) {
      // Headless or test environment fallback
    }
  }

  /// Triggered when a Daily Quest is completed
  static Future<void> showQuestCompleted({
    required String questTitle,
    required int expGained,
  }) async {
    await showImmediate(
      id: idQuestCompleted,
      title: 'PROTOCOL COMPLETE: ${questTitle.toUpperCase()}',
      body: 'Earned +$expGained EXP. Telemetry updated.',
    );
  }

  /// Triggered on Level Up ascension
  static Future<void> showLevelUp({required int newLevel}) async {
    await showImmediate(
      id: idLevelUp,
      title: 'LEVEL UP: ASCENSION LV. $newLevel',
      body: 'Stat points distributed: +2 to ALL 6 core attributes.',
    );
  }

  /// Triggered on Rank Up ascension
  static Future<void> showRankUp({required String newRank}) async {
    await showImmediate(
      id: idRankUp,
      title: 'RANK ASCENSION: ${newRank.toUpperCase()}',
      body: 'Your total attributes elevated you to Rank $newRank.',
    );
  }

  /// Triggered when an Achievement honor is unlocked
  static Future<void> showAchievementUnlocked({
    required String achievementTitle,
  }) async {
    await showImmediate(
      id: idAchievement,
      title: 'HONOR UNLOCKED: ${achievementTitle.toUpperCase()}',
      body: 'New achievement added to System Codex honors.',
    );
  }

  /// Triggered when Operative profile credentials or biometrics are updated
  static Future<void> showProfileUpdated({
    required String username,
  }) async {
    await showImmediate(
      id: idProfileUpdated,
      title: 'PROFILE UPDATED: ${username.toUpperCase()}',
      body: 'Operative credentials and biometric data successfully recalibrated.',
    );
  }

  // --- SCHEDULED NOTIFICATIONS ---

  /// Schedules recurring daily reminder at 19:00 (7:00 PM)
  /// Triggers even if the app process is terminated.
  static Future<void> scheduleDailyReminder({
    int hour = 19,
    int minute = 0,
  }) async {
    // Record scheduled entry
    sentHistory.add(
      SentNotificationRecord(
        id: idDailyReminder,
        title: 'DAILY SYSTEM REMINDER',
        body: 'Incomplete quests detect potential penalty. Initialize protocols.',
        timestamp: DateTime.now(),
        isScheduled: true,
      ),
    );

    if (_isInTest) {
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(android: androidDetails);

      final scheduledTime = _nextInstanceOfHour(hour, minute);

      await _plugin.zonedSchedule(
        idDailyReminder,
        'DAILY SYSTEM REMINDER',
        'Incomplete quests detect potential penalty. Initialize protocols.',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Test environment fallback
    }
  }

  /// Cancels the scheduled daily reminder
  static Future<void> cancelDailyReminder() async {
    if (_isInTest) return;
    try {
      await _plugin.cancel(idDailyReminder);
    } catch (_) {}
  }

  /// Cancels all active and scheduled notifications
  static Future<void> cancelAll() async {
    if (_isInTest) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Clears in-memory audit logs (useful for unit test teardown)
  static void clearHistory() {
    sentHistory.clear();
  }

  static tz.TZDateTime _nextInstanceOfHour(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
