import 'dart:math';

import '../models/game_2048_move.dart';
import '../models/game_2048_tile.dart';

class Game2048Engine {
  int _nextTileId = 1;
  final Random _random;
  final int Function()? _spawnValue;

  Game2048Engine({Random? random, int Function()? spawnValue})
      : _random = random ?? Random(),
        _spawnValue = spawnValue;

  List<Game2048Tile> createInitialTiles() {
    var tiles = <Game2048Tile>[];
    tiles = spawnTile(tiles);
    return spawnTile(tiles);
  }

  List<Game2048Tile> spawnTile(List<Game2048Tile> tiles) {
    _nextTileId = max(_nextTileId, _nextAvailableId(tiles));
    final occupiedPositions = {for (final tile in tiles) tile.position};
    final emptyPositions = [
      for (var row = 0; row < 4; row++)
        for (var col = 0; col < 4; col++)
          if (!occupiedPositions.contains(Game2048Position(row, col)))
            Game2048Position(row, col),
    ];
    if (emptyPositions.isEmpty) return List.of(tiles);

    final value = _spawnValue?.call() ?? (_random.nextDouble() < 0.9 ? 2 : 4);
    return [
      ...tiles,
      Game2048Tile(
        id: _nextTileId++,
        value: value,
        position: emptyPositions[_random.nextInt(emptyPositions.length)],
      ),
    ];
  }

  bool hasAvailableMove(List<Game2048Tile> tiles) {
    final tilesByPosition = {
      for (final tile in tiles) tile.position: tile,
    };
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 4; col++) {
        final position = Game2048Position(row, col);
        final tile = tilesByPosition[position];
        if (tile == null) return true;
        if (col < 3 &&
            tile.value ==
                tilesByPosition[Game2048Position(row, col + 1)]?.value) {
          return true;
        }
        if (row < 3 &&
            tile.value ==
                tilesByPosition[Game2048Position(row + 1, col)]?.value) {
          return true;
        }
      }
    }
    return false;
  }

  Game2048MoveResult move(
    List<Game2048Tile> tiles,
    Game2048Direction direction,
  ) {
    _nextTileId = max(_nextTileId, _nextAvailableId(tiles));
    final tilesByPosition = {
      for (final tile in tiles) tile.position: tile,
    };
    final movedTiles = <Game2048Tile>[];
    final transitions = <Game2048Transition>[];
    final merges = <Game2048Merge>[];
    var scoreGained = 0;
    var didMove = false;

    for (final line in _orderedLines(direction)) {
      final compact = [
        for (final position in line)
          if (tilesByPosition[position] case final tile?) tile,
      ];
      var sourceIndex = 0;
      var destinationIndex = 0;
      while (sourceIndex < compact.length) {
        final current = compact[sourceIndex];
        final destination = line[destinationIndex];
        if (sourceIndex + 1 < compact.length &&
            compact[sourceIndex + 1].value == current.value) {
          final next = compact[sourceIndex + 1];
          final value = current.value * 2;
          final resultId = _nextTileId++;
          movedTiles.add(
            Game2048Tile(id: resultId, value: value, position: destination),
          );
          for (final source in [current, next]) {
            transitions.add(
              Game2048Transition(
                tileId: source.id,
                from: source.position,
                to: destination,
              ),
            );
          }
          merges.add(
            Game2048Merge(
              sourceTileIds: [current.id, next.id],
              resultTileId: resultId,
              value: value,
              position: destination,
            ),
          );
          scoreGained += value;
          didMove = true;
          sourceIndex += 2;
        } else {
          final movedTile = current.copyWith(position: destination);
          movedTiles.add(movedTile);
          if (current.position != destination) {
            transitions.add(
              Game2048Transition(
                tileId: current.id,
                from: current.position,
                to: destination,
              ),
            );
            didMove = true;
          }
          sourceIndex++;
        }
        destinationIndex++;
      }
    }

    return Game2048MoveResult(
      tiles: movedTiles,
      transitions: transitions,
      merges: merges,
      scoreGained: scoreGained,
      didMove: didMove,
      isGameOver: !hasAvailableMove(movedTiles),
      highestTile:
          movedTiles.fold(0, (highest, tile) => max(highest, tile.value)),
    );
  }

  int _nextAvailableId(List<Game2048Tile> tiles) =>
      tiles.fold(0, (highest, tile) => max(highest, tile.id)) + 1;

  List<List<Game2048Position>> _orderedLines(Game2048Direction direction) {
    switch (direction) {
      case Game2048Direction.left:
        return [
          for (var row = 0; row < 4; row++)
            [for (var col = 0; col < 4; col++) Game2048Position(row, col)],
        ];
      case Game2048Direction.right:
        return [
          for (var row = 0; row < 4; row++)
            [for (var col = 3; col >= 0; col--) Game2048Position(row, col)],
        ];
      case Game2048Direction.up:
        return [
          for (var col = 0; col < 4; col++)
            [for (var row = 0; row < 4; row++) Game2048Position(row, col)],
        ];
      case Game2048Direction.down:
        return [
          for (var col = 0; col < 4; col++)
            [for (var row = 3; row >= 0; row--) Game2048Position(row, col)],
        ];
    }
  }
}
