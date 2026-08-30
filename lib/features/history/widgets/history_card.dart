import 'package:flutter/material.dart';
import '../models/activity_log_model.dart';

class HistoryCard extends StatelessWidget {
  final ActivityLogModel log;

  const HistoryCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final style = _getActivityVisuals(log.activityType, log.title);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Icon Box + Title)
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: style.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  style.icon,
                  color: style.iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  log.displayTitle,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // 2. Description
          if (log.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              log.description,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],

          // 3. Footer (User Tag + Points + Timestamp)
          const SizedBox(height: 14),
          Row(
            children: [
              // User Tag Pill
              _buildUserPill(log.userName ?? 'User'),
              const SizedBox(width: 8),

              // Points Badge
              if (log.pointsEarned > 0) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFD54F),
                            Color(0xFFFFA000),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '¢',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '+${log.pointsEarned} poin',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(),

              // Timestamp
              Text(
                log.formattedDate,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserPill(String name) {
    final isPink = name.toLowerCase().contains('nay') ||
        name.toLowerCase().contains('cewe') ||
        name.toLowerCase().contains('putri') ||
        name.toLowerCase().contains('anisa');

    final bgColor = isPink ? const Color(0xFFFFD6EC) : const Color(0xFFD0EBFF);
    final textColor =
        isPink ? const Color(0xFFD81B60) : const Color(0xFF0288D1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  _ActivityVisuals _getActivityVisuals(String type, String rawTitle) {
    final titleLower = rawTitle.toLowerCase();
    final typeLower = type.toLowerCase();

    // 1. Vacation / Travel (Sky Blue)
    if (typeLower.contains('vacation') ||
        titleLower.contains('liburan') ||
        titleLower.contains('agenda')) {
      return _ActivityVisuals(
        icon: Icons.flight_takeoff_rounded,
        iconColor: const Color(0xFF0D8BF0),
        backgroundColor: const Color(0xFFE0F2FE),
      );
    }

    // 2. Reading / Progress Update (Green)
    if (typeLower.contains('progress') ||
        typeLower.contains('read') ||
        titleLower.contains('baca') ||
        titleLower.contains('progres')) {
      return _ActivityVisuals(
        icon: Icons.sync_rounded,
        iconColor: const Color(0xFF10B981),
        backgroundColor: const Color(0xFFE6F9EE),
      );
    }

    // 2. Add / Create (Blue)
    if (typeLower.contains('add') ||
        typeLower.contains('create') ||
        titleLower.contains('tambah') ||
        titleLower.contains('membuat')) {
      return _ActivityVisuals(
        icon: Icons.add_rounded,
        iconColor: const Color(0xFF0284C7),
        backgroundColor: const Color(0xFFE0F2FE),
      );
    }

    // 3. Edit / Update / Review (Orange / Peach)
    if (typeLower.contains('update') ||
        typeLower.contains('review') ||
        typeLower.contains('edit') ||
        titleLower.contains('ubah') ||
        titleLower.contains('edit') ||
        titleLower.contains('ulasan') ||
        titleLower.contains('rating')) {
      return _ActivityVisuals(
        icon: Icons.edit_outlined,
        iconColor: const Color(0xFFF59E0B),
        backgroundColor: const Color(0xFFFFF3E0),
      );
    }

    // 4. Delete / Completed (Pink / Coral)
    if (typeLower.contains('delete') ||
        typeLower.contains('complete') ||
        typeLower.contains('finish') ||
        titleLower.contains('hapus') ||
        titleLower.contains('selesai') ||
        titleLower.contains('tamat')) {
      return _ActivityVisuals(
        icon: titleLower.contains('hapus')
            ? Icons.delete_outline_rounded
            : Icons.check_circle_outline_rounded,
        iconColor: const Color(0xFFF43F5E),
        backgroundColor: const Color(0xFFFFECEE),
      );
    }

    // Default Fallback
    return _ActivityVisuals(
      icon: Icons.auto_awesome_rounded,
      iconColor: const Color(0xFF8B5CF6),
      backgroundColor: const Color(0xFFF3E8FF),
    );
  }
}

class _ActivityVisuals {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  _ActivityVisuals({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
}
