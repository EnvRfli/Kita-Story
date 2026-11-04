import 'package:flutter/material.dart';

import '../models/cycle_summary.dart';
import '../utils/cycle_role.dart';

class CycleHomeBanner extends StatelessWidget {
  final CycleRole role;
  final String? partnerName;
  final CycleSummary? summary;
  final VoidCallback onTap;

  const CycleHomeBanner({
    super.key,
    required this.role,
    required this.onTap,
    this.partnerName,
    this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final isMonitor = role == CycleRole.monitor;
    final gradient = summary?.phase.gradient ??
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8FAB), Color(0xFFE11D48)],
        );

    final title = isMonitor
        ? 'Siklus ${(partnerName ?? 'Pasangan')}'
        : 'Siklus Haid';

    final subtitle = summary == null
        ? (isMonitor
            ? 'Belum ada data siklus dari pasanganmu'
            : 'Atur siklusmu untuk mulai melihat prediksi')
        : summary!.isLate
            ? '${summary!.periodCountdownLabel} · ${summary!.phase.label}'
            : 'Hari ${summary!.dayOfCycle} · ${summary!.phase.label} · '
                '${summary!.periodCountdownLabel}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(gradient: gradient),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    summary?.phase.emoji ?? '🌸',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
