import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/note_model.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final bool isGrid;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.isGrid = true,
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
        margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: note.isCompleted ? 0.18 : 0.38),
              blurRadius: note.isCompleted ? 6 : 12,
              offset: Offset(0, note.isCompleted ? 2 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isGrid ? 13 : 18,
                vertical: isGrid ? 13 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Top Section: Title & Badges
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        '${note.title} ✨',
                        style: TextStyle(
                          fontSize: isGrid ? 14.5 : 16,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.2,
                        ),
                        maxLines: isGrid ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Badges (Shared & Completed)
                      if (note.isShared || note.isCompleted) ...[
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (note.isShared)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.people_rounded,
                                      size: 10,
                                      color: textColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Bersama',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (note.isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Selesai ✓',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Content Preview
                      if (note.isChecklist)
                        _buildChecklistPreview(textColor, checkedColor)
                      else
                        _buildTextPreview(textColor),
                    ],
                  ),

                  // 2. Bottom Section: Footer (Last Update & Updated By)
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
          fontSize: isGrid ? 12 : 13,
          fontStyle: FontStyle.italic,
          color: textColor.withValues(alpha: 0.65),
        ),
      );
    }

    final maxItems = isGrid ? 3 : 4;
    final displayItems = note.items.take(maxItems).toList();
    final hasMore = note.items.length > maxItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.5),
            child: Row(
              children: [
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: item.isChecked ? checkedColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(3.5),
                    border: Border.all(
                      color: item.isChecked
                          ? checkedColor
                          : textColor.withValues(alpha: 0.45),
                      width: 1.3,
                    ),
                  ),
                  child: item.isChecked
                      ? const Icon(
                          Icons.check_rounded,
                          size: 11,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.itemText,
                    style: TextStyle(
                      fontSize: isGrid ? 12 : 13.5,
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
            padding: const EdgeInsets.only(left: 21, top: 1),
            child: Text(
              '...',
              style: TextStyle(
                fontSize: 12,
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
          fontSize: isGrid ? 12 : 13,
          fontStyle: FontStyle.italic,
          color: textColor.withValues(alpha: 0.65),
        ),
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: isGrid ? 12 : 13.5,
        fontWeight: FontWeight.w500,
        color: textColor.withValues(alpha: 0.9),
        height: 1.3,
      ),
      maxLines: isGrid ? 3 : 3,
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
      label = isGrid ? '$timeStr • $updater' : '$timeStr • oleh $updater';
    } else if (timeStr.isNotEmpty) {
      label = timeStr;
    } else if (updater.isNotEmpty) {
      label = isGrid ? updater : 'oleh $updater';
    }

    if (label.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 10.5,
            color: textColor.withValues(alpha: 0.65),
          ),
          const SizedBox(width: 3.5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isGrid ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.70),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
