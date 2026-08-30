import 'package:flutter/material.dart';
import '../models/vacation_activity_model.dart';

class VacationTimelineCard extends StatelessWidget {
  final VacationActivityModel activity;
  final int activityIndex;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const VacationTimelineCard({
    super.key,
    required this.activity,
    this.activityIndex = 0,
    this.isFirst = false,
    this.isLast = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = activity.isCompleted;
    final isGrey = activityIndex >= 3 && !isCompleted;
    final nodeColor = isCompleted
        ? const Color(0xFF10B981)
        : (isGrey ? const Color(0xFFCBD5E1) : const Color(0xFFFFB000));
    final isHollow = activityIndex < 2 && !isCompleted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Timeline Indicator
          SizedBox(
            width: 28,
            child: Column(
              children: [
                // Top line
                Expanded(
                  flex: 1,
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : (isCompleted
                            ? const Color(0xFF10B981)
                            : (isGrey
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFFFFB000))),
                  ),
                ),
                // Center Node Dot / Ring
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isHollow ? Colors.white : nodeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: nodeColor,
                      width: isHollow ? 3.5 : 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: nodeColor.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                // Bottom line
                Expanded(
                  flex: 2,
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : (isCompleted
                            ? const Color(0xFF10B981)
                            : (isGrey
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFFFFB000))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Right Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time Range
                        Text(
                          activity.timeRange,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF8A00),
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 5),

                        // Title
                        Text(
                          activity.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isCompleted
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF1E293B),
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),

                        // Description
                        if (activity.description != null &&
                            activity.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            activity.description!.trim(),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
