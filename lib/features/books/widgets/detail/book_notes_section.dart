import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BookNotesSection extends StatelessWidget {
  final List<Map<String, dynamic>> notes;
  final VoidCallback onAddNote;

  const BookNotesSection({
    super.key,
    required this.notes,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48 - 14) / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.sticky_note_2_outlined,
                  color: Color(0xFF6B4454), size: 20),
              SizedBox(width: 8),
              Text(
                'Shared Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4454),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              ...List.generate(notes.length, (index) {
                final note = notes[index];
                final noteText = (note['note_text'] as String?) ?? '';
                final pageNumber = note['page_number'];
                final bgColor = index % 2 == 0
                    ? AppColors.mintGreen.withValues(alpha: 0.35)
                    : AppColors.lavender.withValues(alpha: 0.55);

                return Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              pageNumber != null ? 'Hlm $pageNumber' : 'Note',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B4454),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.push_pin_rounded,
                            size: 14,
                            color: Color(0xFF6B4454),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '"$noteText"',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF333333),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              // Add Note Card
              InkWell(
                onTap: onAddNote,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: cardWidth,
                  height: 110,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.softPink,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD1DC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Color(0xFF6B4454),
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tambah Catatan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B4454),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
