import 'package:flutter/material.dart';

import '../models/tetromino.dart';
import 'tetris_mino.dart';

class TetrisNextPreview extends StatelessWidget {
  const TetrisNextPreview({
    super.key,
    required this.queue,
    this.previewCount = 3,
  });

  final List<TetrominoType> queue;
  final int previewCount;

  @override
  Widget build(BuildContext context) {
    final types = <TetrominoType?>[
      for (var index = 0; index < previewCount; index++)
        index < queue.length ? queue[index] : null,
    ];

    return Container(
      key: const ValueKey('tetris-next-preview'),
      width: 86,
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'NEXT',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          for (var index = 0; index < types.length; index++) ...[
            SizedBox(
              height: 24,
              child: types[index] == null
                  ? const Center(
                      child: Text(
                        '—',
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : _MiniTetromino(type: types[index]!),
            ),
            if (index < types.length - 1) const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }
}

class _MiniTetromino extends StatelessWidget {
  const _MiniTetromino({required this.type});

  final TetrominoType type;

  @override
  Widget build(BuildContext context) {
    const cell = 5.4;
    final width = type.widthForRotation(0);
    final offsetX = (4 - width) / 2;

    return SizedBox(
      width: 4 * cell,
      height: 2 * cell,
      child: Stack(
        children: [
          for (final shapeCell in type.cellsForRotation(0))
            Positioned(
              left: (shapeCell.col + offsetX) * cell,
              top: shapeCell.row * cell,
              child: TetrisMino(
                type: type,
                size: cell * 0.88,
              ),
            ),
        ],
      ),
    );
  }
}
