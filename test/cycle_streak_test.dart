import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/cycle/models/cycle_data.dart';
import 'package:kita_story/features/cycle/models/cycle_day_log_model.dart';

final DateTime _today = DateTime(2026, 11, 4);

CycleDayLogModel _log(DateTime date, {String flow = 'none'}) {
  return CycleDayLogModel(
    id: '${date.year}-${date.month}-${date.day}',
    userId: 'user-1',
    logDate: date,
    flow: flow,
  );
}

CycleData _data(List<CycleDayLogModel> logs) {
  return CycleData(userId: 'user-1', today: _today, logs: logs);
}

void main() {
  group('CycleData.logStreak', () {
    test('is 0 without any logs', () {
      expect(_data([]).logStreak, 0);
    });

    test('counts today as 1', () {
      expect(_data([_log(_today)]).logStreak, 1);
    });

    test('counts three consecutive days ending today', () {
      final logs = [
        _log(_today),
        _log(_today.subtract(const Duration(days: 1))),
        _log(_today.subtract(const Duration(days: 2))),
      ];

      expect(_data(logs).logStreak, 3);
    });

    test('keeps the streak alive with only yesterday logged', () {
      final logs = [
        _log(_today.subtract(const Duration(days: 1))),
        _log(_today.subtract(const Duration(days: 2))),
      ];

      expect(_data(logs).logStreak, 2);
    });

    test('stops at a gap', () {
      final logs = [
        _log(_today),
        _log(_today.subtract(const Duration(days: 1))),
        _log(_today.subtract(const Duration(days: 3))),
      ];

      expect(_data(logs).logStreak, 2);
    });

    test('is 0 when the most recent log is older than yesterday', () {
      final logs = [
        _log(_today.subtract(const Duration(days: 2))),
        _log(_today.subtract(const Duration(days: 3))),
      ];

      expect(_data(logs).logStreak, 0);
    });
  });

  test('logsThisMonth counts only the current month', () {
    final logs = [
      _log(_today),
      _log(DateTime(2026, 11, 1)),
      _log(DateTime(2026, 10, 31)),
      _log(DateTime(2026, 10, 30)),
    ];

    expect(_data(logs).logsThisMonth, 2);
  });
}
