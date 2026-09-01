import 'package:flutter/material.dart';

class FinanceCategoryModel {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final Color color;
  final IconData? icon;

  const FinanceCategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    this.icon,
  });

  /// Default categories for Income
  static const List<FinanceCategoryModel> defaultIncomeCategories = [
    FinanceCategoryModel(
      id: 'gaji',
      name: 'Gaji',
      type: 'income',
      color: Color(0xFF00BBA7), // Mint/Cyan
      icon: Icons.payments_rounded,
    ),
    FinanceCategoryModel(
      id: 'bonus',
      name: 'Bonus',
      type: 'income',
      color: Color(0xFF10B981), // Emerald Green
      icon: Icons.card_giftcard_rounded,
    ),
    FinanceCategoryModel(
      id: 'investasi',
      name: 'Investasi',
      type: 'income',
      color: Color(0xFF0088FF), // Blue
      icon: Icons.trending_up_rounded,
    ),
    FinanceCategoryModel(
      id: 'hadiah',
      name: 'Hadiah',
      type: 'income',
      color: Color(0xFFFFB800), // Amber
      icon: Icons.redeem_rounded,
    ),
    FinanceCategoryModel(
      id: 'lainnya_income',
      name: 'Lain-lain',
      type: 'income',
      color: Color(0xFF8B5CF6), // Purple
      icon: Icons.more_horiz_rounded,
    ),
  ];

  /// Default categories for Expense
  static const List<FinanceCategoryModel> defaultExpenseCategories = [
    FinanceCategoryModel(
      id: 'makan_minum',
      name: 'Makan dan Minum',
      type: 'expense',
      color: Color(0xFFFF4B4B), // Vibrant Coral Red
      icon: Icons.restaurant_rounded,
    ),
    FinanceCategoryModel(
      id: 'belanja',
      name: 'Belanja',
      type: 'expense',
      color: Color(0xFFFF8A00), // Pastel Orange
      icon: Icons.shopping_bag_rounded,
    ),
    FinanceCategoryModel(
      id: 'skincare',
      name: 'Skincare',
      type: 'expense',
      color: Color(0xFFFFC107), // Gold/Yellow
      icon: Icons.face_retouching_natural_rounded,
    ),
    FinanceCategoryModel(
      id: 'transportasi',
      name: 'Transportasi',
      type: 'expense',
      color: Color(0xFF10B981), // Green
      icon: Icons.directions_car_rounded,
    ),
    FinanceCategoryModel(
      id: 'kesehatan',
      name: 'Kesehatan',
      type: 'expense',
      color: Color(0xFF0088FF), // Pastel Blue
      icon: Icons.local_hospital_rounded,
    ),
    FinanceCategoryModel(
      id: 'kos_tagihan',
      name: 'Kos',
      type: 'expense',
      color: Color(0xFF8B5CF6), // Purple
      icon: Icons.home_rounded,
    ),
    FinanceCategoryModel(
      id: 'hiburan',
      name: 'Hiburan',
      type: 'expense',
      color: Color(0xFFEC4899), // Pink
      icon: Icons.sports_esports_rounded,
    ),
    FinanceCategoryModel(
      id: 'lainnya_expense',
      name: 'Lain-lain',
      type: 'expense',
      color: Color(0xFF00BBA7), // Teal
      icon: Icons.more_horiz_rounded,
    ),
  ];

  /// Color palette generator for custom categories
  static Color getColorForCategory(String name, {bool isExpense = true}) {
    final lower = name.toLowerCase().trim();
    if (lower.contains('makan') || lower.contains('minum') || lower.contains('food')) {
      return const Color(0xFFFF4B4B);
    }
    if (lower.contains('belanja') || lower.contains('shop')) {
      return const Color(0xFFFF8A00);
    }
    if (lower.contains('skin') || lower.contains('make') || lower.contains('beauty')) {
      return const Color(0xFFFFC107);
    }
    if (lower.contains('trans') || lower.contains('bensin') || lower.contains('ojol')) {
      return const Color(0xFF10B981);
    }
    if (lower.contains('sehat') || lower.contains('obat') || lower.contains('dokter')) {
      return const Color(0xFF0088FF);
    }
    if (lower.contains('kos') || lower.contains('sewa') || lower.contains('listrik')) {
      return const Color(0xFF8B5CF6);
    }
    if (lower.contains('hiburan') || lower.contains('jalan') || lower.contains('nonton')) {
      return const Color(0xFFEC4899);
    }
    if (lower.contains('gaji') || lower.contains('salary')) {
      return const Color(0xFF00BBA7);
    }

    // Dynamic hash color based on category name string
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    const colors = [
      Color(0xFFFF4B4B),
      Color(0xFFFF8A00),
      Color(0xFFFFC107),
      Color(0xFF10B981),
      Color(0xFF00BBA7),
      Color(0xFF0088FF),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF64748B),
    ];
    return colors[hash % colors.length];
  }
}
