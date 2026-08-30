import 'package:flutter/material.dart';

class NoteColorPicker extends StatelessWidget {
  final String selectedColor; // 'pink', 'yellow', 'orange', 'green', 'blue', 'purple'
  final ValueChanged<String> onColorSelected;

  const NoteColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  static const List<Map<String, dynamic>> colors = [
    {'id': 'pink', 'color': Color(0xFFFF94B4), 'label': 'Pink'},
    {'id': 'yellow', 'color': Color(0xFFFFD166), 'label': 'Kuning'},
    {'id': 'orange', 'color': Color(0xFFFFA07A), 'label': 'Oranye'},
    {'id': 'green', 'color': Color(0xFFC4D685), 'label': 'Hijau'},
    {'id': 'blue', 'color': Color(0xFF90CAF9), 'label': 'Biru'},
    {'id': 'purple', 'color': Color(0xFFCE93D8), 'label': 'Ungu'},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: colors.map((item) {
        final id = item['id'] as String;
        final color = item['color'] as Color;
        final isSelected = selectedColor == id;

        return GestureDetector(
          onTap: () => onColorSelected(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isSelected ? 0.6 : 0.25),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
