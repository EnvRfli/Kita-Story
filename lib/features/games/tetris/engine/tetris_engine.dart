import 'dart:math';

import '../models/tetris_game_state.dart';
import '../models/tetris_move_result.dart';
import '../models/tetromino.dart';

/// Pure Tetris rules engine. It never touches Flutter, storage, or network.
class TetrisEngine {
  TetrisEngine({
    Random? random,
    List<TetrominoType> Function()? bagGenerator,
  })  : _random = random ?? Random(),
        _bagGenerator = bagGenerator;

  static const Map<int, int> lineScores = {
    0: 0,
    1: 100,
    2: 300,
    3: 500,
    4: 800,
  };

  static const List<int> gravityMilliseconds = [
    800,
    720,
    630,
    550,
    470,
    380,
    300,
    220,
    130,
    100,
    80,
    80,
    70,
    70,
    60,
    60,
    50,
    50,
    40,
    40,
  ];

  final Random _random;
  final List<TetrominoType> Function()? _bagGenerator;

  List<TetrominoType> generateBag() {
    final injected = _bagGenerator?.call();
    if (injected != null && injected.isNotEmpty) {
      return List<TetrominoType>.of(injected);
    }
    final bag = List<TetrominoType>.of(TetrominoType.values);
    bag.shuffle(_random);
    return bag;
  }

  TetrisGameState createInitialState() {
    final queue = <TetrominoType>[
      ...generateBag(),
      ...generateBag(),
    ];
    final base = TetrisGameState(
      board: TetrisGameState.emptyBoard(),
      activePiece: null,
      nextQueue: queue,
      score: 0,
      lines: 0,
      level: 1,
      piecesPlaced: 0,
      clearingRows: const [],
      isGameOver: false,
    );
    return _spawnNext(base);
  }

  TetrisActionResult moveLeft(TetrisGameState state) =>
      _move(state, rowDelta: 0, colDelta: -1);

  TetrisActionResult moveRight(TetrisGameState state) =>
      _move(state, rowDelta: 0, colDelta: 1);

  TetrisActionResult tick(TetrisGameState state) =>
      _move(state, rowDelta: 1, colDelta: 0);

  TetrisActionResult softDrop(TetrisGameState state) {
    final result = _move(state, rowDelta: 1, colDelta: 0);
    if (!result.didMove) return result;
    return TetrisActionResult(
      state: result.state.copyWith(score: result.state.score + 1),
      didMove: true,
      scoreGained: 1,
    );
  }

  TetrisActionResult rotate(TetrisGameState state) {
    final piece = state.activePiece;
    if (piece == null || state.isClearing || state.isGameOver) {
      return TetrisActionResult(state: state, didMove: false);
    }

    final newRotation = (piece.rotation + 1) % 4;
    const kicks = [
      [0, 0],
      [0, -1],
      [0, 1],
      [0, -2],
      [0, 2],
      [-1, 0],
      [-1, -1],
      [-1, 1],
      [1, 0],
    ];

    for (final kick in kicks) {
      final candidate = piece.copyWith(
        rotation: newRotation,
        row: piece.row + kick[0],
        col: piece.col + kick[1],
      );
      if (!collides(state, candidate)) {
        return TetrisActionResult(
          state: state.copyWith(activePiece: candidate),
          didMove: true,
        );
      }
    }

    return TetrisActionResult(state: state, didMove: false);
  }

  TetrisActionResult hardDrop(TetrisGameState state) {
    final piece = state.activePiece;
    if (piece == null || state.isClearing || state.isGameOver) {
      return TetrisActionResult(state: state, didMove: false);
    }

    final targetRow = ghostRow(state);
    final distance = targetRow - piece.row;
    final droppedPiece = piece.copyWith(row: targetRow);
    final result = _lockPiece(
      state,
      droppedPiece,
      bonusScore: distance * 2,
    );
    return TetrisActionResult(
      state: result.state,
      didMove: true,
      pieceLocked: true,
      clearedRows: result.clearedRows,
      scoreGained: result.scoreGained,
      isGameOver: result.isGameOver,
      lockedType: droppedPiece.type,
    );
  }

  TetrisActionResult lockPiece(TetrisGameState state) {
    final piece = state.activePiece;
    if (piece == null || state.isClearing || state.isGameOver) {
      return TetrisActionResult(state: state, didMove: false);
    }
    final result = _lockPiece(state, piece);
    return TetrisActionResult(
      state: result.state,
      didMove: true,
      pieceLocked: true,
      clearedRows: result.clearedRows,
      scoreGained: result.scoreGained,
      isGameOver: result.isGameOver,
      lockedType: piece.type,
    );
  }

  /// Removes the marked rows, then spawns the next piece.
  TetrisGameState completeClear(TetrisGameState state) {
    if (state.clearingRows.isEmpty) return state;

    final board = [
      for (final row in state.board) List<int?>.of(row),
    ];

    final rowsToRemove = List<int>.of(state.clearingRows)..sort();
    for (final row in rowsToRemove.reversed) {
      board.removeAt(row);
    }
    for (var index = 0; index < rowsToRemove.length; index++) {
      board.insert(0, List<int?>.filled(TetrisGameState.columns, null));
    }

    final cleared = state.copyWith(
      board: board,
      clearActivePiece: true,
      clearingRows: const [],
    );
    return _spawnNext(cleared);
  }

  int ghostRow(TetrisGameState state) {
    final piece = state.activePiece;
    if (piece == null) return 0;

    var row = piece.row;
    while (true) {
      final candidate = piece.copyWith(row: row + 1);
      if (collides(state, candidate)) return row;
      row++;
    }
  }

  bool collides(TetrisGameState state, TetrisPiece piece) {
    for (final cell in piece.cells) {
      if (cell.col < 0 ||
          cell.col >= TetrisGameState.columns ||
          cell.row < 0 ||
          cell.row >= TetrisGameState.rows) {
        return true;
      }
      if (state.board[cell.row][cell.col] != null) return true;
    }
    return false;
  }

  Duration gravityIntervalForLevel(int level) {
    final index = (level - 1).clamp(0, gravityMilliseconds.length - 1);
    return Duration(milliseconds: gravityMilliseconds[index]);
  }

  TetrisActionResult _move(
    TetrisGameState state, {
    required int rowDelta,
    required int colDelta,
  }) {
    final piece = state.activePiece;
    if (piece == null || state.isClearing || state.isGameOver) {
      return TetrisActionResult(state: state, didMove: false);
    }

    final candidate = piece.copyWith(
      row: piece.row + rowDelta,
      col: piece.col + colDelta,
    );
    if (collides(state, candidate)) {
      return TetrisActionResult(state: state, didMove: false);
    }

    return TetrisActionResult(
      state: state.copyWith(activePiece: candidate),
      didMove: true,
    );
  }

  TetrisGameState _spawnNext(TetrisGameState state) {
    final queue = List<TetrominoType>.of(state.nextQueue);
    if (queue.isEmpty) queue.addAll(generateBag());
    if (queue.length < 6) queue.addAll(generateBag());

    final nextType = queue.removeAt(0);
    if (queue.length < 6) queue.addAll(generateBag());

    final piece = TetrisPiece(
      type: nextType,
      rotation: 0,
      row: 0,
      col: (TetrisGameState.columns - nextType.widthForRotation(0)) ~/ 2,
    );
    final blocked = collides(state, piece);

    return state.copyWith(
      activePiece: blocked ? null : piece,
      clearActivePiece: blocked,
      nextQueue: queue,
      isGameOver: blocked,
    );
  }

  _LockResult _lockPiece(
    TetrisGameState state,
    TetrisPiece piece, {
    int bonusScore = 0,
  }) {
    final board = [
      for (final row in state.board) List<int?>.of(row),
    ];
    for (final cell in piece.cells) {
      board[cell.row][cell.col] = piece.type.index;
    }

    final clearedRows = <int>[];
    for (var row = 0; row < TetrisGameState.rows; row++) {
      if (board[row].every((cell) => cell != null)) {
        clearedRows.add(row);
      }
    }

    final baseScore = lineScores[clearedRows.length] ?? 0;
    final scoreGained = (baseScore * state.level) + bonusScore;
    final newLines = state.lines + clearedRows.length;
    final newLevel = 1 + (newLines ~/ 10);

    final locked = state.copyWith(
      board: board,
      clearActivePiece: true,
      score: state.score + scoreGained,
      lines: newLines,
      level: newLevel,
      piecesPlaced: state.piecesPlaced + 1,
      clearingRows: clearedRows,
      isGameOver: false,
    );

    if (clearedRows.isEmpty) {
      final next = _spawnNext(locked);
      return _LockResult(
        state: next,
        clearedRows: const [],
        scoreGained: scoreGained,
        isGameOver: next.isGameOver,
      );
    }

    return _LockResult(
      state: locked,
      clearedRows: clearedRows,
      scoreGained: scoreGained,
      isGameOver: false,
    );
  }
}

class _LockResult {
  const _LockResult({
    required this.state,
    required this.clearedRows,
    required this.scoreGained,
    required this.isGameOver,
  });

  final TetrisGameState state;
  final List<int> clearedRows;
  final int scoreGained;
  final bool isGameOver;
}
