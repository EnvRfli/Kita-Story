import 'package:flutter/foundation.dart';

import 'tetris_game_state.dart';
import 'tetromino.dart';

/// Result of one movement, rotation, or lock action.
@immutable
class TetrisActionResult {
  TetrisActionResult({
    required this.state,
    required this.didMove,
    this.pieceLocked = false,
    List<int> clearedRows = const [],
    this.scoreGained = 0,
    this.isGameOver = false,
    this.lockedType,
  }) : clearedRows = List.unmodifiable(clearedRows);

  final TetrisGameState state;
  final bool didMove;
  final bool pieceLocked;
  final List<int> clearedRows;
  final int scoreGained;
  final bool isGameOver;
  final TetrominoType? lockedType;
}
