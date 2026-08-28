import 'package:flutter/material.dart';

class BookRatingPicker extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;

  const BookRatingPicker({
    super.key,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
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
        children: [
          const Text(
            'Personal Rating',
            style: TextStyle(
              color: Color(0xFF6B4454),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final isFilled = index < rating;
              return IconButton(
                splashRadius: 22,
                icon: Icon(
                  isFilled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFilled ? const Color(0xFFFF8DA1) : const Color(0xFFD6B9C3),
                  size: 30,
                ),
                onPressed: () {
                  onRatingChanged(index + 1);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
