import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/game_2048/engine/game_2048_engine.dart';
import 'package:kita_story/features/games/game_2048/models/game_2048_move.dart';
import 'package:kita_story/features/games/game_2048/models/game_2048_tile.dart';

List<Game2048Tile> row(List<int> values) => [
      for (var col = 0; col < values.length; col++)
        if (values[col] != 0)
          Game2048Tile(
            id: col + 1,
            value: values[col],
            position: Game2048Position(0, col),
          ),
    ];

List<int> firstRow(Game2048MoveResult result) {
  final values = List.filled(4, 0);
  for (final tile in result.tiles.where((tile) => tile.position.row == 0)) {
    values[tile.position.col] = tile.value;
  }
  return values;
}

List<Game2048Tile> sparseBoard() => const [
      Game2048Tile(id: 1, value: 2, position: Game2048Position(0, 1)),
      Game2048Tile(id: 2, value: 4, position: Game2048Position(1, 2)),
    ];

Game2048Tile tileAt(
  Game2048MoveResult result,
  int row,
  int col,
) =>
    result.tiles.singleWhere(
      (tile) => tile.position == Game2048Position(row, col),
    );

List<Game2048Tile> fullCheckerboard({bool horizontalMatch = false}) => [
      for (var row = 0; row < 4; row++)
        for (var col = 0; col < 4; col++)
          Game2048Tile(
            id: row * 4 + col + 1,
            value: horizontalMatch && row == 0 && col == 1
                ? 2
                : (row + col).isEven
                    ? 2
                    : 4,
            position: Game2048Position(row, col),
          ),
    ];

void main() {
  test('merges four equal tiles into two tiles only once', () {
    final result = Game2048Engine().move(
      row([2, 2, 2, 2]),
      Game2048Direction.left,
    );

    expect(firstRow(result), [4, 4, 0, 0]);
    expect(result.scoreGained, 8);
    expect(result.merges, hasLength(2));
  });

  test('does not merge a produced tile again in the same swipe', () {
    final result = Game2048Engine().move(
      row([2, 2, 4, 0]),
      Game2048Direction.left,
    );

    expect(firstRow(result), [4, 4, 0, 0]);
    expect(result.scoreGained, 4);
  });

  test('moves a sparse board left toward column zero', () {
    final result = Game2048Engine().move(
      sparseBoard(),
      Game2048Direction.left,
    );

    expect(tileAt(result, 0, 0).value, 2);
    expect(tileAt(result, 1, 0).value, 4);
  });

  test('moves a sparse board right toward column three', () {
    final result = Game2048Engine().move(
      sparseBoard(),
      Game2048Direction.right,
    );

    expect(tileAt(result, 0, 3).value, 2);
    expect(tileAt(result, 1, 3).value, 4);
  });

  test('moves a sparse board up toward row zero', () {
    final result = Game2048Engine().move(
      sparseBoard(),
      Game2048Direction.up,
    );

    expect(tileAt(result, 0, 1).value, 2);
    expect(tileAt(result, 0, 2).value, 4);
  });

  test('moves a sparse board down toward row three', () {
    final result = Game2048Engine().move(
      sparseBoard(),
      Game2048Direction.down,
    );

    expect(tileAt(result, 3, 1).value, 2);
    expect(tileAt(result, 3, 2).value, 4);
  });

  test(
      'reports no movement and no coordinate transitions for an unchanged swipe',
      () {
    final result = Game2048Engine().move(
      row([2, 4, 8, 16]),
      Game2048Direction.left,
    );

    expect(result.didMove, isFalse);
    expect(
        result.transitions
            .where((transition) => transition.from != transition.to),
        isEmpty);
  });

  test('spawns the injected value at a seeded empty position', () {
    final engine = Game2048Engine(
      random: Random(1),
      spawnValue: () => 4,
    );

    final spawned = engine.spawnTile(row([2, 0, 0, 0]));

    expect(spawned, hasLength(2));
    final newTile = spawned.singleWhere((tile) => tile.id != 1);
    expect(newTile.value, 4);
    expect(newTile.position, const Game2048Position(2, 2));
  });

  test('creates two initial tiles at distinct board positions', () {
    final tiles = Game2048Engine(random: Random(1)).createInitialTiles();

    expect(tiles, hasLength(2));
    expect(tiles.map((tile) => tile.id).toSet(), hasLength(2));
    expect(tiles.map((tile) => tile.position).toSet(), hasLength(2));
    expect(tiles.map((tile) => tile.value), everyElement(anyOf(2, 4)));
  });

  test('reports no available move for a full board without equal neighbors',
      () {
    expect(Game2048Engine().hasAvailableMove(fullCheckerboard()), isFalse);
  });

  test('reports an available move for a full board with equal neighbors', () {
    expect(
      Game2048Engine()
          .hasAvailableMove(fullCheckerboard(horizontalMatch: true)),
      isTrue,
    );
  });

  test('reports game over when a full checkerboard cannot move', () {
    final result = Game2048Engine().move(
      fullCheckerboard(),
      Game2048Direction.left,
    );

    expect(result.didMove, isFalse);
    expect(result.isGameOver, isTrue);
  });

  test('records every merge source and assigns a new result id', () {
    final result = Game2048Engine().move(
      row([2, 2, 0, 0]),
      Game2048Direction.left,
    );

    expect(result.transitions.map((transition) => transition.tileId), [1, 2]);
    expect(result.transitions.map((transition) => transition.to), [
      const Game2048Position(0, 0),
      const Game2048Position(0, 0),
    ]);
    expect(result.merges.single.sourceTileIds, [1, 2]);
    expect(result.merges.single.resultTileId, isNot(anyOf(1, 2)));
  });

  test('copyWith moves a tile without changing its stable id', () {
    const tile = Game2048Tile(
      id: 7,
      value: 2,
      position: Game2048Position(0, 0),
    );

    final moved = tile.copyWith(position: const Game2048Position(0, 3));

    expect(moved.id, 7);
    expect(moved.value, 2);
    expect(moved.position, const Game2048Position(0, 3));
  });

  test('move result retains its transition and merge animation metadata', () {
    const from = Game2048Position(0, 0);
    const to = Game2048Position(0, 3);
    const transition = Game2048Transition(tileId: 7, from: from, to: to);
    final merge = Game2048Merge(
      sourceTileIds: [7, 8],
      resultTileId: 7,
      value: 4,
      position: to,
    );
    final result = Game2048MoveResult(
      tiles: [Game2048Tile(id: 7, value: 4, position: to)],
      transitions: [transition],
      merges: [merge],
      scoreGained: 4,
      didMove: true,
      isGameOver: false,
      highestTile: 4,
    );

    expect(Game2048Direction.values, contains(Game2048Direction.left));
    expect(result.transitions.single.to, to);
    expect(result.merges.single.sourceTileIds, [7, 8]);
    expect(result.scoreGained, 4);
    expect(result.didMove, isTrue);
    expect(result.isGameOver, isFalse);
    expect(result.highestTile, 4);
  });

  test('move metadata collections are isolated and unmodifiable', () {
    const position = Game2048Position(0, 0);
    const tile = Game2048Tile(id: 7, value: 2, position: position);
    const transition = Game2048Transition(
      tileId: 7,
      from: position,
      to: position,
    );
    final sourceTileIds = [7, 8];
    final merge = Game2048Merge(
      sourceTileIds: sourceTileIds,
      resultTileId: 7,
      value: 4,
      position: position,
    );
    final tiles = [tile];
    final transitions = [transition];
    final merges = [merge];
    final result = Game2048MoveResult(
      tiles: tiles,
      transitions: transitions,
      merges: merges,
      scoreGained: 4,
      didMove: true,
      isGameOver: false,
      highestTile: 4,
    );

    sourceTileIds.add(16);
    tiles.clear();
    transitions.clear();
    merges.clear();

    expect(merge.sourceTileIds, [7, 8]);
    expect(result.tiles, [tile]);
    expect(result.transitions, [transition]);
    expect(result.merges, [merge]);
    expect(() => merge.sourceTileIds.add(16), throwsUnsupportedError);
    expect(() => result.tiles.clear(), throwsUnsupportedError);
    expect(() => result.transitions.clear(), throwsUnsupportedError);
    expect(() => result.merges.clear(), throwsUnsupportedError);
  });
}
