import 'package:flutter/material.dart';
import '../providers/finance_provider.dart';

class FinanceSummaryRow extends StatelessWidget {
  final double income;
  final double expense;
  final bool isBalanceVisible;
  final VoidCallback? onIncomeTap;
  final VoidCallback? onExpenseTap;

  const FinanceSummaryRow({
    super.key,
    required this.income,
    required this.expense,
    this.isBalanceVisible = true,
    this.onIncomeTap,
    this.onExpenseTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedIncome = FinanceProvider.formatRupiah(income);
    final formattedExpense = FinanceProvider.formatRupiah(expense);

    return Row(
      children: [
        // 1. Pemasukan Card
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.arrow_downward_rounded,
            iconColor: const Color(0xFF00BBA7),
            iconBgColor: const Color(0xFFE0F7F6),
            label: 'Pemasukan',
            nominal: isBalanceVisible ? formattedIncome : '••••••••',
            onTap: onIncomeTap,
          ),
        ),
        const SizedBox(width: 14),

        // 2. Pengeluaran Card
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.arrow_upward_rounded,
            iconColor: const Color(0xFFFF5252),
            iconBgColor: const Color(0xFFFFECEB),
            label: 'Pengeluaran',
            nominal: isBalanceVisible ? formattedExpense : '••••••••',
            onTap: onExpenseTap,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String nominal,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: iconColor.withValues(alpha: 0.08),
          highlightColor: iconColor.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon Circle + Subtle Chevron Affordance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 18,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: onTap != null
                          ? const Color(0xFF94A3B8)
                          : Colors.transparent,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Label
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),

                // Nominal
                Text(
                  nominal,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
