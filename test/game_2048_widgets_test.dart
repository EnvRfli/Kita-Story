import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/game_2048/engine/game_2048_engine.dart';
import 'package:kita_story/features/games/game_2048/models/game_2048_move.dart';
import 'package:kita_story/features/games/game_2048/models/game_2048_snapshot.dart';
import 'package:kita_story/features/games/game_2048/models/game_2048_tile.dart';
import 'package:kita_story/features/games/game_2048/providers/game_2048_provider.dart';
import 'package:kita_story/features/games/game_2048/repositories/game_2048_repository.dart';
import 'package:kita_story/features/games/game_2048/services/game_2048_local_storage.dart';
import 'package:kita_story/features/games/game_2048/ui/game_2048_screen.dart';
import 'package:kita_story/features/games/game_2048/widgets/game_2048_board.dart';
import 'package:kita_story/features/games/game_2048/widgets/game_2048_tile_widget.dart';
import 'package:provider/provider.dart';

const _tiles = [
  Game2048Tile(
    id: 7,
    value: 2,
    position: Game2048Position(0, 0),
  ),
  Game2048Tile(
    id: 12,
    value: 16,
    position: Game2048Position(3, 3),
  ),
];

Widget _boardHarness({
  required double width,
  List<Game2048Tile> tiles = _tiles,
  ValueChanged<Game2048Direction>? onSwipe,
}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: Game2048Board(
              tiles: tiles,
              onSwipe: onSwipe ?? (_) {},
            ),
          ),
        ),
      ),
    );

class _WidgetMemoryStorage extends Game2048LocalStorage {
  Game2048Snapshot? activeSnapshot;
  int bestScore;

  _WidgetMemoryStorage({this.bestScore = 0});

  @override
  Future<void> clear() async => activeSnapshot = null;

  @override
  Future<Game2048Snapshot?> load() async => activeSnapshot;

  @override
  Future<int> loadBestScore() async => bestScore;

  @override
  Future<void> save(Game2048Snapshot snapshot) async {
    activeSnapshot = snapshot;
  }

  @override
  Future<void> saveBestScore(int score) async {
    bestScore = score;
  }
}

class _WidgetScriptedEngine extends Game2048Engine {
  _WidgetScriptedEngine({
    required this.initialTiles,
    this.results = const [],
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

class _WidgetRepository extends Game2048Repository {
  @override
  Future<Set<int>> claimMilestones(Set<int> candidates) async => candidates;

  @override
  Future<Game2048Result> saveResult({
    required int score,
    required int highestTile,
    required int movesCount,
    required int durationSeconds,
  }) async =>
      Game2048Result(
        id: 'test-result',
        userId: 'test-user',
        partnerId: null,
        score: score,
        highestTile: highestTile,
        movesCount: movesCount,
        durationSeconds: durationSeconds,
        completedAt: DateTime.utc(2026, 9, 17),
      );
}

Game2048Tile _screenTile(int id, int value) => Game2048Tile(
      id: id,
      value: value,
      position: Game2048Position(0, id - 1),
    );

Game2048MoveResult _screenResult({
  required List<Game2048Tile> tiles,
  int scoreGained = 0,
  bool isGameOver = false,
}) =>
    Game2048MoveResult(
      tiles: tiles,
      transitions: const [],
      merges: const [],
      scoreGained: scoreGained,
      didMove: true,
      isGameOver: isGameOver,
      highestTile: tiles.fold(
        0,
        (highest, tile) => highest > tile.value ? highest : tile.value,
      ),
    );

Widget _screenHarness(Game2048Provider provider) => MaterialApp(
      home: ChangeNotifierProvider<Game2048Provider>.value(
        value: provider,
        child: const Game2048Screen(),
      ),
    );

void main() {
  testWidgets('renders all cells and keeps tile keys at 320 pixels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_boardHarness(width: 320));

    expect(find.byKey(const ValueKey('2048-background-cell-0-0')), findsOne);
    expect(find.byKey(const ValueKey('2048-background-cell-3-3')), findsOne);
    expect(find.byType(Game2048BoardCell), findsNWidgets(16));
    expect(find.byKey(const ValueKey('2048-tile-7')), findsOne);
    expect(find.byKey(const ValueKey('2048-tile-12')), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('caps board geometry without overflow at 600 pixels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_boardHarness(width: 600));

    expect(find.byType(Game2048BoardCell), findsNWidgets(16));
    expect(find.byType(AnimatedPositioned), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dispatches a horizontal swipe past the threshold once', (
    WidgetTester tester,
  ) async {
    final directions = <Game2048Direction>[];
    await tester.pumpWidget(
      _boardHarness(width: 320, onSwipe: directions.add),
    );

    await tester.drag(find.byType(Game2048Board), const Offset(120, 0));

    expect(directions, [Game2048Direction.right]);
  });

  testWidgets('dispatches a vertical swipe past the threshold once', (
    WidgetTester tester,
  ) async {
    final directions = <Game2048Direction>[];
    await tester.pumpWidget(
      _boardHarness(width: 320, onSwipe: directions.add),
    );

    await tester.drag(find.byType(Game2048Board), const Offset(0, 120));

    expect(directions, [Game2048Direction.down]);
  });

  testWidgets('does not dispatch a drag below the swipe threshold', (
    WidgetTester tester,
  ) async {
    final directions = <Game2048Direction>[];
    await tester.pumpWidget(
      _boardHarness(width: 320, onSwipe: directions.add),
    );

    await tester.drag(find.byType(Game2048Board), const Offset(8, 0));

    expect(directions, isEmpty);
  });

  testWidgets('uses the dominant horizontal axis for a diagonal swipe', (
    WidgetTester tester,
  ) async {
    final directions = <Game2048Direction>[];
    await tester.pumpWidget(
      _boardHarness(width: 320, onSwipe: directions.add),
    );

    await tester.drag(find.byType(Game2048Board), const Offset(120, 72));

    expect(directions, [Game2048Direction.right]);
  });

  test('maps every standard tile value through 65536 to a solid color', () {
    const values = [
      2,
      4,
      8,
      16,
      32,
      64,
      128,
      256,
      512,
      1024,
      2048,
      4096,
      8192,
      16384,
      32768,
      65536,
    ];

    expect(Game2048TileWidget.valueColors.keys, values);
    for (final value in values) {
      expect(Game2048TileWidget.colorFor(value), isA<Color>());
    }
    expect(Game2048TileWidget.gradientFor(131072), isNotNull);
  });

  testWidgets('active 2048 game protects both back paths', (
    WidgetTester tester,
  ) async {
    final storage = _WidgetMemoryStorage();
    final provider = Game2048Provider(
      engine: _WidgetScriptedEngine(
        initialTiles: [_screenTile(1, 2), _screenTile(2, 4)],
      ),
      storage: storage,
      repository: _WidgetRepository(),
    );
    await provider.newGame();
    await tester.pumpWidget(_screenHarness(provider));

    expect(find.text('2048'), findsOneWidget);
    expect(find.text('Skor'), findsOneWidget);
    expect(find.text('Terbaik'), findsOneWidget);
    expect(find.byType(Game2048Board), findsOneWidget);
    expect(find.text('Urungkan'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('game-2048-back-button')));
    await tester.pumpAndSettle();
    expect(find.text('Lanjut Bermain'), findsOneWidget);
    expect(find.text('Simpan & Keluar'), findsOneWidget);
    expect(find.text('Akhiri Permainan'), findsOneWidget);

    await tester.tap(find.text('Lanjut Bermain'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan & Keluar'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Lanjut Bermain'), findsOneWidget);
    expect(find.text('Simpan & Keluar'), findsOneWidget);
    expect(find.text('Akhiri Permainan'), findsOneWidget);

    await tester.tap(find.text('Simpan & Keluar'));
    await tester.pumpAndSettle();
    expect(storage.activeSnapshot, isNotNull);
    expect(provider.status, Game2048Status.playing);
  });

  testWidgets('ending an active 2048 game records then clears its run', (
    WidgetTester tester,
  ) async {
    final storage = _WidgetMemoryStorage();
    final provider = Game2048Provider(
      engine: _WidgetScriptedEngine(
        initialTiles: [_screenTile(1, 2), _screenTile(2, 4)],
      ),
      storage: storage,
      repository: _WidgetRepository(),
    );
    await provider.newGame();
    await tester.pumpWidget(_screenHarness(provider));

    await tester.tap(find.byKey(const ValueKey('game-2048-back-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Akhiri Permainan'));
    await tester.pumpAndSettle();
    expect(storage.activeSnapshot, isNull);
    expect(provider.status, Game2048Status.gameOver);
  });

  testWidgets('shows a playful celebration when 2048 is reached', (
    WidgetTester tester,
  ) async {
    final provider = Game2048Provider(
      engine: _WidgetScriptedEngine(
        initialTiles: [_screenTile(1, 1024), _screenTile(2, 1024)],
        results: [
          _screenResult(tiles: [_screenTile(3, 2048)], scoreGained: 2048),
        ],
      ),
      storage: _WidgetMemoryStorage(),
      repository: _WidgetRepository(),
    );
    await provider.newGame();
    provider.swipe(Game2048Direction.left);
    await provider.completeAnimation();
    await tester.pumpWidget(_screenHarness(provider));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('game-2048-confetti')), findsOneWidget);
    expect(find.text('2048'), findsWidgets);
    expect(find.text('2.048'), findsWidgets);
    expect(find.text('Lanjutkan Bermain'), findsOneWidget);

    await tester.tap(find.text('Lanjutkan Bermain'));
    await tester.pump();
    expect(provider.status, Game2048Status.playing);
  });

  testWidgets('shows game-over results and remains usable at 343 by 775', (
    WidgetTester tester,
  ) async {
    final provider = Game2048Provider(
      engine: _WidgetScriptedEngine(
        initialTiles: [_screenTile(1, 2), _screenTile(2, 2)],
        results: [
          _screenResult(
            tiles: [_screenTile(3, 4)],
            scoreGained: 4,
            isGameOver: true,
          ),
        ],
        hasAvailableMoves: false,
      ),
      storage: _WidgetMemoryStorage(bestScore: 2),
      repository: _WidgetRepository(),
    );
    await provider.newGame();
    provider.swipe(Game2048Direction.left);
    await provider.completeAnimation();

    await tester.binding.setSurfaceSize(const Size(343, 775));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_screenHarness(provider));
    await tester.pumpAndSettle();

    expect(find.text('Game Selesai'), findsOneWidget);
    expect(find.text('Skor Akhir'), findsOneWidget);
    expect(find.text('4'), findsWidgets);
    expect(find.text('Tile Tertinggi'), findsOneWidget);
    expect(find.text('Main Lagi'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Main Lagi'));
    await tester.pumpAndSettle();
    expect(provider.status, Game2048Status.playing);
  });
}
