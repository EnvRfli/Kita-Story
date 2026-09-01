import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/note_model.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = note.cardBackgroundColor;
    final textColor = note.cardTextColor;
    final checkedColor = note.cardCheckedItemColor;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: note.isCompleted ? 0.60 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: note.isCompleted ? 0.20 : 0.45),
              blurRadius: note.isCompleted ? 8 : 14,
              offset: Offset(0, note.isCompleted ? 3 : 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Sparkle & Completed Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${note.title} ✨',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (note.isShared) ...[
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_rounded,
                                size: 11,
                                color: textColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Bersama',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (note.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Selesai ✓',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Content Preview
                  if (note.isChecklist)
                    _buildChecklistPreview(textColor, checkedColor)
                  else
                    _buildTextPreview(textColor),

                  // Footer: Last Update & Updated By (if shared)
                  _buildFooter(context, textColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistPreview(Color textColor, Color checkedColor) {
    if (note.items.isEmpty) {
      return Text(
        'Belum ada item checklist',
        style: TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: textColor.withValues(alpha: 0.65),
        ),
      );
    }

    final displayItems = note.items.take(4).toList();
    final hasMore = note.items.length > 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: item.isChecked ? checkedColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: item.isChecked
                          ? checkedColor
                          : textColor.withValues(alpha: 0.45),
                      width: 1.4,
                    ),
                  ),
                  child: item.isChecked
                      ? const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.itemText,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: item.isChecked
                          ? textColor.withValues(alpha: 0.55)
                          : textColor,
                      decoration:
                          item.isChecked ? TextDecoration.lineThrough : null,
                      decorationColor: textColor.withValues(alpha: 0.7),
                      decorationThickness: 1.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(left: 25, top: 2),
            child: Text(
              '...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor.withValues(alpha: 0.75),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextPreview(Color textColor) {
    final text = note.content?.trim() ?? '';
    if (text.isEmpty) {
      return Text(
        'Catatan kosong',
        style: TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: textColor.withValues(alpha: 0.65),
        ),
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: textColor.withValues(alpha: 0.9),
        height: 1.35,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter(BuildContext context, Color textColor) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUserProfile?.id;
    final currentUserName = authProvider.currentUserProfile?.name.trim();
    final effectiveCurrentUserName =
        (currentUserName != null && currentUserName.isNotEmpty)
            ? currentUserName
            : 'Saya';
    final partnerName = authProvider.partnerProfile?.name.trim();
    final effectivePartnerName = (partnerName != null && partnerName.isNotEmpty)
        ? partnerName
        : 'Pasangan';

    final updateTime = note.updatedAt ?? note.createdAt;
    final timeStr = DateFormatter.formatRelativeTime(updateTime);

    String updater = '';
    if (note.isShared) {
      final updaterId = note.lastUpdatedBy ?? note.addedBy;
      if (updaterId != null && updaterId.isNotEmpty) {
        if (updaterId == currentUserId) {
          updater = effectiveCurrentUserName;
        } else {
          updater = effectivePartnerName;
        }
      }
    }

    String label = '';
    if (timeStr.isNotEmpty && updater.isNotEmpty) {
      label = '$timeStr • oleh $updater';
    } else if (timeStr.isNotEmpty) {
      label = timeStr;
    } else if (updater.isNotEmpty) {
      label = 'oleh $updater';
    }

    if (label.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 11.5,
            color: textColor.withValues(alpha: 0.65),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.70),
            ),
          ),
        ],
      ),
    );
  }
}
