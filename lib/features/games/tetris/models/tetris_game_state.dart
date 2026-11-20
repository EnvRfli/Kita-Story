import 'package:flutter/foundation.dart';

import 'tetromino.dart';

/// Immutable snapshot of one Tetris session.
@immutable
class TetrisGameState {
  TetrisGameState({
    required List<List<int?>> board,
    required this.activePiece,
    required List<TetrominoType> nextQueue,
    required this.score,
    required this.lines,
    required this.level,
    required this.piecesPlaced,
    required List<int> clearingRows,
    required this.isGameOver,
  })  : board = List.unmodifiable(
          board.map((row) => List<int?>.unmodifiable(row)),
        ),
        nextQueue = List.unmodifiable(nextQueue),
        clearingRows = List.unmodifiable(clearingRows);

  static const int columns = 10;
  static const int rows = 20;

  /// Board cells contain a [TetrominoType.index] or null when empty.
  final List<List<int?>> board;
  final TetrisPiece? activePiece;
  final List<TetrominoType> nextQueue;
  final int score;
  final int lines;
  final int level;
  final int piecesPlaced;

  /// Rows that are full and waiting for the clear animation.
  final List<int> clearingRows;
  final bool isGameOver;

  bool get isClearing => clearingRows.isNotEmpty;

  TetrominoType? typeAt(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= columns) return null;
    final value = board[row][col];
    if (value == null) return null;
    if (value < 0 || value >= TetrominoType.values.length) return null;
    return TetrominoType.values[value];
  }

  TetrisGameState copyWith({
    List<List<int?>>? board,
    TetrisPiece? activePiece,
    bool clearActivePiece = false,
    List<TetrominoType>? nextQueue,
    int? score,
    int? lines,
    int? level,
    int? piecesPlaced,
    List<int>? clearingRows,
    bool? isGameOver,
  }) =>
      TetrisGameState(
        board: board ?? this.board,
        activePiece:
            clearActivePiece ? null : (activePiece ?? this.activePiece),
        nextQueue: nextQueue ?? this.nextQueue,
        score: score ?? this.score,
        lines: lines ?? this.lines,
        level: level ?? this.level,
        piecesPlaced: piecesPlaced ?? this.piecesPlaced,
        clearingRows: clearingRows ?? this.clearingRows,
        isGameOver: isGameOver ?? this.isGameOver,
      );

  static List<List<int?>> emptyBoard() => List.generate(
        rows,
        (_) => List<int?>.filled(columns, null),
      );
}
