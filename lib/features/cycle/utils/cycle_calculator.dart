import '../models/cycle_day_log_model.dart';
import '../models/cycle_summary.dart';
import 'cycle_date_utils.dart';

class CycleCalculator {
  // Luteal phase is modelled as a fixed 14 days, the common clinical average.
  static const int _lutealDays = 14;

  static const int _minCycleGapDays = 10;

  static CycleSummary compute({
    required DateTime lastPeriodStart,
    required int cycleLength,
    required int periodLength,
    DateTime? today,
    bool allowRollover = true,
  }) {
    final todayD = cycleDateOnly(today ?? DateTime.now());
    final startD = cycleDateOnly(lastPeriodStart);
    final safeCycle = cycleLength.clamp(21, 45);
    final safePeriod = periodLength.clamp(2, 10);

    var diff = todayD.difference(startD).inDays;
    if (diff < 0) diff = 0;

    final completedCycles = allowRollover ? diff ~/ safeCycle : 0;
    final dayOfCycle = diff - (completedCycles * safeCycle) + 1;
    final cycleStart = startD.add(Duration(days: completedCycles * safeCycle));

    final ovulationDay = _ovulationDayFor(safeCycle, safePeriod);
    final phase = _phaseFor(dayOfCycle, safePeriod, ovulationDay);
    final phaseStart = _phaseStartDayFor(phase, safePeriod, ovulationDay);

    final nextPeriodStart = cycleStart.add(Duration(days: safeCycle));
    final ovulationDate = cycleStart.add(Duration(days: ovulationDay - 1));
    final fertileStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDate.add(const Duration(days: 1));

    return CycleSummary(
      phase: phase,
      dayOfCycle: dayOfCycle,
      cycleLength: safeCycle,
      periodLength: safePeriod,
      today: todayD,
      lastPeriodStart: startD,
      cycleStart: cycleStart,
      nextPeriodStart: nextPeriodStart,
      ovulationDay: ovulationDay,
      ovulationDate: ovulationDate,
      fertileStart: fertileStart,
      fertileEnd: fertileEnd,
      daysUntilNextPeriod: nextPeriodStart.difference(todayD).inDays,
      phaseDayIndex: dayOfCycle - phaseStart + 1,
    );
  }

  static ({CyclePhase phase, int dayOfCycle}) phaseOn(
    DateTime date, {
    required DateTime lastPeriodStart,
    required int cycleLength,
    required int periodLength,
  }) {
    final dateD = cycleDateOnly(date);
    final startD = cycleDateOnly(lastPeriodStart);
    final safeCycle = cycleLength.clamp(21, 45);
    final safePeriod = periodLength.clamp(2, 10);

    var diff = dateD.difference(startD).inDays;
    if (diff < 0) diff = 0;

    final dayOfCycle = diff % safeCycle + 1;
    final ovulationDay = _ovulationDayFor(safeCycle, safePeriod);

    return (
      phase: _phaseFor(dayOfCycle, safePeriod, ovulationDay),
      dayOfCycle: dayOfCycle,
    );
  }

  /// Returns the first day of the most recent bleeding run.
  /// A run needs either two bleeding days or one medium/heavy day, so a single
  /// spotting day does not reset the cycle.
  static DateTime? detectLastPeriodStart(List<CycleDayLogModel> logs) {
    final starts = detectPeriodStarts(logs);
    return starts.isEmpty ? null : starts.last;
  }

  /// All detected period starts, oldest first.
  static List<DateTime> detectPeriodStarts(List<CycleDayLogModel> logs) {
    final bleeding = logs.where((log) => log.hasBleeding).toList()
      ..sort((a, b) =>
          cycleDateOnly(a.logDate).compareTo(cycleDateOnly(b.logDate)));

    if (bleeding.isEmpty) return const [];

    final starts = <DateTime>[];
    var groupStart = cycleDateOnly(bleeding.first.logDate);
    var groupDays = 1;
    var groupHasStrongFlow = _isStrongFlow(bleeding.first.flow);
    var previous = groupStart;

    for (final log in bleeding.skip(1)) {
      final day = cycleDateOnly(log.logDate);
      if (day == previous) continue;

      final gap = day.difference(previous).inDays;
      if (gap > 2) {
        if (groupHasStrongFlow || groupDays >= 2) starts.add(groupStart);
        groupStart = day;
        groupDays = 1;
        groupHasStrongFlow = _isStrongFlow(log.flow);
      } else {
        groupDays++;
        groupHasStrongFlow = groupHasStrongFlow || _isStrongFlow(log.flow);
      }
      previous = day;
    }

    if (groupHasStrongFlow || groupDays >= 2) starts.add(groupStart);
    return _mergeCloseStarts(starts);
  }

  static List<DateTime> _mergeCloseStarts(List<DateTime> starts) {
    final merged = <DateTime>[];
    for (final start in starts) {
      if (merged.isEmpty ||
          start.difference(merged.last).inDays >= _minCycleGapDays) {
        merged.add(start);
      }
    }
    return merged;
  }

  static bool _isStrongFlow(String flow) => flow == 'medium' || flow == 'heavy';

  static int _ovulationDayFor(int safeCycle, int safePeriod) {
    final lower = safePeriod + 2;
    final upper = safeCycle - 2;
    final maxBoundary = upper < lower ? lower : upper;
    return (safeCycle - _lutealDays).clamp(lower, maxBoundary);
  }

  static CyclePhase _phaseFor(
    int dayOfCycle,
    int periodLength,
    int ovulationDay,
  ) {
    final ovulationStart = ovulationDay - 1;
    final ovulationEnd = ovulationDay + 1;

    if (dayOfCycle <= periodLength) return CyclePhase.menstrual;
    if (dayOfCycle < ovulationStart) return CyclePhase.follicular;
    if (dayOfCycle <= ovulationEnd) return CyclePhase.ovulation;
    return CyclePhase.luteal;
  }

  static int _phaseStartDayFor(
    CyclePhase phase,
    int periodLength,
    int ovulationDay,
  ) {
    switch (phase) {
      case CyclePhase.menstrual:
        return 1;
      case CyclePhase.follicular:
        return periodLength + 1;
      case CyclePhase.ovulation:
        return ovulationDay - 1;
      case CyclePhase.luteal:
        return ovulationDay + 2;
    }
  }
}
