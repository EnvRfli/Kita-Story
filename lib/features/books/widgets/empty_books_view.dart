import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class EmptyBooksView extends StatelessWidget {
  final VoidCallback? onAddPressed;

  const EmptyBooksView({
    super.key,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.softPink.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 64,
                color: Color(0xFF6B4454),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Buku',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4454),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mulai petualangan membacamu bersama pasangan dengan menambahkan buku pertama!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (onAddPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text(
                  'Tambah Buku',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B6B8A),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
