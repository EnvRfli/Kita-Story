import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/cycle/models/cycle_data.dart';
import 'package:kita_story/features/cycle/models/cycle_day_log_model.dart';
import 'package:kita_story/features/cycle/models/cycle_settings_model.dart';

CycleData _data({
  required DateTime today,
  required DateTime lastPeriodStart,
  List<CycleDayLogModel> logs = const [],
}) {
  return CycleData(
    userId: 'user-1',
    today: today,
    settings: CycleSettingsModel(
      userId: 'user-1',
      cycleLength: 28,
      periodLength: 5,
      lastPeriodStart: lastPeriodStart,
    ),
    logs: logs,
  );
}

CycleDayLogModel _log(DateTime date, String flow) {
  return CycleDayLogModel(
    id: '${date.year}-${date.month}-${date.day}',
    userId: 'user-1',
    logDate: date,
    flow: flow,
  );
}

void main() {
  final today = DateTime(2026, 11, 4);

  test('35 days after the last period start is 7 days late', () {
    final data = _data(
      today: today,
      lastPeriodStart: today.subtract(const Duration(days: 35)),
    );

    expect(data.summary, isNotNull);
    expect(data.summary!.isLate, isTrue);
    expect(data.summary!.lateDays, 7);
    expect(data.isPeriodLate, isTrue);
    expect(data.expectedPeriodStart, today.subtract(const Duration(days: 7)));
  });

  test('a heavy log resets the cycle and clears late status', () {
    final data = _data(
      today: today,
      lastPeriodStart: today.subtract(const Duration(days: 35)),
      logs: [_log(today.subtract(const Duration(days: 2)), 'heavy')],
    );

    expect(data.summary!.isLate, isFalse);
    expect(data.summary!.dayOfCycle, 3);
  });

  test('a single spotting day does not clear late status', () {
    final data = _data(
      today: today,
      lastPeriodStart: today.subtract(const Duration(days: 35)),
      logs: [_log(today, 'spotting')],
    );

    expect(data.summary!.isLate, isTrue);
    expect(data.summary!.lateDays, 7);
  });

  test('no settings means no summary', () {
    final data = CycleData(userId: 'user-1', today: today);

    expect(data.summary, isNull);
    expect(data.isPeriodLate, isFalse);
    expect(data.expectedPeriodStart, isNull);
  });
}
