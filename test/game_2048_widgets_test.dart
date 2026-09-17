import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/game_2048/models/game_2048_move.dart';
import 'package:kita_story/features/games/game_2048/models/game_2048_tile.dart';
import 'package:kita_story/features/games/game_2048/widgets/game_2048_board.dart';
import 'package:kita_story/features/games/game_2048/widgets/game_2048_tile_widget.dart';

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
}
