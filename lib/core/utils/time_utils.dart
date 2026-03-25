import 'package:intl/intl.dart';

class TimeUtils {
  TimeUtils._();

  static String formatMessageTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(dt.year, dt.month, dt.day);

    if (msgDay == today || msgDay == yesterday) {
      return DateFormat.jm().format(dt); // e.g. "2:34 PM"
    }
    return DateFormat('MMM d').format(dt); // e.g. "Mar 20"
  }

  static String formatThreadTime(DateTime dt) {
    return formatMessageTime(dt);
  }

  static bool shouldShowTimestamp(DateTime? prev, DateTime current) {
    if (prev == null) return true;
    return current.difference(prev).inMinutes > 5;
  }

  static String groupLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final msgDay = DateTime(dt.year, dt.month, dt.day);

    if (msgDay == today) return 'Today';
    if (msgDay == yesterday) return 'Yesterday';
    if (!msgDay.isBefore(startOfWeek)) return 'This Week';
    return 'Earlier';
  }

  static int groupOrder(String label) {
    switch (label) {
      case 'Today':
        return 0;
      case 'Yesterday':
        return 1;
      case 'This Week':
        return 2;
      default:
        return 3;
    }
  }
}
