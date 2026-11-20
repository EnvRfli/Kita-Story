import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/tetromino.dart';
import 'tetris_mino.dart';

class TetrisArtwork extends StatelessWidget {
  const TetrisArtwork({
    super.key,
    this.size = 120,
    this.showBackdrop = false,
  });

  final double size;
  final bool showBackdrop;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: size * 0.14,
            top: size * 0.16,
            child: Transform.rotate(
              angle: -0.42,
              child: _ArtPiece(
                type: TetrominoType.i,
                cell: size * 0.13,
              ),
            ),
          ),
          Positioned(
            right: size * 0.12,
            top: size * 0.06,
            child: Transform.rotate(
              angle: 0.24,
              child: _ArtPiece(
                type: TetrominoType.t,
                cell: size * 0.17,
              ),
            ),
          ),
          Positioned(
            left: size * 0.30,
            bottom: size * 0.08,
            child: Transform.rotate(
              angle: 0.18,
              child: _ArtPiece(
                type: TetrominoType.l,
                cell: size * 0.15,
              ),
            ),
          ),
          Positioned(
            right: size * 0.20,
            bottom: size * 0.18,
            child: Transform.rotate(
              angle: -0.12,
              child: _ArtPiece(
                type: TetrominoType.o,
                cell: size * 0.12,
              ),
            ),
          ),
          Positioned(
            left: size * 0.08,
            top: size * 0.05,
            child: _Sparkle(size: size * 0.055, color: const Color(0xFFFBBF24)),
          ),
          Positioned(
            right: size * 0.04,
            top: size * 0.42,
            child: _Sparkle(size: size * 0.04, color: const Color(0xFF38BDF8)),
          ),
        ],
      ),
    );

    if (!showBackdrop) return content;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.4),
          radius: 1.1,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF3E8FF),
            Color(0xFFE0F2FE),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Center(child: content),
    );
  }
}

class _ArtPiece extends StatelessWidget {
  const _ArtPiece({required this.type, required this.cell});

  final TetrominoType type;
  final double cell;

  @override
  Widget build(BuildContext context) {
    final cells = type.cellsForRotation(0);
    final width = type.widthForRotation(0) * cell;
    final height = type.heightForRotation(0) * cell;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          for (final shapeCell in cells)
            Positioned(
              left: shapeCell.col * cell,
              top: shapeCell.row * cell,
              child: TetrisMino(type: type, size: cell * 0.92),
            ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: math.pi / 4,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size * 0.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: size,
              ),
            ],
          ),
        ),
      );
}
