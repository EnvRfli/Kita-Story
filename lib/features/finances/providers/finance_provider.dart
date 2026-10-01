import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/finance_category_model.dart';
import '../models/finance_filter_model.dart';
import '../models/transaction_model.dart';
import '../models/finance_budget_model.dart';
import '../repositories/finance_repository.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/finance_widget_service.dart';

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

  // Pagination for All Transactions Screen (15 items per fetch)
  static const int _pageSize = 15;
  List<TransactionModel> _pagedTransactions = [];
  List<TransactionModel> get pagedTransactions => _pagedTransactions;

  // Budgets state
  List<FinanceBudgetModel> _budgets = [];
  List<FinanceBudgetModel> get budgets => _budgets;
  bool _isLoadingBudgets = false;
  bool get isLoadingBudgets => _isLoadingBudgets;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingPaged = false;
  bool get isLoadingPaged => _isLoadingPaged;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  int _currentOffset = 0;

  // Filter State
  FinanceFilterModel _filter = const FinanceFilterModel();
  FinanceFilterModel get filter => _filter;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isBalanceVisible = true;
  bool get isBalanceVisible => _isBalanceVisible;

  List<String> _customIncomeCategories = [];
  List<String> get customIncomeCategories => _customIncomeCategories;

  List<String> _customExpenseCategories = [];
  List<String> get customExpenseCategories => _customExpenseCategories;

  // User Finance Summary Settings
  final Map<String, int?> _userSummaryStartDays = {};
  Map<String, int?> get userSummaryStartDays => _userSummaryStartDays;

  bool _isAllTimeView = false;
  bool get isAllTimeView => _isAllTimeView;

  static const List<String> _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des'
  ];

  int? getStartDayForUser({String? targetUserId}) {
    if (targetUserId == null) return null;
    return _userSummaryStartDays[targetUserId];
  }

  bool hasCustomStartDay({String? targetUserId}) {
    final day = getStartDayForUser(targetUserId: targetUserId);
    return day != null && day >= 1 && day <= 31;
  }

  Future<void> fetchSummarySettings(String userId) async {
    // 1. Check local cache first
    final prefs = await SharedPreferences.getInstance();
    final cachedVal = prefs.getInt('finance_summary_start_day_$userId');
    if (cachedVal != null && cachedVal > 0) {
      _userSummaryStartDays[userId] = cachedVal;
    }

    // 2. Fetch from Supabase
    try {
      final remoteVal = await _repository.getSummaryStartDay(userId);
      _userSummaryStartDays[userId] = remoteVal;
      if (remoteVal != null) {
        await prefs.setInt('finance_summary_start_day_$userId', remoteVal);
      } else {
        await prefs.remove('finance_summary_start_day_$userId');
      }
    } catch (_) {}

    notifyListeners();
  }

  Future<void> updateSummaryStartDay({
    required String userId,
    int? startDay,
  }) async {
    _userSummaryStartDays[userId] = startDay;
    _isAllTimeView = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (startDay != null) {
      await prefs.setInt('finance_summary_start_day_$userId', startDay);
    } else {
      await prefs.remove('finance_summary_start_day_$userId');
    }

    await _repository.saveSummaryStartDay(userId, startDay);
  }

  void toggleSummaryViewMode() {
    _isAllTimeView = !_isAllTimeView;
    notifyListeners();
  }

  void setAllTimeViewMode(bool isAllTime) {
    _isAllTimeView = isAllTime;
    notifyListeners();
  }

  /// Compute active date range for the user's cycle if startDay is set
  (DateTime, DateTime)? getCycleRangeForUser({String? targetUserId}) {
    final startDay = getStartDayForUser(targetUserId: targetUserId);
    if (startDay == null || startDay < 1 || startDay > 31) return null;

    final now = DateTime.now();
    final clampedDay = startDay.clamp(1, 28);
    DateTime start;
    DateTime end;

    if (now.day >= clampedDay) {
      start = DateTime(now.year, now.month, clampedDay);
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      final daysInNext = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
      final nextDay = clampedDay.clamp(1, daysInNext);
      end = DateTime(nextMonth.year, nextMonth.month, nextDay, 23, 59, 59, 999)
          .subtract(const Duration(days: 1));
    } else {
      final prevMonth = DateTime(now.year, now.month - 1, 1);
      final daysInPrev = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;
      final prevDay = clampedDay.clamp(1, daysInPrev);
      start = DateTime(prevMonth.year, prevMonth.month, prevDay);
      end = DateTime(now.year, now.month, clampedDay, 23, 59, 59, 999)
          .subtract(const Duration(days: 1));
    }

    return (start, end);
  }

  /// Dynamic income calculated based on custom cycle date or all-time
  double getDynamicIncome({String? targetUserId}) {
    if (_isAllTimeView || !hasCustomStartDay(targetUserId: targetUserId)) {
      double total = 0.0;
      for (final t in _transactions) {
        if (t.isIncome) total += t.amount;
      }
      return total;
    }

    final cycle = getCycleRangeForUser(targetUserId: targetUserId);
    if (cycle == null) {
      double total = 0.0;
      for (final t in _transactions) {
        if (t.isIncome) total += t.amount;
      }
      return total;
    }

    double total = 0.0;
    for (final t in _transactions) {
      final tDate = t.transactionDate.toLocal();
      if (t.isIncome && !tDate.isBefore(cycle.$1) && !tDate.isAfter(cycle.$2)) {
        total += t.amount;
      }
    }
    return total;
  }

  /// Dynamic expense calculated based on custom cycle date or all-time
  double getDynamicExpense({String? targetUserId}) {
    if (_isAllTimeView || !hasCustomStartDay(targetUserId: targetUserId)) {
      double total = 0.0;
      for (final t in _transactions) {
        if (t.isExpense) total += t.amount;
      }
      return total;
    }

    final cycle = getCycleRangeForUser(targetUserId: targetUserId);
    if (cycle == null) {
      double total = 0.0;
      for (final t in _transactions) {
        if (t.isExpense) total += t.amount;
      }
      return total;
    }

    double total = 0.0;
    for (final t in _transactions) {
      final tDate = t.transactionDate.toLocal();
      if (t.isExpense &&
          !tDate.isBefore(cycle.$1) &&
          !tDate.isAfter(cycle.$2)) {
        total += t.amount;
      }
    }
    return total;
  }

  /// Label for the dynamic period in FinanceSummaryRow
  String getDynamicPeriodLabel({String? targetUserId}) {
    if (_isAllTimeView || !hasCustomStartDay(targetUserId: targetUserId)) {
      return 'Keseluruhan';
    }

    final cycle = getCycleRangeForUser(targetUserId: targetUserId);
    if (cycle == null) return 'Keseluruhan';

    final startDay = getStartDayForUser(targetUserId: targetUserId);
    return 'Tgl $startDay (${cycle.$1.day} ${_shortMonths[cycle.$1.month - 1]} – ${cycle.$2.day} ${_shortMonths[cycle.$2.month - 1]})';
  }

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
    _syncWidget();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('finance_is_balance_visible', _isBalanceVisible);
  }

  void _syncWidget() {
    FinanceWidgetService.updateWidget(
      totalBalance: totalBalance,
      totalRemaining: totalMonthlyBudgetRemaining(),
      isBalanceVisible: _isBalanceVisible,
    );
  }

  void setFilter(FinanceFilterModel newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  void resetFilter() {
    _filter = const FinanceFilterModel();
    notifyListeners();
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
    final defaultNames = FinanceCategoryModel.defaultIncomeCategories
        .map((c) => c.name)
        .toList();
    final set = <String>{...defaultNames, ..._customIncomeCategories};
    // Also include any categories found in historical transactions
    for (final t in _transactions) {
      if (t.isIncome) set.add(t.category);
    }
    return set.toList();
  }

  /// All categories available for Expense (defaults + custom)
  List<String> get allExpenseCategoryNames {
    final defaultNames = FinanceCategoryModel.defaultExpenseCategories
        .map((c) => c.name)
        .toList();
    final set = <String>{...defaultNames, ..._customExpenseCategories};
    // Also include any categories found in historical transactions
    for (final t in _transactions) {
      if (t.isExpense) set.add(t.category);
    }
    return set.toList();
  }

  /// All Unique Categories (Income + Expense)
  List<String> get allCategories {
    final set = <String>{...allIncomeCategoryNames, ...allExpenseCategoryNames};
    return set.toList();
  }

  /// Transaksi Hari Ini
  List<TransactionModel> get todayTransactions {
    final now = DateTime.now();
    return _transactions.where((t) {
      final d = t.transactionDate;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  /// Total Net Transaksi Hari Ini (Income - Expense)
  double get todayNetTotal {
    double total = 0.0;
    for (final t in todayTransactions) {
      if (t.isIncome) {
        total += t.amount;
      } else {
        total -= t.amount;
      }
    }
    return total;
  }

  /// Total Pemasukan Hari Ini
  double get todayIncome {
    double total = 0.0;
    for (final t in todayTransactions) {
      if (t.isIncome) {
        total += t.amount;
      }
    }
    return total;
  }

  /// Total Pengeluaran Hari Ini
  double get todayExpense {
    double total = 0.0;
    for (final t in todayTransactions) {
      if (t.isExpense) {
        total += t.amount;
      }
    }
    return total;
  }

  /// 5 Transaksi Terakhir untuk section Riwayat Transaksi di Main Screen
  List<TransactionModel> get recentTransactions {
    return _transactions.take(5).toList();
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
  double get currentMonthNetSavings => currentMonthIncome - currentMonthExpense;

  /// Expense Breakdown by Category for Donut Chart
  /// Follows the active dynamic cycle date or all-time setting
  List<CategoryBreakdownItem> getDynamicCategoryExpenseBreakdown({
    String? targetUserId,
  }) {
    final Map<String, double> categoryTotals = {};
    Iterable<TransactionModel> targetList;

    if (_isAllTimeView || !hasCustomStartDay(targetUserId: targetUserId)) {
      targetList = _transactions.where((t) => t.isExpense);
    } else {
      final cycle = getCycleRangeForUser(targetUserId: targetUserId);
      if (cycle == null) {
        targetList = _transactions.where((t) => t.isExpense);
      } else {
        targetList = _transactions.where((t) {
          if (!t.isExpense) return false;
          final tDate = t.transactionDate.toLocal();
          return !tDate.isBefore(cycle.$1) && !tDate.isAfter(cycle.$2);
        });
      }
    }

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
      final color =
          FinanceCategoryModel.getColorForCategory(entry.key, isExpense: true);
      return CategoryBreakdownItem(
        name: entry.key,
        amount: entry.value,
        percentage: percentage,
        color: color,
      );
    }).toList();
  }

  /// Expense Breakdown by Category for Donut Chart (backward compatibility)
  List<CategoryBreakdownItem> get categoryExpenseBreakdown =>
      getDynamicCategoryExpenseBreakdown();

  /// Fetch overview transactions from server
  Future<void> fetchTransactions({
    String? targetUserId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _repository.getTransactions(
        targetUserId: targetUserId,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat data transaksi: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
      _syncWidget();
    }
  }

  FinanceFilterModel _activePagedFilter = const FinanceFilterModel();
  FinanceFilterModel get activePagedFilter => _activePagedFilter;

  /// Fetch Initial Paged Transactions for All Transactions Screen (15 items)
  Future<void> fetchInitialPagedTransactions({
    String? targetUserId,
    FinanceFilterModel? filter,
  }) async {
    if (filter != null) {
      _activePagedFilter = filter;
    }
    _isLoadingPaged = true;
    _currentOffset = 0;
    _hasMore = true;
    _pagedTransactions = [];
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _repository.getTransactionsPaged(
        targetUserId: targetUserId,
        filter: _activePagedFilter,
        limit: _pageSize,
        offset: 0,
      );
      _pagedTransactions = list;
      _currentOffset = list.length;
      if (list.length < _pageSize) {
        _hasMore = false;
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat transaksi: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoadingPaged = false;
      notifyListeners();
    }
  }

  /// Fetch More Paged Transactions when user scrolls to bottom (15 items per fetch)
  Future<void> fetchMoreTransactions({
    String? targetUserId,
    FinanceFilterModel? filter,
  }) async {
    if (_isLoadingMore || !_hasMore || _isLoadingPaged) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final list = await _repository.getTransactionsPaged(
        targetUserId: targetUserId,
        filter: filter ?? _activePagedFilter,
        limit: _pageSize,
        offset: _currentOffset,
      );

      if (list.isNotEmpty) {
        // Prevent duplicate IDs
        final existingIds = _pagedTransactions.map((t) => t.id).toSet();
        for (final item in list) {
          if (!existingIds.contains(item.id)) {
            _pagedTransactions.add(item);
          }
        }
        _currentOffset += list.length;
      }

      if (list.length < _pageSize) {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Error fetching more transactions: $e');
    } finally {
      _isLoadingMore = false;
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
      _transactions
          .sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      // Also prepend to paged transactions if loaded
      _pagedTransactions.removeWhere((t) => t.id == newTransaction.id);
      _pagedTransactions.insert(0, newTransaction);
      _pagedTransactions
          .sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      notifyListeners();
      _syncWidget();

      // Check budget thresholds for instant push notification alert
      _checkBudgetAlerts(newTransaction);

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
        _transactions
            .sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      }

      final pagedIndex =
          _pagedTransactions.indexWhere((t) => t.id == transactionId);
      if (pagedIndex != -1) {
        _pagedTransactions[pagedIndex] = updated;
        _pagedTransactions
            .sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      }

      notifyListeners();
      _syncWidget();

      // Check budget thresholds for instant push notification alert
      _checkBudgetAlerts(updated);

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
      _pagedTransactions.removeWhere((t) => t.id == transactionId);
      notifyListeners();
      _syncWidget();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // BUDGETS MANAGEMENT & ALERTS
  // ===========================================================================

  /// Fetch active budgets
  Future<void> fetchBudgets({String? targetUserId, String? partnerId}) async {
    _isLoadingBudgets = true;
    notifyListeners();

    try {
      _budgets = await _repository.getBudgets(
        targetUserId: targetUserId,
        partnerId: partnerId,
      );
    } catch (e) {
      debugPrint('Error fetching budgets in FinanceProvider: $e');
    } finally {
      _isLoadingBudgets = false;
      notifyListeners();
      _syncWidget();
    }
  }

  /// Get calculated progress for all budgets
  List<FinanceBudgetProgress> getBudgetProgressList({String? currentUserId}) {
    final List<FinanceBudgetProgress> list = [];
    for (int i = 0; i < _budgets.length; i++) {
      final b = _budgets[i];
      final rolled = b.checkAndRollover();
      if (rolled.startDate != b.startDate || rolled.endDate != b.endDate) {
        _budgets[i] = rolled;
        // Background sync to DB so server is also updated
        _repository
            .updateBudget(
              rolled.id,
              category: rolled.category,
              amount: rolled.amount,
              periodType: rolled.periodType,
              startDate: rolled.startDate,
              endDate: rolled.endDate,
              repeatType: rolled.repeatType,
              monthlyStartDay: rolled.monthlyStartDay,
              isShared: rolled.isShared,
              partnerId: rolled.partnerId,
            )
            .then((_) {},
                onError: (e) => debugPrint('Error syncing rollover: $e'));
      }
      list.add(rolled.calculateProgress(_transactions,
          currentUserId: currentUserId));
    }
    return list;
  }

  /// Total remaining budget for all monthly budgets:
  /// Uses active cycle progress so custom start day budgets (e.g. tanggal 25) are respected
  double totalMonthlyBudgetRemaining({String? currentUserId}) {
    final progressList = getBudgetProgressList(currentUserId: currentUserId);
    final monthlyProgress =
        progressList.where((p) => p.budget.periodType == 'monthly').toList();
    if (monthlyProgress.isEmpty) return 0.0;

    // If there is an 'all categories' budget, its remaining is the canonical remaining
    final allCategoriesProgress =
        monthlyProgress.where((p) => p.budget.isAllCategories).firstOrNull;
    if (allCategoriesProgress != null) {
      return allCategoriesProgress.remaining;
    }

    final totalBudget =
        monthlyProgress.fold(0.0, (sum, p) => sum + p.budget.amount);
    final totalSpent = monthlyProgress.fold(0.0, (sum, p) => sum + p.spent);
    return math.max(0.0, totalBudget - totalSpent);
  }

  /// Total allocated budget for all monthly budgets
  double get totalMonthlyBudgetAllocated {
    return _budgets
        .where((b) => b.periodType == 'monthly')
        .fold(0.0, (sum, b) => sum + b.amount);
  }

  /// Add a new budget
  Future<bool> addBudget({
    required String category,
    required double amount,
    required String periodType,
    required DateTime startDate,
    required DateTime endDate,
    String repeatType = 'auto_renew',
    int monthlyStartDay = 1,
    bool isShared = false,
    String? partnerId,
  }) async {
    try {
      final newBudget = await _repository.createBudget(
        category: category,
        amount: amount,
        periodType: periodType,
        startDate: startDate,
        endDate: endDate,
        repeatType: repeatType,
        monthlyStartDay: monthlyStartDay,
        isShared: isShared,
        partnerId: partnerId,
      );

      _budgets.insert(0, newBudget);
      notifyListeners();
      _syncWidget();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambah budget: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  /// Update an existing budget
  Future<bool> editBudget(
    String budgetId, {
    required String category,
    required double amount,
    required String periodType,
    required DateTime startDate,
    required DateTime endDate,
    String repeatType = 'auto_renew',
    int monthlyStartDay = 1,
    bool isShared = false,
    String? partnerId,
  }) async {
    try {
      final updated = await _repository.updateBudget(
        budgetId,
        category: category,
        amount: amount,
        periodType: periodType,
        startDate: startDate,
        endDate: endDate,
        repeatType: repeatType,
        monthlyStartDay: monthlyStartDay,
        isShared: isShared,
        partnerId: partnerId,
      );

      final index = _budgets.indexWhere((b) => b.id == budgetId);
      if (index != -1) {
        _budgets[index] = updated;
        notifyListeners();
        _syncWidget();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui budget: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  /// Remove a budget
  Future<bool> removeBudget(String budgetId) async {
    try {
      await _repository.deleteBudget(budgetId);
      _budgets.removeWhere((b) => b.id == budgetId);
      notifyListeners();
      _syncWidget();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus budget: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  /// Evaluate budget health after transaction entry and trigger instant push notification
  Future<void> _checkBudgetAlerts(TransactionModel transaction) async {
    if (!transaction.isExpense) return;

    for (int i = 0; i < _budgets.length; i++) {
      final budget = _budgets[i];
      if (!budget.matchesCategory(transaction.category)) continue;

      final progress = budget.calculateProgress(_transactions);

      // Alert 80%
      if (progress.percentage >= 80.0 &&
          !budget.alert80Notified &&
          !progress.isOverBudget) {
        try {
          await NotificationService.showInstantNotification(
            id: budget.id.hashCode & 0x7FFFFFFF,
            title: '⚠️ Peringatan Budget: ${budget.category}',
            body:
                'Pengeluaran "${budget.category}" sudah mencapai ${progress.percentage.toStringAsFixed(0)}% dari batas budget!',
          );
          await _repository.updateBudgetNotificationFlags(budget.id,
              alert80: true);
          _budgets[i] = budget.copyWith(alert80Notified: true);
        } catch (err) {
          debugPrint('Notification 80% error: $err');
        }
      }

      // Alert 100% (Overbudget)
      if (progress.isOverBudget && !budget.alert100Notified) {
        try {
          await NotificationService.showInstantNotification(
            id: (budget.id.hashCode + 1) & 0x7FFFFFFF,
            title: '🚨 Budget Terlampaui: ${budget.category}',
            body:
                'Pengeluaran "${budget.category}" sudah melebihi batas budget yang ditetapkan!',
          );
          await _repository.updateBudgetNotificationFlags(budget.id,
              alert100: true);
          _budgets[i] = budget.copyWith(alert100Notified: true);
        } catch (err) {
          debugPrint('Notification 100% error: $err');
        }
      }
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
