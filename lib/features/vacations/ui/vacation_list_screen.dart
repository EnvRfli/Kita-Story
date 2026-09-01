import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/vacation_model.dart';
import '../providers/vacation_provider.dart';
import '../widgets/vacation_calendar_header.dart';
import '../widgets/vacation_card.dart';

class VacationListScreen extends StatefulWidget {
  final String? targetUserId;
  final bool isReadOnly;

  const VacationListScreen({
    super.key,
    this.targetUserId,
    this.isReadOnly = false,
  });

  @override
  State<VacationListScreen> createState() => _VacationListScreenState();
}

class _VacationListScreenState extends State<VacationListScreen> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  double _currentMinChildSize = 0.45;
  double _currentMaxChildSize = 0.90;
  DateTime? _selectedCalendarDate;

  static const List<String> _months = [
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void initState() {
    super.initState();
    _selectedCalendarDate = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VacationProvider>();
      provider.resetCalendarAndFilters();
      provider.loadVacations(targetUserId: widget.targetUserId);
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _toggleSheet() {
    if (!_sheetController.isAttached) return;
    final current = _sheetController.size;
    final mid = (_currentMinChildSize + _currentMaxChildSize) / 2;
    final target = current > mid ? _currentMinChildSize : _currentMaxChildSize;
    _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF0088FF),
      body: Consumer<VacationProvider>(
        builder: (context, provider, child) {
          final vacations = provider.filteredVacations;
          final allVacations = provider.vacations;

          // Dynamic expanded title based on selected date or active focused month
          final String activeDateTitle;
          if (_selectedCalendarDate != null) {
            activeDateTitle =
                '${_selectedCalendarDate!.day} ${_months[_selectedCalendarDate!.month - 1]} ${_selectedCalendarDate!.year}';
          } else {
            activeDateTitle =
                '${_months[provider.focusedMonth.month - 1]} ${provider.focusedMonth.year}';
          }

          // Dynamically compute calendar height based on number of weeks (4, 5, or 6)
          final firstDayOfMonth = DateTime(
              provider.focusedMonth.year, provider.focusedMonth.month, 1);
          final lastDayOfMonth = DateTime(
              provider.focusedMonth.year, provider.focusedMonth.month + 1, 0);
          final leadingDaysCount = firstDayOfMonth.weekday % 7;
          final daysInMonth = lastDayOfMonth.day;
          final totalCells = ((leadingDaysCount + daysInMonth) / 7).ceil() * 7;
          final totalWeeks = totalCells ~/ 7;

          const topBarHeight = 56.0;
          const monthNavHeight = 36.0 + 14.0;
          const weekdayRowHeight = 18.0 + 10.0;
          final gridHeight = totalWeeks * 36.0 + (totalWeeks - 1) * 6.0;
          const calendarBottomPadding = 16.0;

          final totalCalendarSectionHeight = statusBarHeight +
              topBarHeight +
              monthNavHeight +
              weekdayRowHeight +
              gridHeight +
              calendarBottomPadding;

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = constraints.maxHeight;

              // Dynamic min and max child sizes without hardcoding
              final minChildSize =
                  ((screenHeight - totalCalendarSectionHeight) / screenHeight)
                      .clamp(0.25, 0.75);
              final maxChildSize =
                  ((screenHeight - (statusBarHeight + topBarHeight)) /
                          screenHeight)
                      .clamp(0.85, 0.95);

              _currentMinChildSize = minChildSize;
              _currentMaxChildSize = maxChildSize;

              return Stack(
                children: [
                  // 1. Calendar Header Layer (Smooth reactive opacity without triggering parent rebuilds)
                  Positioned(
                    top: statusBarHeight + topBarHeight,
                    left: 0,
                    right: 0,
                    child: ListenableBuilder(
                      listenable: _sheetController,
                      builder: (context, child) {
                        double progress = 0.0;
                        if (_sheetController.isAttached) {
                          final range = maxChildSize - minChildSize;
                          if (range > 0) {
                            progress =
                                ((_sheetController.size - minChildSize) / range)
                                    .clamp(0.0, 1.0);
                          }
                        }
                        return Opacity(
                          opacity: (1.0 - (progress * 1.8)).clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, -16.0 * progress),
                            child: child,
                          ),
                        );
                      },
                      child: VacationCalendarHeader(
                        focusedMonth: provider.focusedMonth,
                        onPreviousMonth: provider.previousMonth,
                        onNextMonth: provider.nextMonth,
                        vacations: allVacations,
                        selectedDate: _selectedCalendarDate,
                        onDateSelected: (date) {
                          setState(() {
                            if (_selectedCalendarDate != null &&
                                _isSameDay(_selectedCalendarDate!, date)) {
                              _selectedCalendarDate = null;
                            } else {
                              _selectedCalendarDate = date;
                            }
                          });
                        },
                      ),
                    ),
                  ),

                  // 2. Interactive Sliding Bottom Sheet
                  DraggableScrollableSheet(
                    controller: _sheetController,
                    initialChildSize: minChildSize,
                    minChildSize: minChildSize,
                    maxChildSize: maxChildSize,
                    snap: true,
                    snapSizes: [minChildSize, maxChildSize],
                    snapAnimationDuration: const Duration(milliseconds: 250),
                    builder: (context, scrollController) {
                      // Filter by selected calendar date if active
                      List<VacationModel> displayVacations = vacations;
                      if (_selectedCalendarDate != null) {
                        final sel = DateTime(
                            _selectedCalendarDate!.year,
                            _selectedCalendarDate!.month,
                            _selectedCalendarDate!.day);
                        displayVacations = displayVacations.where((v) {
                          final start = DateTime(v.startDate.year,
                              v.startDate.month, v.startDate.day);
                          final end = DateTime(
                              v.endDate.year, v.endDate.month, v.endDate.day);
                          return !sel.isBefore(start) && !sel.isAfter(end);
                        }).toList();
                      }

                      return Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(32)),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 18,
                              offset: Offset(0, -4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(32)),
                          child: RefreshIndicator(
                            color: const Color(0xFF0088FF),
                            onRefresh: () => provider.loadVacations(
                              targetUserId: widget.targetUserId,
                            ),
                            child: CustomScrollView(
                              controller: scrollController,
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              slivers: [
                                // Header Sliver (Drag handle & Filter tabs)
                                SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      // Drag Handle Bar (Tappable to toggle expand/collapse)
                                      GestureDetector(
                                        onTap: _toggleSheet,
                                        behavior: HitTestBehavior.opaque,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          child: Center(
                                            child: Container(
                                              width: 38,
                                              height: 4.5,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFCBD5E1),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Filter Tabs Row
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            20, 0, 20, 10),
                                        child: Row(
                                          children: [
                                            _buildTabPill(
                                              context,
                                              title:
                                                  'Semua (${provider.allCount})',
                                              isSelected: provider.filterTab ==
                                                  VacationFilterTab.all,
                                              onTap: () =>
                                                  provider.setFilterTab(
                                                      VacationFilterTab.all),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildTabPill(
                                              context,
                                              title:
                                                  'Sedang Berjalan (${provider.inProgressCount})',
                                              isSelected: provider.filterTab ==
                                                  VacationFilterTab.inProgress,
                                              onTap: () =>
                                                  provider.setFilterTab(
                                                      VacationFilterTab
                                                          .inProgress),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildTabPill(
                                              context,
                                              title:
                                                  'Selesai (${provider.completedCount})',
                                              isSelected: provider.filterTab ==
                                                  VacationFilterTab.completed,
                                              onTap: () =>
                                                  provider.setFilterTab(
                                                      VacationFilterTab
                                                          .completed),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Active Date Filter Banner with Reset Action
                                      if (_selectedCalendarDate != null)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              20, 0, 20, 10),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0088FF)
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFF0088FF)
                                                    .withValues(alpha: 0.22),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.calendar_today_rounded,
                                                  size: 15,
                                                  color: Color(0xFF0088FF),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Tanggal: ${_selectedCalendarDate!.day} ${_months[_selectedCalendarDate!.month - 1]} ${_selectedCalendarDate!.year}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF0088FF),
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedCalendarDate =
                                                          null;
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFF0088FF),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.refresh_rounded,
                                                          size: 13,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Reset',
                                                          style: TextStyle(
                                                            fontSize: 11.5,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Content Sliver (Loading / Error / Empty / List of Cards)
                                if (provider.isLoading)
                                  const SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF0088FF),
                                      ),
                                    ),
                                  )
                                else if (provider.errorMessage != null)
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.error_outline_rounded,
                                              size: 48,
                                              color: Color(0xFFEF4444),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              provider.errorMessage!,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF0088FF),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed: () =>
                                                  provider.loadVacations(
                                                targetUserId:
                                                    widget.targetUserId,
                                              ),
                                              child: const Text(
                                                'Coba Lagi',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                else if (displayVacations.isEmpty)
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: _buildEmptyState(),
                                  )
                                else
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 0, 20, 90),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final vacation =
                                              displayVacations[index];
                                          return VacationCard(
                                            vacation: vacation,
                                            onTap: () {
                                              context.push(
                                                '/vacation-detail',
                                                extra: {
                                                  'vacationId': vacation.id,
                                                  'isReadOnly':
                                                      widget.isReadOnly,
                                                },
                                              );
                                            },
                                          );
                                        },
                                        childCount: displayVacations.length,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 3. Fixed Top App Bar Layer (Perfect Horizontal Center Cross-Fade with ListenableBuilder)
                  Positioned(
                    top: statusBarHeight,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: topBarHeight,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () => context.pop(),
                          ),
                          Expanded(
                            child: Center(
                              child: ListenableBuilder(
                                listenable: _sheetController,
                                builder: (context, _) {
                                  double progress = 0.0;
                                  if (_sheetController.isAttached) {
                                    final range = maxChildSize - minChildSize;
                                    if (range > 0) {
                                      progress = ((_sheetController.size -
                                                  minChildSize) /
                                              range)
                                          .clamp(0.0, 1.0);
                                    }
                                  }
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Title 1: "Liburan" (Resting State)
                                      Opacity(
                                        opacity: (1.0 - (progress * 1.6))
                                            .clamp(0.0, 1.0),
                                        child: const Text(
                                          'Liburan',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),

                                      // Title 2: Dynamic Month / Date (Expanded State)
                                      Opacity(
                                        opacity: ((progress - 0.2) * 1.6)
                                            .clamp(0.0, 1.0),
                                        child: Text(
                                          activeDateTitle,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 48), // Symmetrical balancing
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: widget.isReadOnly
          ? null
          : Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8A00),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8A00).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/add-vacation'),
                  customBorder: const CircleBorder(),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTabPill(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0080FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF0080FF) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0080FF).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasDateFilter = _selectedCalendarDate != null;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    hasDateFilter ? '📅' : '✈️',
                    style: const TextStyle(fontSize: 38),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasDateFilter
                    ? 'Tidak Ada Liburan pada Tanggal Ini'
                    : 'Belum Ada Jadwal Liburan',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasDateFilter
                    ? 'Tidak ada agenda liburan yang dijadwalkan pada tanggal ${_selectedCalendarDate!.day} ${_months[_selectedCalendarDate!.month - 1]} ${_selectedCalendarDate!.year}.'
                    : 'Rencanakan momen liburan berkesan bersama pasangan dengan menekan tombol + di bawah!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              if (hasDateFilter) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0088FF),
                    side:
                        const BorderSide(color: Color(0xFF0088FF), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedCalendarDate = null;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Tampilkan Semua Jadwal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
