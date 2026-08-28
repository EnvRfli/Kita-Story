import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BookGenrePicker extends StatelessWidget {
  final TextEditingController controller;
  final List<String> selectedGenres;
  final List<String> availableGenres;
  final ValueChanged<String> onToggleGenre;
  final ValueChanged<String> onAddNewGenre;

  const BookGenrePicker({
    super.key,
    required this.controller,
    required this.selectedGenres,
    required this.availableGenres,
    required this.onToggleGenre,
    required this.onAddNewGenre,
  });

  @override
  Widget build(BuildContext context) {
    // Combine available genres and any custom selected ones
    final allDisplayGenres = <String>{
      ...availableGenres,
      ...selectedGenres,
    }.toList();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Genres',
                style: TextStyle(
                  color: Color(0xFF6B4454),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (selectedGenres.isNotEmpty)
                Text(
                  '${selectedGenres.length} terpilih',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B6B8A),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Pilih genre dari database atau ketik untuk menambah baru.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),

          // Available & Selected Genre Chips
          if (allDisplayGenres.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allDisplayGenres.map((g) {
                final isSelected = selectedGenres.contains(g);
                return InkWell(
                  onTap: () => onToggleGenre(g),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6B4454)
                          : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6B4454)
                            : const Color(0xFFEADBDF),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          g,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6B4454),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Add New Genre Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B4454)),
                  onSubmitted: (text) => onAddNewGenre(text),
                  decoration: InputDecoration(
                    hintText: 'Ketik genre baru...',
                    hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFFEADBDF), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFFEADBDF), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFF3B6B8A), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => onAddNewGenre(controller.text),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B6B8A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
