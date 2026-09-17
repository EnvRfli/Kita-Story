import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/game_2048/engine/game_2048_engine.dart';
import 'package:kita_story/features/games/game_2048/models/game_2048_move.dart';
import 'package:kita_story/features/games/game_2048/models/game_2048_snapshot.dart';
import 'package:kita_story/features/games/game_2048/models/game_2048_tile.dart';
import 'package:kita_story/features/games/game_2048/providers/game_2048_provider.dart';
import 'package:kita_story/features/games/game_2048/services/game_2048_local_storage.dart';

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

  @override
  Future<Game2048Snapshot?> load() async => activeSnapshot;

  @override
  Future<void> save(Game2048Snapshot snapshot) async {
    activeSnapshot = snapshot;
    saveCount++;
  }

  @override
  Future<void> clear() async {
    activeSnapshot = null;
  }

  @override
  Future<int> loadBestScore() async => bestScore;

  @override
  Future<void> saveBestScore(int score) async {
    bestScore = score;
  }
}

void main() {
  group('Game2048Provider', () {
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
      );
      await provider.newGame();

      provider.swipe(Game2048Direction.left);
      await provider.completeAnimation();

      expect(provider.status, Game2048Status.gameOver);
    });
  });
}
