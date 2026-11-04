import 'package:flutter/material.dart';

import '../data/cycle_content.dart';
import '../models/cycle_summary.dart';

class CycleDailyInsights extends StatelessWidget {
  final CycleSummary summary;
  final String? insight;
  final VoidCallback onOpenAll;

  const CycleDailyInsights({
    super.key,
    required this.summary,
    required this.onOpenAll,
    this.insight,
  });

  @override
  Widget build(BuildContext context) {
    final content = CycleContent.forPhase(summary.phase);
    final dayIndex = summary.phaseDayIndex;
    final suggestion = CycleContent.rotatingTips(
      content.bodyTips,
      dayIndex,
      count: 1,
    ).first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Insight harian',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            GestureDetector(
              onTap: onOpenAll,
              child: const Row(
                children: [
                  Text(
                    'Lihat semua',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE11D48),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 15,
                    color: Color(0xFFE11D48),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (insight != null && insight!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE11D48).withValues(alpha: 0.14),
              ),
            ),
            child: Text(
              insight!,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7F1D3A),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          height: 104,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            children: [
              _InsightCard(
                icon: Icons.mood_rounded,
                color: const Color(0xFF8B5CF6),
                label: 'Mood',
                value: content.predictedMoods.first,
                onTap: onOpenAll,
              ),
              const SizedBox(width: 8),
              _InsightCard(
                icon: Icons.bolt_rounded,
                color: const Color(0xFFF59E0B),
                label: 'Energi',
                value: '${content.energyLevel}/5',
                onTap: onOpenAll,
              ),
              const SizedBox(width: 8),
              _InsightCard(
                icon: Icons.healing_rounded,
                color: const Color(0xFF0EA5E9),
                label: 'Gejala umum',
                value: content.commonSymptoms.take(2).join(', '),
                onTap: onOpenAll,
              ),
              const SizedBox(width: 8),
              _InsightCard(
                icon: Icons.lightbulb_rounded,
                color: const Color(0xFF10B981),
                label: 'Saran',
                value: suggestion,
                onTap: onOpenAll,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _InsightCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
