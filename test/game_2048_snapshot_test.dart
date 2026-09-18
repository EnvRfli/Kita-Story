import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/2048/models/game_2048_snapshot.dart';
import 'package:kita_story/features/games/2048/models/game_2048_tile.dart';
import 'package:kita_story/features/games/2048/services/game_2048_local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Game2048Snapshot snapshot({
  List<Game2048Snapshot> undoSnapshots = const [],
  Game2048PendingFinalization? pendingFinalization,
}) =>
    Game2048Snapshot(
      schemaVersion: 1,
      tiles: const [
        Game2048Tile(
          id: 4,
          value: 128,
          position: Game2048Position(1, 2),
        ),
      ],
      score: 900,
      bestScore: 1200,
      undoSnapshots: undoSnapshots,
      undosLeft: 2,
      moveCount: 17,
      elapsedSeconds: 31,
      hasCelebrated2048: false,
      highestMilestone: 128,
      startedAt: DateTime.utc(2026, 9, 17),
      pendingFinalization: pendingFinalization,
    );

void main() {
  test('snapshot round trip preserves pending finalization', () {
    final value = snapshot(
      pendingFinalization: const Game2048PendingFinalization(
        runId: '11111111-1111-4111-8111-111111111111',
        score: 900,
        highestTile: 128,
        movesCount: 17,
        durationSeconds: 31,
        resultConfirmed: true,
      ),
    );

    final json = value.toJson();
    final restored = Game2048Snapshot.fromJson(json);

    expect(json['pending_finalization'], {
      'run_id': '11111111-1111-4111-8111-111111111111',
      'score': 900,
      'highest_tile': 128,
      'moves_count': 17,
      'duration_seconds': 31,
      'result_confirmed': true,
    });
    expect(
      restored.pendingFinalization?.runId,
      '11111111-1111-4111-8111-111111111111',
    );
    expect(restored.pendingFinalization?.score, 900);
    expect(restored.pendingFinalization?.highestTile, 128);
    expect(restored.pendingFinalization?.movesCount, 17);
    expect(restored.pendingFinalization?.durationSeconds, 31);
    expect(restored.pendingFinalization?.resultConfirmed, isTrue);
  });

  test('reads legacy pending finalization without a run id', () {
    final json = snapshot(
      pendingFinalization: const Game2048PendingFinalization(
        score: 900,
        highestTile: 128,
        movesCount: 17,
        durationSeconds: 31,
        resultConfirmed: false,
      ),
    ).toJson();
    (json['pending_finalization']! as Map<String, Object?>).remove('run_id');

    final restored = Game2048Snapshot.fromJson(json);

    expect(restored.pendingFinalization?.runId, isNull);
  });

  test('snapshot round trip preserves board undo and celebration state', () {
    final undoSnapshot = snapshot();
    final currentSnapshot = snapshot(undoSnapshots: [undoSnapshot]);

    final restored = Game2048Snapshot.fromJson(currentSnapshot.toJson());

    expect(restored.tiles.single.id, 4);
    expect(restored.tiles.single.position, const Game2048Position(1, 2));
    expect(restored.undosLeft, 2);
    expect(restored.hasCelebrated2048, isFalse);
    expect(restored.undoSnapshots, hasLength(1));
    expect(restored.undoSnapshots.single.undoSnapshots, isEmpty);
    expect(restored.startedAt, DateTime.utc(2026, 9, 17));
  });

  test('snapshot JSON fields use the versioned snake_case schema', () {
    final json = snapshot().toJson();

    expect(json['schema_version'], 1);
    expect(json['best_score'], 1200);
    expect(json['undo_snapshots'], isEmpty);
    expect(json['has_celebrated_2048'], isFalse);
    expect(json['highest_milestone'], 128);
    expect(json['started_at'], '2026-09-17T00:00:00.000Z');
    expect(json['schemaVersion'], isNull);
  });

  test('snapshot collections are isolated and immutable', () {
    final tiles = [
      const Game2048Tile(
        id: 1,
        value: 2,
        position: Game2048Position(0, 0),
      ),
    ];
    final undos = [snapshot()];
    final value = snapshot();
    final immutable = Game2048Snapshot(
      schemaVersion: value.schemaVersion,
      tiles: tiles,
      score: value.score,
      bestScore: value.bestScore,
      undoSnapshots: undos,
      undosLeft: value.undosLeft,
      moveCount: value.moveCount,
      elapsedSeconds: value.elapsedSeconds,
      hasCelebrated2048: value.hasCelebrated2048,
      highestMilestone: value.highestMilestone,
      startedAt: value.startedAt,
    );

    tiles.clear();
    undos.clear();

    expect(immutable.tiles, hasLength(1));
    expect(immutable.undoSnapshots, hasLength(1));
    expect(() => immutable.tiles.clear(), throwsUnsupportedError);
    expect(() => immutable.undoSnapshots.clear(), throwsUnsupportedError);
  });

  test('rejects unsupported and malformed snapshots', () {
    expect(
      () => Game2048Snapshot.fromJson({'schema_version': 99}),
      throwsFormatException,
    );
    expect(
      () => Game2048Snapshot.fromJson({'schema_version': 1}),
      throwsFormatException,
    );
    expect(
      () => Game2048Snapshot.fromJson({
        ...snapshot().toJson(),
        'tiles': [
          {'id': 1, 'value': 2, 'row': 0, 'col': '0'},
        ],
      }),
      throwsFormatException,
    );
  });

  test('local storage persists an active snapshot across instances', () async {
    SharedPreferences.setMockInitialValues({});
    final firstStorage = Game2048LocalStorage();

    await firstStorage.save(snapshot());

    final restored = await Game2048LocalStorage().load();
    expect(restored, isNotNull);
    expect(restored!.score, 900);
    expect(restored.tiles.single.position, const Game2048Position(1, 2));
  });

  test('local storage removes corrupt active snapshot JSON', () async {
    SharedPreferences.setMockInitialValues({
      'game_2048_active_v1': '{not valid JSON',
    });

    final restored = await Game2048LocalStorage().load();
    final preferences = await SharedPreferences.getInstance();

    expect(restored, isNull);
    expect(preferences.containsKey('game_2048_active_v1'), isFalse);
  });

  test('local storage keeps best score independently from active snapshots',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = Game2048LocalStorage();

    await storage.saveBestScore(3200);
    await storage.save(snapshot());
    await storage.clear();

    expect(await storage.loadBestScore(), 3200);
    expect(await storage.load(), isNull);
  });
}
