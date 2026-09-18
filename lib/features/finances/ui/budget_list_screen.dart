import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/finance_budget_model.dart';
import '../providers/finance_provider.dart';
import '../widgets/bottom_sheets/add_budget_bottom_sheet.dart';
import '../widgets/finance_balance_card.dart';

class BudgetListScreen extends StatefulWidget {
  final String? targetUserId;
  final String? partnerName;
  final bool isPartnerMode;

  const BudgetListScreen({
    super.key,
    this.targetUserId,
    this.partnerName,
    this.isPartnerMode = false,
  });

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'monthly', 'weekly', 'daily', 'shared'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBudgets();
    });
  }

  void _loadBudgets() {
    final auth = context.read<AuthProvider>();
    final uid = widget.targetUserId ?? auth.currentUserProfile?.id;
    final partnerId = auth.currentUserProfile?.partnerId;

    context.read<FinanceProvider>().fetchBudgets(
          targetUserId: uid,
          partnerId: partnerId,
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FinanceBudgetProgress> _filterItems(
      List<FinanceBudgetProgress> progressList) {
    final query = _searchController.text.trim().toLowerCase();

    return progressList.where((item) {
      // Search query filter
      if (query.isNotEmpty) {
        final matches = item.budget.category.toLowerCase().contains(query);
        if (!matches) return false;
      }

      // Period / Shared chip filter
      if (_selectedFilter == 'monthly') {
        return item.budget.periodType == 'monthly';
      } else if (_selectedFilter == 'weekly') {
        return item.budget.periodType == 'weekly';
      } else if (_selectedFilter == 'daily') {
        return item.budget.periodType == 'daily';
      } else if (_selectedFilter == 'shared') {
        return item.budget.isShared;
      }
      return true;
    }).toList();
  }

  void _confirmDelete(FinanceBudgetModel budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hapus Budget?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus budget untuk "${budget.category}"?',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<FinanceProvider>();
              final success = await provider.removeBudget(budget.id);
              if (!mounted) return;
              if (success) {
                AppSnackBar.success(context, 'Budget berhasil dihapus');
              } else {
                AppSnackBar.error(
                    context, provider.errorMessage ?? 'Gagal menghapus');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final myUid = auth.currentUserProfile?.id;
    final provider = context.watch<FinanceProvider>();

    final allProgress = provider.getBudgetProgressList(currentUserId: myUid);
    final filtered = _filterItems(allProgress);

    // Aggregate summary
    double totalBudget = 0.0;
    double totalSpent = 0.0;
    for (final item in allProgress) {
      totalBudget += item.budget.amount;
      totalSpent += item.spent;
    }
    final totalRemaining = totalBudget - totalSpent;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Unified Standard Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              color: const Color(0xFFFCFCFD),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF1E293B),
                      size: 22,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.isPartnerMode
                          ? (widget.partnerName != null
                              ? 'Budget ${widget.partnerName}'
                              : 'Budget Pasangan')
                          : 'Budget & Anggaran',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isPartnerMode)
                    const SizedBox(width: 48)
                  else
                    IconButton(
                      icon: const Icon(
                        Icons.add_rounded,
                        color: AppColors.gradientBlueEnd,
                        size: 26,
                      ),
                      onPressed: () => AddBudgetBottomSheet.show(context),
                    ),
                ],
              ),
            ),

            // 2. Permanent Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFE2E8F0), width: 1.1),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'Cari kategori budget...',
                    hintStyle:
                        const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF94A3B8), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Color(0xFF94A3B8), size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // 3. Filter Chips Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('Semua', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Bulanan', 'monthly'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Mingguan', 'weekly'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Harian', 'daily'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Bersama Pasangan', 'shared'),
                ],
              ),
            ),

            // 4. Scrollable List Body
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _loadBudgets(),
                color: AppColors.gradientBlueEnd,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  children: [
                    // Summary Banner Card
                    if (allProgress.isNotEmpty)
                      _buildSummaryBanner(
                        totalBudget: totalBudget,
                        totalRemaining: totalRemaining,
                        isBalanceVisible: provider.isBalanceVisible,
                        onToggleVisibility: () =>
                            provider.toggleBalanceVisibility(),
                      ),
                    if (allProgress.isNotEmpty) const SizedBox(height: 16),

                    // Budget Cards
                    if (filtered.isEmpty)
                      _buildEmptyState()
                    else
                      ...filtered.map((item) => _buildBudgetCard(item)),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBanner({
    required double totalBudget,
    required double totalRemaining,
    required bool isBalanceVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return FinanceBalanceCard(
      title: 'Total Alokasi Budget',
      totalBalance: totalBudget,
      netSavings: totalRemaining,
      isBalanceVisible: isBalanceVisible,
      onToggleVisibility: onToggleVisibility,
      subtitleLabel: 'Sisa budget',
      showPlusSign: false,
    );
  }

  Widget _buildBudgetCard(FinanceBudgetProgress item) {
    final clamped = (item.percentage / 100.0).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Category Name + Badges + Popup Menu
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.budget.category,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.budget.isShared) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0088FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite_rounded,
                                size: 10, color: Color(0xFF0088FF)),
                            SizedBox(width: 3),
                            Text(
                              'Bersama',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0088FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Health Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.healthColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.healthStatusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: item.healthColor,
                  ),
                ),
              ),

              // Action Options Popup Menu (Only for own items)
              if (!widget.isPartnerMode)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 18, color: Color(0xFF94A3B8)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      AddBudgetBottomSheet.show(context,
                          budgetToEdit: item.budget);
                    } else if (val == 'delete') {
                      _confirmDelete(item.budget);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded,
                              size: 16, color: Color(0xFF334155)),
                          SizedBox(width: 10),
                          Text('Ubah', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 16, color: Color(0xFFFF4B4B)),
                          SizedBox(width: 10),
                          Text('Hapus',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFFFF4B4B))),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Spent vs Target Amount + Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: FinanceProvider.formatRupiah(item.spent),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: item.isOverBudget
                            ? const Color(0xFFFF4B4B)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    TextSpan(
                      text:
                          ' / ${FinanceProvider.formatRupiah(item.budget.amount)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${item.percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: item.healthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 7.5,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(item.healthColor),
            ),
          ),
          const SizedBox(height: 10),

          // Row 3: Daily Safe-to-Spend & Cycle Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        size: 13, color: Color(0xFFFF7A00)),
                    const SizedBox(width: 4),
                    Text(
                      item.isOverBudget
                          ? 'Melebihi budget ${FinanceProvider.formatRupiah((item.spent - item.budget.amount))}'
                          : 'Sisa aman: ${FinanceProvider.formatRupiah(item.dailySafeToSpend)} / hari',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: item.isOverBudget
                            ? const Color(0xFFFF4B4B)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${item.remainingDays} hari lagi',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.gradientBiru : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.1,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gradientBlueStart.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.gradientBlueEnd.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              color: AppColors.gradientBlueEnd,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.isPartnerMode
                ? 'Pasangan belum membuat budget'
                : 'Tidak ada budget ditemukan',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isPartnerMode
                ? 'Daftar alokasi budget pasangan akan muncul di sini jika sudah dibuat.'
                : (_searchController.text.isNotEmpty
                    ? 'Coba gunakan kata kunci pencarian yang lain.'
                    : 'Buat budget baru untuk mengatur target pengeluaran Anda.'),
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
          if (!widget.isPartnerMode && _searchController.text.isEmpty) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.gradientBiru,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gradientBlueStart.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => AddBudgetBottomSheet.show(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Buat Budget Baru',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
