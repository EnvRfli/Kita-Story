import 'package:flutter/material.dart';

import '../models/cycle_summary.dart';
import '../utils/cycle_calculator.dart';
import '../utils/cycle_date_utils.dart';

class CycleWeekOutlook extends StatelessWidget {
  final CycleSummary summary;

  const CycleWeekOutlook({super.key, required this.summary});

  static const List<String> _weekdays = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  @override
  Widget build(BuildContext context) {
    final days = List<DateTime>.generate(
      7,
      (index) => summary.today.add(Duration(days: index)),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.stacked_line_chart_rounded,
                size: 17,
                color: Color(0xFF0F766E),
              ),
              SizedBox(width: 7),
              Text(
                'Prakiraan 7 hari ke depan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: days.map((date) {
              final phase = CycleCalculator.phaseOn(
                date,
                lastPeriodStart: summary.lastPeriodStart,
                cycleLength: summary.cycleLength,
                periodLength: summary.periodLength,
              ).phase;
              final isToday =
                  cycleDateKey(date) == cycleDateKey(summary.today);
              final isLateDay = summary.isLate;
              final color =
                  isLateDay ? const Color(0xFFF59E0B) : phase.color;
              final label = isLateDay ? 'Terlambat' : phase.label;

              return Expanded(
                child: Column(
                  children: [
                    Text(
                      _weekdays[date.weekday - 1],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                        color: isToday
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 30,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isToday
                            ? const Color(0xFF1E293B)
                            : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color:
                              isToday ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
