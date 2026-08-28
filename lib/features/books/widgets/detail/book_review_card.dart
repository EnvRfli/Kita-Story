import 'package:flutter/material.dart';

class BookReviewCard extends StatelessWidget {
  final String? review;
  final VoidCallback onEditReview;

  const BookReviewCard({
    super.key,
    this.review,
    required this.onEditReview,
  });

  @override
  Widget build(BuildContext context) {
    final hasReview = review != null && review!.trim().isNotEmpty;

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
              Row(
                children: const [
                  Icon(Icons.chat_bubble_outline_rounded,
                      color: Color(0xFF3B6B8A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Our Thoughts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4454),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onEditReview,
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined,
                      color: Color(0xFF3B6B8A), size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFF3B6B8A), width: 3),
              ),
            ),
            child: Text(
              hasReview ? '"$review"' : 'Belum ada review bersama. Tulis sekarang!',
              style: TextStyle(
                fontSize: 14,
                color: hasReview ? Colors.black87 : Colors.black45,
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
