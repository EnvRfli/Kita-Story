import 'package:flutter/material.dart';
import 'dart:math' as math;

class SudokuNumPad extends StatelessWidget {
  final Function(int) onNumberSelected;
  final VoidCallback onErase;
  final VoidCallback onHint;
  final int hintsLeft;
  final bool Function(int) isNumberCompleted;

  const SudokuNumPad({
    super.key,
    required this.onNumberSelected,
    required this.onErase,
    required this.onHint,
    required this.hintsLeft,
    required this.isNumberCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Number Row 1-5
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final num = index + 1;
            return _buildNumButton(num);
          }),
        ),
        const SizedBox(height: 12),
        // Number Row 6-9
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            final num = index + 6;
            return _buildNumButton(num);
          }),
        ),
        const SizedBox(height: 24),
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'Hapus',
                icon: Icons.delete_outline_rounded,
                color: const Color(0xFFFF4D4F), // Red
                onTap: onErase,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                label: 'Hint',
                icon: Icons.lightbulb_outline_rounded,
                color: const Color(0xFF0088FF), // Blue
                onTap: onHint,
                badgeCount: hintsLeft,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildNumButton(int number) {
    bool isCompleted = isNumberCompleted(number);
    return _SudokuNumButton(
      number: number,
      isCompleted: isCompleted,
      onTap: () => onNumberSelected(number),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _SudokuNumButton extends StatefulWidget {
  final int number;
  final bool isCompleted;
  final VoidCallback onTap;

  const _SudokuNumButton({
    required this.number,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  State<_SudokuNumButton> createState() => _SudokuNumButtonState();
}

class _SudokuNumButtonState extends State<_SudokuNumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _jiggleController;

  @override
  void initState() {
    super.initState();
    _jiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(_SudokuNumButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _jiggleController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _jiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isCompleted ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _jiggleController,
        builder: (context, child) {
          // Animasi Jiggle: rotasi kecil kiri-kanan menggunakan gelombang sinus (3 putaran = 1.5 kocokan penuh)
          final jiggle = math.sin(_jiggleController.value * math.pi * 3) * 0.15;
          // Animasi Scale: membesar sedikit di awal lalu kembali normal
          final scale = 1.0 + math.sin(_jiggleController.value * math.pi) * 0.15;

          return Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Transform.rotate(
              angle: jiggle,
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isCompleted ? const Color(0xFFF8FAFC) : Colors.white,
            borderRadius: BorderRadius.circular(widget.isCompleted ? 12 : 8),
            border: Border.all(
              color: widget.isCompleted
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFFE2E8F0),
              width: widget.isCompleted ? 0.5 : 1.1,
            ),
            boxShadow: widget.isCompleted
                ? [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.0),
                      blurRadius: 0,
                      offset: const Offset(0, 0),
                    )
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            style: TextStyle(
              fontSize: widget.isCompleted ? 16 : 22,
              fontWeight:
                  widget.isCompleted ? FontWeight.w500 : FontWeight.w600,
              color: widget.isCompleted
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF1E293B),
            ),
            child: Text(widget.number.toString()),
          ),
        ),
      ),
    );
  }
}
