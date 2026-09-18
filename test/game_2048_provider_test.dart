import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/2048/engine/game_2048_engine.dart';
import 'package:kita_story/features/games/2048/models/game_2048_move.dart';
import 'package:kita_story/features/games/2048/models/game_2048_snapshot.dart';
import 'package:kita_story/features/games/2048/models/game_2048_tile.dart';
import 'package:kita_story/features/games/2048/providers/game_2048_provider.dart';
import 'package:kita_story/features/games/2048/repositories/game_2048_repository.dart';
import 'package:kita_story/features/games/2048/services/game_2048_local_storage.dart';

Game2048Tile tile(int id, int value) => Game2048Tile(
      id: id,
      value: value,
      position: Game2048Position(0, id - 1),
    );

Game2048MoveResult result({
  required List<Game2048Tile> tiles,
  int scoreGained = 0,
  bool didMove = true,
  bool isGameOver = false,
}) =>
    Game2048MoveResult(
      tiles: tiles,
      transitions: const [],
      merges: const [],
      scoreGained: scoreGained,
      didMove: didMove,
      isGameOver: isGameOver,
      highestTile: tiles.fold(
          0,
          (highest, current) =>
              current.value > highest ? current.value : highest),
    );

class ScriptedEngine extends Game2048Engine {
  ScriptedEngine({
    required this.initialTiles,
    required this.results,
    this.hasAvailableMoves = true,
  });

  final List<Game2048Tile> initialTiles;
  final List<Game2048MoveResult> results;
  final bool hasAvailableMoves;
  var _resultIndex = 0;

  @override
  List<Game2048Tile> createInitialTiles() => initialTiles;

  @override
  Game2048MoveResult move(
    List<Game2048Tile> tiles,
    Game2048Direction direction,
  ) =>
      results[_resultIndex++];

  @override
  List<Game2048Tile> spawnTile(List<Game2048Tile> tiles) => tiles;

  @override
  bool hasAvailableMove(List<Game2048Tile> tiles) => hasAvailableMoves;
}

class MemoryStorage extends Game2048LocalStorage {
  Game2048Snapshot? activeSnapshot;
  int bestScore = 0;
  var saveCount = 0;
  var failNextClear = false;

  @override
  Future<Game2048Snapshot?> load() async => activeSnapshot;

  @override
  Future<void> save(Game2048Snapshot snapshot) async {
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
    bestScore = score;
  }
}

class RecordingRepository extends Game2048Repository {
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
        int highestTile,
        int movesCount,
        int durationSeconds,
      })> saveCalls = [];

  @override
  Future<Set<int>> claimMilestones(Set<int> candidates) async {
    claimCalls.add(Set.of(candidates));
    if (_claimResponses.isEmpty) return const {};
    return _claimResponses.removeAt(0);
  }

  @override
  Future<Game2048Result> saveResult({
    required String runId,
    required int score,
    required int highestTile,
    required int movesCount,
    required int durationSeconds,
  }) async {
    saveCalls.add((
      runId: runId,
      score: score,
      highestTile: highestTile,
      movesCount: movesCount,
      durationSeconds: durationSeconds,
    ));
    if (_saveOutcomes.isNotEmpty && !_saveOutcomes.removeAt(0)) {
      throw StateError('Result write failed.');
    }
    return Game2048Result(
      id: 'result',
      userId: 'user',
      partnerId: null,
      score: score,
      highestTile: highestTile,
      movesCount: movesCount,
      durationSeconds: durationSeconds,
      completedAt: DateTime.utc(2026, 9, 17),
    );
  }
}

class BlockingClaimRepository extends RecordingRepository {
  final claimResult = Completer<Set<int>>();

  @override
  Future<Set<int>> claimMilestones(Set<int> candidates) {
    claimCalls.add(Set.of(candidates));
    return claimResult.future;
  }
}

void main() {
  group('Game2048Provider', () {
    test('retries only unresolved milestone claims', () async {
      final repository = RecordingRepository(
        claimResponses: [
          {128, 512},
          {256, 1024, 2048},
        ],
      );
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 1024), tile(2, 1024)],
          results: [
            result(tiles: [tile(3, 2048)], scoreGained: 2048)
          ],
        ),
        storage: MemoryStorage(),
        repository: repository,
      );

      await provider.newGame();
      provider.swipe(Game2048Direction.left);

      expect(repository.claimCalls, isEmpty);

      await provider.completeAnimation();

      expect(repository.claimCalls, [
        {128, 256, 512, 1024, 2048},
      ]);
      expect(provider.pendingMilestones, [256, 1024, 2048]);

      await provider.claimPendingMilestones();

      expect(repository.claimCalls, [
        {128, 256, 512, 1024, 2048},
        {256, 1024, 2048},
      ]);
      expect(provider.pendingMilestones, isEmpty);
    });

    test('save and exit only persists the active game locally', () async {
      final storage = MemoryStorage();
      final repository = RecordingRepository();
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 2), tile(2, 2)],
          results: const [],
        ),
        storage: storage,
        repository: repository,
      );

      await provider.newGame();
      await provider.saveAndExit();

      expect(storage.activeSnapshot, isNotNull);
      expect(repository.saveCalls, isEmpty);
      expect(provider.status, Game2048Status.playing);
    });

    test('end run writes one result and clears the active snapshot', () async {
      var currentTime = DateTime.utc(2026, 9, 17, 12);
      final storage = MemoryStorage();
      final repository = RecordingRepository();
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 2), tile(2, 2)],
          results: [
            result(tiles: [tile(3, 4)], scoreGained: 4)
          ],
        ),
        storage: storage,
        repository: repository,
        clock: () => currentTime,
        runIdGenerator: () => '11111111-1111-4111-8111-111111111111',
      );

      await provider.newGame();
      currentTime = currentTime.add(const Duration(seconds: 12));
      provider.swipe(Game2048Direction.left);
      await provider.completeAnimation();

      await Future.wait([provider.endRun(), provider.endRun()]);

      expect(repository.saveCalls, [
        (
          runId: '11111111-1111-4111-8111-111111111111',
          score: 4,
          highestTile: 4,
          movesCount: 1,
          durationSeconds: 12,
        ),
      ]);
      expect(storage.activeSnapshot, isNull);
      expect(provider.status, Game2048Status.gameOver);
    });

    test('retains a pending result and active snapshot until a retry succeeds',
        () async {
      final storage = MemoryStorage();
      final repository = RecordingRepository(saveOutcomes: [false, true]);
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 2), tile(2, 2)],
          results: const [],
        ),
        storage: storage,
        repository: repository,
        runIdGenerator: () => '22222222-2222-4222-8222-222222222222',
      );

      await provider.newGame();
      await provider.saveAndExit();
      await provider.endRun();

      expect(repository.saveCalls, hasLength(1));
      expect(storage.activeSnapshot, isNotNull);
      expect(provider.hasPendingWrite, isTrue);
      expect(provider.status, Game2048Status.error);

      await provider.retryPendingWrites();

      expect(repository.saveCalls, hasLength(2));
      expect(
        repository.saveCalls.map((call) => call.runId).toSet(),
        {'22222222-2222-4222-8222-222222222222'},
      );
      expect(storage.activeSnapshot, isNull);
      expect(provider.hasPendingWrite, isFalse);
      expect(provider.status, Game2048Status.gameOver);
    });

    test('end run retries a failed finalization in the same provider',
        () async {
      final storage = MemoryStorage();
      final repository = RecordingRepository(saveOutcomes: [false, true]);
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 2), tile(2, 2)],
          results: const [],
        ),
        storage: storage,
        repository: repository,
      );

      await provider.newGame();
      await provider.endRun();
      expect(provider.status, Game2048Status.error);

      await provider.endRun();

      expect(repository.saveCalls, hasLength(2));
      expect(repository.saveCalls[1].runId, repository.saveCalls[0].runId);
      expect(storage.activeSnapshot, isNull);
      expect(provider.hasPendingWrite, isFalse);
      expect(provider.status, Game2048Status.gameOver);
    });

    test(
        'does not save a confirmed result again when clearing local state fails',
        () async {
      final storage = MemoryStorage()..failNextClear = true;
      final repository = RecordingRepository();
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 2), tile(2, 2)],
          results: const [],
        ),
        storage: storage,
        repository: repository,
      );

      await provider.newGame();
      await provider.saveAndExit();
      await provider.endRun();

      expect(repository.saveCalls, hasLength(1));
      expect(storage.activeSnapshot, isNotNull);
      expect(provider.hasPendingWrite, isTrue);

      await provider.retryPendingWrites();

      expect(repository.saveCalls, hasLength(1));
      expect(storage.activeSnapshot, isNull);
      expect(provider.hasPendingWrite, isFalse);
    });

    test('new game scopes end-run deduplication to the new run', () async {
      final repository = RecordingRepository();
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 2), tile(2, 2)],
          results: const [],
        ),
        storage: MemoryStorage(),
        repository: repository,
      );

      await provider.newGame();
      await provider.endRun();
      await provider.newGame();
      await provider.endRun();

      expect(repository.saveCalls, hasLength(2));
    });

    test('restore retries a durable unconfirmed finalization before play',
        () async {
      final storage = MemoryStorage();
      final firstRepository = RecordingRepository(saveOutcomes: [false]);
      final firstProvider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 2), tile(2, 2)],
          results: const [],
        ),
        storage: storage,
        repository: firstRepository,
        runIdGenerator: () => '33333333-3333-4333-8333-333333333333',
      );
      await firstProvider.newGame();
      await firstProvider.endRun();

      expect(storage.activeSnapshot?.pendingFinalization, isNotNull);
      expect(
        storage.activeSnapshot?.pendingFinalization?.resultConfirmed,
        isFalse,
      );

      final retryRepository = RecordingRepository();
      final restoredProvider = Game2048Provider(
        engine: ScriptedEngine(initialTiles: const [], results: const []),
        storage: storage,
        repository: retryRepository,
      );

      expect(await restoredProvider.restore(), isTrue);
      expect(retryRepository.saveCalls, hasLength(1));
      expect(
        retryRepository.saveCalls.single.runId,
        '33333333-3333-4333-8333-333333333333',
      );
      expect(storage.activeSnapshot, isNull);
      expect(restoredProvider.status, Game2048Status.gameOver);

      await restoredProvider.endRun();
      expect(retryRepository.saveCalls, hasLength(1));
    });

    test('restore clears a confirmed finalization without saving it again',
        () async {
      final storage = MemoryStorage()..failNextClear = true;
      final firstRepository = RecordingRepository();
      final firstProvider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 2), tile(2, 2)],
          results: const [],
        ),
        storage: storage,
        repository: firstRepository,
      );
      await firstProvider.newGame();
      await firstProvider.endRun();

      expect(
        storage.activeSnapshot?.pendingFinalization?.resultConfirmed,
        isTrue,
      );

      final retryRepository = RecordingRepository();
      final restoredProvider = Game2048Provider(
        engine: ScriptedEngine(initialTiles: const [], results: const []),
        storage: storage,
        repository: retryRepository,
      );

      expect(await restoredProvider.restore(), isTrue);
      expect(retryRepository.saveCalls, isEmpty);
      expect(storage.activeSnapshot, isNull);
      expect(restoredProvider.status, Game2048Status.gameOver);

      await restoredProvider.endRun();
      expect(retryRepository.saveCalls, isEmpty);
    });

    test('finalizes a terminal move without waiting for an overlay action',
        () async {
      final storage = MemoryStorage();
      final repository = RecordingRepository();
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 2), tile(2, 2)],
          results: [
            result(
              tiles: [tile(3, 4)],
              scoreGained: 4,
              isGameOver: true,
            ),
          ],
          hasAvailableMoves: false,
        ),
        storage: storage,
        repository: repository,
      );

      await provider.newGame();
      provider.swipe(Game2048Direction.left);
      await provider.completeAnimation();

      expect(repository.saveCalls, hasLength(1));
      expect(storage.activeSnapshot, isNull);
      expect(provider.status, Game2048Status.gameOver);
    });

    test('queues terminal finalization before waiting on milestone claims',
        () async {
      final storage = MemoryStorage();
      final repository = BlockingClaimRepository();
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 64), tile(2, 64)],
          results: [
            result(
              tiles: [tile(3, 128)],
              scoreGained: 128,
              isGameOver: true,
            ),
          ],
          hasAvailableMoves: false,
        ),
        storage: storage,
        repository: repository,
      );

      await provider.newGame();
      provider.swipe(Game2048Direction.left);
      final completion = provider.completeAnimation();
      await Future<void>.delayed(Duration.zero);

      expect(storage.activeSnapshot?.pendingFinalization, isNotNull);
      expect(provider.status, Game2048Status.saving);

      repository.claimResult.complete(const {});
      await completion;
      expect(storage.activeSnapshot, isNull);
      expect(repository.saveCalls, hasLength(1));
    });

    test('end run settles a locked move before finalization', () async {
      final storage = MemoryStorage();
      final repository = RecordingRepository();
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 2), tile(2, 2)],
          results: [
            result(tiles: [tile(3, 4)], scoreGained: 4)
          ],
        ),
        storage: storage,
        repository: repository,
      );

      await provider.newGame();
      provider.swipe(Game2048Direction.left);
      await provider.endRun();

      expect(provider.isInputLocked, isFalse);
      expect(repository.saveCalls, hasLength(1));
      expect(storage.activeSnapshot, isNull);

      await provider.completeAnimation();

      expect(repository.saveCalls, hasLength(1));
      expect(storage.activeSnapshot, isNull);
      expect(provider.status, Game2048Status.gameOver);
    });

    test('save and exit settles a locked move without a delayed resave',
        () async {
      final storage = MemoryStorage();
      final repository = RecordingRepository();
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 2), tile(2, 2)],
          results: [
            result(tiles: [tile(3, 4)], scoreGained: 4)
          ],
        ),
        storage: storage,
        repository: repository,
      );

      await provider.newGame();
      provider.swipe(Game2048Direction.left);
      await provider.saveAndExit();

      expect(provider.isInputLocked, isFalse);
      expect(repository.saveCalls, isEmpty);
      expect(storage.activeSnapshot, isNotNull);
      final savesAfterExit = storage.saveCount;

      await provider.completeAnimation();

      expect(storage.saveCount, savesAfterExit);
      expect(repository.saveCalls, isEmpty);
    });

    test('starts a new run and locks valid input until animation completes',
        () async {
      final storage = MemoryStorage();
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 2), tile(2, 2)],
          results: [
            result(tiles: [tile(3, 4)], scoreGained: 4)
          ],
        ),
        storage: storage,
        repository: RecordingRepository(),
      );

      await provider.newGame();

      expect(provider.status, Game2048Status.playing);
      expect(provider.tiles, hasLength(2));
      expect(provider.score, 0);
      expect(provider.undosLeft, 3);

      provider.swipe(Game2048Direction.left);

      expect(provider.score, 4);
      expect(provider.moveCount, 1);
      expect(provider.undoSnapshots, hasLength(1));
      expect(provider.isInputLocked, isTrue);

      provider.swipe(Game2048Direction.right);
      expect(provider.moveCount, 1);

      await provider.completeAnimation();
      expect(provider.isInputLocked, isFalse);
      expect(storage.saveCount, 1);
    });

    test('keeps only three snapshots and never replenishes undo credits',
        () async {
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 2), tile(2, 2)],
          results: [
            result(tiles: [tile(3, 4)], scoreGained: 4),
            result(tiles: [tile(4, 8)], scoreGained: 8),
            result(tiles: [tile(5, 16)], scoreGained: 16),
            result(tiles: [tile(6, 32)], scoreGained: 32),
          ],
        ),
        storage: MemoryStorage(),
        repository: RecordingRepository(),
      );
      await provider.newGame();
      for (var index = 0; index < 4; index++) {
        provider.swipe(Game2048Direction.left);
        await provider.completeAnimation();
      }

      expect(provider.undoSnapshots, hasLength(3));
      expect(provider.score, 60);

      expect(await provider.undo(), isTrue);
      expect(provider.score, 28);
      expect(provider.undosLeft, 2);
      expect(await provider.undo(), isTrue);
      expect(provider.score, 12);
      expect(provider.undosLeft, 1);
      expect(await provider.undo(), isTrue);
      expect(provider.score, 4);
      expect(provider.undosLeft, 0);

      expect(await provider.undo(), isFalse);
      expect(provider.score, 4);
      expect(provider.undosLeft, 0);
    });

    test('ignores an invalid swipe without changing gameplay state', () async {
      final storage = MemoryStorage();
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 2), tile(2, 4)],
          results: [
            result(
              tiles: [tile(1, 2), tile(2, 4)],
              didMove: false,
            ),
          ],
        ),
        storage: storage,
        repository: RecordingRepository(),
      );
      await provider.newGame();

      provider.swipe(Game2048Direction.left);
      await provider.completeAnimation();

      expect(provider.status, Game2048Status.playing);
      expect(provider.score, 0);
      expect(provider.moveCount, 0);
      expect(provider.undoSnapshots, isEmpty);
      expect(provider.isInputLocked, isFalse);
      expect(storage.saveCount, 0);
      expect(() => provider.tiles.clear(), throwsUnsupportedError);
    });

    test('celebrates 2048 once and continues playing beyond it', () async {
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 1024), tile(2, 1024)],
          results: [
            result(tiles: [tile(3, 2048)], scoreGained: 2048),
            result(tiles: [tile(4, 4096)], scoreGained: 4096),
          ],
        ),
        storage: MemoryStorage(),
        repository: RecordingRepository(),
      );
      await provider.newGame();

      provider.swipe(Game2048Direction.left);
      await provider.completeAnimation();

      expect(provider.status, Game2048Status.celebrating2048);
      expect(
          provider.pendingMilestones, containsAll([128, 256, 512, 1024, 2048]));

      provider.continueAfter2048();
      expect(provider.status, Game2048Status.playing);

      provider.swipe(Game2048Direction.left);
      await provider.completeAnimation();

      expect(provider.status, Game2048Status.playing);
      expect(provider.pendingMilestones, contains(4096));
    });

    test('enters game over after dismissing a terminal 2048 celebration',
        () async {
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 1024), tile(2, 1024)],
          results: [
            result(tiles: [tile(3, 2048)], scoreGained: 2048)
          ],
          hasAvailableMoves: false,
        ),
        storage: MemoryStorage(),
        repository: RecordingRepository(),
      );
      await provider.newGame();

      provider.swipe(Game2048Direction.left);
      await provider.completeAnimation();
      expect(provider.status, Game2048Status.celebrating2048);

      provider.continueAfter2048();

      expect(provider.status, Game2048Status.gameOver);
    });

    test('tracks elapsed time with a clock and restores undo duration',
        () async {
      var currentTime = DateTime.utc(2026, 9, 17, 12);
      final storage = MemoryStorage();
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 2), tile(2, 2)],
          results: [
            result(tiles: [tile(3, 4)], scoreGained: 4)
          ],
        ),
        storage: storage,
        repository: RecordingRepository(),
        clock: () => currentTime,
      );
      await provider.newGame();
      currentTime = currentTime.add(const Duration(seconds: 12));

      expect(provider.elapsedSeconds, 12);
      provider.swipe(Game2048Direction.left);
      await provider.completeAnimation();
      expect(storage.activeSnapshot!.elapsedSeconds, 12);

      currentTime = currentTime.add(const Duration(seconds: 5));
      expect(await provider.undo(), isTrue);
      expect(provider.elapsedSeconds, 12);
      currentTime = currentTime.add(const Duration(seconds: 5));
      expect(provider.elapsedSeconds, 17);
    });

    test('settles into a new-game-ready state when no snapshot is available',
        () async {
      final provider = Game2048Provider(
        engine: ScriptedEngine(initialTiles: const [], results: const []),
        storage: MemoryStorage(),
        repository: RecordingRepository(),
      );

      expect(await provider.restore(), isFalse);
      expect(provider.status, Game2048Status.playing);
      expect(provider.tiles, isEmpty);
    });

    test('checks game over after spawning the valid move result', () async {
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 2), tile(2, 2)],
          results: [
            result(
              tiles: [tile(3, 4)],
              scoreGained: 4,
              isGameOver: false,
            ),
          ],
          hasAvailableMoves: false,
        ),
        storage: MemoryStorage(),
        repository: RecordingRepository(),
      );
      await provider.newGame();

      provider.swipe(Game2048Direction.left);
      await provider.completeAnimation();

      expect(provider.status, Game2048Status.gameOver);
    });

    test('tracks newlyUnlockedMilestone, sessionClaimedMilestones, and sessionPointsEarned',
        () async {
      final repository = RecordingRepository(claimResponses: [
        {128},
      ]);
      final provider = Game2048Provider(
        engine: ScriptedEngine(
          initialTiles: [tile(1, 64), tile(2, 64)],
          results: [
            result(
              tiles: [tile(3, 128)],
              scoreGained: 128,
            ),
          ],
        ),
        storage: MemoryStorage(),
        repository: repository,
      );
      await provider.newGame();

      expect(provider.sessionPointsEarned, 0);
      expect(provider.newlyUnlockedMilestone, isNull);

      provider.swipe(Game2048Direction.left);
      expect(provider.newlyUnlockedMilestone, 128);

      await provider.completeAnimation();
      expect(provider.sessionClaimedMilestones, {128});
      expect(provider.sessionPointsEarned, 2);

      provider.clearNewlyUnlockedMilestone();
      expect(provider.newlyUnlockedMilestone, isNull);

      await provider.newGame();
      expect(provider.sessionPointsEarned, 0);
      expect(provider.sessionClaimedMilestones, isEmpty);
    });
  });
}
