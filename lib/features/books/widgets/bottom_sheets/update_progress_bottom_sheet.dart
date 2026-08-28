import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class UpdateProgressBottomSheet extends StatefulWidget {
  final int initialPage;
  final int totalPages;
  final Future<void> Function(int newPage) onSave;

  const UpdateProgressBottomSheet({
    super.key,
    required this.initialPage,
    required this.totalPages,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required int initialPage,
    required int totalPages,
    required Future<void> Function(int newPage) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => UpdateProgressBottomSheet(
        initialPage: initialPage,
        totalPages: totalPages,
        onSave: onSave,
      ),
    );
  }

  @override
  State<UpdateProgressBottomSheet> createState() =>
      _UpdateProgressBottomSheetState();
}

class _UpdateProgressBottomSheetState extends State<UpdateProgressBottomSheet> {
  late final TextEditingController _controller;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPage.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateInput(String value) {
    final page = int.tryParse(value.trim());
    if (page == null) {
      setState(() => _errorMessage = 'Masukkan angka halaman yang valid');
    } else if (page < 0) {
      setState(() => _errorMessage = 'Halaman tidak boleh kurang dari 0');
    } else if (widget.totalPages > 0 && page > widget.totalPages) {
      setState(() => _errorMessage =
          'Halaman ($page) tidak boleh melebihi total halaman (${widget.totalPages})');
    } else {
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
    }
  }

  Future<void> _handleSave() async {
    final page = int.tryParse(_controller.text.trim());
    if (page == null) {
      setState(() => _errorMessage = 'Masukkan angka halaman yang valid');
      return;
    }
    if (page < 0) {
      setState(() => _errorMessage = 'Halaman tidak boleh kurang dari 0');
      return;
    }
    if (widget.totalPages > 0 && page > widget.totalPages) {
      setState(() => _errorMessage =
          'Halaman tidak boleh melebihi total halaman (${widget.totalPages})');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    await widget.onSave(page);
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
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Update Progres Membaca',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B4454),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total halaman buku: ${widget.totalPages}',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            onChanged: _validateInput,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B4454),
            ),
            decoration: InputDecoration(
              hintText: 'Halaman saat ini',
              hintStyle: const TextStyle(color: Colors.black26, fontSize: 16),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _errorMessage != null
                      ? const Color(0xFFD9534F)
                      : const Color(0xFFEADBDF),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _errorMessage != null
                      ? const Color(0xFFD9534F)
                      : const Color(0xFFEADBDF),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _errorMessage != null
                      ? const Color(0xFFD9534F)
                      : const Color(0xFF3B6B8A),
                  width: 1.5,
                ),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFD9534F), size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFD9534F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
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
                elevation: 0,
              ),
              onPressed: (_isSaving || _errorMessage != null) ? null : _handleSave,
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
                      'Simpan Progres',
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
