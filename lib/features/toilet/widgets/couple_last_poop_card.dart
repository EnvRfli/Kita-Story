import 'package:flutter/material.dart';
import '../models/poop_log_model.dart';

class CoupleLastPoopCard extends StatelessWidget {
  final PoopLogModel? latestLog;
  final int todayCount;

  const CoupleLastPoopCard({
    super.key,
    required this.latestLog,
    required this.todayCount,
  });

  @override
  Widget build(BuildContext context) {
    final status = DigestiveStatusInfo.fromLastPoop(latestLog?.poopedAt);
    final lastSummary = latestLog != null
        ? 'Terakhir: ${latestLog!.relativeTime} di ${latestLog!.locationName}'
        : 'Belum ada catatan toilet';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: status.badgeBgColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              status.iconEmoji,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                height: 1.0,
              ),
              strutStyle: const StrutStyle(
                fontSize: 22,
                height: 1.0,
                forceStrutHeight: true,
              ),
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        status.badgeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: status.badgeTextColor,
                        ),
                      ),
                    ),
                    if (todayCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Hari ini ${todayCount}x',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0088FF),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  lastSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.tipText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    );
  }
}
