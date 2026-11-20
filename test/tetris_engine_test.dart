import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/tetris/engine/tetris_engine.dart';
import 'package:kita_story/features/games/tetris/models/tetris_game_state.dart';
import 'package:kita_story/features/games/tetris/models/tetromino.dart';

TetrisGameState stateWith({
  List<List<int?>>? board,
  TetrisPiece? activePiece,
  List<TetrominoType>? nextQueue,
  int score = 0,
  int lines = 0,
  int level = 1,
  int piecesPlaced = 0,
  List<int> clearingRows = const [],
  bool isGameOver = false,
}) =>
    TetrisGameState(
      board: board ?? TetrisGameState.emptyBoard(),
      activePiece: activePiece,
      nextQueue: nextQueue ??
          const [
            TetrominoType.i,
            TetrominoType.o,
            TetrominoType.t,
            TetrominoType.s,
            TetrominoType.z,
            TetrominoType.j,
            TetrominoType.l,
          ],
      score: score,
      lines: lines,
      level: level,
      piecesPlaced: piecesPlaced,
      clearingRows: clearingRows,
      isGameOver: isGameOver,
    );

List<List<int?>> boardWithFilledRows(
  List<int> rowIndexes, {
  int? exceptColumn,
}) {
  final board = TetrisGameState.emptyBoard();
  for (final row in rowIndexes) {
    for (var col = 0; col < TetrisGameState.columns; col++) {
      if (col == exceptColumn) continue;
      board[row][col] = TetrominoType.i.index;
    }
  }
  return board;
}

void main() {
  group('TetrisEngine initial state', () {
    test('spawns one active piece and a preview queue', () {
      final engine = TetrisEngine(random: Random(1));
      final state = engine.createInitialState();

      expect(state.activePiece, isNotNull);
      expect(state.nextQueue.length, greaterThanOrEqualTo(6));
      expect(state.board.length, TetrisGameState.rows);
      expect(state.board.first.length, TetrisGameState.columns);
      expect(state.score, 0);
      expect(state.lines, 0);
      expect(state.level, 1);
      expect(state.isGameOver, isFalse);
    });

    test('generates a seven-bag containing every tetromino once', () {
      final engine = TetrisEngine(random: Random(7));

      final bag = engine.generateBag();

      expect(bag, hasLength(7));
      expect(bag.toSet(), TetrominoType.values.toSet());
    });

    test('uses an injected deterministic queue', () {
      final engine = TetrisEngine(
        bagGenerator: () => [
          TetrominoType.t,
          TetrominoType.i,
          TetrominoType.o,
          TetrominoType.s,
          TetrominoType.z,
          TetrominoType.j,
          TetrominoType.l,
        ],
      );

      final state = engine.createInitialState();

      expect(state.activePiece?.type, TetrominoType.t);
      expect(
        state.nextQueue.take(3).toList(),
        [TetrominoType.i, TetrominoType.o, TetrominoType.s],
      );
    });
  });

  group('TetrisEngine movement', () {
    test('moves left and right until the wall blocks it', () {
      final engine = TetrisEngine();
      var state = stateWith(
        activePiece: const TetrisPiece(
          type: TetrominoType.o,
          rotation: 0,
          row: 0,
          col: 4,
        ),
      );

      for (var index = 0; index < 4; index++) {
        final result = engine.moveLeft(state);
        expect(result.didMove, isTrue);
        state = result.state;
      }
      expect(state.activePiece?.col, 0);
      expect(engine.moveLeft(state).didMove, isFalse);

      for (var index = 0; index < 8; index++) {
        state = engine.moveRight(state).state;
      }
      expect(state.activePiece?.col, 8);
      expect(engine.moveRight(state).didMove, isFalse);
    });

    test('rotates and kicks an I piece away from the right wall', () {
      final engine = TetrisEngine();
      final state = stateWith(
        activePiece: const TetrisPiece(
          type: TetrominoType.i,
          rotation: 1,
          row: 2,
          col: 7,
        ),
      );

      final result = engine.rotate(state);

      expect(result.didMove, isTrue);
      expect(result.state.activePiece?.rotation, 2);
      expect(result.state.activePiece?.col, lessThanOrEqualTo(6));
      expect(
        engine.collides(result.state, result.state.activePiece!),
        isFalse,
      );
    });

    test('keeps a valid rotation in place when no kick is needed', () {
      final engine = TetrisEngine();
      final state = stateWith(
        activePiece: const TetrisPiece(
          type: TetrominoType.i,
          rotation: 0,
          row: 0,
          col: 7,
        ),
      );

      final result = engine.rotate(state);

      expect(result.didMove, isTrue);
      expect(result.state.activePiece?.rotation, 1);
      expect(result.state.activePiece?.col, 7);
      expect(
        engine.collides(result.state, result.state.activePiece!),
        isFalse,
      );
    });

    test('soft drop adds one point per row', () {
      final engine = TetrisEngine();
      final result = engine.softDrop(
        stateWith(
          activePiece: const TetrisPiece(
            type: TetrominoType.o,
            rotation: 0,
            row: 0,
            col: 4,
          ),
        ),
      );

      expect(result.didMove, isTrue);
      expect(result.state.activePiece?.row, 1);
      expect(result.scoreGained, 1);
      expect(result.state.score, 1);
    });

    test('ghost row finds the last valid row without mutating the piece', () {
      final engine = TetrisEngine();
      final state = stateWith(
        activePiece: const TetrisPiece(
          type: TetrominoType.o,
          rotation: 0,
          row: 0,
          col: 4,
        ),
      );

      expect(engine.ghostRow(state), 18);
      expect(state.activePiece?.row, 0);
    });
  });

  group('TetrisEngine locking and clearing', () {
    test('hard drop locks at the floor and adds two points per row', () {
      final engine = TetrisEngine();
      final state = stateWith(
        activePiece: const TetrisPiece(
          type: TetrominoType.o,
          rotation: 0,
          row: 0,
          col: 4,
        ),
        nextQueue: const [
          TetrominoType.i,
          TetrominoType.t,
          TetrominoType.s,
          TetrominoType.z,
          TetrominoType.j,
          TetrominoType.l,
        ],
      );

      final result = engine.hardDrop(state);

      expect(result.didMove, isTrue);
      expect(result.pieceLocked, isTrue);
      expect(result.clearedRows, isEmpty);
      expect(result.state.score, 36);
      expect(result.state.piecesPlaced, 1);
      expect(result.state.board[18][4], TetrominoType.o.index);
      expect(result.state.board[19][5], TetrominoType.o.index);
      expect(result.state.activePiece?.type, TetrominoType.i);
    });

    test('locks a single line, marks it, then collapses it', () {
      final engine = TetrisEngine();
      final board = boardWithFilledRows([19], exceptColumn: 9);
      final state = stateWith(
        board: board,
        activePiece: const TetrisPiece(
          type: TetrominoType.o,
          rotation: 0,
          row: 18,
          col: 8,
        ),
      );

      final result = engine.lockPiece(state);

      expect(result.pieceLocked, isTrue);
      expect(result.clearedRows, [19]);
      expect(result.state.clearingRows, [19]);
      expect(result.state.activePiece, isNull);
      expect(result.state.score, 100);
      expect(result.state.lines, 1);
      expect(result.state.level, 1);

      final cleared = engine.completeClear(result.state);

      expect(cleared.clearingRows, isEmpty);
      expect(cleared.lines, 1);
      expect(cleared.activePiece, isNotNull);
      expect(cleared.board[19][8], TetrominoType.o.index);
      expect(cleared.board[19][9], TetrominoType.o.index);
      expect(cleared.board[18][8], isNull);
    });

    test('clears four lines as a tetris and awards 800 times the level', () {
      final engine = TetrisEngine();
      final board = boardWithFilledRows([16, 17, 18, 19], exceptColumn: 9);
      final state = stateWith(
        board: board,
        activePiece: const TetrisPiece(
          type: TetrominoType.i,
          rotation: 1,
          row: 16,
          col: 7,
        ),
      );

      final result = engine.lockPiece(state);

      expect(result.clearedRows, [16, 17, 18, 19]);
      expect(result.state.score, 800);
      expect(result.state.lines, 4);

      final cleared = engine.completeClear(result.state);

      expect(cleared.lines, 4);
      expect(cleared.level, 1);
      expect(cleared.score, 800);
      expect(
        cleared.board.every((row) => row.every((cell) => cell == null)),
        isTrue,
      );
    });

    test('levels up every ten lines and speeds up gravity', () {
      final engine = TetrisEngine();
      final board = boardWithFilledRows([19], exceptColumn: 9);
      final state = stateWith(
        board: board,
        activePiece: const TetrisPiece(
          type: TetrominoType.o,
          rotation: 0,
          row: 18,
          col: 8,
        ),
        lines: 9,
        level: 1,
      );

      final result = engine.lockPiece(state);
      final cleared = engine.completeClear(result.state);

      expect(cleared.lines, 10);
      expect(cleared.level, 2);
      expect(
        engine.gravityIntervalForLevel(2),
        lessThan(engine.gravityIntervalForLevel(1)),
      );
    });

    test('scores a clear using the level before the line update', () {
      final engine = TetrisEngine();
      final board = boardWithFilledRows([19], exceptColumn: 9);
      final state = stateWith(
        board: board,
        activePiece: const TetrisPiece(
          type: TetrominoType.o,
          rotation: 0,
          row: 18,
          col: 8,
        ),
        lines: 9,
        level: 1,
      );

      final result = engine.lockPiece(state);

      expect(result.state.score, 100);
      expect(result.state.level, 2);
    });

    test('reports game over when the next piece cannot spawn', () {
      final engine = TetrisEngine();
      final board = TetrisGameState.emptyBoard();
      for (var col = 0; col < TetrisGameState.columns; col++) {
        if (col == 4) continue;
        board[0][col] = TetrominoType.i.index;
      }
      final state = stateWith(
        board: board,
        activePiece: const TetrisPiece(
          type: TetrominoType.o,
          rotation: 0,
          row: 1,
          col: 4,
        ),
        nextQueue: const [
          TetrominoType.i,
          TetrominoType.t,
          TetrominoType.s,
          TetrominoType.z,
          TetrominoType.j,
          TetrominoType.l,
        ],
      );

      final result = engine.lockPiece(state);

      expect(result.isGameOver, isTrue);
      expect(result.state.isGameOver, isTrue);
      expect(result.state.activePiece, isNull);
    });
  });
}
