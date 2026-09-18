import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/activity_log_service.dart';
import '../models/transaction_model.dart';
import '../models/finance_filter_model.dart';
import '../models/finance_budget_model.dart';

class FinanceRepository {
  final _client = SupabaseNetwork.client;

  String _formatRupiah(double amount) {
    final intVal = amount.round();
    final str = intVal.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  /// Fetch transactions strictly for the specified user (personal isolation)
  Future<List<TransactionModel>> getTransactions({
    String? targetUserId,
  }) async {
    final user = _client.auth.currentUser;
    final uid = targetUserId ?? user?.id;
    if (uid == null) return [];

    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', uid)
          .order('transaction_date', ascending: false);

      return (response as List)
          .map(
              (json) => TransactionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      rethrow;
    }
  }

  /// Fetch paginated transactions with server-side filtering (default limit: 15 per fetch)
  Future<List<TransactionModel>> getTransactionsPaged({
    String? targetUserId,
    FinanceFilterModel? filter,
    int limit = 15,
    int offset = 0,
  }) async {
    final user = _client.auth.currentUser;
    final uid = targetUserId ?? user?.id;
    if (uid == null) return [];

    try {
      PostgrestFilterBuilder<PostgrestList> filterQuery =
          _client.from('transactions').select().eq('user_id', uid);

      if (filter != null) {
        // 1. Type
        if (filter.type == FinanceTypeFilter.income) {
          filterQuery = filterQuery.eq('type', 'income');
        } else if (filter.type == FinanceTypeFilter.expense) {
          filterQuery = filterQuery.eq('type', 'expense');
        }

        // 2. Category
        if (filter.category != null && filter.category!.isNotEmpty) {
          filterQuery = filterQuery.eq('category', filter.category!);
        }

        // 3. Period
        final now = DateTime.now();
        if (filter.period == FinancePeriodFilter.today) {
          final startToday =
              DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
          final endToday =
              DateTime(now.year, now.month, now.day, 23, 59, 59, 999)
                  .toUtc()
                  .toIso8601String();
          filterQuery = filterQuery
              .gte('transaction_date', startToday)
              .lte('transaction_date', endToday);
        } else if (filter.period == FinancePeriodFilter.thisWeek) {
          final startOfWeek = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: now.weekday - 1))
              .toUtc()
              .toIso8601String();
          filterQuery = filterQuery.gte('transaction_date', startOfWeek);
        } else if (filter.period == FinancePeriodFilter.thisMonth) {
          final startOfMonth =
              DateTime(now.year, now.month, 1).toUtc().toIso8601String();
          filterQuery = filterQuery.gte('transaction_date', startOfMonth);
        } else if (filter.period == FinancePeriodFilter.lastMonth) {
          final startLastMonth =
              DateTime(now.year, now.month - 1, 1).toUtc().toIso8601String();
          final endLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59, 999)
              .toUtc()
              .toIso8601String();
          filterQuery = filterQuery
              .gte('transaction_date', startLastMonth)
              .lte('transaction_date', endLastMonth);
        } else if (filter.period == FinancePeriodFilter.custom &&
            filter.customStartDate != null &&
            filter.customEndDate != null) {
          final start = DateTime(
            filter.customStartDate!.year,
            filter.customStartDate!.month,
            filter.customStartDate!.day,
          ).toUtc().toIso8601String();
          final end = DateTime(
            filter.customEndDate!.year,
            filter.customEndDate!.month,
            filter.customEndDate!.day,
            23,
            59,
            59,
            999,
          ).toUtc().toIso8601String();
          filterQuery = filterQuery
              .gte('transaction_date', start)
              .lte('transaction_date', end);
        }
      }

      // 4. Sorting & Range
      PostgrestTransformBuilder<PostgrestList> transformQuery;
      if (filter != null) {
        switch (filter.sortBy) {
          case FinanceSortBy.dateAsc:
            transformQuery =
                filterQuery.order('transaction_date', ascending: true);
            break;
          case FinanceSortBy.amountDesc:
            transformQuery = filterQuery.order('amount', ascending: false);
            break;
          case FinanceSortBy.amountAsc:
            transformQuery = filterQuery.order('amount', ascending: true);
            break;
          case FinanceSortBy.dateDesc:
            transformQuery =
                filterQuery.order('transaction_date', ascending: false);
            break;
        }
      } else {
        transformQuery =
            filterQuery.order('transaction_date', ascending: false);
      }

      final response = await transformQuery.range(offset, offset + limit - 1);

      return (response as List)
          .map(
              (json) => TransactionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching paginated transactions: $e');
      rethrow;
    }
  }

  /// Create a new transaction and award points via ActivityLogService
  Future<TransactionModel> createTransaction({
    required String type, // 'income' or 'expense'
    required String title,
    required String category,
    required double amount,
    required DateTime transactionDate,
    String? note,
    bool isShared = true,
    String? partnerId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Pengguna belum login');

    final payload = <String, dynamic>{
      'user_id': user.id,
      'type': type,
      'title': title.trim(),
      'category': category.trim(),
      'amount': amount,
      'transaction_date': transactionDate.toUtc().toIso8601String(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response =
        await _client.from('transactions').insert(payload).select().single();

    final newTransaction = TransactionModel.fromJson(response);
    final formattedNominal = _formatRupiah(amount);

    // Gamification & Points Ledger (+5 for income, +3 for expense)
    try {
      final isIncome = type == 'income';
      await ActivityLogService.recordActivityAndAddPoints(
        userId: user.id,
        points: isIncome ? 5 : 3,
        activityType: isIncome ? 'add_income' : 'add_expense',
        title: isIncome ? 'Mencatat Pemasukan 💵' : 'Mencatat Pengeluaran 💳',
        description: isIncome
            ? 'Mencatat pemasukan "$title" (+$formattedNominal)'
            : 'Mencatat pengeluaran "$title" (-$formattedNominal)',
        referenceId: newTransaction.id,
      );
    } catch (logError) {
      debugPrint('Warning recording finance gamification activity: $logError');
    }

    return newTransaction;
  }

  /// Update an existing transaction and award points
  Future<TransactionModel> updateTransaction(
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
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Pengguna belum login');

    final payload = <String, dynamic>{
      'type': type,
      'title': title.trim(),
      'category': category.trim(),
      'amount': amount,
      'transaction_date': transactionDate.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await _client
        .from('transactions')
        .update(payload)
        .eq('id', transactionId)
        .select()
        .single();

    final updated = TransactionModel.fromJson(response);

    // Gamification edit reward (+2 points)
    try {
      await ActivityLogService.recordActivityAndAddPoints(
        userId: user.id,
        points: 2,
        activityType: 'edit_transaction',
        title: 'Memperbarui Transaksi 📝',
        description: 'Memperbarui catatan transaksi "$title"',
        referenceId: transactionId,
      );
    } catch (logError) {
      debugPrint('Warning recording edit finance activity: $logError');
    }

    return updated;
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    await _client.from('transactions').delete().eq('id', transactionId);
  }

  // ===========================================================================
  // BUDGETS MODULE METHODS
  // ===========================================================================

  /// Fetch active budgets for user (including shared budgets with partner)
  Future<List<FinanceBudgetModel>> getBudgets({
    String? targetUserId,
    String? partnerId,
  }) async {
    final user = _client.auth.currentUser;
    final uid = targetUserId ?? user?.id;
    if (uid == null) return [];

    try {
      // Query budgets where user_id = uid, or shared with partner
      var query = _client.from('finance_budgets').select();

      final List response;
      if (partnerId != null && partnerId.isNotEmpty) {
        response = await query.or(
          'user_id.eq.$uid,and(is_shared.eq.true,or(user_id.eq.$partnerId,partner_id.eq.$uid))',
        ).order('created_at', ascending: false);
      } else {
        response = await query.eq('user_id', uid).order('created_at', ascending: false);
      }

      final budgets = response
          .map((json) => FinanceBudgetModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Check auto-renew rollover for all budgets
      final List<FinanceBudgetModel> updatedList = [];
      for (final b in budgets) {
        final rolled = b.checkAndRollover();
        if (rolled.startDate != b.startDate || rolled.endDate != b.endDate) {
          // Persist rollover to database in background
          _client.from('finance_budgets').update({
            'start_date': '${rolled.startDate.year.toString().padLeft(4, '0')}-${rolled.startDate.month.toString().padLeft(2, '0')}-${rolled.startDate.day.toString().padLeft(2, '0')}',
            'end_date': '${rolled.endDate.year.toString().padLeft(4, '0')}-${rolled.endDate.month.toString().padLeft(2, '0')}-${rolled.endDate.day.toString().padLeft(2, '0')}',
            'alert_80_notified': false,
            'alert_100_notified': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('id', b.id).then((_) {}, onError: (err) {
            debugPrint('Error syncing budget rollover to DB: $err');
          });
          updatedList.add(rolled);
        } else {
          updatedList.add(b);
        }
      }

      return updatedList;
    } catch (e) {
      debugPrint('Error fetching budgets: $e');
      rethrow;
    }
  }

  /// Create a new budget and award +5 gamification points
  Future<FinanceBudgetModel> createBudget({
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
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Pengguna belum login');

    final payload = <String, dynamic>{
      'user_id': user.id,
      if (partnerId != null) 'partner_id': partnerId,
      'is_shared': isShared,
      'category': category.trim(),
      'amount': amount,
      'period_type': periodType,
      'start_date': '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'end_date': '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      'repeat_type': repeatType,
      'monthly_start_day': monthlyStartDay,
      'alert_80_notified': false,
      'alert_100_notified': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await _client
        .from('finance_budgets')
        .insert(payload)
        .select()
        .single();

    final newBudget = FinanceBudgetModel.fromJson(response);
    final formattedNominal = _formatRupiah(amount);

    // Gamification & Points Ledger (+5 for adding new budget)
    try {
      await ActivityLogService.recordActivityAndAddPoints(
        userId: user.id,
        points: 5,
        activityType: 'add_budget',
        title: 'Menambah Budget Baru 🎯',
        description: isShared
            ? 'Menetapkan budget bersama "$category" ($formattedNominal)'
            : 'Menetapkan budget "$category" ($formattedNominal)',
        referenceId: newBudget.id,
      );
    } catch (logError) {
      debugPrint('Warning recording finance budget gamification activity: $logError');
    }

    return newBudget;
  }

  /// Update an existing budget
  Future<FinanceBudgetModel> updateBudget(
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
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Pengguna belum login');

    final payload = <String, dynamic>{
      if (partnerId != null) 'partner_id': partnerId,
      'is_shared': isShared,
      'category': category.trim(),
      'amount': amount,
      'period_type': periodType,
      'start_date': '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'end_date': '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      'repeat_type': repeatType,
      'monthly_start_day': monthlyStartDay,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await _client
        .from('finance_budgets')
        .update(payload)
        .eq('id', budgetId)
        .select()
        .single();

    return FinanceBudgetModel.fromJson(response);
  }

  /// Update notification alert flags to avoid re-triggering notifications in same cycle
  Future<void> updateBudgetNotificationFlags(
    String budgetId, {
    bool? alert80,
    bool? alert100,
  }) async {
    final payload = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (alert80 != null) payload['alert_80_notified'] = alert80;
    if (alert100 != null) payload['alert_100_notified'] = alert100;

    await _client.from('finance_budgets').update(payload).eq('id', budgetId);
  }

  /// Delete a budget
  Future<void> deleteBudget(String budgetId) async {
    await _client.from('finance_budgets').delete().eq('id', budgetId);
  }
}
