import 'package:flutter/material.dart';

class BookSynopsisCard extends StatelessWidget {
  final String? synopsis;

  const BookSynopsisCard({
    super.key,
    this.synopsis,
  });

  @override
  Widget build(BuildContext context) {
    if (synopsis == null || synopsis!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

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
            children: const [
              Icon(Icons.menu_book_rounded, color: Color(0xFF6B4454), size: 20),
              SizedBox(width: 8),
              Text(
                'Synopsis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4454),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            synopsis!,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
