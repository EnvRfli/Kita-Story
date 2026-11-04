DateTime cycleDateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);

const List<String> cycleLongMonths = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const List<String> cycleShortMonths = [
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
  'Des',
];

const List<String> cycleWeekdaysShort = [
  'Sen',
  'Sel',
  'Rab',
  'Kam',
  'Jum',
  'Sab',
  'Min',
];

String cycleDateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String cycleIsoDate(DateTime date) => cycleDateKey(date);

DateTime? cycleParseDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final parsed = DateTime.tryParse(text);
  return parsed == null ? null : cycleDateOnly(parsed);
}

String cycleMonthYear(DateTime date) =>
    '${cycleLongMonths[date.month - 1]} ${date.year}';

String cycleLongDate(DateTime date) =>
    '${date.day} ${cycleLongMonths[date.month - 1]} ${date.year}';

String cycleShortDate(DateTime date) =>
    '${date.day} ${cycleShortMonths[date.month - 1]} ${date.year}';

String cycleShortDayRange(DateTime start, DateTime end) {
  if (start.month == end.month) {
    return '${start.day}–${end.day} ${cycleShortMonths[start.month - 1]}';
  }
  return '${start.day} ${cycleShortMonths[start.month - 1]}–'
      '${end.day} ${cycleShortMonths[end.month - 1]}';
}

String cycleRelativeDayLabel(DateTime date, {DateTime? today}) {
  final reference = cycleDateOnly(today ?? DateTime.now());
  final target = cycleDateOnly(date);
  final diff = target.difference(reference).inDays;

  if (diff == 0) return 'Hari ini';
  if (diff == 1) return 'Besok';
  if (diff == -1) return 'Kemarin';
  if (diff < 0) return '${-diff} hari lalu';
  return '$diff hari lagi';
}
