
// Wait, since I didn't add intl package, I will just use basic dart DateTime methods or add intl package.
// Let me use a basic implementation that doesn't strictly require intl if I don't have it, 
// or I can just format it simply.

class DateFormatter {
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    // simple format: DD/MM/YYYY
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
