import 'package:flutter/material.dart';

import '../data/cycle_content.dart';
import '../models/cycle_summary.dart';
import 'cycle_partner_guide_card.dart';
import 'cycle_recommendation_section.dart';

class CycleInsightSheet {
  static Future<void> show(
    BuildContext context, {
    required CycleSummary summary,
  }) {
    final content = CycleContent.forPhase(summary.phase);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SheetShell(
        title: 'Saran ${summary.phase.title}',
        subtitle:
            'Hari ke-${summary.phaseDayIndex} di fase ini · ${summary.phase.emoji} ${summary.phase.label}',
        intro: content.hormoneSummary,
        child: CycleRecommendationSection(summary: summary, flat: true),
      ),
    );
  }
}

class CyclePartnerGuideSheet {
  static Future<void> show(
    BuildContext context, {
    required CycleSummary summary,
    String? partnerName,
  }) {
    final name =
        (partnerName == null || partnerName.trim().isEmpty)
            ? 'pasanganmu'
            : partnerName.trim();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SheetShell(
        title: 'Cara mendukung $name',
        subtitle:
            'Hari ke-${summary.phaseDayIndex} di fase ${summary.phase.label}',
        child: CyclePartnerGuideCard(
          summary: summary,
          partnerName: partnerName,
          flat: true,
        ),
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? intro;
  final Widget child;

  const _SheetShell({
    required this.title,
    required this.subtitle,
    this.intro,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF94A3B8),
                ),
              ),
              if (intro != null) ...[
                const SizedBox(height: 10),
                Text(
                  intro!,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
