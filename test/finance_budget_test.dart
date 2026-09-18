import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/finances/models/finance_budget_model.dart';
import 'package:kita_story/features/finances/models/transaction_model.dart';

void main() {
  group('FinanceBudgetModel Tests', () {
    test(
        'calculateProgress properly computes spent, remaining, and health status',
        () {
      final budget = FinanceBudgetModel(
        id: 'b1',
        userId: 'user1',
        category: 'Makan dan Minum',
        amount: 1000000,
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
      );

      final transactions = [
        TransactionModel(
          id: 't1',
          userId: 'user1',
          type: 'expense',
          title: 'Makan Siang',
          category: 'Makan dan Minum',
          amount: 300000,
          transactionDate: DateTime(2026, 9, 5),
        ),
        TransactionModel(
          id: 't2',
          userId: 'user1',
          type: 'expense',
          title: 'Kopi',
          category: 'Makan dan Minum',
          amount: 200000,
          transactionDate: DateTime(2026, 9, 10),
        ),
        // Irrelevant transaction (income)
        TransactionModel(
          id: 't3',
          userId: 'user1',
          type: 'income',
          title: 'Gaji',
          category: 'Gaji',
          amount: 5000000,
          transactionDate: DateTime(2026, 9, 1),
        ),
      ];

      final progress =
          budget.calculateProgress(transactions, currentUserId: 'user1');

      expect(progress.spent, 500000);
      expect(progress.remaining, 500000);
      expect(progress.percentage, 50.0);
      expect(progress.status, BudgetHealthStatus.normal);
      expect(progress.isOverBudget, false);
      expect(progress.isNearLimit, false);
    });

    test('calculateProgress detects warning status at >= 80%', () {
      final budget = FinanceBudgetModel(
        id: 'b2',
        userId: 'user1',
        category: 'Belanja',
        amount: 1000000,
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
      );

      final transactions = [
        TransactionModel(
          id: 't1',
          userId: 'user1',
          type: 'expense',
          title: 'Baju',
          category: 'Belanja',
          amount: 850000,
          transactionDate: DateTime(2026, 9, 12),
        ),
      ];

      final progress =
          budget.calculateProgress(transactions, currentUserId: 'user1');

      expect(progress.spent, 850000);
      expect(progress.percentage, 85.0);
      expect(progress.status, BudgetHealthStatus.warning);
      expect(progress.isNearLimit, true);
      expect(progress.isOverBudget, false);
    });

    test('calculateProgress detects overbudget at > 100%', () {
      final budget = FinanceBudgetModel(
        id: 'b3',
        userId: 'user1',
        category: 'Semua Pengeluaran',
        amount: 1000000,
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
      );

      final transactions = [
        TransactionModel(
          id: 't1',
          userId: 'user1',
          type: 'expense',
          title: 'Belanja',
          category: 'Belanja',
          amount: 700000,
          transactionDate: DateTime(2026, 9, 10),
        ),
        TransactionModel(
          id: 't2',
          userId: 'user1',
          type: 'expense',
          title: 'Makan',
          category: 'Makan dan Minum',
          amount: 400000,
          transactionDate: DateTime(2026, 9, 11),
        ),
      ];

      final progress =
          budget.calculateProgress(transactions, currentUserId: 'user1');

      expect(progress.spent, 1100000);
      expect(progress.remaining, 0.0);
      expect(progress.percentage, closeTo(110.0, 0.001));
      expect(progress.status, BudgetHealthStatus.over);
      expect(progress.isOverBudget, true);
    });

    test('Shared budget counts partner transactions', () {
      final sharedBudget = FinanceBudgetModel(
        id: 'b4',
        userId: 'user1',
        partnerId: 'partner1',
        isShared: true,
        category: 'Makan dan Minum',
        amount: 1000000,
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
      );

      final transactions = [
        TransactionModel(
          id: 't1',
          userId: 'user1',
          type: 'expense',
          title: 'Makan User',
          category: 'Makan dan Minum',
          amount: 250000,
          transactionDate: DateTime(2026, 9, 2),
        ),
        TransactionModel(
          id: 't2',
          userId: 'partner1',
          type: 'expense',
          title: 'Makan Partner',
          category: 'Makan dan Minum',
          amount: 350000,
          transactionDate: DateTime(2026, 9, 3),
        ),
      ];

      final progress =
          sharedBudget.calculateProgress(transactions, currentUserId: 'user1');

      expect(progress.spent, 600000);
      expect(progress.remaining, 400000);
    });

    test('checkAndRollover computes new dates when expired', () {
      final expiredBudget = FinanceBudgetModel(
        id: 'b5',
        userId: 'user1',
        category: 'Makan dan Minum',
        amount: 1000000,
        periodType: 'daily',
        startDate: DateTime(2020, 1, 1),
        endDate: DateTime(2020, 1, 1),
        repeatType: 'auto_renew',
        alert80Notified: true,
        alert100Notified: true,
      );

      final rolled = expiredBudget.checkAndRollover();

      expect(rolled.alert80Notified, false);
      expect(rolled.alert100Notified, false);
      expect(rolled.startDate.year >= 2026, true);
    });

    test('monthly budgets calculate remaining correctly and ignore non-monthly',
        () {
      final monthlyBudget1 = FinanceBudgetModel(
        id: 'mb1',
        userId: 'user1',
        category: 'Makan',
        amount: 500000,
        periodType: 'monthly',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
      );

      final monthlyBudget2 = FinanceBudgetModel(
        id: 'mb2',
        userId: 'user1',
        category: 'Transport',
        amount: 300000,
        periodType: 'monthly',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
      );

      final transactions = [
        TransactionModel(
          id: 't1',
          userId: 'user1',
          type: 'expense',
          title: 'Makan Padang',
          category: 'Makan',
          amount: 200000,
          transactionDate: DateTime(2026, 9, 5),
        ),
        TransactionModel(
          id: 't2',
          userId: 'user1',
          type: 'expense',
          title: 'Bensin',
          category: 'Transport',
          amount: 100000,
          transactionDate: DateTime(2026, 9, 6),
        ),
        TransactionModel(
          id: 't3',
          userId: 'user1',
          type: 'expense',
          title: 'Kopi',
          category: 'Kopi Harian',
          amount: 25000,
          transactionDate: DateTime.utc(2026, 9, 14, 12),
        ),
      ];

      final p1 = monthlyBudget1.calculateProgress(transactions,
          currentUserId: 'user1');
      final p2 = monthlyBudget2.calculateProgress(transactions,
          currentUserId: 'user1');

      // Per-category progress for individual monthly budgets:
      expect(p1.spent, 200000);
      expect(p1.remaining, 300000);
      expect(p2.spent, 100000);
      expect(p2.remaining, 200000);

      // "Sisa bulan ini": Total monthly budget (800k) minus ALL expenses this month (200k + 100k + 25k = 325k) regardless of category
      final totalMonthlyBudget = monthlyBudget1.amount + monthlyBudget2.amount;
      final totalMonthExpenses = transactions
          .where((t) => t.isExpense)
          .fold(0.0, (s, t) => s + t.amount);
      final totalRemainingMonth = totalMonthlyBudget - totalMonthExpenses;

      expect(totalMonthlyBudget, 800000);
      expect(totalMonthExpenses, 325000);
      expect(totalRemainingMonth, 475000);
    });
  });
}
