import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/tetris/engine/tetris_engine.dart';
import 'package:kita_story/features/games/tetris/models/tetris_game_state.dart';
import 'package:kita_story/features/games/tetris/models/tetris_snapshot.dart';
import 'package:kita_story/features/games/tetris/models/tetromino.dart';
import 'package:kita_story/features/games/tetris/providers/tetris_provider.dart';
import 'package:kita_story/features/games/tetris/repositories/tetris_repository.dart';
import 'package:kita_story/features/games/tetris/services/tetris_local_storage.dart';

TetrisGameState buildState({
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

class ScriptedEngine extends TetrisEngine {
  ScriptedEngine(this.initialState);

  final TetrisGameState initialState;

  @override
  TetrisGameState createInitialState() => initialState;
}

class MemoryStorage extends TetrisLocalStorage {
  TetrisSnapshot? activeSnapshot;
  int bestScore = 0;
  int saveCount = 0;
  bool failNextClear = false;

  @override
  Future<TetrisSnapshot?> load() async => activeSnapshot;

  @override
  Future<void> save(TetrisSnapshot snapshot) async {
    activeSnapshot = snapshot;
    saveCount++;
  }

  @override
  Future<void> clear() async {
    if (failNextClear) {
      failNextClear = false;
      throw StateError('Snapshot clear failed.');
    }
    activeSnapshot = null;
  }

  @override
  Future<int> loadBestScore() async => bestScore;

  @override
  Future<void> saveBestScore(int score) async {
    if (score > bestScore) bestScore = score;
  }
}

class RecordingRepository extends TetrisRepository {
  RecordingRepository({
    List<Set<int>> claimResponses = const [],
    List<bool> saveOutcomes = const [],
  })  : _claimResponses = List.of(claimResponses),
        _saveOutcomes = List.of(saveOutcomes);

  final List<Set<int>> _claimResponses;
  final List<bool> _saveOutcomes;
  final List<Set<int>> claimCalls = [];
  final List<
      ({
        String runId,
        int score,
        int lines,
        int level,
        int pieces,
        int duration,
      })> saveCalls = [];

  @override
  Future<Set<int>> claimMilestones(Set<int> candidates) async {
    claimCalls.add(Set.of(candidates));
    if (_claimResponses.isEmpty) return const {};
    return _claimResponses.removeAt(0);
  }

  @override
  Future<TetrisResult> saveResult({
    required String runId,
    required int score,
    required int linesCleared,
    required int levelReached,
    required int piecesPlaced,
    required int durationSeconds,
  }) async {
    saveCalls.add((
      runId: runId,
      score: score,
      lines: linesCleared,
      level: levelReached,
      pieces: piecesPlaced,
      duration: durationSeconds,
    ));
    if (_saveOutcomes.isNotEmpty && !_saveOutcomes.removeAt(0)) {
      throw StateError('Result write failed.');
    }
    return TetrisResult(
      id: runId,
      userId: 'user',
      partnerId: null,
      score: score,
      linesCleared: linesCleared,
      levelReached: levelReached,
      piecesPlaced: piecesPlaced,
      durationSeconds: durationSeconds,
      completedAt: DateTime.utc(2026, 11, 19),
    );
  }
}

TetrisProvider buildProvider({
  TetrisGameState? initialState,
  MemoryStorage? storage,
  RecordingRepository? repository,
  DateTime Function()? clock,
  Duration lockDelay = const Duration(milliseconds: 500),
}) =>
    TetrisProvider(
      engine: ScriptedEngine(initialState ?? buildState()),
      storage: storage ?? MemoryStorage(),
      repository: repository ?? RecordingRepository(),
      autoGravity: false,
      lockDelay: lockDelay,
      clock: clock,
      runIdGenerator: () => '11111111-1111-4111-8111-111111111111',
    );

void main() {
  group('TetrisProvider', () {
    test('starts a game with the scripted active piece and zero score',
        () async {
      final provider = buildProvider(
        initialState: buildState(
          activePiece: const TetrisPiece(
            type: TetrominoType.o,
            rotation: 0,
            row: 0,
            col: 4,
          ),
        ),
      );
      addTearDown(provider.dispose);

      await provider.newGame();

      expect(provider.status, TetrisStatus.playing);
      expect(provider.activePiece?.type, TetrominoType.o);
      expect(provider.score, 0);
      expect(provider.lines, 0);
      expect(provider.level, 1);
    });

    test('moves, rotates, and soft drops through provider actions', () async {
      final provider = buildProvider(
        initialState: buildState(
          activePiece: const TetrisPiece(
            type: TetrominoType.t,
            rotation: 0,
            row: 0,
            col: 3,
          ),
        ),
      );
      addTearDown(provider.dispose);
      await provider.newGame();

      provider.moveLeft();
      expect(provider.activePiece?.col, 2);

      provider.moveRight();
      provider.moveRight();
      expect(provider.activePiece?.col, 4);

      provider.rotate();
      expect(provider.activePiece?.rotation, 1);

      provider.softDrop();
      expect(provider.activePiece?.row, 1);
      expect(provider.score, 1);
    });

    test('hard drop locks the piece and spawns the next one', () async {
      final provider = buildProvider(
        initialState: buildState(
          activePiece: const TetrisPiece(
            type: TetrominoType.o,
            rotation: 0,
            row: 0,
            col: 4,
          ),
        ),
      );
      addTearDown(provider.dispose);
      await provider.newGame();

      provider.hardDrop();

      expect(provider.status, TetrisStatus.playing);
      expect(provider.piecesPlaced, 1);
      expect(provider.score, 36);
      expect(provider.board[19][5], TetrominoType.o.index);
      expect(provider.activePiece?.type, TetrominoType.i);
    });

    test('clears a line through the clearing state and saves the run',
        () async {
      final storage = MemoryStorage();
      final board = TetrisGameState.emptyBoard();
      for (var col = 0; col < 9; col++) {
        board[19][col] = TetrominoType.i.index;
      }
      final provider = buildProvider(
        storage: storage,
        initialState: buildState(
          board: board,
          activePiece: const TetrisPiece(
            type: TetrominoType.o,
            rotation: 0,
            row: 18,
            col: 8,
          ),
        ),
      );
      addTearDown(provider.dispose);
      await provider.newGame();

      provider.hardDrop();

      expect(provider.status, TetrisStatus.clearing);
      expect(provider.clearingRows, [19]);
      expect(provider.lines, 1);
      expect(provider.score, 100);

      await provider.completeLineClear();

      expect(provider.status, TetrisStatus.playing);
      expect(provider.clearingRows, isEmpty);
      expect(provider.activePiece, isNotNull);
      expect(provider.board[19][8], TetrominoType.o.index);
      expect(storage.saveCount, greaterThan(0));
    });

    test('queues a pause request while a line clear resolves', () async {
      final board = TetrisGameState.emptyBoard();
      for (var col = 0; col < 9; col++) {
        board[19][col] = TetrominoType.i.index;
      }
      final provider = buildProvider(
        initialState: buildState(
          board: board,
          activePiece: const TetrisPiece(
            type: TetrominoType.o,
            rotation: 0,
            row: 18,
            col: 8,
          ),
        ),
      );
      addTearDown(provider.dispose);
      await provider.newGame();

      provider.hardDrop();
      expect(provider.status, TetrisStatus.clearing);

      provider.pause();
      expect(provider.status, TetrisStatus.clearing);

      await provider.completeLineClear();

      expect(provider.status, TetrisStatus.paused);
      expect(provider.clearingRows, isEmpty);
    });

    test('pauses and resumes the game', () async {
      final provider = buildProvider();
      addTearDown(provider.dispose);
      await provider.newGame();

      provider.pause();
      expect(provider.status, TetrisStatus.paused);

      provider.resume();
      expect(provider.status, TetrisStatus.playing);
    });

    test('detects game over and finalizes the result', () async {
      final storage = MemoryStorage();
      final repository = RecordingRepository();
      final board = TetrisGameState.emptyBoard();
      for (var col = 0; col < TetrisGameState.columns; col++) {
        if (col == 4) continue;
        board[0][col] = TetrominoType.i.index;
      }
      final provider = buildProvider(
        storage: storage,
        repository: repository,
        initialState: buildState(
          board: board,
          activePiece: const TetrisPiece(
            type: TetrominoType.o,
            rotation: 0,
            row: 1,
            col: 4,
          ),
          nextQueue: const [
            TetrominoType.o,
            TetrominoType.i,
            TetrominoType.t,
            TetrominoType.s,
            TetrominoType.z,
            TetrominoType.j,
            TetrominoType.l,
          ],
        ),
      );
      addTearDown(provider.dispose);
      await provider.newGame();

      provider.hardDrop();
      expect(provider.status, TetrisStatus.gameOver);
      expect(provider.hasPendingWrite, isTrue);

      await provider.endRun();

      expect(provider.hasPendingWrite, isFalse);
      expect(repository.saveCalls, hasLength(1));
      expect(storage.activeSnapshot, isNull);
      expect(provider.status, TetrisStatus.gameOver);
    });

    test('records and claims a milestone when ten lines are cleared', () async {
      final repository = RecordingRepository(claimResponses: [
        {10},
      ]);
      final board = TetrisGameState.emptyBoard();
      for (var col = 0; col < 9; col++) {
        board[19][col] = TetrominoType.i.index;
      }
      final provider = buildProvider(
        repository: repository,
        initialState: buildState(
          board: board,
          activePiece: const TetrisPiece(
            type: TetrominoType.o,
            rotation: 0,
            row: 18,
            col: 8,
          ),
          lines: 9,
        ),
      );
      addTearDown(provider.dispose);
      await provider.newGame();

      provider.hardDrop();
      await provider.completeLineClear();

      expect(provider.newlyUnlockedMilestone, 10);
      expect(provider.pendingMilestones, isEmpty);
      expect(provider.sessionClaimedMilestones, {10});
      expect(provider.sessionPointsEarned, 2);
      expect(repository.claimCalls, [
        {10},
      ]);
    });

    test('retries a failed finalization in the same provider', () async {
      final storage = MemoryStorage();
      final repository = RecordingRepository(saveOutcomes: [false, true]);
      final provider = buildProvider(
        storage: storage,
        repository: repository,
      );
      addTearDown(provider.dispose);
      await provider.newGame();

      await provider.endRun();

      expect(provider.status, TetrisStatus.error);
      expect(provider.hasPendingWrite, isTrue);
      expect(storage.activeSnapshot, isNotNull);
      expect(repository.saveCalls, hasLength(1));

      await provider.endRun();

      expect(provider.status, TetrisStatus.gameOver);
      expect(provider.hasPendingWrite, isFalse);
      expect(storage.activeSnapshot, isNull);
      expect(repository.saveCalls, hasLength(2));
    });

    test('save and exit persists the snapshot without writing a result',
        () async {
      final storage = MemoryStorage();
      final repository = RecordingRepository();
      final provider = buildProvider(
        storage: storage,
        repository: repository,
      );
      addTearDown(provider.dispose);
      await provider.newGame();

      await provider.saveAndExit();

      expect(storage.activeSnapshot, isNotNull);
      expect(repository.saveCalls, isEmpty);
      expect(provider.status, TetrisStatus.playing);
    });

    test('restores an active snapshot', () async {
      final storage = MemoryStorage();
      final board = TetrisGameState.emptyBoard();
      board[19][0] = TetrominoType.t.index;
      storage.activeSnapshot = TetrisSnapshot(
        schemaVersion: TetrisSnapshot.currentSchemaVersion,
        board: board,
        activePiece: const TetrisPiece(
          type: TetrominoType.i,
          rotation: 0,
          row: 2,
          col: 3,
        ),
        nextQueue: const [
          TetrominoType.o,
          TetrominoType.t,
          TetrominoType.s,
          TetrominoType.z,
          TetrominoType.j,
          TetrominoType.l,
        ],
        score: 500,
        bestScore: 800,
        lines: 4,
        level: 1,
        piecesPlaced: 12,
        elapsedSeconds: 30,
        clearingRows: const [],
        pendingMilestones: const [],
        startedAt: DateTime.utc(2026, 11, 19),
      );
      final provider = buildProvider(storage: storage);
      addTearDown(provider.dispose);

      expect(await provider.restore(), isTrue);

      expect(provider.status, TetrisStatus.playing);
      expect(provider.score, 500);
      expect(provider.bestScore, 800);
      expect(provider.lines, 4);
      expect(provider.activePiece?.type, TetrominoType.i);
      expect(provider.board[19][0], TetrominoType.t.index);
    });

    test('tracks elapsed time while playing and excludes paused time',
        () async {
      var now = DateTime.utc(2026, 11, 19, 12);
      final provider = buildProvider(clock: () => now);
      addTearDown(provider.dispose);
      await provider.newGame();

      now = now.add(const Duration(seconds: 12));
      expect(provider.elapsedSeconds, 12);

      provider.pause();
      now = now.add(const Duration(seconds: 30));
      expect(provider.elapsedSeconds, 12);

      provider.resume();
      now = now.add(const Duration(seconds: 5));
      expect(provider.elapsedSeconds, 17);
    });

    test('keeps elapsed time while resolving a line clear', () async {
      var now = DateTime.utc(2026, 11, 19, 12);
      final board = TetrisGameState.emptyBoard();
      for (var col = 0; col < 9; col++) {
        board[19][col] = TetrominoType.i.index;
      }
      final provider = buildProvider(
        clock: () => now,
        initialState: buildState(
          board: board,
          activePiece: const TetrisPiece(
            type: TetrominoType.o,
            rotation: 0,
            row: 18,
            col: 8,
          ),
        ),
      );
      addTearDown(provider.dispose);
      await provider.newGame();

      now = now.add(const Duration(seconds: 10));
      provider.hardDrop();
      now = now.add(const Duration(seconds: 2));
      await provider.completeLineClear();

      expect(provider.elapsedSeconds, 12);

      now = now.add(const Duration(seconds: 3));
      expect(provider.elapsedSeconds, 15);
    });

    test('does not award a milestone that is already claimed', () async {
      final board = TetrisGameState.emptyBoard();
      for (var col = 0; col < 9; col++) {
        board[19][col] = TetrominoType.i.index;
      }
      final provider = buildProvider(
        initialState: buildState(
          board: board,
          activePiece: const TetrisPiece(
            type: TetrominoType.o,
            rotation: 0,
            row: 18,
            col: 8,
          ),
          lines: 9,
        ),
      );
      addTearDown(provider.dispose);
      provider.setClaimedMilestones({10});
      await provider.newGame();

      provider.hardDrop();
      await provider.completeLineClear();

      expect(provider.newlyUnlockedMilestone, isNull);
      expect(provider.pendingMilestones, isEmpty);
    });
  });
}
