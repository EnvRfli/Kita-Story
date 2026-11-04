import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/poop_log_model.dart';
import '../providers/toilet_provider.dart';
import 'add_poop_bottom_sheet.dart';

class PoopDetailBottomSheet extends StatefulWidget {
  final PoopLogModel log;
  final bool isReadOnly;

  const PoopDetailBottomSheet({
    super.key,
    required this.log,
    this.isReadOnly = false,
  });

  static Future<void> show(
    BuildContext context, {
    required PoopLogModel log,
    bool isReadOnly = false,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => PoopDetailBottomSheet(
        log: log,
        isReadOnly: isReadOnly,
      ),
    );
  }

  @override
  State<PoopDetailBottomSheet> createState() => _PoopDetailBottomSheetState();
}

class _PoopDetailBottomSheetState extends State<PoopDetailBottomSheet> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Catatan',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus catatan di "${widget.log.locationName}"?',
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      final provider = context.read<ToiletProvider>();
      final success = await provider.deletePoopLog(widget.log.id);

      if (!mounted) return;
      setState(() => _isDeleting = false);

      if (success) {
        Navigator.of(context).pop();
        AppSnackBar.success(context, 'Catatan berhasil dihapus');
      } else {
        AppSnackBar.error(
          context,
          provider.errorMessage ?? 'Gagal menghapus catatan',
        );
      }
    }
  }

  void _handleEdit() {
    Navigator.of(context).pop();
    AddPoopBottomSheet.show(
      context,
      logToEdit: widget.log,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final myUid = auth.currentUserProfile?.id;
    final canModify = !widget.isReadOnly && widget.log.userId == myUid;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Handle Bar
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Icon Circle
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.log.stoolTypeBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    widget.log.stoolTypeEmoji,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1.0,
                    ),
                    strutStyle: const StrutStyle(
                      fontSize: 24,
                      height: 1.0,
                      forceStrutHeight: true,
                    ),
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Location Name & Condition Tag
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      widget.log.locationName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: widget.log.stoolTypeBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.log.stoolTypeShort,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: widget.log.stoolTypeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.log.locationAddress != null &&
                  widget.log.locationAddress!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    widget.log.locationAddress!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),

              // 4. Time
              Center(
                child: Text(
                  widget.log.formattedDateTime,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),

              // 5. Note (if any)
              if (widget.log.note != null && widget.log.note!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    widget.log.note!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                ),
              ],

              // 6. Open in Maps Button
              if (widget.log.hasCoordinates) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      LocationService.openMaps(
                        latitude: widget.log.latitude!,
                        longitude: widget.log.longitude!,
                        label: widget.log.locationName,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0088FF),
                      side: const BorderSide(
                        color: Color(0xFFBAE6FD),
                        width: 1.2,
                      ),
                      backgroundColor: const Color(0xFFF0F9FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.location_on_rounded, size: 17),
                    label: const Text(
                      'Lihat Lokasi di Peta',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],

              // 7. Edit & Delete Buttons
              if (canModify) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0088FF), Color(0xFF0775D5)],
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isDeleting ? null : _handleEdit,
                            borderRadius: BorderRadius.circular(13),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Ubah',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF3B30), Color(0xFFE02424)],
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isDeleting ? null : _handleDelete,
                            borderRadius: BorderRadius.circular(13),
                            child: Center(
                              child: _isDeleting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.white,
                                          size: 17,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Hapus',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
