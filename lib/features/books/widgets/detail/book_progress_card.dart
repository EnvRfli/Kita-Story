import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/book_model.dart';

class BookProgressCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onUpdateProgress;

  const BookProgressCard({
    super.key,
    required this.book,
    required this.onUpdateProgress,
  });

  @override
  Widget build(BuildContext context) {
    final progress = book.totalPages > 0
        ? (book.currentPage / book.totalPages).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'READING PROGRESS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Halaman ${book.currentPage}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4454),
                        ),
                      ),
                      Text(
                        ' / ${book.totalPages}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: onUpdateProgress,
                child: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF6B4454),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF3E8EC),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF3B6B8A)),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).toInt()}% Selesai Dibaca',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B6B8A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
