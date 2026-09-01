import 'package:flutter/foundation.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/activity_log_service.dart';
import '../models/transaction_model.dart';

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

  /// Fetch all personal and shared transactions
  Future<List<TransactionModel>> getTransactions({
    String? targetUserId,
    String? partnerId,
  }) async {
    final user = _client.auth.currentUser;
    final uid = targetUserId ?? user?.id;
    if (uid == null) return [];

    try {
      dynamic response;

      if (partnerId != null && partnerId.isNotEmpty) {
        // Query transactions created by user OR shared transactions created by partner
        response = await _client
            .from('transactions')
            .select()
            .or('user_id.eq.$uid,and(user_id.eq.$partnerId,is_shared.eq.true)')
            .order('transaction_date', ascending: false);
      } else {
        response = await _client
            .from('transactions')
            .select()
            .eq('user_id', uid)
            .order('transaction_date', ascending: false);
      }

      return (response as List)
          .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
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
      'is_shared': isShared,
      if (partnerId != null && isShared) 'partner_id': partnerId,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await _client
        .from('transactions')
        .insert(payload)
        .select()
        .single();

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
      'is_shared': isShared,
      'partner_id': isShared ? partnerId : null,
      'note': note?.trim(),
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
}
