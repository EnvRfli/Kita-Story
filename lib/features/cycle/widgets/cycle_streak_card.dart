import 'package:flutter/material.dart';

import '../models/cycle_data.dart';
import '../utils/cycle_date_utils.dart';

class CycleStreakCard extends StatelessWidget {
  final CycleData data;

  const CycleStreakCard({super.key, required this.data});

  static const Map<int, int> _milestones = {3: 5, 7: 10, 14: 20};

  @override
  Widget build(BuildContext context) {
    final streak = data.logStreak;
    final logsByDate = data.logsByDate;
    final milestone = _nextMilestone(streak);
    final milestoneLabel = milestone == null
        ? 'Streak luar biasa! 🔥'
        : '${milestone.key - streak} hari lagi → +${milestone.value} poin';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF97316), Color(0xFFE11D48)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                '$streak',
                style: const TextStyle(
                  fontSize: 26,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'hari beruntun',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${data.logsThisMonth} catatan bulan ini',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (index) {
              final day = data.today.subtract(Duration(days: 6 - index));
              final done = logsByDate.containsKey(cycleDateKey(day));
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: done
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 9),
          Text(
            milestoneLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }

  MapEntry<int, int>? _nextMilestone(int streak) {
    for (final entry in _milestones.entries) {
      if (streak < entry.key) return entry;
    }
    return null;
  }
}
