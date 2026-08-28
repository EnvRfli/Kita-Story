import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/book_model.dart';

class BookDetailHeader extends StatelessWidget {
  final BookModel book;
  final List<String> genres;
  final VoidCallback onEditBook;

  const BookDetailHeader({
    super.key,
    required this.book,
    required this.genres,
    required this.onEditBook,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cover with edit button overlay
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomRight,
          children: [
            Container(
              height: 220,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(Icons.menu_book, size: 60, color: Color(0xFFD6B9C3)),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.menu_book_rounded, size: 60, color: Color(0xFFD6B9C3)),
                    ),
            ),
            Positioned(
              right: -8,
              bottom: -8,
              child: InkWell(
                onTap: onEditBook,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF6B4454),
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            book.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B4454),
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Author
        if (book.author != null && book.author!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            book.author!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Rating Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8EC),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final rating = book.personalRating ?? 0;
              final isFilled = index < rating;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  isFilled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFilled ? const Color(0xFFFF8DA1) : const Color(0xFFD6B9C3),
                  size: 20,
                ),
              );
            }),
          ),
        ),

        // Genres
        if (genres.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: genres.map((g) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lavender.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    g,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B4454),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
