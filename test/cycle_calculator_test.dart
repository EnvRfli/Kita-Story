import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/cycle/models/cycle_day_log_model.dart';
import 'package:kita_story/features/cycle/models/cycle_summary.dart';
import 'package:kita_story/features/cycle/utils/cycle_calculator.dart';

CycleDayLogModel _log(DateTime date, String flow) {
  return CycleDayLogModel(
    id: '${date.year}-${date.month}-${date.day}',
    userId: 'user-1',
    logDate: date,
    flow: flow,
  );
}

void main() {
  group('CycleCalculator.compute (28/5)', () {
    final start = DateTime(2026, 1, 1);

    CycleSummary computeAt(int daysAfterStart) {
      return CycleCalculator.compute(
        lastPeriodStart: start,
        cycleLength: 28,
        periodLength: 5,
        today: start.add(Duration(days: daysAfterStart)),
      );
    }

    test('day 1 is menstrual', () {
      final summary = computeAt(0);
      expect(summary.dayOfCycle, 1);
      expect(summary.phase, CyclePhase.menstrual);
      expect(summary.daysUntilNextPeriod, 28);
    });

    test('day 5 is still menstrual', () {
      final summary = computeAt(4);
      expect(summary.dayOfCycle, 5);
      expect(summary.phase, CyclePhase.menstrual);
    });

    test('day 6 starts follicular', () {
      final summary = computeAt(5);
      expect(summary.dayOfCycle, 6);
      expect(summary.phase, CyclePhase.follicular);
    });

    test('day 12 is follicular', () {
      final summary = computeAt(11);
      expect(summary.dayOfCycle, 12);
      expect(summary.phase, CyclePhase.follicular);
    });

    test('days 13 to 15 are ovulation', () {
      expect(computeAt(12).phase, CyclePhase.ovulation);
      expect(computeAt(13).phase, CyclePhase.ovulation);
      expect(computeAt(14).phase, CyclePhase.ovulation);
    });

    test('day 16 starts luteal', () {
      final summary = computeAt(15);
      expect(summary.dayOfCycle, 16);
      expect(summary.phase, CyclePhase.luteal);
    });

    test('day 28 is still luteal', () {
      final summary = computeAt(27);
      expect(summary.dayOfCycle, 28);
      expect(summary.phase, CyclePhase.luteal);
      expect(summary.daysUntilNextPeriod, 1);
    });

    test('day 29 rolls to day 1 of the next cycle', () {
      final summary = computeAt(28);
      expect(summary.dayOfCycle, 1);
      expect(summary.phase, CyclePhase.menstrual);
      expect(summary.daysUntilNextPeriod, 28);
    });

    test('fertile window is ovulation -5 until +1', () {
      final summary = computeAt(0);
      expect(summary.ovulationDay, 14);
      expect(summary.ovulationDate, DateTime(2026, 1, 14));
      expect(summary.fertileStart, DateTime(2026, 1, 9));
      expect(summary.fertileEnd, DateTime(2026, 1, 15));
    });

    test('phaseDayIndex increases within the phase', () {
      expect(computeAt(0).phaseDayIndex, 1);
      expect(computeAt(2).phaseDayIndex, 3);
      expect(computeAt(5).phaseDayIndex, 1);
      expect(computeAt(12).phaseDayIndex, 1);
    });
  });

  group('CycleCalculator.compute at supported boundaries', () {
    test('21/4 produces every phase', () {
      final start = DateTime(2026, 3, 1);
      CyclePhase phaseAt(int days) => CycleCalculator.compute(
            lastPeriodStart: start,
            cycleLength: 21,
            periodLength: 4,
            today: start.add(Duration(days: days)),
          ).phase;

      expect(phaseAt(0), CyclePhase.menstrual);
      expect(phaseAt(4), CyclePhase.follicular);
      expect(phaseAt(5), CyclePhase.ovulation);
      expect(phaseAt(8), CyclePhase.luteal);
    });

    test('35/7 produces every phase', () {
      final start = DateTime(2026, 5, 1);
      CyclePhase phaseAt(int days) => CycleCalculator.compute(
            lastPeriodStart: start,
            cycleLength: 35,
            periodLength: 7,
            today: start.add(Duration(days: days)),
          ).phase;

      expect(phaseAt(0), CyclePhase.menstrual);
      expect(phaseAt(7), CyclePhase.follicular);
      expect(phaseAt(19), CyclePhase.ovulation);
      expect(phaseAt(22), CyclePhase.luteal);
    });

    test('a future last period start does not crash', () {
      final summary = CycleCalculator.compute(
        lastPeriodStart: DateTime(2026, 6, 10),
        cycleLength: 28,
        periodLength: 5,
        today: DateTime(2026, 6, 1),
      );

      expect(summary.dayOfCycle, 1);
      expect(summary.phase, CyclePhase.menstrual);
    });
  });

  group('CycleCalculator.phaseOn', () {
    test('returns the phase for arbitrary dates', () {
      final start = DateTime(2026, 1, 1);

      final follicular = CycleCalculator.phaseOn(
        DateTime(2026, 1, 7),
        lastPeriodStart: start,
        cycleLength: 28,
        periodLength: 5,
      );
      expect(follicular.phase, CyclePhase.follicular);
      expect(follicular.dayOfCycle, 7);

      final nextCycle = CycleCalculator.phaseOn(
        DateTime(2026, 2, 1),
        lastPeriodStart: start,
        cycleLength: 28,
        periodLength: 5,
      );
      expect(nextCycle.dayOfCycle, 4);
      expect(nextCycle.phase, CyclePhase.menstrual);
    });
  });

  group('CycleCalculator.detectLastPeriodStart', () {
    test('picks the start of the most recent bleeding run', () {
      final logs = [
        _log(DateTime(2026, 1, 1), 'medium'),
        _log(DateTime(2026, 1, 2), 'heavy'),
        _log(DateTime(2026, 1, 3), 'medium'),
        _log(DateTime(2026, 1, 4), 'light'),
        _log(DateTime(2026, 1, 25), 'medium'),
        _log(DateTime(2026, 1, 26), 'heavy'),
        _log(DateTime(2026, 1, 27), 'medium'),
        _log(DateTime(2026, 1, 28), 'light'),
      ];

      expect(
        CycleCalculator.detectLastPeriodStart(logs),
        DateTime(2026, 1, 25),
      );
      expect(CycleCalculator.detectPeriodStarts(logs), [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 25),
      ]);
    });

    test('returns null without bleeding logs', () {
      final logs = [
        _log(DateTime(2026, 1, 1), 'none'),
        _log(DateTime(2026, 1, 2), 'spotting'),
      ];

      expect(CycleCalculator.detectLastPeriodStart(logs), isNull);
      expect(CycleCalculator.detectPeriodStarts(logs), isEmpty);
    });
  });

  group('CycleCalculator.compute late period (allowRollover: false)', () {
    final start = DateTime(2026, 1, 1);

    CycleSummary computeAt(int daysAfterStart) {
      return CycleCalculator.compute(
        lastPeriodStart: start,
        cycleLength: 28,
        periodLength: 5,
        today: start.add(Duration(days: daysAfterStart)),
        allowRollover: false,
      );
    }

    test('day 28 is not late yet', () {
      final summary = computeAt(27);
      expect(summary.dayOfCycle, 28);
      expect(summary.daysUntilNextPeriod, 1);
      expect(summary.isLate, isFalse);
    });

    test('the expected start day is still not late', () {
      final summary = computeAt(28);
      expect(summary.dayOfCycle, 29);
      expect(summary.daysUntilNextPeriod, 0);
      expect(summary.isLate, isFalse);
      expect(summary.dayLabel, 'Haid diperkirakan hari ini');
    });

    test('the day after the expected start is late by 1', () {
      final summary = computeAt(29);
      expect(summary.isLate, isTrue);
      expect(summary.lateDays, 1);
      expect(summary.phase, CyclePhase.luteal);
    });

    test('day 35 is late by 6 and the label reflects it', () {
      final summary = computeAt(34);
      expect(summary.lateDays, 6);
      expect(summary.dayLabel, 'Terlambat 6 hari');
    });
  });
}
