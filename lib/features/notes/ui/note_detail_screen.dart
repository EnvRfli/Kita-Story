import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/note_model.dart';
import '../providers/note_provider.dart';
import '../utils/note_format_helper.dart';
import '../widgets/widgets.dart';

class NoteDetailScreen extends StatefulWidget {
  final NoteModel note;
  final bool isReadOnly;

  const NoteDetailScreen({
    super.key,
    required this.note,
    this.isReadOnly = false,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late NoteModel _currentNote;
  bool _isTogglingComplete = false;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _refreshNoteDetails();
  }

  Future<void> _refreshNoteDetails() async {
    final updated = await Provider.of<NoteProvider>(context, listen: false)
        .getNoteById(_currentNote.id);
    if (updated != null && mounted) {
      setState(() => _currentNote = updated);
    }
  }

  Future<void> _handleExportNote() async {
    HapticFeedback.mediumImpact();
    final text = NoteFormatHelper.exportNote(_currentNote);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    AppSnackBar.success(
      context,
      'Catatan berhasil disalin ke clipboard! 📋',
    );
  }

  Future<void> _handleImportNote() async {
    final result = await NoteImportBottomSheet.show(
      context,
      currentNote: _currentNote,
    );

    if (result == null || !mounted) return;

    final provider = Provider.of<NoteProvider>(context, listen: false);

    final title = result.updateTitle && result.data.title != null
        ? result.data.title!
        : _currentNote.title;

    if (_currentNote.isChecklist || result.data.isChecklist) {
      final List<Map<String, dynamic>> updatedChecklistItems = [];

      if (!result.replaceExisting) {
        // Keep existing items
        for (final item in _currentNote.items) {
          updatedChecklistItems.add({
            'item_text': item.itemText,
            'is_checked': item.isChecked,
            'checked_by': item.checkedBy,
          });
        }
      }

      // Add imported items
      for (final item in result.data.checklistItems) {
        updatedChecklistItems.add({
          'item_text': item.text,
          'is_checked': item.isChecked,
        });
      }

      final success = await provider.updateNote(
        _currentNote.id,
        title: title,
        type: 'checklist',
        color: _currentNote.color,
        isShared: _currentNote.isShared,
        partnerId: _currentNote.partnerId,
        checklistItems: updatedChecklistItems,
      );

      if (!mounted) return;
      if (success) {
        AppSnackBar.success(
          context,
          'Berhasil mengimpor ${result.data.checklistItems.length} item checklist! 🎉',
        );
        _refreshNoteDetails();
      } else {
        AppSnackBar.error(
          context,
          provider.errorMessage ?? 'Gagal mengimpor catatan',
        );
      }
    } else {
      // Text note
      final newContent = result.replaceExisting
          ? (result.data.textContent ?? '')
          : '${_currentNote.content ?? ''}\n${result.data.textContent ?? ''}'
              .trim();

      final success = await provider.updateNote(
        _currentNote.id,
        title: title,
        type: 'text',
        content: newContent,
        color: _currentNote.color,
        isShared: _currentNote.isShared,
        partnerId: _currentNote.partnerId,
      );

      if (!mounted) return;
      if (success) {
        AppSnackBar.success(
          context,
          'Isi catatan berhasil diperbarui dari teks impor! 🎉',
        );
        _refreshNoteDetails();
      } else {
        AppSnackBar.error(
          context,
          provider.errorMessage ?? 'Gagal mengimpor catatan',
        );
      }
    }
  }

  Future<void> _toggleNoteCompletion() async {
    final canEdit = !widget.isReadOnly || _currentNote.isShared;
    if (!canEdit || _isTogglingComplete) return;

    final willBeCompleted = !_currentNote.isCompleted;
    setState(() => _isTogglingComplete = true);

    final provider = Provider.of<NoteProvider>(context, listen: false);
    final success =
        await provider.markNoteCompleted(_currentNote.id, willBeCompleted);

    if (!mounted) return;
    setState(() => _isTogglingComplete = false);

    if (success) {
      setState(() {
        _currentNote = _currentNote.copyWith(
          isCompleted: willBeCompleted,
          completedAt: willBeCompleted ? DateTime.now() : null,
        );
      });

      if (willBeCompleted) {
        AppSnackBar.success(
          context,
          'Catatan selesai! Anda mendapatkan +10 Poin 🎉',
        );
      } else {
        AppSnackBar.info(
            context, 'Status catatan diubah menjadi aktif kembali');
      }
    }
  }

  Future<void> _handleToggleShareNote(AuthProvider authProvider) async {
    final partner = authProvider.partnerProfile;
    if (partner == null) {
      AppSnackBar.info(
        context,
        'Hubungkan akun dengan pasangan terlebih dahulu untuk berbagi catatan.',
      );
      return;
    }

    final willShare = !_currentNote.isShared;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              willShare ? Icons.favorite_rounded : Icons.lock_outline_rounded,
              color:
                  willShare ? const Color(0xFF0088FF) : const Color(0xFF64748B),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              willShare ? 'Bagikan Catatan' : 'Hentikan Berbagi',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Text(
          willShare
              ? 'Bagikan catatan "${_currentNote.title}" ke ${partner.name}? Kalian berdua dapat melihat dan mengedit bersama.'
              : 'Jadikan catatan "${_currentNote.title}" sebagai catatan pribadi kembali?',
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  willShare ? const Color(0xFF0088FF) : const Color(0xFF64748B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              willShare ? 'Bagikan' : 'Jadikan Pribadi',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      HapticFeedback.mediumImpact();
      final provider = Provider.of<NoteProvider>(context, listen: false);
      final success = await provider.toggleNoteShared(
        _currentNote.id,
        isShared: willShare,
        partnerId: willShare ? partner.id : null,
      );

      if (mounted) {
        if (success) {
          setState(() {
            _currentNote = _currentNote.copyWith(
              isShared: willShare,
              partnerId: willShare ? partner.id : null,
            );
          });
          AppSnackBar.success(
            context,
            willShare
                ? 'Catatan berhasil dibagikan ke ${partner.name}! 💕'
                : 'Catatan kini telah diubah menjadi pribadi.',
          );
        } else {
          AppSnackBar.error(
            context,
            provider.errorMessage ?? 'Gagal mengubah status berbagi catatan',
          );
        }
      }
    }
  }

  Future<void> _handleDeleteNote() async {
    final canEdit = !widget.isReadOnly || _currentNote.isShared;
    if (!canEdit) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Catatan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus catatan "${_currentNote.title}"?',
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
      final provider = Provider.of<NoteProvider>(context, listen: false);
      final success = await provider.deleteNote(_currentNote.id);
      if (mounted) {
        if (success) {
          AppSnackBar.success(
            context,
            'Catatan "${_currentNote.title}" berhasil dihapus!',
          );
          context.pop();
        } else {
          AppSnackBar.error(
            context,
            provider.errorMessage ?? 'Gagal menghapus catatan',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = !widget.isReadOnly || _currentNote.isShared;
    final authProvider = Provider.of<AuthProvider>(context);
    final hasPartner = authProvider.partnerProfile != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF1E293B),
            size: 22,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Copy / Export Button (Available for all)
          IconButton(
            icon: const Icon(
              Icons.copy_rounded,
              color: Color(0xFF1E293B),
              size: 20,
            ),
            tooltip: 'Salin Format Teks / WhatsApp',
            onPressed: _handleExportNote,
          ),

          if (canEdit) ...[
            // Import Button
            IconButton(
              icon: const Icon(
                Icons.file_download_outlined,
                color: Color(0xFF1E293B),
                size: 22,
              ),
              tooltip: 'Impor Teks / WhatsApp',
              onPressed: _handleImportNote,
            ),

            // Quick Share / Unshare with Partner Button
            if (hasPartner)
              IconButton(
                icon: Icon(
                  _currentNote.isShared
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _currentNote.isShared
                      ? const Color(0xFF0088FF)
                      : const Color(0xFF64748B),
                  size: 22,
                ),
                tooltip: _currentNote.isShared
                    ? 'Catatan Bersama'
                    : 'Bagikan ke Pasangan',
                onPressed: () => _handleToggleShareNote(authProvider),
              ),

            // Delete Icon Button
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFFF3B30),
                size: 22,
              ),
              onPressed: _handleDeleteNote,
            ),

            // Edit Pencil Icon Button
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF1E293B),
                size: 22,
              ),
              onPressed: () async {
                await context.push('/add-note', extra: _currentNote);
                if (!mounted) return;
                _refreshNoteDetails();
              },
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Completion Banner (Apakah catatan ini sudah selesai? [Selesai])
              if (canEdit) ...[
                _buildCompletionBanner(),
                const SizedBox(height: 20),
              ],

              // 2. Shared Note Badge Pill
              if (_currentNote.isShared) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0088FF).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.people_rounded,
                        size: 13,
                        color: Color(0xFF0088FF),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Catatan Bersama (Kolaboratif)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0088FF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // 3. Note Title
              Text(
                _currentNote.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 18),

              // 4. Content: Checklist Items OR Text Body
              if (_currentNote.isChecklist)
                _buildChecklistSection()
              else
                _buildTextSection(),

              const SizedBox(height: 24),

              // 5. Quick Action Bar (Salin & Impor Teks)
              _buildQuickActionBar(canEdit),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionBar(bool canEdit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _handleExportNote,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: Color(0xFF475569),
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Salin Catatan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (canEdit) ...[
            Container(
              width: 1,
              height: 22,
              color: const Color(0xFFCBD5E1),
            ),
            Expanded(
              child: InkWell(
                onTap: _handleImportNote,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.file_download_outlined,
                        size: 18,
                        color: AppColors.primaryPurple,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Impor Teks',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionBanner() {
    final isDone = _currentNote.isCompleted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isDone
                  ? 'Catatan ini telah selesai! 🎉'
                  : 'Apakah catatan ini sudah selesai?',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isDone ? FontWeight.w700 : FontWeight.w600,
                color:
                    isDone ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _isTogglingComplete ? null : _toggleNoteCompletion,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7.5),
              decoration: BoxDecoration(
                color: isDone ? Colors.white : const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(10),
                border: isDone
                    ? Border.all(color: const Color(0xFFCBD5E1), width: 1.2)
                    : null,
                boxShadow: isDone
                    ? null
                    : [
                        BoxShadow(
                          color:
                              const Color(0xFF22C55E).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: _isTogglingComplete
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF22C55E),
                        ),
                      ),
                    )
                  : Text(
                      isDone ? 'Batalkan' : 'Selesai',
                      style: TextStyle(
                        color: isDone ? const Color(0xFF64748B) : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistSection() {
    final items = _currentNote.items;
    if (items.isEmpty) {
      return const Text(
        'Belum ada item checklist pada catatan ini.',
        style: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Color(0xFF94A3B8),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Live Interactive Checkbox
              InkWell(
                onTap: (!widget.isReadOnly || _currentNote.isShared)
                    ? () async {
                        final willBeChecked = !item.isChecked;
                        setState(() {
                          final updatedItems = _currentNote.items.map((i) {
                            if (i.id == item.id) {
                              return i.copyWith(isChecked: willBeChecked);
                            }
                            return i;
                          }).toList();
                          _currentNote =
                              _currentNote.copyWith(items: updatedItems);
                        });

                        await Provider.of<NoteProvider>(context, listen: false)
                            .toggleChecklistItem(
                          _currentNote.id,
                          item.id,
                          willBeChecked,
                        );
                      }
                    : null,
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color:
                        item.isChecked ? const Color(0xFF22C55E) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: item.isChecked
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFCBD5E1),
                      width: 1.6,
                    ),
                  ),
                  child: item.isChecked
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Item text (strikethrough when checked)
              Expanded(
                child: Text(
                  item.itemText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: item.isChecked
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF1E293B),
                    decoration:
                        item.isChecked ? TextDecoration.lineThrough : null,
                    decorationColor: const Color(0xFF94A3B8),
                    decorationThickness: 2.0,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextSection() {
    final text = _currentNote.content?.trim() ?? '';
    if (text.isEmpty) {
      return const Text(
        'Catatan kosong.',
        style: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Color(0xFF94A3B8),
        ),
      );
    }

    return SelectableText(
      text,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF334155),
        height: 1.6,
        letterSpacing: 0.1,
      ),
    );
  }
}
