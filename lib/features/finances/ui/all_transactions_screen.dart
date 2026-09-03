import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/finance_filter_model.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../widgets/transaction_card.dart';
import '../widgets/bottom_sheets/finance_filter_bottom_sheet.dart';
import '../widgets/bottom_sheets/transaction_detail_bottom_sheet.dart';

class AllTransactionsScreen extends StatefulWidget {
  final String? targetUserId;
  final String? partnerName;
  final bool isPartnerMode;

  const AllTransactionsScreen({
    super.key,
    this.targetUserId,
    this.partnerName,
    this.isPartnerMode = false,
  });

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  FinanceFilterModel _currentFilter = const FinanceFilterModel();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      final auth = context.read<AuthProvider>();
      final uid = widget.targetUserId ?? auth.currentUserProfile?.id;
      context.read<FinanceProvider>().fetchMoreTransactions(
            targetUserId: uid,
            filter: _currentFilter,
          );
    }
  }

  Future<void> _loadInitialData() async {
    final auth = context.read<AuthProvider>();
    final uid = widget.targetUserId ?? auth.currentUserProfile?.id;
    await context.read<FinanceProvider>().fetchInitialPagedTransactions(
          targetUserId: uid,
          filter: _currentFilter,
        );
  }

  void _onFilterChanged(FinanceFilterModel newFilter) {
    setState(() {
      _currentFilter = newFilter;
    });
    final auth = context.read<AuthProvider>();
    final uid = widget.targetUserId ?? auth.currentUserProfile?.id;
    context.read<FinanceProvider>().fetchInitialPagedTransactions(
          targetUserId: uid,
          filter: newFilter,
        );
  }

  void _openFilterBottomSheet() {
    FinanceFilterBottomSheet.show(
      context,
      initialFilter: _currentFilter,
      onApply: (newFilter) {
        _onFilterChanged(newFilter);
      },
    );
  }

  List<TransactionModel> _filterAndSearchItems(List<TransactionModel> items) {
    // 1. Apply Finance Filters (Type, Period, Category, Sort)
    var result = _currentFilter.apply(items);

    // 2. Apply Text Search
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((t) {
        final titleMatch = t.title.toLowerCase().contains(query);
        final catMatch = t.category.toLowerCase().contains(query);
        final amountMatch = t.amount.toString().contains(query) ||
            FinanceProvider.formatRupiah(t.amount)
                .toLowerCase()
                .contains(query);
        return titleMatch || catMatch || amountMatch;
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final myUid = auth.currentUserProfile?.id;
    final isPartner = widget.isPartnerMode ||
        (widget.targetUserId != null && widget.targetUserId != myUid);

    final screenTitle = isPartner
        ? (widget.partnerName != null
            ? 'Semua Transaksi (${widget.partnerName})'
            : 'Semua Transaksi Pasangan')
        : 'Semua Transaksi';

    final provider = context.watch<FinanceProvider>();
    final filteredItems = _filterAndSearchItems(provider.pagedTransactions);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Standard Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
                      screenTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Filter Button with Active Badge
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _currentFilter.isActive
                              ? Icons.tune_rounded
                              : Icons.tune_outlined,
                          color: _currentFilter.isActive
                              ? const Color(0xFFFF7A00)
                              : const Color(0xFF1E293B),
                          size: 22,
                        ),
                        onPressed: _openFilterBottomSheet,
                      ),
                      if (_currentFilter.isActive)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF7A00),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Permanent Search Bar (48px)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari transaksi atau kategori...',
                    hintStyle: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // 3. Active Filter Badges Row (if filter is active)
            if (_currentFilter.isActive)
              Container(
                height: 38,
                margin: const EdgeInsets.only(top: 4, bottom: 4),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (_currentFilter.type != FinanceTypeFilter.all)
                      _buildActiveFilterTag(
                        _currentFilter.type == FinanceTypeFilter.income
                            ? 'Pemasukan 💵'
                            : 'Pengeluaran 💳',
                        () => _onFilterChanged(_currentFilter.copyWith(
                            type: FinanceTypeFilter.all)),
                      ),
                    if (_currentFilter.period != FinancePeriodFilter.all)
                      _buildActiveFilterTag(
                        _getPeriodLabel(_currentFilter.period),
                        () => _onFilterChanged(_currentFilter.copyWith(
                            period: FinancePeriodFilter.all,
                            customStartDate: null,
                            customEndDate: null)),
                      ),
                    if (_currentFilter.category != null)
                      _buildActiveFilterTag(
                        _currentFilter.category!,
                        () => _onFilterChanged(
                            _currentFilter.copyWith(clearCategory: true)),
                      ),
                    if (_currentFilter.sortBy != FinanceSortBy.dateDesc)
                      _buildActiveFilterTag(
                        _getSortLabel(_currentFilter.sortBy),
                        () => _onFilterChanged(_currentFilter.copyWith(
                            sortBy: FinanceSortBy.dateDesc)),
                      ),
                    InkWell(
                      onTap: () => _onFilterChanged(const FinanceFilterModel()),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECEB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Reset Semua ✕',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF3B30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 4. Content List with Infinite Scroll Pagination
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadInitialData,
                color: const Color(0xFFFF7A00),
                child: provider.isLoadingPaged &&
                        provider.pagedTransactions.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFFFF7A00),
                        ),
                      )
                    : filteredItems.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: filteredItems.length +
                                (provider.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == filteredItems.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Color(0xFFFF7A00),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final item = filteredItems[index];
                              return TransactionCard(
                                transaction: item,
                                isBalanceVisible: provider.isBalanceVisible,
                                onTap: () {
                                  TransactionDetailBottomSheet.show(
                                    context,
                                    transaction: item,
                                    isReadOnly: isPartner,
                                  );
                                },
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterTag(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7A00).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF7A00).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF7A00),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: Color(0xFFFF7A00),
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(FinancePeriodFilter period) {
    switch (period) {
      case FinancePeriodFilter.today:
        return 'Hari Ini';
      case FinancePeriodFilter.thisWeek:
        return 'Minggu Ini';
      case FinancePeriodFilter.thisMonth:
        return 'Bulan Ini';
      case FinancePeriodFilter.lastMonth:
        return 'Bulan Lalu';
      case FinancePeriodFilter.custom:
        return 'Custom Tanggal';
      case FinancePeriodFilter.all:
        return 'Semua Waktu';
    }
  }

  String _getSortLabel(FinanceSortBy sort) {
    switch (sort) {
      case FinanceSortBy.dateAsc:
        return 'Terlama ⏳';
      case FinanceSortBy.amountDesc:
        return 'Nominal Tertinggi 📈';
      case FinanceSortBy.amountAsc:
        return 'Nominal Terendah 📉';
      case FinanceSortBy.dateDesc:
        return 'Terbaru ⏱️';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: Color(0xFFFF7A00),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Transaksi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tidak ditemukan transaksi yang cocok dengan kata kunci atau filter yang Anda pilih.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
            if (_currentFilter.isActive ||
                _searchController.text.isNotEmpty) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _currentFilter = const FinanceFilterModel());
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF7A00)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Reset Pencarian & Filter',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF7A00),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
