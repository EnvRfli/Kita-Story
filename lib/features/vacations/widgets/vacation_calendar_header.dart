import 'package:flutter/material.dart';
import '../models/vacation_model.dart';

class VacationCalendarHeader extends StatelessWidget {
  final DateTime focusedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final List<VacationModel> vacations;
  final DateTime? selectedDate;
  final Function(DateTime)? onDateSelected;

  const VacationCalendarHeader({
    super.key,
    required this.focusedMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.vacations,
    this.selectedDate,
    this.onDateSelected,
  });

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

  static const List<String> _weekDays = [
    'MIN',
    'SEN',
    'SEL',
    'RAB',
    'KAM',
    'JUM',
    'SAB'
  ];

  static const List<Color> _vacationColors = [
    Color(0xFFFFB700), // Soft Amber Gold
    Color(0xFF00C0E8), // Soft Cyan Turquoise
    Color(0xFF1FBF72), // Soft Emerald Green
  ];

  Color _getVacationColor(VacationModel vacation) {
    final idx = vacation.id.hashCode.abs() % _vacationColors.length;
    return _vacationColors[idx];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isDateInVacation(DateTime date, VacationModel v) {
    final d = DateTime(date.year, date.month, date.day);
    final start =
        DateTime(v.startDate.year, v.startDate.month, v.startDate.day);
    final end = DateTime(v.endDate.year, v.endDate.month, v.endDate.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0);

    // Leading days from previous month
    final leadingDaysCount = firstDayOfMonth.weekday % 7; // Sunday = 0
    final prevMonthLastDay =
        DateTime(focusedMonth.year, focusedMonth.month, 0).day;

    final daysInMonth = lastDayOfMonth.day;
    final totalCells = ((leadingDaysCount + daysInMonth) / 7).ceil() * 7;
    final totalWeeks = totalCells ~/ 7;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Month Navigation Bar (Perfect Horizontal Center)
          Row(
            children: [
              GestureDetector(
                onTap: onPreviousMonth,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFF0088FF),
                    size: 26,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _months[focusedMonth.month - 1],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onNextMonth,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF0088FF),
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Weekday Names Row (MIN SEN SEL RAB KAM JUM SAB)
          Row(
            children: _weekDays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // 3. Dynamic Weeks Column (4, 5, or 6 weeks)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(totalWeeks, (weekIndex) {
              return Padding(
                padding: EdgeInsets.only(bottom: weekIndex < totalWeeks - 1 ? 6.0 : 0.0),
                child: SizedBox(
                  height: 36,
                  child: Row(
                    children: List.generate(7, (colIndex) {
                      final cellIndex = weekIndex * 7 + colIndex;
                      final isPrevMonth = cellIndex < leadingDaysCount;
                      final isNextMonth =
                          cellIndex >= leadingDaysCount + daysInMonth;

                      int dayNum;
                      DateTime cellDate;

                      if (isPrevMonth) {
                        dayNum =
                            prevMonthLastDay - leadingDaysCount + cellIndex + 1;
                        cellDate = DateTime(
                            focusedMonth.year, focusedMonth.month - 1, dayNum);
                      } else if (isNextMonth) {
                        dayNum =
                            cellIndex - leadingDaysCount - daysInMonth + 1;
                        cellDate = DateTime(
                            focusedMonth.year, focusedMonth.month + 1, dayNum);
                      } else {
                        dayNum = cellIndex - leadingDaysCount + 1;
                        cellDate = DateTime(
                            focusedMonth.year, focusedMonth.month, dayNum);
                      }

                      final isToday = _isSameDay(cellDate, today);

                      // Find matching vacation for this date
                      VacationModel? matchingVacation;
                      for (var v in vacations) {
                        if (_isDateInVacation(cellDate, v)) {
                          matchingVacation = v;
                          break;
                        }
                      }

                      final hasVacation = matchingVacation != null;

                      // Determine span connection in this week row
                      bool hasPrevInRow = false;
                      bool hasNextInRow = false;

                      if (hasVacation) {
                        if (colIndex > 0) {
                          final prevDate =
                              cellDate.subtract(const Duration(days: 1));
                          hasPrevInRow =
                              _isDateInVacation(prevDate, matchingVacation);
                        }
                        if (colIndex < 6) {
                          final nextDate =
                              cellDate.add(const Duration(days: 1));
                          hasNextInRow =
                              _isDateInVacation(nextDate, matchingVacation);
                        }
                      }

                      // Container decoration & margins
                      BorderRadius? pillRadius;
                      EdgeInsets cellMargin = EdgeInsets.zero;
                      Color? pillColor;

                      final isSelectedDate = selectedDate != null && _isSameDay(cellDate, selectedDate!);
                      Border? cellBorder;

                      if (hasVacation) {
                        pillColor = _getVacationColor(matchingVacation);

                        if (!hasPrevInRow && !hasNextInRow) {
                          // Single day pill
                          pillRadius = BorderRadius.circular(18);
                          cellMargin = const EdgeInsets.symmetric(horizontal: 4);
                        } else if (!hasPrevInRow && hasNextInRow) {
                          // Start of range in this row
                          pillRadius = const BorderRadius.horizontal(
                              left: Radius.circular(18));
                          cellMargin = const EdgeInsets.only(left: 4);
                        } else if (hasPrevInRow && !hasNextInRow) {
                          // End of range in this row
                          pillRadius = const BorderRadius.horizontal(
                              right: Radius.circular(18));
                          cellMargin = const EdgeInsets.only(right: 4);
                        } else {
                          // Middle of range
                          pillRadius = BorderRadius.zero;
                          cellMargin = EdgeInsets.zero;
                        }

                        if (isSelectedDate) {
                          cellBorder = Border.all(color: Colors.white, width: 2.2);
                        }
                      } else if (isToday) {
                        // Highlight for Today (056FCC requested by user)
                        pillColor = const Color(0xFF056FCC);
                        pillRadius = BorderRadius.circular(18);
                        cellMargin = const EdgeInsets.symmetric(horizontal: 4);
                        if (isSelectedDate) {
                          cellBorder = Border.all(color: Colors.white, width: 2.2);
                        }
                      } else if (isSelectedDate) {
                        // Tapped day without vacation
                        pillColor = Colors.white.withValues(alpha: 0.25);
                        pillRadius = BorderRadius.circular(18);
                        cellMargin = const EdgeInsets.symmetric(horizontal: 4);
                        cellBorder = Border.all(color: Colors.white, width: 1.8);
                      }

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (onDateSelected != null) {
                              onDateSelected!(cellDate);
                            }
                          },
                          child: Container(
                            margin: cellMargin,
                            decoration: BoxDecoration(
                              color: pillColor ?? Colors.transparent,
                              borderRadius: pillRadius,
                              border: cellBorder,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$dayNum',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: (hasVacation || isToday || isSelectedDate)
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: (isPrevMonth || isNextMonth)
                                    ? Colors.white.withValues(alpha: 0.35)
                                    : Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
