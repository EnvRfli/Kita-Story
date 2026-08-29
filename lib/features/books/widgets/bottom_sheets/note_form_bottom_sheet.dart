import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';

class NoteFormBottomSheet extends StatefulWidget {
  final Future<void> Function(int pageNumber, String noteText) onSave;

  const NoteFormBottomSheet({
    super.key,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required Future<void> Function(int pageNumber, String noteText) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => NoteFormBottomSheet(
        onSave: onSave,
      ),
    );
  }

  @override
  State<NoteFormBottomSheet> createState() => _NoteFormBottomSheetState();
}

class _NoteFormBottomSheetState extends State<NoteFormBottomSheet> {
  final _pageController = TextEditingController();
  final _textController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final page = int.tryParse(_pageController.text.trim()) ?? 0;
    final text = _textController.text.trim();

    if (text.isEmpty) {
      AppSnackBar.warning(context, 'Catatan tidak boleh kosong');
      return;
    }

    setState(() => _isSaving = true);
    await widget.onSave(page, text);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tambah Shared Note',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B4454),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Catat kutipan atau momen berkesan di halaman tertentu.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _pageController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B4454),
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Nomor Halaman (Contoh: 142)',
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
              prefixIcon: const Icon(Icons.bookmark_outline_rounded,
                  color: Color(0xFF6B4454), size: 20),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFEADBDF), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFEADBDF), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF3B6B8A), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _textController,
            maxLines: 3,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B4454),
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: 'Kutipan / Catatan...',
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFEADBDF), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFEADBDF), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFEADBDF), width: 1),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B6B8A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Simpan Catatan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
