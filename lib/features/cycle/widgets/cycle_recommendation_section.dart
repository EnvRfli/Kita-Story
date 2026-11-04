import 'package:flutter/material.dart';

import '../data/cycle_content.dart';
import '../models/cycle_summary.dart';

class CycleRecommendationSection extends StatelessWidget {
  final CycleSummary summary;
  final bool flat;

  const CycleRecommendationSection({
    super.key,
    required this.summary,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = CycleContent.forPhase(summary.phase);
    final dayIndex = summary.phaseDayIndex;

    final body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                summary.phase.emoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saran untukmu hari ini',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Hari ke-$dayIndex di ${summary.phase.title.toLowerCase()}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _TipGroup(
            icon: Icons.spa_rounded,
            color: const Color(0xFF10B981),
            title: 'Kenyamanan tubuh',
            items: CycleContent.rotatingTips(content.bodyTips, dayIndex, count: 2),
          ),
          const SizedBox(height: 12),
          _TipGroup(
            icon: Icons.restaurant_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Makanan & minuman',
            items: CycleContent.rotatingTips(content.foodTips, dayIndex, count: 2),
          ),
          const SizedBox(height: 12),
          _TipGroup(
            icon: Icons.directions_run_rounded,
            color: const Color(0xFF06B6D4),
            title: 'Aktivitas',
            items:
                CycleContent.rotatingTips(content.activityTips, dayIndex, count: 2),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sebaiknya dihindari',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFBE123C),
                  ),
                ),
                const SizedBox(height: 6),
                ...CycleContent.rotatingTips(
                  content.avoidTips,
                  dayIndex,
                  count: 2,
                ).map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '•  ',
                          style: TextStyle(
                            color: Color(0xFFBE123C),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: Color(0xFF7F1D1D),
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
        ],
      );

    if (flat) return body;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: body,
    );
  }
}

class _TipGroup extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;

  const _TipGroup({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...items.map(
          (tip) => Padding(
            padding: const EdgeInsets.only(left: 34, bottom: 4),
            child: Text(
              '•  $tip',
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
