import 'package:flutter/material.dart';

import '../models/cycle_data.dart';
import '../models/cycle_summary.dart';
import '../utils/cycle_calculator.dart';
import '../utils/cycle_date_utils.dart';

class CycleMonthCalendar extends StatefulWidget {
  final CycleData data;
  final CycleSummary summary;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  const CycleMonthCalendar({
    super.key,
    required this.data,
    required this.summary,
    required this.selectedDate,
    required this.onSelectDate,
  });

  @override
  State<CycleMonthCalendar> createState() => _CycleMonthCalendarState();
}

class _CycleMonthCalendarState extends State<CycleMonthCalendar> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      1,
    );
  }

  @override
  void didUpdateWidget(covariant CycleMonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (cycleDateKey(oldWidget.selectedDate) !=
        cycleDateKey(widget.selectedDate)) {
      final selected = widget.selectedDate;
      if (selected.year != _visibleMonth.year ||
          selected.month != _visibleMonth.month) {
        _visibleMonth = DateTime(selected.year, selected.month, 1);
      }
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _goToToday() {
    final today = widget.summary.today;
    setState(() {
      _visibleMonth = DateTime(today.year, today.month, 1);
    });
    widget.onSelectDate(today);
  }

  CyclePhase? _phaseFor(DateTime date) {
    final start = widget.summary.lastPeriodStart;
    if (date.isBefore(start)) return null;
    final diff = date.difference(start).inDays;
    if (diff > widget.summary.cycleLength * 12) return null;
    if (widget.summary.isLate &&
        !date.isBefore(widget.summary.nextPeriodStart)) {
      return null;
    }

    return CycleCalculator.phaseOn(
      date,
      lastPeriodStart: start,
      cycleLength: widget.summary.cycleLength,
      periodLength: widget.summary.periodLength,
    ).phase;
  }

  bool _isFertile(DateTime date) {
    return !date.isBefore(widget.summary.fertileStart) &&
        !date.isAfter(widget.summary.fertileEnd);
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday;

    final weeks = <List<DateTime?>>[];
    var row = List<DateTime?>.filled(firstWeekday - 1, null, growable: true);
    for (var day = 1; day <= daysInMonth; day++) {
      row.add(DateTime(_visibleMonth.year, _visibleMonth.month, day));
      if (row.length == 7) {
        weeks.add(row);
        row = <DateTime?>[];
      }
    }
    if (row.isNotEmpty) {
      while (row.length < 7) {
        row.add(null);
      }
      weeks.add(row);
    }

    final isCurrentMonth = _visibleMonth.year == widget.summary.today.year &&
        _visibleMonth.month == widget.summary.today.month;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cycleMonthYear(_visibleMonth),
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (!isCurrentMonth)
                GestureDetector(
                  onTap: _goToToday,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text(
                      'Hari ini',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                  ),
                ),
              _MonthNavButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => _changeMonth(-1),
              ),
              const SizedBox(width: 4),
              _MonthNavButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: cycleWeekdaysShort
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -120) {
                _changeMonth(1);
              } else if (velocity > 120) {
                _changeMonth(-1);
              }
            },
            child: Column(
              children: weeks
                  .map(
                    (week) => Row(
                      children: week
                          .map(
                            (date) => Expanded(
                              child: date == null
                                  ? const SizedBox(height: 42)
                                  : _buildDayCell(date),
                            ),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          _CalendarLegend(isLate: widget.summary.isLate),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final isSelected =
        cycleDateKey(date) == cycleDateKey(widget.selectedDate);
    final isToday = cycleDateKey(date) == cycleDateKey(widget.summary.today);
    final log = widget.data.logForDate(date);
    final phase = _phaseFor(date);
    final hasBleeding = log?.hasBleeding == true;
    final isPeriod = hasBleeding || phase == CyclePhase.menstrual;
    final isOvulation = phase == CyclePhase.ovulation;
    final isFertile = _isFertile(date);

    Color background = Colors.transparent;
    Color textColor = const Color(0xFF334155);
    Color? borderColor;
    var borderWidth = 1.0;

    if (isSelected) {
      background = const Color(0xFF1E293B);
      textColor = Colors.white;
    } else if (hasBleeding) {
      background = const Color(0xFFE11D48);
      textColor = Colors.white;
    } else if (isPeriod) {
      background = const Color(0xFFFFE4E6);
      textColor = const Color(0xFFBE123C);
    } else if (isOvulation) {
      background = const Color(0xFFCFFAFE);
      textColor = const Color(0xFF0E7490);
    } else if (isFertile) {
      background = const Color(0xFFF0FDFA);
      textColor = const Color(0xFF0F766E);
    }

    if (isToday && !isSelected) {
      borderColor = const Color(0xFF1E293B);
      borderWidth = 1.3;
    }

    final dotColor = log == null
        ? null
        : (log.hasBleeding ? Colors.white : const Color(0xFF64748B));

    return GestureDetector(
      onTap: () => widget.onSelectDate(date),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 42,
        child: Center(
          child: Container(
            width: 32,
            height: 38,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: borderColor == null
                  ? null
                  : Border.all(color: borderColor, width: borderWidth),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected || hasBleeding ? FontWeight.w800 : FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (dotColor != null) ...[
                  const SizedBox(height: 1),
                  Container(
                    width: 3.5,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: const Color(0xFF64748B)),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  final bool isLate;

  const _CalendarLegend({required this.isLate});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _legend(const Color(0xFFF9A8D4), 'Haid'),
        _legend(const Color(0xFF5EEAD4), 'Subur'),
        _legend(const Color(0xFF06B6D4), 'Ovulasi'),
        _legend(const Color(0xFF94A3B8), 'Catatan'),
        if (isLate) _legend(const Color(0xFFF59E0B), 'Prediksi dijeda'),
      ],
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
