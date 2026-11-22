import 'package:intl/intl.dart';

/// Date and Time Helper Functions for Daily Reset and History Chronology
class DateHelper {
  DateHelper._();

  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _readableFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _shortFormat = DateFormat('dd MMM');

  /// Returns today's date formatted as YYYY-MM-DD
  static String todayString() {
    return _isoFormat.format(DateTime.now());
  }

  /// Formats a DateTime object as YYYY-MM-DD
  static String formatDate(DateTime dt) {
    return _isoFormat.format(dt);
  }

  /// Parses a YYYY-MM-DD string into a DateTime
  static DateTime parseDate(String dateStr) {
    return _isoFormat.parse(dateStr);
  }

  /// Calculates difference in calendar days between two YYYY-MM-DD strings (date2 - date1)
  static int daysBetween(String date1, String date2) {
    try {
      final d1 = _isoFormat.parse(date1);
      final d2 = _isoFormat.parse(date2);
      final normalizedD1 = DateTime(d1.year, d1.month, d1.day);
      final normalizedD2 = DateTime(d2.year, d2.month, d2.day);
      return normalizedD2.difference(normalizedD1).inDays;
    } catch (_) {
      return 0;
    }
  }

  /// Checks if currentDate is exactly 1 calendar day after lastDate
  static bool isConsecutiveDay(String lastDate, String currentDate) {
    return daysBetween(lastDate, currentDate) == 1;
  }

  /// Formats DateTime as readable string e.g. "22 Nov 2026"
  static String formatReadable(DateTime dt) {
    return _readableFormat.format(dt).toUpperCase();
  }

  /// Formats DateTime as short string e.g. "22 NOV"
  static String formatShortDate(DateTime dt) {
    return _shortFormat.format(dt).toUpperCase();
  }
}
