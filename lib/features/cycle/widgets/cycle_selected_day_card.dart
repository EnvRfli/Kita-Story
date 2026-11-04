import 'package:flutter/material.dart';

import '../models/cycle_day_log_model.dart';
import '../models/cycle_summary.dart';
import '../utils/cycle_date_utils.dart';

class CycleSelectedDayCard extends StatelessWidget {
  final DateTime date;
  final CyclePhase? phase;
  final CycleDayLogModel? log;
  final bool canLog;
  final VoidCallback? onLog;

  const CycleSelectedDayCard({
    super.key,
    required this.date,
    required this.phase,
    required this.log,
    required this.canLog,
    this.onLog,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = cycleDateKey(date) == cycleDateKey(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cycleLongDate(date),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          isToday ? 'Hari ini' : cycleRelativeDayLabel(date),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        if (phase != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: phase!.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${phase!.emoji} ${phase!.label}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: phase!.color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (canLog && onLog != null)
                GestureDetector(
                  onTap: onLog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          log != null
                              ? Icons.edit_rounded
                              : Icons.add_rounded,
                          size: 13,
                          color: const Color(0xFFE11D48),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          log != null ? 'Edit' : 'Catat',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE11D48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (log == null)
            const Text(
              'Belum ada catatan di tanggal ini.',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF94A3B8),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _MiniChip(
                  label: log!.flowLabel,
                  color: log!.flowColor,
                ),
                if (log!.moodLabel != null)
                  _MiniChip(
                    label: '${log!.moodEmoji} ${log!.moodLabel}',
                    color: const Color(0xFF8B5CF6),
                  ),
                if (log!.symptoms.isNotEmpty)
                  _MiniChip(
                    label: log!.symptomLabels.take(2).join(', '),
                    color: const Color(0xFF0EA5E9),
                  ),
              ],
            ),
          if (log?.notes != null && log!.notes!.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              log!.notes!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                fontStyle: FontStyle.italic,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
