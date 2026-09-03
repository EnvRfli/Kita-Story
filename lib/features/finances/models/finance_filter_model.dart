import 'transaction_model.dart';

enum FinanceTypeFilter { all, income, expense }

enum FinancePeriodFilter { all, today, thisWeek, thisMonth, lastMonth, custom }

enum FinanceSortBy { dateDesc, dateAsc, amountDesc, amountAsc }

class FinanceFilterModel {
  final FinanceTypeFilter type;
  final FinancePeriodFilter period;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String? category;
  final FinanceSortBy sortBy;

  const FinanceFilterModel({
    this.type = FinanceTypeFilter.all,
    this.period = FinancePeriodFilter.all,
    this.customStartDate,
    this.customEndDate,
    this.category,
    this.sortBy = FinanceSortBy.dateDesc,
  });

  bool get isActive {
    return type != FinanceTypeFilter.all ||
        period != FinancePeriodFilter.all ||
        category != null ||
        sortBy != FinanceSortBy.dateDesc ||
        customStartDate != null ||
        customEndDate != null;
  }

  FinanceFilterModel copyWith({
    FinanceTypeFilter? type,
    FinancePeriodFilter? period,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? category,
    bool clearCategory = false,
    FinanceSortBy? sortBy,
  }) {
    return FinanceFilterModel(
      type: type ?? this.type,
      period: period ?? this.period,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      category: clearCategory ? null : (category ?? this.category),
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// Apply filter and sorting to an in-memory list of transactions
  List<TransactionModel> apply(List<TransactionModel> items) {
    var result = List<TransactionModel>.from(items);
    final now = DateTime.now();

    // 1. Filter by Type
    if (type == FinanceTypeFilter.income) {
      result = result.where((t) => t.isIncome).toList();
    } else if (type == FinanceTypeFilter.expense) {
      result = result.where((t) => t.isExpense).toList();
    }

    // 2. Filter by Category
    if (category != null && category!.isNotEmpty && category != 'Semua Kategori') {
      result = result.where((t) => t.category == category).toList();
    }

    // 3. Filter by Period
    switch (period) {
      case FinancePeriodFilter.today:
        result = result.where((t) {
          final d = t.transactionDate;
          return d.year == now.year && d.month == now.month && d.day == now.day;
        }).toList();
        break;
      case FinancePeriodFilter.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        result = result.where((t) => t.transactionDate.isAfter(weekStart.subtract(const Duration(seconds: 1)))).toList();
        break;
      case FinancePeriodFilter.thisMonth:
        result = result.where((t) {
          final d = t.transactionDate;
          return d.year == now.year && d.month == now.month;
        }).toList();
        break;
      case FinancePeriodFilter.lastMonth:
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        result = result.where((t) {
          final d = t.transactionDate;
          return d.year == lastMonthDate.year && d.month == lastMonthDate.month;
        }).toList();
        break;
      case FinancePeriodFilter.custom:
        if (customStartDate != null && customEndDate != null) {
          final start = DateTime(customStartDate!.year, customStartDate!.month, customStartDate!.day);
          final end = DateTime(customEndDate!.year, customEndDate!.month, customEndDate!.day, 23, 59, 59);
          result = result.where((t) {
            return t.transactionDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
                t.transactionDate.isBefore(end.add(const Duration(seconds: 1)));
          }).toList();
        }
        break;
      case FinancePeriodFilter.all:
        break;
    }

    // 4. Sorting
    switch (sortBy) {
      case FinanceSortBy.dateAsc:
        result.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
        break;
      case FinanceSortBy.amountDesc:
        result.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case FinanceSortBy.amountAsc:
        result.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case FinanceSortBy.dateDesc:
        result.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
        break;
    }

    return result;
  }
}
