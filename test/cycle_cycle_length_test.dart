import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/cycle/models/cycle_data.dart';
import 'package:kita_story/features/cycle/models/cycle_day_log_model.dart';
import 'package:kita_story/features/cycle/models/cycle_settings_model.dart';
import 'package:kita_story/features/cycle/utils/cycle_calculator.dart';

final DateTime _today = DateTime(2026, 11, 4);

CycleDayLogModel _log(DateTime date, {String flow = 'heavy'}) {
  return CycleDayLogModel(
    id: '${date.year}-${date.month}-${date.day}',
    userId: 'user-1',
    logDate: date,
    flow: flow,
  );
}

CycleData _data({
  required List<CycleDayLogModel> logs,
  int configuredCycleLength = 28,
}) {
  return CycleData(
    userId: 'user-1',
    today: _today,
    settings: CycleSettingsModel(
      userId: 'user-1',
      cycleLength: configuredCycleLength,
      periodLength: 5,
      lastPeriodStart: _today.subtract(const Duration(days: 5)),
    ),
    logs: logs,
  );
}

void main() {
  test('28-day cycle puts ovulation on day 14', () {
    final summary = CycleCalculator.compute(
      lastPeriodStart: DateTime(2026, 1, 1),
      cycleLength: 28,
      periodLength: 5,
      today: DateTime(2026, 1, 1),
    );

    expect(summary.ovulationDay, 14);
    expect(summary.ovulationDate, DateTime(2026, 1, 14));
  });

  test('30-day cycle puts ovulation on day 16', () {
    final summary = CycleCalculator.compute(
      lastPeriodStart: DateTime(2026, 1, 1),
      cycleLength: 30,
      periodLength: 5,
      today: DateTime(2026, 1, 1),
    );

    expect(summary.ovulationDay, 16);
  });

  test('21-day cycle puts ovulation on day 7', () {
    final summary = CycleCalculator.compute(
      lastPeriodStart: DateTime(2026, 1, 1),
      cycleLength: 21,
      periodLength: 5,
      today: DateTime(2026, 1, 1),
    );

    expect(summary.ovulationDay, 7);
  });

  test('only two detected periods keep the configured cycle length', () {
    final data = _data(
      logs: [
        _log(_today.subtract(const Duration(days: 44))),
        _log(_today.subtract(const Duration(days: 22))),
      ],
    );

    expect(data.periodStarts.length, 2);
    expect(data.averageCycleLength, isNull);
    expect(data.cycleLength, 28);
    expect(data.summary!.ovulationDay, 14);
  });

  test('three detected 22-day periods switch to the detected average', () {
    final data = _data(
      logs: [
        _log(_today.subtract(const Duration(days: 44))),
        _log(_today.subtract(const Duration(days: 22))),
        _log(_today),
      ],
    );

    expect(data.averageCycleLength, 22);
    expect(data.cycleLength, 22);
    expect(data.summary!.ovulationDay, 8);
  });

  test('a split bleeding run is merged instead of shortening the cycle', () {
    final starts = CycleCalculator.detectPeriodStarts([
      _log(_today.subtract(const Duration(days: 50))),
      _log(_today.subtract(const Duration(days: 44))),
      _log(_today.subtract(const Duration(days: 22))),
    ]);

    expect(starts, [
      _today.subtract(const Duration(days: 50)),
      _today.subtract(const Duration(days: 22)),
    ]);
  });
}
