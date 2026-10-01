import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/finances/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Finance Breakdown Cycle Calculations', () {
    (DateTime, DateTime) getCycleDates(int year, int month, int startDay) {
      final clampedDay = startDay.clamp(1, 28);
      final start = DateTime(year, month, clampedDay);
      final nextMonth = DateTime(year, month + 1, 1);
      final daysInNext = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
      final nextDay = clampedDay.clamp(1, daysInNext);
      final end = DateTime(nextMonth.year, nextMonth.month, nextDay, 23, 59, 59, 999)
          .subtract(const Duration(days: 1));
      return (start, end);
    }

    test('getCycleDates for 25th computes correct boundary range', () {
      final cycle = getCycleDates(2026, 9, 25);
      expect(cycle.$1, DateTime(2026, 9, 25));
      expect(cycle.$2.year, 2026);
      expect(cycle.$2.month, 10);
      expect(cycle.$2.day, 24);
    });

    test('getCycleDates for August 25th computes correct boundary range', () {
      final cycle = getCycleDates(2026, 8, 25);
      expect(cycle.$1, DateTime(2026, 8, 25));
      expect(cycle.$2.year, 2026);
      expect(cycle.$2.month, 9);
      expect(cycle.$2.day, 24);
    });

    test('transactions at 3:00 AM on start date are included in cycle', () {
      final cycle = getCycleDates(2026, 9, 25);
      final tSubuh = TransactionModel(
        id: 't1',
        userId: 'u1',
        type: 'expense',
        title: 'Makan Subuh',
        category: 'Makan',
        amount: 50000,
        transactionDate: DateTime(2026, 9, 25, 3, 0),
      );

      final tDate = tSubuh.transactionDate.toLocal();
      final isIncluded = !tDate.isBefore(cycle.$1) && !tDate.isAfter(cycle.$2);
      expect(isIncluded, true);
    });

    test('transactions before cycle start date are excluded', () {
      final cycle = getCycleDates(2026, 9, 25);
      final tOld = TransactionModel(
        id: 't2',
        userId: 'u1',
        type: 'expense',
        title: 'Makan Lama',
        category: 'Makan',
        amount: 50000,
        transactionDate: DateTime(2026, 9, 24, 23, 59),
      );

      final tDate = tOld.transactionDate.toLocal();
      final isIncluded = !tDate.isBefore(cycle.$1) && !tDate.isAfter(cycle.$2);
      expect(isIncluded, false);
    });
  });
}
