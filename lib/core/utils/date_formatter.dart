// Wait, since I didn't add intl package, I will just use basic dart DateTime methods or add intl package.
// Let me use a basic implementation that doesn't strictly require intl if I don't have it,
// or I can just format it simply.

class DateFormatter {
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des'
  ];

  /// Safely converts a DateTime to local time and detects/corrects timestamps
  /// that were mistakenly stored as local time in a UTC field (+7 hour future offset).
  static DateTime parseAndSanitize(DateTime? date) {
    if (date == null) return DateTime.now();
    DateTime local = date.toLocal();
    final now = DateTime.now();

    // If the date is in the future by more than 3 minutes,
    // it was saved without UTC offset (shifted forward by local timezone offset).
    // Correct it back to actual local time by subtracting the local timezone offset.
    if (local.isAfter(now.add(const Duration(minutes: 3)))) {
      final adjusted = local.subtract(now.timeZoneOffset);
      if (!adjusted.isAfter(now.add(const Duration(minutes: 2)))) {
        local = adjusted;
      }
    }
    return local;
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    final local = parseAndSanitize(date);
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    final local = parseAndSanitize(date);
    return '${formatDate(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static String formatActivityDate(DateTime? date) {
    if (date == null) return '-';
    final local = parseAndSanitize(date);
    final day = local.day;
    final month = _months[local.month - 1];
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  static String formatRelativeTime(DateTime? date) {
    if (date == null) return '';
    final local = parseAndSanitize(date);
    final now = DateTime.now();
    final diff = now.difference(local);

    // If future or within last 60 seconds (with clock skew tolerance)
    if (diff.inSeconds < 60 && diff.inSeconds >= -60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60 && diff.inMinutes > 0) {
      return '${diff.inMinutes} mnt lalu';
    } else if (now.year == local.year &&
        now.month == local.month &&
        now.day == local.day) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays <= 2 &&
        (now.day - local.day == 1 ||
            (diff.inHours >= 12 && diff.inHours < 48))) {
      return 'Kemarin, ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    } else if (now.year == local.year) {
      final month = _months[local.month - 1];
      return '${local.day} $month, ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    } else {
      final month = _months[local.month - 1];
      return '${local.day} $month ${local.year}';
    }
  }
}
