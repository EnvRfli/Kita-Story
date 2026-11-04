import '../models/cycle_day_log_model.dart';
import '../models/cycle_settings_model.dart';
import '../models/cycle_summary.dart';
import '../utils/cycle_calculator.dart';
import '../utils/cycle_date_utils.dart';

class CycleData {
  final String userId;
  final CycleSettingsModel? settings;
  final List<CycleDayLogModel> logs;
  final DateTime today;

  CycleData({
    required this.userId,
    this.settings,
    List<CycleDayLogModel> logs = const [],
    DateTime? today,
  })  : logs = List<CycleDayLogModel>.unmodifiable(
          [...logs]..sort((a, b) => b.logDate.compareTo(a.logDate)),
        ),
        today = cycleDateOnly(today ?? DateTime.now());

  bool get isEmpty => settings == null && logs.isEmpty;

  bool get needsSetup => summary == null;

  DateTime? get effectiveLastPeriodStart {
    final detected = CycleCalculator.detectLastPeriodStart(logs);
    final configured = settings?.lastPeriodStart;
    if (detected == null) return configured;
    if (configured == null) return detected;
    return detected.isAfter(configured) ? detected : configured;
  }

  /// Average length between detected period starts, or null when there is not
  /// enough history yet (fewer than three detected periods, i.e. two gaps).
  /// With only one gap a single mis-logged period would skew every prediction,
  /// so the configured cycle length wins until more history exists.
  int? get averageCycleLength {
    final starts = periodStarts;
    if (starts.length < 3) return null;

    final lengths = <int>[];
    for (var i = 1; i < starts.length; i++) {
      final length = starts[i].difference(starts[i - 1]).inDays;
      if (length >= 15 && length <= 60) lengths.add(length);
    }
    if (lengths.isEmpty) return null;

    final average = lengths.reduce((a, b) => a + b) / lengths.length;
    return average.round().clamp(21, 45);
  }

  int get cycleLength => averageCycleLength ?? settings?.cycleLength ?? 28;

  int get periodLength => settings?.periodLength ?? 5;

  List<DateTime> get periodStarts => CycleCalculator.detectPeriodStarts(logs);

  CycleSummary? get summary {
    final start = effectiveLastPeriodStart;
    if (start == null) return null;
    return CycleCalculator.compute(
      lastPeriodStart: start,
      cycleLength: cycleLength,
      periodLength: periodLength,
      today: today,
      allowRollover: false,
    );
  }

  bool get isPeriodLate => summary?.isLate ?? false;

  DateTime? get expectedPeriodStart => summary?.nextPeriodStart;

  int get logStreak {
    final map = logsByDate;
    var cursor = today;
    if (!map.containsKey(cycleDateKey(cursor))) {
      cursor = today.subtract(const Duration(days: 1));
      if (!map.containsKey(cycleDateKey(cursor))) return 0;
    }
    var streak = 0;
    while (map.containsKey(cycleDateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get logsThisMonth => logs
      .where(
        (log) =>
            log.logDate.year == today.year && log.logDate.month == today.month,
      )
      .length;

  Map<String, CycleDayLogModel> get logsByDate {
    final map = <String, CycleDayLogModel>{};
    for (final log in logs) {
      map[log.dateKey] = log;
    }
    return map;
  }

  CycleDayLogModel? get todayLog => logForDate(today);

  CycleDayLogModel? logForDate(DateTime date) =>
      logsByDate[cycleDateKey(cycleDateOnly(date))];

  List<CycleDayLogModel> get recentLogs => logs.take(5).toList();

  bool get isStale {
    final start = effectiveLastPeriodStart;
    if (start == null) return false;
    return today.difference(start).inDays > 12 * cycleLength;
  }
}
