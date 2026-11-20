import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/tetris/models/tetris_game_state.dart';
import 'package:kita_story/features/games/tetris/models/tetris_snapshot.dart';
import 'package:kita_story/features/games/tetris/models/tetromino.dart';
import 'package:kita_story/features/games/tetris/services/tetris_local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

TetrisSnapshot snapshot({
  TetrisPendingFinalization? pendingFinalization,
  List<int> pendingMilestones = const [10, 25],
}) {
  final board = TetrisGameState.emptyBoard();
  board[19][0] = TetrominoType.t.index;
  board[19][1] = TetrominoType.t.index;
  board[18][1] = TetrominoType.t.index;
  board[19][2] = TetrominoType.o.index;

  return TetrisSnapshot(
    schemaVersion: TetrisSnapshot.currentSchemaVersion,
    board: board,
    activePiece: const TetrisPiece(
      type: TetrominoType.i,
      rotation: 1,
      row: 2,
      col: 7,
    ),
    nextQueue: const [
      TetrominoType.t,
      TetrominoType.o,
      TetrominoType.s,
      TetrominoType.z,
      TetrominoType.j,
      TetrominoType.l,
    ],
    score: 12300,
    bestScore: 20400,
    startingBestScore: 8000,
    lines: 42,
    level: 5,
    piecesPlaced: 87,
    elapsedSeconds: 321,
    clearingRows: const [17, 18],
    pendingMilestones: pendingMilestones,
    startedAt: DateTime.utc(2026, 11, 19),
    pendingFinalization: pendingFinalization,
  );
}

void main() {
  test('snapshot round trip preserves board, piece, queue, and progress', () {
    final json = snapshot().toJson();
    final restored = TetrisSnapshot.fromJson(json);

    expect(json['schema_version'], 1);
    expect(json['score'], 12300);
    expect(json['starting_best_score'], 8000);
    expect(json['active_piece'], {
      'type': 'I',
      'rotation': 1,
      'row': 2,
      'col': 7,
    });
    expect(json['next_queue'], ['T', 'O', 'S', 'Z', 'J', 'L']);
    expect(json['clearing_rows'], [17, 18]);
    expect(json['pending_milestones'], [10, 25]);
    expect(json['started_at'], '2026-11-19T00:00:00.000Z');

    expect(restored.board[19][0], TetrominoType.t.index);
    expect(restored.activePiece?.type, TetrominoType.i);
    expect(restored.activePiece?.rotation, 1);
    expect(restored.nextQueue.first, TetrominoType.t);
    expect(restored.score, 12300);
    expect(restored.bestScore, 20400);
    expect(restored.startingBestScore, 8000);
    expect(restored.lines, 42);
    expect(restored.level, 5);
    expect(restored.piecesPlaced, 87);
    expect(restored.elapsedSeconds, 321);
    expect(restored.clearingRows, [17, 18]);
    expect(restored.pendingMilestones, [10, 25]);
    expect(restored.startedAt, DateTime.utc(2026, 11, 19));
  });

  test('snapshot round trip preserves pending finalization', () {
    final value = snapshot(
      pendingFinalization: const TetrisPendingFinalization(
        runId: '22222222-2222-4222-8222-222222222222',
        score: 12300,
        lines: 42,
        level: 5,
        piecesPlaced: 87,
        durationSeconds: 321,
        resultConfirmed: true,
      ),
    );

    final restored = TetrisSnapshot.fromJson(value.toJson());

    expect(restored.pendingFinalization?.runId,
        '22222222-2222-4222-8222-222222222222');
    expect(restored.pendingFinalization?.score, 12300);
    expect(restored.pendingFinalization?.lines, 42);
    expect(restored.pendingFinalization?.level, 5);
    expect(restored.pendingFinalization?.piecesPlaced, 87);
    expect(restored.pendingFinalization?.durationSeconds, 321);
    expect(restored.pendingFinalization?.resultConfirmed, isTrue);
  });

  test('reads legacy pending finalization without a run id', () {
    final json = snapshot(
      pendingFinalization: const TetrisPendingFinalization(
        score: 12300,
        lines: 42,
        level: 5,
        piecesPlaced: 87,
        durationSeconds: 321,
        resultConfirmed: false,
      ),
    ).toJson();
    (json['pending_finalization']! as Map<String, Object?>).remove('run_id');

    final restored = TetrisSnapshot.fromJson(json);

    expect(restored.pendingFinalization?.runId, isNull);
  });

  test('rejects unsupported and malformed snapshots', () {
    expect(
      () => TetrisSnapshot.fromJson({'schema_version': 99}),
      throwsFormatException,
    );
    expect(
      () => TetrisSnapshot.fromJson({'schema_version': 1}),
      throwsFormatException,
    );
    expect(
      () => TetrisSnapshot.fromJson({
        ...snapshot().toJson(),
        'board': [
          [1, 2, 3],
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => TetrisSnapshot.fromJson({
        ...snapshot().toJson(),
        'active_piece': {
          'type': 'X',
          'rotation': 0,
          'row': 0,
          'col': 0,
        },
      }),
      throwsFormatException,
    );
  });

  test('snapshot collections are isolated and immutable', () {
    final board = TetrisGameState.emptyBoard();
    final queue = <TetrominoType>[TetrominoType.i];
    final milestones = <int>[10];
    final value = TetrisSnapshot(
      schemaVersion: TetrisSnapshot.currentSchemaVersion,
      board: board,
      activePiece: null,
      nextQueue: queue,
      score: 0,
      bestScore: 0,
      lines: 0,
      level: 1,
      piecesPlaced: 0,
      elapsedSeconds: 0,
      clearingRows: const [],
      pendingMilestones: milestones,
      startedAt: DateTime.utc(2026, 11, 19),
    );

    board[0][0] = 1;
    queue.clear();
    milestones.clear();

    expect(value.board[0][0], isNull);
    expect(value.nextQueue, hasLength(1));
    expect(value.pendingMilestones, hasLength(1));
    expect(() => value.board.add([]), throwsUnsupportedError);
    expect(() => value.nextQueue.clear(), throwsUnsupportedError);
    expect(() => value.pendingMilestones.clear(), throwsUnsupportedError);
  });

  test('local storage persists an active snapshot across instances', () async {
    SharedPreferences.setMockInitialValues({});
    final firstStorage = TetrisLocalStorage();

    await firstStorage.save(snapshot());

    final restored = await TetrisLocalStorage().load();
    expect(restored, isNotNull);
    expect(restored!.score, 12300);
    expect(restored.activePiece?.type, TetrominoType.i);
    expect(restored.board[19][0], TetrominoType.t.index);
  });

  test('local storage removes corrupt active snapshot JSON', () async {
    SharedPreferences.setMockInitialValues({
      'game_tetris_active_v1': '{not valid JSON',
    });

    final restored = await TetrisLocalStorage().load();
    final preferences = await SharedPreferences.getInstance();

    expect(restored, isNull);
    expect(preferences.containsKey('game_tetris_active_v1'), isFalse);
  });

  test('local storage keeps best score independently from active snapshots',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = TetrisLocalStorage();

    await storage.saveBestScore(32000);
    await storage.save(snapshot());
    await storage.clear();

    expect(await storage.loadBestScore(), 32000);
    expect(await storage.load(), isNull);
  });
}
