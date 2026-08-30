import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../models/note_model.dart';
import '../utils/note_format_helper.dart';

class NoteImportResult {
  final ParsedNoteData data;
  final bool replaceExisting;
  final bool updateTitle;

  const NoteImportResult({
    required this.data,
    required this.replaceExisting,
    required this.updateTitle,
  });
}

class NoteImportBottomSheet extends StatefulWidget {
  final NoteModel? currentNote;

  const NoteImportBottomSheet({
    super.key,
    this.currentNote,
  });

  static Future<NoteImportResult?> show(
    BuildContext context, {
    NoteModel? currentNote,
  }) {
    return showModalBottomSheet<NoteImportResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NoteImportBottomSheet(currentNote: currentNote),
    );
  }

  @override
  State<NoteImportBottomSheet> createState() => _NoteImportBottomSheetState();
}

class _NoteImportBottomSheetState extends State<NoteImportBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  bool _replaceExisting = false;
  bool _updateTitle = true;
  ParsedNoteData _parsedData = const ParsedNoteData();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final parsed = NoteFormatHelper.parseImportText(_textController.text);
    setState(() {
      _parsedData = parsed;
    });
  }

  Future<void> _pasteFromClipboard() async {
    HapticFeedback.lightImpact();
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      final text = clipboardData.text!;
      _textController.text = text;
      _onTextChanged();
      if (mounted) {
        AppSnackBar.info(context, 'Teks berhasil ditempel dari clipboard 📋');
      }
    } else {
      if (mounted) {
        AppSnackBar.error(context, 'Clipboard kosong atau tidak berisi teks');
      }
    }
  }

  void _handleImport() {
    if (_textController.text.trim().isEmpty) {
      AppSnackBar.error(
          context, 'Masukkan atau tempel teks catatan terlebih dahulu');
      return;
    }

    if (_parsedData.checklistItems.isEmpty &&
        (_parsedData.textContent == null ||
            _parsedData.textContent!.trim().isEmpty)) {
      AppSnackBar.error(
          context, 'Tidak ada item catatan yang terdeteksi dari teks');
      return;
    }

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(
      NoteImportResult(
        data: _parsedData,
        replaceExisting: _replaceExisting,
        updateTitle: _updateTitle && _parsedData.title != null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final totalItems = _parsedData.checklistItems.length;
    final checkedCount =
        _parsedData.checklistItems.where((i) => i.isChecked).length;
    final uncheckedCount = totalItems - checkedCount;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Title & Paste Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.file_download_outlined,
                    color: AppColors.primaryPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Impor Catatan Teks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste_rounded, size: 16),
                  label: const Text(
                    'Tempel',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: AppColors.primaryPurple.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. Format Guidance Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Format teks yang didukung:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: '• Baris 1: *Judul Catatan* (opsional)\n',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: '• ',
                        ),
                        TextSpan(
                          text: '- ~Item checklist selesai~\n',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: '• ',
                        ),
                        TextSpan(
                          text: '- Item checklist belum selesai',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Input Text Area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 6,
                minLines: 4,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF1E293B),
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  hintText:
                      'Tempel atau ketik catatan di sini...\n\nContoh:\n*Daftar Belanja*\n- ~Susu UHT~\n- Telur 1 pack\n- Roti gandum',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 5. Detection Badge Preview
            if (_textController.text.trim().isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFBBF7D0),
                    width: 1.1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF16A34A),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _parsedData.title != null
                            ? 'Judul: "${_parsedData.title}" • $totalItems item ($checkedCount selesai, $uncheckedCount belum)'
                            : '$totalItems item checklist terdeteksi ($checkedCount selesai, $uncheckedCount belum)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 6. Options Section (if modifying an existing note)
            if (widget.currentNote != null) ...[
              // Replace vs Append
              InkWell(
                onTap: () {
                  setState(() => _replaceExisting = !_replaceExisting);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _replaceExisting
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: _replaceExisting
                            ? AppColors.primaryPurple
                            : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Ganti seluruh item yang ada saat ini',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_parsedData.title != null) ...[
                const SizedBox(height: 4),
                InkWell(
                  onTap: () {
                    setState(() => _updateTitle = !_updateTitle);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          _updateTitle
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: _updateTitle
                              ? AppColors.primaryPurple
                              : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Perbarui judul catatan menjadi "${_parsedData.title}"',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
            ],

            // 7. Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _handleImport,
                    icon: const Icon(
                      Icons.file_download_done_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Impor ke Catatan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
