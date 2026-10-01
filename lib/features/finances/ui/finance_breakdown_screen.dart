import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/transaction_model.dart';
import '../models/finance_category_model.dart';
import '../providers/finance_provider.dart';
import '../widgets/bottom_sheets/add_transaction_bottom_sheet.dart';
import '../widgets/bottom_sheets/transaction_detail_bottom_sheet.dart';

class FinanceBreakdownScreen extends StatefulWidget {
  final String? targetUserId;
  final String? partnerName;
  final bool isPartnerMode;
  final String initialType; // 'expense' or 'income'

  const FinanceBreakdownScreen({
    super.key,
    this.targetUserId,
    this.partnerName,
    this.isPartnerMode = false,
    this.initialType = 'expense',
  });

  @override
  State<FinanceBreakdownScreen> createState() => _FinanceBreakdownScreenState();
}

class _CategoryGroupData {
  final String name;
  final double totalAmount;
  final double percentage; // 0 - 100
  final Color color;
  final IconData icon;
  final List<TransactionModel> transactions;

  const _CategoryGroupData({
    required this.name,
    required this.totalAmount,
    required this.percentage,
    required this.color,
    required this.icon,
    required this.transactions,
  });
}

class _FinanceBreakdownScreenState extends State<FinanceBreakdownScreen> {
  late String _selectedType; // 'expense' or 'income'

  // Date filtering state
  late int _selectedYear;
  late int _selectedMonth;
  int? _customStartDay;
  bool _isDateInitialized = false;
  bool _isCustomRange = false;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Accordion state (set of expanded category names)
  final Set<String> _expandedCategories = {};

  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

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

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDateInitialized) {
      _isDateInitialized = true;
      _initDefaultDateRange();
    }
  }

  void _initDefaultDateRange() {
    final auth = context.read<AuthProvider>();
    final uid = widget.targetUserId ?? auth.currentUserProfile?.id;
    final provider = context.read<FinanceProvider>();
    _customStartDay = provider.getStartDayForUser(targetUserId: uid);

    final now = DateTime.now();
    if (_customStartDay != null) {
      final clampedDay = _customStartDay!.clamp(1, 28);
      int year = now.year;
      int month = now.month;
      if (now.day < clampedDay) {
        if (month == 1) {
          month = 12;
          year -= 1;
        } else {
          month -= 1;
        }
      }
      _selectedYear = year;
      _selectedMonth = month;
    } else {
      _selectedYear = now.year;
      _selectedMonth = now.month;
    }
  }

  (DateTime, DateTime) _getCycleDates(int year, int month, int startDay) {
    final clampedDay = startDay.clamp(1, 28);
    final start = DateTime(year, month, clampedDay);
    final nextMonth = DateTime(year, month + 1, 1);
    final daysInNext = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    final nextDay = clampedDay.clamp(1, daysInNext);
    final end =
        DateTime(nextMonth.year, nextMonth.month, nextDay, 23, 59, 59, 999)
            .subtract(const Duration(days: 1));
    return (start, end);
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    final uid = widget.targetUserId ?? auth.currentUserProfile?.id;
    context.read<FinanceProvider>().fetchTransactions(targetUserId: uid);
  }

  DateTime get _activeStartDate {
    if (_isCustomRange && _customStartDate != null) {
      return DateTime(
        _customStartDate!.year,
        _customStartDate!.month,
        _customStartDate!.day,
      );
    }
    if (_customStartDay != null) {
      return _getCycleDates(_selectedYear, _selectedMonth, _customStartDay!).$1;
    }
    return DateTime(_selectedYear, _selectedMonth, 1);
  }

  DateTime get _activeEndDate {
    if (_isCustomRange && _customEndDate != null) {
      return DateTime(
        _customEndDate!.year,
        _customEndDate!.month,
        _customEndDate!.day,
        23,
        59,
        59,
        999,
      );
    }
    if (_customStartDay != null) {
      return _getCycleDates(_selectedYear, _selectedMonth, _customStartDay!).$2;
    }
    // Last day of _selectedMonth
    return DateTime(_selectedYear, _selectedMonth + 1, 0, 23, 59, 59, 999);
  }

  void _goToPreviousMonth() {
    setState(() {
      _isCustomRange = false;
      _customStartDate = null;
      _customEndDate = null;
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear -= 1;
      } else {
        _selectedMonth -= 1;
      }
    });
  }

  void _goToNextMonth() {
    setState(() {
      _isCustomRange = false;
      _customStartDate = null;
      _customEndDate = null;
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear += 1;
      } else {
        _selectedMonth += 1;
      }
    });
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final cleanStart = DateTime(
        _activeStartDate.year, _activeStartDate.month, _activeStartDate.day);
    final cleanEnd =
        DateTime(_activeEndDate.year, _activeEndDate.month, _activeEndDate.day);
    final initialRange = cleanEnd.isBefore(cleanStart)
        ? DateTimeRange(start: cleanStart, end: cleanStart)
        : DateTimeRange(start: cleanStart, end: cleanEnd);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: initialRange,
      helpText: 'Pilih Rentang Periode',
      saveText: 'Terapkan',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: const Color(0xFFFF7A00),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: const Color(0xFF1E293B),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _isCustomRange = true;
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  void _resetToDefaultPeriod() {
    final now = DateTime.now();
    setState(() {
      _isCustomRange = false;
      _customStartDate = null;
      _customEndDate = null;
      if (_customStartDay != null) {
        final clampedDay = _customStartDay!.clamp(1, 28);
        int year = now.year;
        int month = now.month;
        if (now.day < clampedDay) {
          if (month == 1) {
            month = 12;
            year -= 1;
          } else {
            month -= 1;
          }
        }
        _selectedYear = year;
        _selectedMonth = month;
      } else {
        _selectedYear = now.year;
        _selectedMonth = now.month;
      }
    });
  }

  void _toggleCategory(String catName) {
    setState(() {
      if (_expandedCategories.contains(catName)) {
        _expandedCategories.remove(catName);
      } else {
        _expandedCategories.add(catName);
      }
    });
  }

  void _toggleAllCategories(List<_CategoryGroupData> groups) {
    setState(() {
      if (_expandedCategories.length == groups.length) {
        _expandedCategories.clear();
      } else {
        _expandedCategories.clear();
        for (final g in groups) {
          _expandedCategories.add(g.name);
        }
      }
    });
  }

  String _formatDateShort(DateTime dt) {
    return '${dt.day} ${_shortMonths[dt.month - 1]} ${dt.year}';
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${_shortMonths[dt.month - 1]} ${dt.year} • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final myUid = auth.currentUserProfile?.id;
    final isPartner = widget.isPartnerMode ||
        (widget.targetUserId != null && widget.targetUserId != myUid);

    final isExpense = _selectedType == 'expense';
    final themeColor =
        isExpense ? const Color(0xFFFF4B4B) : const Color(0xFF00BBA7);
    final themeBgColor =
        isExpense ? const Color(0xFFFFECEB) : const Color(0xFFE0F7F6);

    final screenTitle = isPartner
        ? (widget.partnerName != null
            ? 'Rincian ${isExpense ? 'Pengeluaran' : 'Pemasukan'} (${widget.partnerName})'
            : 'Rincian ${isExpense ? 'Pengeluaran' : 'Pemasukan'} Pasangan')
        : 'Rincian ${isExpense ? 'Pengeluaran' : 'Pemasukan'}';

    final provider = context.watch<FinanceProvider>();
    final allTransactions = provider.transactions;

    // Filter transactions by type & date range
    final start = _activeStartDate;
    final end = _activeEndDate;
    final filteredTransactions = allTransactions.where((t) {
      final matchesType = isExpense ? t.isExpense : t.isIncome;
      if (!matchesType) return false;
      final tDate = t.transactionDate.toLocal();
      return !tDate.isBefore(start) && !tDate.isAfter(end);
    }).toList();

    // Group by category
    final Map<String, List<TransactionModel>> categoryMap = {};
    double totalAmount = 0.0;
    for (final t in filteredTransactions) {
      categoryMap.putIfAbsent(t.category, () => []).add(t);
      totalAmount += t.amount;
    }

    // Sort transactions within each category by date descending
    for (final list in categoryMap.values) {
      list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    }

    // Build category group list, sorted by totalAmount descending
    final List<_CategoryGroupData> categoryGroups = [];
    categoryMap.forEach((name, txs) {
      final catTotal =
          txs.fold<double>(0.0, (prev, elem) => prev + elem.amount);
      if (catTotal > 0) {
        final percentage =
            totalAmount > 0 ? (catTotal / totalAmount) * 100.0 : 0.0;
        final color = FinanceCategoryModel.getColorForCategory(name,
            isExpense: isExpense);
        final icon =
            FinanceCategoryModel.getIconForCategory(name, isExpense: isExpense);

        categoryGroups.add(_CategoryGroupData(
          name: name,
          totalAmount: catTotal,
          percentage: percentage,
          color: color,
          icon: icon,
          transactions: txs,
        ));
      }
    });

    categoryGroups.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final isAllExpanded = categoryGroups.isNotEmpty &&
        _expandedCategories.length == categoryGroups.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Standard Header Bar
            _buildHeader(screenTitle),

            // 2. Segmented Type Switcher (Pengeluaran | Pemasukan)
            _buildTypeSwitcher(),

            // 3. Period Filter & Navigator Bar
            _buildPeriodSelector(),

            // 4. Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _loadData(),
                color: const Color(0xFFFF7A00),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // A. Visualisasi Grafik (Donut Chart & Proportion Bar)
                      _buildChartCard(
                        totalAmount: totalAmount,
                        totalTransactions: filteredTransactions.length,
                        groups: categoryGroups,
                        isExpense: isExpense,
                        themeColor: themeColor,
                        themeBgColor: themeBgColor,
                      ),
                      const SizedBox(height: 20),

                      // B. Section Header Accordion
                      if (categoryGroups.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Kategori ${isExpense ? 'Pengeluaran' : 'Pemasukan'}',
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${categoryGroups.length}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: themeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Quick Action: Buka/Tutup Semua
                            GestureDetector(
                              onTap: () => _toggleAllCategories(categoryGroups),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isAllExpanded ? 'Tutup Semua' : 'Buka Semua',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // C. Accordion List
                      if (categoryGroups.isEmpty)
                        _buildEmptyState(
                            isExpense, themeColor, themeBgColor, isPartner)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categoryGroups.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final group = categoryGroups[index];
                            final isExpanded =
                                _expandedCategories.contains(group.name);
                            return _buildCategoryAccordionCard(
                              group: group,
                              isExpanded: isExpanded,
                              isExpense: isExpense,
                              themeColor: themeColor,
                              isReadOnly: isPartner,
                            );
                          },
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Standard Header Bar
  Widget _buildHeader(String title) {
    return Container(
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
              title,
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
          const SizedBox(width: 48), // Symmetrical balance spacer
        ],
      ),
    );
  }

  /// 2. Segmented Switcher (Pengeluaran vs Pemasukan)
  Widget _buildTypeSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Tab 1: Pengeluaran
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_selectedType != 'expense') {
                    setState(() {
                      _selectedType = 'expense';
                      _expandedCategories.clear();
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: _selectedType == 'expense'
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _selectedType == 'expense'
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 16,
                        color: _selectedType == 'expense'
                            ? const Color(0xFFFF4B4B)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pengeluaran',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: _selectedType == 'expense'
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: _selectedType == 'expense'
                              ? const Color(0xFFFF4B4B)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tab 2: Pemasukan
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_selectedType != 'income') {
                    setState(() {
                      _selectedType = 'income';
                      _expandedCategories.clear();
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: _selectedType == 'income'
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _selectedType == 'income'
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_downward_rounded,
                        size: 16,
                        color: _selectedType == 'income'
                            ? const Color(0xFF00BBA7)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pemasukan',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: _selectedType == 'income'
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: _selectedType == 'income'
                              ? const Color(0xFF00BBA7)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Period Filter & Navigator Bar
  Widget _buildPeriodSelector() {
    final String periodLabel;
    final String periodSubtitle;

    if (_isCustomRange && _customStartDate != null) {
      periodLabel =
          '${_formatDateShort(_activeStartDate)} – ${_formatDateShort(_activeEndDate)}';
      periodSubtitle = 'Rentang Kustom';
    } else if (_customStartDay != null) {
      final start = _activeStartDate;
      final end = _activeEndDate;
      periodLabel =
          '${start.day} ${_shortMonths[start.month - 1]} – ${end.day} ${_shortMonths[end.month - 1]} ${end.year}';
      periodSubtitle = 'Siklus Tgl $_customStartDay';
    } else {
      periodLabel = '${_monthNames[_selectedMonth - 1]} $_selectedYear';
      periodSubtitle =
          '1 ${_shortMonths[_selectedMonth - 1]} – ${_activeEndDate.day} ${_shortMonths[_selectedMonth - 1]} $_selectedYear';
    }

    final now = DateTime.now();
    bool isDefaultPeriod;
    if (_isCustomRange) {
      isDefaultPeriod = false;
    } else if (_customStartDay != null) {
      final clampedDay = _customStartDay!.clamp(1, 28);
      int defaultYear = now.year;
      int defaultMonth = now.month;
      if (now.day < clampedDay) {
        if (defaultMonth == 1) {
          defaultMonth = 12;
          defaultYear -= 1;
        } else {
          defaultMonth -= 1;
        }
      }
      isDefaultPeriod =
          _selectedYear == defaultYear && _selectedMonth == defaultMonth;
    } else {
      isDefaultPeriod =
          _selectedYear == now.year && _selectedMonth == now.month;
    }

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Month Button
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            color: const Color(0xFF334155),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            splashRadius: 16,
            onPressed: _goToPreviousMonth,
          ),

          // Month Label / Date Range Display (Tap to pick date range)
          Expanded(
            child: InkWell(
              onTap: _pickCustomDateRange,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            periodLabel,
                            style: TextStyle(
                              fontSize:
                                  (_isCustomRange || _customStartDay != null)
                                      ? 13
                                      : 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Color(0xFF64748B),
                          size: 18,
                        ),
                      ],
                    ),
                    Text(
                      periodSubtitle,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Next Month Button
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            color: const Color(0xFF334155),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            splashRadius: 16,
            onPressed: _goToNextMonth,
          ),

          // Quick Calendar / Reset Button
          if (!isDefaultPeriod)
            InkWell(
              onTap: _resetToDefaultPeriod,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(left: 2, right: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _customStartDay != null ? 'Siklus Ini' : 'Bulan Ini',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF7A00),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.calendar_today_rounded, size: 16),
              color: const Color(0xFF64748B),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              splashRadius: 16,
              onPressed: _pickCustomDateRange,
            ),
        ],
      ),
    );
  }

  /// 4. Chart Visualization Card (Donut Chart & Proportion Bar)
  Widget _buildChartCard({
    required double totalAmount,
    required int totalTransactions,
    required List<_CategoryGroupData> groups,
    required bool isExpense,
    required Color themeColor,
    required Color themeBgColor,
  }) {
    final hasData = groups.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grafik ${isExpense ? 'Pengeluaran' : 'Pemasukan'}',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: themeBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalTransactions Transaksi',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: themeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (!hasData) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pie_chart_outline_rounded,
                      color: Color(0xFF94A3B8),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Belum ada ${isExpense ? 'pengeluaran' : 'pemasukan'} di periode ini',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Donut Chart with Center Summary
            SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 170),
                    painter: _BreakdownDonutPainter(groups: groups),
                  ),
                  // Center Text Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total ${isExpense ? 'Keluar' : 'Masuk'}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          FinanceProvider.formatRupiah(totalAmount),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: themeColor,
                            letterSpacing: -0.4,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${groups.length} Kategori',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Segmented Proportion Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: groups.map((g) {
                    final flex = math.max(1, (g.percentage * 10).round());
                    return Expanded(
                      flex: flex,
                      child: Container(color: g.color),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Category Legend Badges (Wrap)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: groups.take(6).map((g) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: g.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        g.name,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${g.percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 5. Accordion Category Card
  Widget _buildCategoryAccordionCard({
    required _CategoryGroupData group,
    required bool isExpanded,
    required bool isExpense,
    required Color themeColor,
    bool isReadOnly = false,
  }) {
    final formattedTotal = FinanceProvider.formatRupiah(group.totalAmount);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded
              ? group.color.withValues(alpha: 0.35)
              : const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isExpanded ? 0.035 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // A. Accordion Header (Tappable)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleCategory(group.name),
              borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(18))
                  : BorderRadius.circular(18),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Category Icon Circle
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: group.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            group.icon,
                            color: group.color,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Category Name & Tx Count + Percentage
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    '${group.transactions.length} transaksi',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF94A3B8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${group.percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: group.color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Total Amount & Animated Chevron
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formattedTotal,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF94A3B8),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Subtle Progress Bar indicator
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (group.percentage / 100.0).clamp(0.01, 1.0),
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(group.color),
                        minHeight: 3.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // B. Accordion Body (List of Transactions under this category)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  color: const Color(0xFFFAFAFC),
                  child: Column(
                    children: group.transactions.map((tx) {
                      return _buildTransactionItemRow(
                        tx,
                        isExpense,
                        themeColor,
                        isReadOnly: isReadOnly,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Transaction item row inside accordion
  Widget _buildTransactionItemRow(
    TransactionModel tx,
    bool isExpense,
    Color themeColor, {
    bool isReadOnly = false,
  }) {
    final amountFormatted =
        FinanceProvider.formatRupiah(tx.amount, showSymbol: true);
    final prefix = isExpense ? '- ' : '+ ';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          TransactionDetailBottomSheet.show(
            context,
            transaction: tx,
            isReadOnly: isReadOnly,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Direction indicator dot
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: themeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),

              // Title, Date, & Note
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDateTime(tx.transactionDate),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    if (tx.note != null && tx.note!.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        tx.note!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Nominal
              Text(
                '$prefix$amountFormatted',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: themeColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty State Widget
  Widget _buildEmptyState(
    bool isExpense,
    Color themeColor,
    Color themeBgColor,
    bool isPartner,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: themeBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: themeColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum Ada Catatan ${isExpense ? 'Pengeluaran' : 'Pemasukan'}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPartner
                ? 'Pasangan belum mencatat ${isExpense ? 'pengeluaran' : 'pemasukan'} pada periode ini.'
                : 'Tidak ada transaksi yang tercatat pada periode ini.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF94A3B8),
            ),
          ),
          if (!isPartner) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                AddTransactionBottomSheet.show(
                  context,
                  initialType: _selectedType,
                );
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Tambah ${isExpense ? 'Pengeluaran' : 'Pemasukan'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom Donut Chart Painter for Breakdown Screen
class _BreakdownDonutPainter extends CustomPainter {
  final List<_CategoryGroupData> groups;

  _BreakdownDonutPainter({required this.groups});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 14.0;
    final radius =
        (math.min(size.width, size.height) / 2) - (strokeWidth / 2) - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2; // Start from top 12 o'clock
    const totalCircumference = 2 * math.pi;
    final hasMultiple = groups.length > 1;
    final gapAngle = hasMultiple ? 0.04 : 0.0;

    for (final item in groups) {
      final sweepAngle = (item.percentage / 100.0) * totalCircumference;
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      final effectiveSweep =
          hasMultiple ? math.max(0.01, sweepAngle - gapAngle) : sweepAngle;
      final effectiveStart =
          hasMultiple ? startAngle + (gapAngle / 2) : startAngle;

      canvas.drawArc(rect, effectiveStart, effectiveSweep, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _BreakdownDonutPainter oldDelegate) {
    return oldDelegate.groups != groups;
  }
}
