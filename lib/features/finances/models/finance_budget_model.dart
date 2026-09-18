import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'transaction_model.dart';
import 'finance_category_model.dart';

enum BudgetHealthStatus {
  normal, // < 80%
  warning, // 80% - 100%
  over, // > 100%
}

class FinanceBudgetModel {
  static const String allCategoriesKey = 'Semua Pengeluaran';

  final String id;
  final String userId;
  final String? partnerId;
  final bool isShared;
  final String category;
  final double amount;
  final String periodType; // 'daily', 'weekly', 'monthly', 'custom'
  final DateTime startDate;
  final DateTime endDate;
  final String repeatType; // 'auto_renew', 'none'
  final int monthlyStartDay; // 1 - 31 (default: 1)
  final bool alert80Notified;
  final bool alert100Notified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FinanceBudgetModel({
    required this.id,
    required this.userId,
    this.partnerId,
    this.isShared = false,
    required this.category,
    required this.amount,
    this.periodType = 'monthly',
    required this.startDate,
    required this.endDate,
    this.repeatType = 'auto_renew',
    this.monthlyStartDay = 1,
    this.alert80Notified = false,
    this.alert100Notified = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isAutoRenew => repeatType == 'auto_renew';
  bool get isAllCategories =>
      category == allCategoriesKey || category.toUpperCase() == 'ALL';

  /// Check if a transaction category belongs to this budget
  bool matchesCategory(String transactionCategory) {
    if (isAllCategories) return true;
    return category.trim().toLowerCase() ==
        transactionCategory.trim().toLowerCase();
  }

  /// Calculates the spent amount, remaining amount, and health status for a given transaction list
  FinanceBudgetProgress calculateProgress(
    List<TransactionModel> transactions, {
    String? currentUserId,
  }) {
    double spent = 0.0;
    final startUtc = DateTime.utc(
        startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final endUtc = DateTime.utc(
        endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

    for (final t in transactions) {
      if (!t.isExpense) continue;

      final tDate = t.transactionDate.toUtc();
      if (tDate.isBefore(startUtc) || tDate.isAfter(endUtc)) continue;

      if (!matchesCategory(t.category)) continue;

      // Ownership filter
      if (isShared) {
        // In shared mode: count if transaction is marked shared, or from user/partner
        final isOwner = t.userId == userId ||
            (partnerId != null && t.userId == partnerId) ||
            (currentUserId != null && t.userId == currentUserId);
        if (isOwner) {
          spent += t.amount;
        }
      } else {
        // Personal budget: only count owner's transactions
        if (t.userId == userId || (currentUserId != null && t.userId == currentUserId)) {
          spent += t.amount;
        }
      }
    }

    final double remaining = math.max(0.0, amount - spent);
    final double percentage = amount > 0 ? (spent / amount) * 100 : 0.0;

    BudgetHealthStatus status;
    if (spent > amount) {
      status = BudgetHealthStatus.over;
    } else if (percentage >= 80.0) {
      status = BudgetHealthStatus.warning;
    } else {
      status = BudgetHealthStatus.normal;
    }

    // Daily safe to spend calculation
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetEnd = DateTime(endDate.year, endDate.month, endDate.day);
    final remainingDays = math.max(1, targetEnd.difference(today).inDays + 1);
    final dailySafe = remaining / remainingDays;

    return FinanceBudgetProgress(
      budget: this,
      spent: spent,
      remaining: remaining,
      percentage: percentage,
      status: status,
      remainingDays: remainingDays,
      dailySafeToSpend: dailySafe,
    );
  }

  /// Evaluates whether the current active date range is expired.
  /// If expired and repeatType == 'auto_renew', computes a new rollover range.
  FinanceBudgetModel checkAndRollover() {
    if (!isAutoRenew) return this;

    final now = DateTime.now();
    final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // If current time is still within the period, keep as is
    if (!now.isAfter(endOfDay)) return this;

    // Rollover needed: compute new start & end based on periodType
    DateTime newStart;
    DateTime newEnd;

    switch (periodType) {
      case 'daily':
        newStart = DateTime(now.year, now.month, now.day);
        newEnd = DateTime(now.year, now.month, now.day);
        break;

      case 'weekly':
        final weekday = now.weekday; // 1 = Monday
        newStart = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekday - 1));
        newEnd = newStart.add(const Duration(days: 6));
        break;

      case 'monthly':
      default:
        final clampedStartDay = monthlyStartDay.clamp(1, 28);
        if (now.day >= clampedStartDay) {
          newStart = DateTime(now.year, now.month, clampedStartDay);
          final nextMonth = DateTime(now.year, now.month + 1, 1);
          final daysInNext = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
          final nextDay = clampedStartDay.clamp(1, daysInNext);
          newEnd = DateTime(nextMonth.year, nextMonth.month, nextDay)
              .subtract(const Duration(days: 1));
        } else {
          final prevMonth = DateTime(now.year, now.month - 1, 1);
          final daysInPrev = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;
          final prevDay = clampedStartDay.clamp(1, daysInPrev);
          newStart = DateTime(prevMonth.year, prevMonth.month, prevDay);
          newEnd = DateTime(now.year, now.month, clampedStartDay)
              .subtract(const Duration(days: 1));
        }
        break;
    }

    return copyWith(
      startDate: newStart,
      endDate: newEnd,
      alert80Notified: false,
      alert100Notified: false,
    );
  }

  factory FinanceBudgetModel.fromJson(Map<String, dynamic> json) {
    return FinanceBudgetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      partnerId: json['partner_id'] as String?,
      isShared: json['is_shared'] as bool? ?? false,
      category: json['category'] as String? ?? allCategoriesKey,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      periodType: json['period_type'] as String? ?? 'monthly',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : DateTime.now().add(const Duration(days: 30)),
      repeatType: json['repeat_type'] as String? ?? 'auto_renew',
      monthlyStartDay: json['monthly_start_day'] as int? ?? 1,
      alert80Notified: json['alert_80_notified'] as bool? ?? false,
      alert100Notified: json['alert_100_notified'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (partnerId != null) 'partner_id': partnerId,
      'is_shared': isShared,
      'category': category,
      'amount': amount,
      'period_type': periodType,
      'start_date':
          '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'end_date':
          '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      'repeat_type': repeatType,
      'monthly_start_day': monthlyStartDay,
      'alert_80_notified': alert80Notified,
      'alert_100_notified': alert100Notified,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  FinanceBudgetModel copyWith({
    String? id,
    String? userId,
    String? partnerId,
    bool? isShared,
    String? category,
    double? amount,
    String? periodType,
    DateTime? startDate,
    DateTime? endDate,
    String? repeatType,
    int? monthlyStartDay,
    bool? alert80Notified,
    bool? alert100Notified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinanceBudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      partnerId: partnerId ?? this.partnerId,
      isShared: isShared ?? this.isShared,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      repeatType: repeatType ?? this.repeatType,
      monthlyStartDay: monthlyStartDay ?? this.monthlyStartDay,
      alert80Notified: alert80Notified ?? this.alert80Notified,
      alert100Notified: alert100Notified ?? this.alert100Notified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Represents the calculated metrics and state of a budget
class FinanceBudgetProgress {
  final FinanceBudgetModel budget;
  final double spent;
  final double remaining;
  final double percentage; // e.g. 75.4
  final BudgetHealthStatus status;
  final int remainingDays;
  final double dailySafeToSpend;

  const FinanceBudgetProgress({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.status,
    required this.remainingDays,
    required this.dailySafeToSpend,
  });

  bool get isOverBudget => status == BudgetHealthStatus.over;
  bool get isNearLimit => status == BudgetHealthStatus.warning;

  Color get healthColor {
    switch (status) {
      case BudgetHealthStatus.over:
        return const Color(0xFFFF4B4B); // Coral Red
      case BudgetHealthStatus.warning:
        return const Color(0xFFFF8A00); // Pastel Orange
      case BudgetHealthStatus.normal:
        return const Color(0xFF00BBA7); // Mint / Teal
    }
  }

  String get healthStatusLabel {
    switch (status) {
      case BudgetHealthStatus.over:
        return 'Overbudget';
      case BudgetHealthStatus.warning:
        return 'Waspada (80%+)';
      case BudgetHealthStatus.normal:
        return 'Aman';
    }
  }

  Color get categoryColor {
    if (budget.isAllCategories) {
      return const Color(0xFF6B4454); // Deep Maroon accent
    }
    return FinanceCategoryModel.getColorForCategory(budget.category);
  }
}
