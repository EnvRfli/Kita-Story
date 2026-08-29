import 'package:flutter/material.dart';

class BookReviewCard extends StatelessWidget {
  final int? rating;
  final String? review;
  final VoidCallback? onEditReview;

  const BookReviewCard({
    super.key,
    this.rating,
    this.review,
    this.onEditReview,
  });

  @override
  Widget build(BuildContext context) {
    final hasReview = review != null && review!.trim().isNotEmpty;
    final currentRating = rating ?? 5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFFFF7A00),
                    size: 19,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Review',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              if (onEditReview != null)
                InkWell(
                  onTap: onEditReview,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF64748B),
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Star Rating Row
          Row(
            children: List.generate(5, (index) {
              final isFilled = index < currentRating;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFilled
                      ? const Color(0xFFFFB800)
                      : const Color(0xFFCBD5E1),
                  size: 22,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          // Quote Text with Orange Left Border
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 10, top: 2, bottom: 2),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFFFF7A00), width: 2.5),
              ),
            ),
            child: Text(
              hasReview
                  ? '"$review"'
                  : '"Belum ada ulasan untuk buku ini. Ketuk ikon pensil untuk menulis ulasan!"',
              style: TextStyle(
                fontSize: 13,
                color: hasReview
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

