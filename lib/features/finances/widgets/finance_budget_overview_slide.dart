import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/finance_budget_model.dart';
import '../providers/finance_provider.dart';
import 'bottom_sheets/add_budget_bottom_sheet.dart';

class FinanceBudgetOverviewSlide extends StatelessWidget {
  final List<FinanceBudgetProgress> progressList;
  final String? targetUserId;
  final String? partnerName;
  final bool isPartnerMode;

  const FinanceBudgetOverviewSlide({
    super.key,
    required this.progressList,
    this.targetUserId,
    this.partnerName,
    this.isPartnerMode = false,
  });

  void _openBudgetList(BuildContext context) {
    context.push(
      '/finance/budgets',
      extra: {
        'targetUserId': targetUserId,
        'partnerName': partnerName,
        'isPartnerMode': isPartnerMode,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasBudgets = progressList.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Target Budget',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (hasBudgets) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BBA7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${progressList.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00BBA7),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: () => _openBudgetList(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        isPartnerMode ? 'Lihat Semua' : 'Kelola',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284F6),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF0284F6),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!hasBudgets)
            _buildEmptyState(context)
          else
            _buildBudgetContent(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0284F6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              color: Color(0xFF0284F6),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPartnerMode
                ? 'Pasangan Belum Punya Budget'
                : 'Belum Ada Budget Aktif',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPartnerMode
                ? 'Pasangan belum membuat target budget pengeluaran.'
                : 'Tetapkan batas belanja agar keuangan terkontrol rapi.',
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
          if (!isPartnerMode) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6155F5), Color(0xFF0284F6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton.icon(
                onPressed: () => AddBudgetBottomSheet.show(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'Buat Budget Baru',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetContent(BuildContext context) {
    // Show top 3 budgets sorted by highest percentage used
    final sorted = List<FinanceBudgetProgress>.from(progressList)
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    final displayItems = sorted.take(3).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: displayItems.map((item) {
        final clampedProgress = (item.percentage / 100.0).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Category Title & Shared Badge
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: item.categoryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.budget.category,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.budget.isShared) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.favorite_rounded,
                            size: 11,
                            color: Color(0xFF0088FF),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Spent / Budget Amount & Health Badge
                  Row(
                    children: [
                      Text(
                        '${FinanceProvider.formatRupiah(item.spent)} / ${FinanceProvider.formatRupiah(item.budget.amount)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: item.healthColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: item.healthColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: clampedProgress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(item.healthColor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
