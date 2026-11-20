import 'package:flutter/material.dart';

import '../models/tetromino.dart';

class TetrisPalette {
  static const Map<TetrominoType, List<Color>> gradients = {
    TetrominoType.i: [Color(0xFF22D3EE), Color(0xFF0284C7)],
    TetrominoType.o: [Color(0xFFFFE066), Color(0xFFF59E0B)],
    TetrominoType.t: [Color(0xFFC084FC), Color(0xFF7C3AED)],
    TetrominoType.s: [Color(0xFF86EFAC), Color(0xFF16A34A)],
    TetrominoType.z: [Color(0xFFFDA4AF), Color(0xFFE11D48)],
    TetrominoType.j: [Color(0xFF93C5FD), Color(0xFF2563EB)],
    TetrominoType.l: [Color(0xFFFDBA74), Color(0xFFEA580C)],
  };

  static LinearGradient gradientFor(TetrominoType type) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradients[type]!,
      );

  static Color solidFor(TetrominoType type) => gradients[type]!.first;

  static Color deepColorFor(TetrominoType type) => gradients[type]!.last;
}

class TetrisMino extends StatelessWidget {
  const TetrisMino({
    super.key,
    required this.type,
    required this.size,
    this.isGhost = false,
    this.opacity = 1,
  });

  final TetrominoType type;
  final double size;
  final bool isGhost;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.22);
    final solid = TetrisPalette.solidFor(type);

    if (isGhost) {
      return ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: solid.withValues(alpha: 0.10),
            borderRadius: radius,
            border: Border.all(
              color: solid.withValues(alpha: 0.45),
              width: (size * 0.055).clamp(1.0, 3.0),
            ),
          ),
        ),
      );
    }

    return ExcludeSemantics(
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: TetrisPalette.gradientFor(type),
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: solid.withValues(alpha: 0.26),
                blurRadius: size * 0.18,
                offset: Offset(0, size * 0.08),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: size * 0.14,
                top: size * 0.12,
                width: size * 0.48,
                child: Container(
                  height: size * 0.16,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.36),
                    borderRadius: BorderRadius.circular(size * 0.08),
                  ),
                ),
              ),
              Positioned(
                right: size * 0.12,
                bottom: size * 0.12,
                child: Container(
                  width: size * 0.12,
                  height: size * 0.12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TetrisEmptyCell extends StatelessWidget {
  const TetrisEmptyCell({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(size * 0.20),
            border: Border.all(
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.55),
              width: 0.8,
            ),
          ),
        ),
      );
}
