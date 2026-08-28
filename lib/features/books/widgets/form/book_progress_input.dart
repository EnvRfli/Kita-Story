import 'package:flutter/material.dart';

class BookProgressInput extends StatelessWidget {
  final TextEditingController currentPageController;
  final TextEditingController totalPagesController;
  final ValueChanged<String>? onChanged;

  const BookProgressInput({
    super.key,
    required this.currentPageController,
    required this.totalPagesController,
    this.onChanged,
  });

  int get _currentPage => int.tryParse(currentPageController.text.trim()) ?? 0;
  int get _totalPages => int.tryParse(totalPagesController.text.trim()) ?? 0;

  bool get _hasOverflowError =>
      _totalPages > 0 && _currentPage > _totalPages;
  bool get _hasNegativeError => _currentPage < 0 || _totalPages < 0;

  double get _progress {
    if (_totalPages <= 0) return 0.0;
    return (_currentPage / _totalPages).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reading Progress',
            style: TextStyle(
              color: Color(0xFF6B4454),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _buildPageInput(
                  title: 'Halaman Sekarang',
                  controller: currentPageController,
                  hint: '0',
                  hasError: _hasOverflowError || _currentPage < 0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                child: Text(
                  '/',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF6B4454).withValues(alpha: 0.3),
                  ),
                ),
              ),
              Expanded(
                child: _buildPageInput(
                  title: 'Total Halaman',
                  controller: totalPagesController,
                  hint: '0',
                  hasError: _totalPages < 0,
                ),
              ),
            ],
          ),
          if (_hasOverflowError) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFD9534F), size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Halaman sekarang ($_currentPage) melebihi total halaman ($_totalPages)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFD9534F),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (_hasNegativeError) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFD9534F), size: 14),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Nomor halaman tidak boleh kurang dari 0',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFD9534F),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF3E8EC),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF3B6B8A)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).toInt()}% Selesai',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3B6B8A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageInput({
    required String title,
    required TextEditingController controller,
    required String hint,
    bool hasError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B4454),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B4454),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 15),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFD9534F)
                    : const Color(0xFFEADBDF),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFD9534F)
                    : const Color(0xFFEADBDF),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFD9534F)
                    : const Color(0xFF3B6B8A),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
