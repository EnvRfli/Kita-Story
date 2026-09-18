import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/2048/models/game_2048_move.dart';
import 'package:kita_story/features/games/2048/models/game_2048_tile.dart';
import 'package:kita_story/features/games/2048/widgets/game_2048_board.dart';
import 'package:kita_story/features/games/2048/widgets/game_2048_tile_widget.dart';

const _animationDuration = Duration(milliseconds: 100);
const _initialTiles = [
  Game2048Tile(
    id: 1,
    value: 2,
    position: Game2048Position(0, 0),
  ),
  Game2048Tile(
    id: 2,
    value: 2,
    position: Game2048Position(0, 1),
  ),
];

final _firstMergeFrame = _BoardFrame(
  tiles: const [
    Game2048Tile(
      id: 3,
      value: 4,
      position: Game2048Position(0, 0),
    ),
    Game2048Tile(
      id: 4,
      value: 4,
      position: Game2048Position(0, 1),
    ),
  ],
  transitions: const [
    Game2048Transition(
      tileId: 1,
      from: Game2048Position(0, 0),
      to: Game2048Position(0, 0),
    ),
    Game2048Transition(
      tileId: 2,
      from: Game2048Position(0, 1),
      to: Game2048Position(0, 0),
    ),
  ],
  merges: [
    Game2048Merge(
      sourceTileIds: [1, 2],
      resultTileId: 3,
      value: 4,
      position: const Game2048Position(0, 0),
    ),
  ],
);

final _secondMergeFrame = _BoardFrame(
  tiles: const [
    Game2048Tile(
      id: 5,
      value: 8,
      position: Game2048Position(0, 0),
    ),
  ],
  transitions: const [
    Game2048Transition(
      tileId: 3,
      from: Game2048Position(0, 0),
      to: Game2048Position(0, 0),
    ),
    Game2048Transition(
      tileId: 4,
      from: Game2048Position(0, 1),
      to: Game2048Position(0, 0),
    ),
  ],
  merges: [
    Game2048Merge(
      sourceTileIds: [3, 4],
      resultTileId: 5,
      value: 8,
      position: const Game2048Position(0, 0),
    ),
  ],
);

class _BoardFrame {
  const _BoardFrame({
    required this.tiles,
    this.transitions = const [],
    this.merges = const [],
  });

  final List<Game2048Tile> tiles;
  final List<Game2048Transition> transitions;
  final List<Game2048Merge> merges;
}

Widget _harness(ValueNotifier<_BoardFrame> frame) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: ValueListenableBuilder<_BoardFrame>(
            valueListenable: frame,
            builder: (context, value, child) => Game2048Board(
              tiles: value.tiles,
              transitions: value.transitions,
              merges: value.merges,
              animationDuration: _animationDuration,
              onSwipe: (_) {},
            ),
          ),
        ),
      ),
    );

Game2048TileWidget _renderedTile(WidgetTester tester, int id) =>
    tester.widget<Game2048TileWidget>(
      find.byKey(ValueKey('2048-tile-$id')),
    );

void main() {
  testWidgets('merge sources slide before the result tile pops in', (
    WidgetTester tester,
  ) async {
    final frame = ValueNotifier(
      const _BoardFrame(tiles: _initialTiles),
    );
    addTearDown(frame.dispose);
    await tester.pumpWidget(_harness(frame));

    final sourceTwoStart = _renderedTile(tester, 2).left;
    frame.value = _firstMergeFrame;
    await tester.pump();

    expect(find.byKey(const ValueKey('2048-tile-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('2048-tile-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('2048-tile-3')), findsNothing);
    expect(_renderedTile(tester, 2).left, sourceTwoStart);

    await tester.pump();
    expect(_renderedTile(tester, 2).left, _renderedTile(tester, 1).left);

    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const ValueKey('2048-tile-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('2048-tile-3')), findsNothing);

    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byKey(const ValueKey('2048-tile-1')), findsNothing);
    expect(find.byKey(const ValueKey('2048-tile-2')), findsNothing);
    expect(find.byKey(const ValueKey('2048-tile-3')), findsOneWidget);
    expect(_renderedTile(tester, 3).isMerged, isTrue);
  });

  testWidgets('a rapid merge replaces the previous pending animation', (
    WidgetTester tester,
  ) async {
    final frame = ValueNotifier(
      const _BoardFrame(tiles: _initialTiles),
    );
    addTearDown(frame.dispose);
    await tester.pumpWidget(_harness(frame));

    frame.value = _firstMergeFrame;
    await tester.pump();
    frame.value = _secondMergeFrame;
    await tester.pump();

    expect(find.byKey(const ValueKey('2048-tile-1')), findsNothing);
    expect(find.byKey(const ValueKey('2048-tile-2')), findsNothing);
    expect(find.byKey(const ValueKey('2048-tile-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('2048-tile-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('2048-tile-5')), findsNothing);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));

    expect(find.byKey(const ValueKey('2048-tile-3')), findsNothing);
    expect(find.byKey(const ValueKey('2048-tile-4')), findsNothing);
    expect(find.byKey(const ValueKey('2048-tile-5')), findsOneWidget);
  });

  testWidgets('disposing during a merge cancels pending animation work', (
    WidgetTester tester,
  ) async {
    final frame = ValueNotifier(
      const _BoardFrame(tiles: _initialTiles),
    );
    addTearDown(frame.dispose);
    await tester.pumpWidget(_harness(frame));

    frame.value = _firstMergeFrame;
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
  });
}
