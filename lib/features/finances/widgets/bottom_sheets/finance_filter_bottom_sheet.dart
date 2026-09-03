import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/finance_filter_model.dart';
import '../../providers/finance_provider.dart';

class FinanceFilterBottomSheet extends StatefulWidget {
  final FinanceFilterModel initialFilter;
  final ValueChanged<FinanceFilterModel> onApply;

  const FinanceFilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required FinanceFilterModel initialFilter,
    required ValueChanged<FinanceFilterModel> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => FinanceFilterBottomSheet(
        initialFilter: initialFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FinanceFilterBottomSheet> createState() =>
      _FinanceFilterBottomSheetState();
}

class _FinanceFilterBottomSheetState extends State<FinanceFilterBottomSheet> {
  late FinanceTypeFilter _selectedType;
  late FinancePeriodFilter _selectedPeriod;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String? _selectedCategory;
  late FinanceSortBy _selectedSortBy;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialFilter.type;
    _selectedPeriod = widget.initialFilter.period;
    _customStartDate = widget.initialFilter.customStartDate;
    _customEndDate = widget.initialFilter.customEndDate;
    _selectedCategory = widget.initialFilter.category;
    _selectedSortBy = widget.initialFilter.sortBy;
  }

  void _resetAll() {
    setState(() {
      _selectedType = FinanceTypeFilter.all;
      _selectedPeriod = FinancePeriodFilter.all;
      _customStartDate = null;
      _customEndDate = null;
      _selectedCategory = null;
      _selectedSortBy = FinanceSortBy.dateDesc;
    });
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF7A00),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = FinancePeriodFilter.custom;
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  void _applyFilter() {
    final newFilter = FinanceFilterModel(
      type: _selectedType,
      period: _selectedPeriod,
      customStartDate: _customStartDate,
      customEndDate: _customEndDate,
      category: _selectedCategory,
      sortBy: _selectedSortBy,
    );
    widget.onApply(newFilter);
    Navigator.of(context).pop();
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final categories = _selectedType == FinanceTypeFilter.income
        ? provider.allIncomeCategoryNames
        : _selectedType == FinanceTypeFilter.expense
            ? provider.allExpenseCategoryNames
            : provider.allCategories;

    final isFilterModified = _selectedType != FinanceTypeFilter.all ||
        _selectedPeriod != FinancePeriodFilter.all ||
        _selectedCategory != null ||
        _selectedSortBy != FinanceSortBy.dateDesc ||
        _customStartDate != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Handle Bar
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Header Row (Title & Reset)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Keuangan',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (isFilterModified)
                    InkWell(
                      onTap: _resetAll,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF5252),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),

              // 3. Scrollable Filter Content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // A. Tipe Transaksi
                      _buildSectionTitle('Tipe Transaksi'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildFilterChip(
                            label: 'Semua',
                            isSelected: _selectedType == FinanceTypeFilter.all,
                            onTap: () => setState(
                                () => _selectedType = FinanceTypeFilter.all),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Pemasukan 💵',
                            isSelected:
                                _selectedType == FinanceTypeFilter.income,
                            onTap: () => setState(
                                () => _selectedType = FinanceTypeFilter.income),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Pengeluaran 💳',
                            isSelected:
                                _selectedType == FinanceTypeFilter.expense,
                            onTap: () => setState(() =>
                                _selectedType = FinanceTypeFilter.expense),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // B. Periode Waktu
                      _buildSectionTitle('Periode Waktu'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip(
                            label: 'Semua Waktu',
                            isSelected:
                                _selectedPeriod == FinancePeriodFilter.all,
                            onTap: () => setState(() {
                              _selectedPeriod = FinancePeriodFilter.all;
                              _customStartDate = null;
                              _customEndDate = null;
                            }),
                          ),
                          _buildFilterChip(
                            label: 'Hari Ini',
                            isSelected:
                                _selectedPeriod == FinancePeriodFilter.today,
                            onTap: () => setState(() {
                              _selectedPeriod = FinancePeriodFilter.today;
                              _customStartDate = null;
                              _customEndDate = null;
                            }),
                          ),
                          _buildFilterChip(
                            label: 'Minggu Ini',
                            isSelected:
                                _selectedPeriod == FinancePeriodFilter.thisWeek,
                            onTap: () => setState(() {
                              _selectedPeriod = FinancePeriodFilter.thisWeek;
                              _customStartDate = null;
                              _customEndDate = null;
                            }),
                          ),
                          _buildFilterChip(
                            label: 'Bulan Ini',
                            isSelected: _selectedPeriod ==
                                FinancePeriodFilter.thisMonth,
                            onTap: () => setState(() {
                              _selectedPeriod = FinancePeriodFilter.thisMonth;
                              _customStartDate = null;
                              _customEndDate = null;
                            }),
                          ),
                          _buildFilterChip(
                            label: 'Bulan Lalu',
                            isSelected: _selectedPeriod ==
                                FinancePeriodFilter.lastMonth,
                            onTap: () => setState(() {
                              _selectedPeriod = FinancePeriodFilter.lastMonth;
                              _customStartDate = null;
                              _customEndDate = null;
                            }),
                          ),
                          _buildFilterChip(
                            label: _customStartDate != null &&
                                    _customEndDate != null
                                ? '${_formatDate(_customStartDate!)} - ${_formatDate(_customEndDate!)} 📅'
                                : 'Pilih Tanggal 📅',
                            isSelected:
                                _selectedPeriod == FinancePeriodFilter.custom,
                            onTap: _pickCustomDateRange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // C. Kategori
                      _buildSectionTitle('Kategori'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip(
                            label: 'Semua Kategori',
                            isSelected: _selectedCategory == null,
                            onTap: () =>
                                setState(() => _selectedCategory = null),
                          ),
                          ...categories.map((cat) {
                            return _buildFilterChip(
                              label: cat,
                              isSelected: _selectedCategory == cat,
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // D. Urutkan Berdasarkan (Sorting)
                      _buildSectionTitle('Urutkan Berdasarkan'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip(
                            label: 'Terbaru ⏱️',
                            isSelected:
                                _selectedSortBy == FinanceSortBy.dateDesc,
                            onTap: () => setState(
                                () => _selectedSortBy = FinanceSortBy.dateDesc),
                          ),
                          _buildFilterChip(
                            label: 'Terlama ⏳',
                            isSelected:
                                _selectedSortBy == FinanceSortBy.dateAsc,
                            onTap: () => setState(
                                () => _selectedSortBy = FinanceSortBy.dateAsc),
                          ),
                          _buildFilterChip(
                            label: 'Nominal Tertinggi 📈',
                            isSelected:
                                _selectedSortBy == FinanceSortBy.amountDesc,
                            onTap: () => setState(() =>
                                _selectedSortBy = FinanceSortBy.amountDesc),
                          ),
                          _buildFilterChip(
                            label: 'Nominal Terendah 📉',
                            isSelected:
                                _selectedSortBy == FinanceSortBy.amountAsc,
                            onTap: () => setState(() =>
                                _selectedSortBy = FinanceSortBy.amountAsc),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 4. Action Buttons (Terapkan Filter)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0088FF), Color(0xFF0775D5)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0088FF).withValues(alpha: 0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _applyFilter,
                          borderRadius: BorderRadius.circular(12),
                          child: const Center(
                            child: Text(
                              'Terapkan Filter',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF475569),
        letterSpacing: -0.1,
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF7A00).withValues(alpha: 0.12)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF7A00)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? const Color(0xFFFF7A00)
                : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
