import 'package:flutter/material.dart';

import '../data/cycle_content.dart';
import '../models/cycle_summary.dart';

class CyclePartnerGuideCard extends StatelessWidget {
  final CycleSummary summary;
  final String? partnerName;
  final bool flat;

  const CyclePartnerGuideCard({
    super.key,
    required this.summary,
    this.partnerName,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = CycleContent.forPhase(summary.phase);
    final dayIndex = summary.phaseDayIndex;
    final name = (partnerName == null || partnerName!.trim().isEmpty)
        ? 'pasanganmu'
        : partnerName!.trim();
    final tips = CycleContent.rotatingTips(content.partnerTips, dayIndex);
    final avoid = CycleContent.rotatingTips(
      content.partnerAvoidTips,
      dayIndex,
      count: 2,
    );

    final body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: summary.phase.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: summary.phase.color,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cara mendukung $name hari ini',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Fase ${summary.phase.label} · hari ke-$dayIndex',
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
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: summary.phase.color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '✓',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: summary.phase.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hindari dulu',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC2410C),
                  ),
                ),
                const SizedBox(height: 5),
                ...avoid.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '•  $tip',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Color(0xFF7C2D12),
                      ),
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
