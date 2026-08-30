import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../models/vacation_model.dart';
import '../models/vacation_activity_model.dart';
import '../providers/vacation_provider.dart';
import '../widgets/vacation_timeline_card.dart';
import '../widgets/activity_detail_bottom_sheet.dart';
import 'add_vacation_screen.dart';

class VacationDetailScreen extends StatefulWidget {
  final String vacationId;
  final bool isReadOnly;

  const VacationDetailScreen({
    super.key,
    required this.vacationId,
    this.isReadOnly = false,
  });

  @override
  State<VacationDetailScreen> createState() => _VacationDetailScreenState();
}

class _VacationDetailScreenState extends State<VacationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VacationProvider>().loadVacationDetail(widget.vacationId);
    });
  }

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  String _formatDayPill(DateTime dt) {
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _handleDeleteVacation(VacationModel vacation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Jadwal Liburan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus liburan "${vacation.title}" beserta seluruh agendanya?',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await context.read<VacationProvider>().deleteVacation(vacation.id);
        if (mounted) {
          AppSnackBar.success(context, 'Jadwal liburan berhasil dihapus!');
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.error(context, 'Gagal menghapus liburan: $e');
        }
      }
    }
  }

  void _onOpenActivityDetail(
    VacationActivityModel activity,
    VacationModel vacation,
  ) {
    ActivityDetailBottomSheet.show(
      context: context,
      activity: activity,
      isReadOnly: widget.isReadOnly,
      onEdit: () {
        context.push(
          '/add-vacation-activity',
          extra: {
            'vacationId': vacation.id,
            'initialActivity': activity,
            'defaultDate': activity.activityDate,
            'vacationTitle': vacation.title,
          },
        );
      },
      onDelete: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Hapus Aktivitas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            content: Text(
              'Apakah Anda yakin ingin menghapus kegiatan "${activity.title}"?',
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Hapus',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        if (confirm == true && mounted) {
          try {
            await context
                .read<VacationProvider>()
                .deleteActivity(activity.id, vacation.id);
            if (mounted) {
              AppSnackBar.success(context, 'Aktivitas berhasil dihapus!');
            }
          } catch (e) {
            if (mounted) {
              AppSnackBar.error(context, 'Gagal menghapus aktivitas: $e');
            }
          }
        }
      },
      onToggleComplete: () async {
        try {
          await context.read<VacationProvider>().toggleActivityCompleted(
                activity.id,
                !activity.isCompleted,
                vacationId: vacation.id,
                activityTitle: activity.title,
              );
          if (mounted) {
            AppSnackBar.success(
              context,
              !activity.isCompleted
                  ? 'Kegiatan ditandai selesai! 🎉 (+2 Poin)'
                  : 'Status kegiatan diperbarui.',
            );
          }
        } catch (e) {
          if (mounted) {
            AppSnackBar.error(context, 'Gagal memperbarui status kegiatan: $e');
          }
        }
      },
    );
  }

  void _showActionMenu(BuildContext context, VacationModel vacation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              title: const Text(
                'Edit Liburan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
              subtitle: const Text(
                'Ubah judul, deskripsi, dan rentang tanggal liburan',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddVacationScreen(
                      initialVacation: vacation,
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 8, color: Color(0xFFF1F5F9)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              title: const Text(
                'Hapus Liburan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFFEF4444),
                ),
              ),
              subtitle: const Text(
                'Hapus jadwal liburan beserta seluruh agendanya',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _handleDeleteVacation(vacation);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer<VacationProvider>(
        builder: (context, provider, child) {
          final vacation = provider.currentVacation;

          if (provider.isLoadingDetail || vacation == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D8BF0)),
            );
          }

          final allDays = vacation.allDays;
          final selectedDay = provider.selectedDetailDay ?? vacation.startDate;
          final activities = provider.activitiesForSelectedDay;

          return Stack(
            children: [
              // 1. Background Image covering full screen (Ubah.png)
              Positioned.fill(
                child: Image.asset(
                  'lib/assets/background/Ubah.png',
                  fit: BoxFit.cover,
                ),
              ),

              // 2. Main Content inside SafeArea
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Circular Back Button
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x10000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFF1E293B),
                                size: 20,
                              ),
                            ),
                          ),

                          // Actions: 3-Dots Menu Button showing Modal Bottom Sheet
                          if (!widget.isReadOnly)
                            GestureDetector(
                              onTap: () => _showActionMenu(context, vacation),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x10000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.more_vert_rounded,
                                  color: Color(0xFF1E293B),
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Header Info: Title & Description (Increased top & bottom margin)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vacation.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (vacation.description != null &&
                              vacation.description!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              vacation.description!.trim(),
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF64748B),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Horizontal Days Chips Selector (Compact size with gradientBiru)
                    SizedBox(
                      height: 35,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: allDays.length,
                        itemBuilder: (context, index) {
                          final day = allDays[index];
                          final isSelected = day.year == selectedDay.year &&
                              day.month == selectedDay.month &&
                              day.day == selectedDay.day;

                          return GestureDetector(
                            onTap: () => provider.setSelectedDetailDay(day),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? AppColors.gradientBiru
                                    : null,
                                color: isSelected ? null : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? const Color(0xFF6155F5)
                                            .withValues(alpha: 0.35)
                                        : Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _formatDayPill(day),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF334155),
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Timeline Activities List
                    Expanded(
                      child: activities.isEmpty
                          ? _buildEmptyActivities(selectedDay)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                              itemCount: activities.length,
                              itemBuilder: (context, index) {
                                final activity = activities[index];
                                return VacationTimelineCard(
                                  activity: activity,
                                  activityIndex: index,
                                  isFirst: index == 0,
                                  isLast: index == activities.length - 1,
                                  onTap: () => _onOpenActivityDetail(
                                      activity, vacation),
                                );
                              },
                            ),
                    ),

                    // Bottom Button: Tambah Aktivitas (with gradientPartnerBlue)
                    if (!widget.isReadOnly)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPartnerBlue,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0088FF)
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                context.push(
                                  '/add-vacation-activity',
                                  extra: {
                                    'vacationId': vacation.id,
                                    'defaultDate': selectedDay,
                                    'vacationTitle': vacation.title,
                                  },
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: const Center(
                                child: Text(
                                  'Tambah Aktivitas',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyActivities(DateTime day) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '🏖️',
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Belum Ada Aktivitas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Susun agenda kegiatan untuk tanggal ${_formatDayPill(day)} dengan menekan tombol Tambah Aktivitas di bawah.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
