import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/book_model.dart';

class BookGridCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback? onTap;

  const BookGridCard({
    super.key,
    required this.book,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = book.totalPages > 0
        ? (book.currentPage / book.totalPages).clamp(0.0, 1.0)
        : 0.0;
    final isCompleted = progress >= 1.0;
    final hasStarted = book.currentPage > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF3E4EA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4454).withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cover Image with Floating Badges
              Expanded(
                flex: 12,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(21),
                      ),
                      child: book.coverUrl != null &&
                              book.coverUrl!.trim().isNotEmpty
                          ? Image.network(
                              book.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildCoverPlaceholder(),
                            )
                          : _buildCoverPlaceholder(),
                    ),

                    // Subtle Bottom Gradient on Cover
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 45,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.25),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top-Left Status Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFF2E7D32).withValues(alpha: 0.88)
                              : hasStarted
                                  ? const Color(0xFF3B6B8A)
                                      .withValues(alpha: 0.88)
                                  : Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : hasStarted
                                      ? Icons.auto_stories_rounded
                                      : Icons.bookmark_border_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCompleted
                                  ? 'Selesai'
                                  : hasStarted
                                      ? '${(progress * 100).toInt()}%'
                                      : 'Baru',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Top-Right Rating Badge
                    if (book.personalRating != null &&
                        book.personalRating! > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB800),
                                size: 13,
                              ),
                              const SizedBox(width: 2.5),
                              Text(
                                '${book.personalRating}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B4454),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. Info Section (Title, Author, Progress)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B4454),
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Author
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 12,
                          color: Color(0xFF9E7787),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            (book.author != null && book.author!.isNotEmpty)
                                ? book.author!
                                : 'Penulis tidak dikenal',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9E7787),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Reading Progress Track
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5.5,
                        backgroundColor: const Color(0xFFF3E8EC),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF3B6B8A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Pages summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${book.currentPage} / ${book.totalPages} hlm',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF3B6B8A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFEEF3),
            Color(0xFFEAD4DD),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Color(0xFF6B4454),
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
