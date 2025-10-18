import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime date, {String? locale}) {
    if (locale == 'ar') {
      return DateFormat('dd/MM/yyyy', 'ar').format(date);
    }
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatTime(DateTime date, {String? locale}) {
    if (locale == 'ar') {
      return DateFormat('HH:mm', 'ar').format(date);
    }
    return DateFormat('h:mm a').format(date);
  }

  static String formatDateTime(DateTime date, {String? locale}) {
    if (locale == 'ar') {
      return DateFormat('dd/MM/yyyy HH:mm', 'ar').format(date);
    }
    return DateFormat('MMM dd, yyyy h:mm a').format(date);
  }

  static String getRelativeTime(DateTime date, {String? locale}) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return formatDate(date, locale: locale);
    } else if (difference.inDays > 0) {
      if (locale == 'ar') {
        return '${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'} مضت';
      }
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      if (locale == 'ar') {
        return '${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'} مضت';
      }
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      if (locale == 'ar') {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'} مضت';
      }
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return locale == 'ar' ? 'الآن' : 'Just now';
    }
  }

  static String getDayOfWeek(DateTime date, {String? locale}) {
    if (locale == 'ar') {
      return DateFormat('EEEE', 'ar').format(date);
    }
    return DateFormat('EEEE').format(date);
  }

  static String getMonth(DateTime date, {String? locale}) {
    if (locale == 'ar') {
      return DateFormat('MMMM', 'ar').format(date);
    }
    return DateFormat('MMMM').format(date);
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(date, tomorrow);
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  static String getTimeAgo(DateTime date, {String? locale}) {
    if (isToday(date)) {
      return locale == 'ar' ? 'اليوم' : 'Today';
    } else if (isTomorrow(date)) {
      return locale == 'ar' ? 'غداً' : 'Tomorrow';
    } else if (isYesterday(date)) {
      return locale == 'ar' ? 'أمس' : 'Yesterday';
    } else {
      return getRelativeTime(date, locale: locale);
    }
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  static DateTime endOfWeek(DateTime date) {
    final daysUntilSunday = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: daysUntilSunday)));
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }
}