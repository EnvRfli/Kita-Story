import 'package:flutter/material.dart';

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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
    _controller = TextEditingController(
      text: widget.initialPage > 0 ? widget.initialPage.toString() : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateInput(String value) {
    if (value.trim().isEmpty) {
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
      return;
    }
    final page = int.tryParse(value.trim());
    if (page == null) {
      setState(() => _errorMessage = 'Masukkan angka halaman yang valid');
    } else if (page < 0) {
      setState(() => _errorMessage = 'Halaman tidak boleh kurang dari 0');
    } else if (widget.totalPages > 0 && page > widget.totalPages) {
      setState(() => _errorMessage =
          'Halaman tidak boleh melebihi total halaman (${widget.totalPages})');
    } else {
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
    }
  }

  Future<void> _handleSave() async {
    final text = _controller.text.trim();
    final page = text.isEmpty ? 0 : int.tryParse(text);
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Progress Baca',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 18),

          // Input Box with Suffix
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _errorMessage != null
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    onChanged: _validateInput,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                Text(
                  '/ ${widget.totalPages > 0 ? widget.totalPages : 100} Halaman',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Simpan Button (Gradient 0088FF -> 0775D5)
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF0088FF),
                  Color(0xFF0775D5),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0088FF).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap:
                    (_isSaving || _errorMessage != null) ? null : _handleSave,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Simpan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
