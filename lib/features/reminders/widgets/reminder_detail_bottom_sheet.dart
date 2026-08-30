import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../models/reminder_model.dart';
import '../providers/reminder_provider.dart';

class ReminderDetailBottomSheet extends StatefulWidget {
  final List<ReminderModel> reminders;
  final int initialIndex;
  final bool isDailyPopup;
  final bool isReadOnly;

  const ReminderDetailBottomSheet({
    super.key,
    required this.reminders,
    this.initialIndex = 0,
    this.isDailyPopup = false,
    this.isReadOnly = false,
  });

  static Future<void> show(
    BuildContext context, {
    required List<ReminderModel> reminders,
    int initialIndex = 0,
    bool isDailyPopup = false,
    bool isReadOnly = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReminderDetailBottomSheet(
        reminders: reminders,
        initialIndex: initialIndex,
        isDailyPopup: isDailyPopup,
        isReadOnly: isReadOnly,
      ),
    );
  }

  @override
  State<ReminderDetailBottomSheet> createState() =>
      _ReminderDetailBottomSheetState();
}

class _ReminderDetailBottomSheetState extends State<ReminderDetailBottomSheet> {
  late PageController _pageController;
  late int _currentIndex;
  bool _dontShowAgain = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete(ReminderModel reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hapus Pengingat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontSize: 17,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus pengingat "${reminder.title}"?',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = Provider.of<ReminderProvider>(context, listen: false);
      final success = await provider.deleteReminder(reminder.id);
      if (mounted) {
        Navigator.pop(context);
        if (success) {
          AppSnackBar.success(
            context,
            'Pengingat "${reminder.title}" berhasil dihapus!',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.reminders;
    if (list.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Grey Handle Bar
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header Title ("Pengingat")
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pengingat',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
              if (list.length > 1)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_currentIndex + 1} dari ${list.length}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          // Reminder Content (Single or Carousel)
          if (list.length == 1)
            _buildReminderContent(list[0])
          else
            SizedBox(
              height: 135,
              child: PageView.builder(
                controller: _pageController,
                itemCount: list.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (ctx, index) {
                  final reminder = list[index];
                  return _buildReminderContent(reminder);
                },
              ),
            ),
          const SizedBox(height: 16),

          // Action Buttons: "Ubah" (Blue) & "Hapus" (Red) - Only shown in Reminder List Screen
          if (!widget.isReadOnly && !widget.isDailyPopup)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0088FF), Color(0xFF0775D5)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF0088FF).withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final currentReminder = list[_currentIndex];
                          Navigator.pop(context);
                          context.push(
                            '/add-reminder',
                            extra: currentReminder,
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Text(
                            'Ubah',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF3B30), Color(0xFFE02424)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFFF3B30).withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleDelete(list[_currentIndex]),
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Text(
                            'Hapus',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // Daily Popup Checkbox: "Jangan ingatkan lagi hari ini"
          if (widget.isDailyPopup) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                setState(() => _dontShowAgain = !_dontShowAgain);
                if (_dontShowAgain) {
                  await Provider.of<ReminderProvider>(context, listen: false)
                      .setDontShowAgainToday();
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _dontShowAgain,
                        activeColor: const Color(0xFFFF7A00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) async {
                          setState(() => _dontShowAgain = val ?? false);
                          if (_dontShowAgain) {
                            await Provider.of<ReminderProvider>(
                              context,
                              listen: false,
                            ).setDontShowAgainToday();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Jangan ingatkan lagi hari ini',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderContent(ReminderModel reminder) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        Text(
          reminder.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),

        // Description
        Text(
          reminder.description?.isNotEmpty == true
              ? reminder.description!
              : 'Tidak ada deskripsi agenda',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),

        // Date & Countdown Pill Container (Orange border)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFF7A00),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7A00).withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFFFF7A00),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                reminder.formattedDate,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  reminder.countdownDetailedText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
