import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/finance_category_model.dart';
import '../models/transaction_model.dart';
import '../repositories/finance_repository.dart';

class CategoryBreakdownItem {
  final String name;
  final double amount;
  final double percentage; // 0 - 100
  final Color color;

  const CategoryBreakdownItem({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class FinanceProvider extends ChangeNotifier {
  final FinanceRepository _repository = FinanceRepository();

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isBalanceVisible = true;
  bool get isBalanceVisible => _isBalanceVisible;

  List<String> _customIncomeCategories = [];
  List<String> get customIncomeCategories => _customIncomeCategories;

  List<String> _customExpenseCategories = [];
  List<String> get customExpenseCategories => _customExpenseCategories;

  FinanceProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isBalanceVisible = prefs.getBool('finance_is_balance_visible') ?? true;
    _customIncomeCategories =
        prefs.getStringList('finance_custom_income_categories') ?? [];
    _customExpenseCategories =
        prefs.getStringList('finance_custom_expense_categories') ?? [];
    notifyListeners();
  }

  Future<void> toggleBalanceVisibility() async {
    _isBalanceVisible = !_isBalanceVisible;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('finance_is_balance_visible', _isBalanceVisible);
  }

  Future<void> addCustomCategory(String name, {required bool isExpense}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    if (isExpense) {
      if (!_customExpenseCategories.contains(trimmed)) {
        _customExpenseCategories.add(trimmed);
        await prefs.setStringList(
            'finance_custom_expense_categories', _customExpenseCategories);
        notifyListeners();
      }
    } else {
      if (!_customIncomeCategories.contains(trimmed)) {
        _customIncomeCategories.add(trimmed);
        await prefs.setStringList(
            'finance_custom_income_categories', _customIncomeCategories);
        notifyListeners();
      }
    }
  }

  /// All categories available for Income (defaults + custom)
  List<String> get allIncomeCategoryNames {
    final defaultNames =
        FinanceCategoryModel.defaultIncomeCategories.map((c) => c.name).toList();
    final set = <String>{...defaultNames, ..._customIncomeCategories};
    // Also include any categories found in historical transactions
    for (final t in _transactions) {
      if (t.isIncome) set.add(t.category);
    }
    return set.toList();
  }

  /// All categories available for Expense (defaults + custom)
  List<String> get allExpenseCategoryNames {
    final defaultNames =
        FinanceCategoryModel.defaultExpenseCategories.map((c) => c.name).toList();
    final set = <String>{...defaultNames, ..._customExpenseCategories};
    // Also include any categories found in historical transactions
    for (final t in _transactions) {
      if (t.isExpense) set.add(t.category);
    }
    return set.toList();
  }

  /// Total Cumulative Balance (All-Time Income - All-Time Expense)
  double get totalBalance {
    double total = 0.0;
    for (final t in _transactions) {
      if (t.isIncome) {
        total += t.amount;
      } else {
        total -= t.amount;
      }
    }
    return total;
  }

  /// Current Month Income
  double get currentMonthIncome {
    final now = DateTime.now();
    double income = 0.0;
    for (final t in _transactions) {
      if (t.isIncome &&
          t.transactionDate.year == now.year &&
          t.transactionDate.month == now.month) {
        income += t.amount;
      }
    }
    return income;
  }

  /// Current Month Expense
  double get currentMonthExpense {
    final now = DateTime.now();
    double expense = 0.0;
    for (final t in _transactions) {
      if (t.isExpense &&
          t.transactionDate.year == now.year &&
          t.transactionDate.month == now.month) {
        expense += t.amount;
      }
    }
    return expense;
  }

  /// Current Month Net Savings (Income - Expense)
  double get currentMonthNetSavings =>
      currentMonthIncome - currentMonthExpense;

  /// Expense Breakdown by Category for Donut Chart
  List<CategoryBreakdownItem> get categoryExpenseBreakdown {
    final now = DateTime.now();
    final Map<String, double> categoryTotals = {};

    // Filter current month expenses
    final monthExpenses = _transactions.where((t) =>
        t.isExpense &&
        t.transactionDate.year == now.year &&
        t.transactionDate.month == now.month);

    final targetList =
        monthExpenses.isNotEmpty ? monthExpenses : _transactions.where((t) => t.isExpense);

    double totalExp = 0.0;
    for (final t in targetList) {
      categoryTotals[t.category] =
          (categoryTotals[t.category] ?? 0.0) + t.amount;
      totalExp += t.amount;
    }

    if (totalExp <= 0) return [];

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((entry) {
      final percentage = (entry.value / totalExp) * 100.0;
      final color = FinanceCategoryModel.getColorForCategory(entry.key,
          isExpense: true);
      return CategoryBreakdownItem(
        name: entry.key,
        amount: entry.value,
        percentage: percentage,
        color: color,
      );
    }).toList();
  }

  /// Fetch transactions from server
  Future<void> fetchTransactions({
    String? targetUserId,
    String? partnerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _repository.getTransactions(
        targetUserId: targetUserId,
        partnerId: partnerId,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat data transaksi: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a transaction
  Future<bool> createTransaction({
    required String type,
    required String title,
    required String category,
    required double amount,
    required DateTime transactionDate,
    String? note,
    bool isShared = true,
    String? partnerId,
  }) async {
    try {
      final newTransaction = await _repository.createTransaction(
        type: type,
        title: title,
        category: category,
        amount: amount,
        transactionDate: transactionDate,
        note: note,
        isShared: isShared,
        partnerId: partnerId,
      );

      _transactions.insert(0, newTransaction);
      _transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update a transaction
  Future<bool> updateTransaction(
    String transactionId, {
    required String type,
    required String title,
    required String category,
    required double amount,
    required DateTime transactionDate,
    String? note,
    bool isShared = true,
    String? partnerId,
  }) async {
    try {
      final updated = await _repository.updateTransaction(
        transactionId,
        type: type,
        title: title,
        category: category,
        amount: amount,
        transactionDate: transactionDate,
        note: note,
        isShared: isShared,
        partnerId: partnerId,
      );

      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index != -1) {
        _transactions[index] = updated;
        _transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a transaction
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _repository.deleteTransaction(transactionId);
      _transactions.removeWhere((t) => t.id == transactionId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Static Helper: Format Rupiah string
  static String formatRupiah(double amount, {bool showSymbol = true}) {
    final isNegative = amount < 0;
    final absAmount = amount.abs().round();
    final str = absAmount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    final formatted = buffer.toString().split('').reversed.join('');
    final prefix = isNegative ? '- ' : '';
    return showSymbol ? '${prefix}Rp $formatted' : '$prefix$formatted';
  }
}
