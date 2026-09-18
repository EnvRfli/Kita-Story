import 'dart:math';

import '../models/game_2048_move.dart';
import '../models/game_2048_tile.dart';

class Game2048Engine {
  final Random _random;
  final int Function() _spawnValue;
  int _nextTileId;

  Game2048Engine({
    Random? random,
    int Function()? spawnValue,
    int initialTileId = 1,
  })  : _random = random ?? Random(),
        _spawnValue = spawnValue ??
            (() => (random ?? Random()).nextDouble() < 0.9 ? 2 : 4),
        _nextTileId = initialTileId;

  int _generateTileId(Iterable<Game2048Tile> existingTiles) {
    var maxId = _nextTileId;
    for (final tile in existingTiles) {
      if (tile.id >= maxId) {
        maxId = tile.id + 1;
      }
    }
    _nextTileId = maxId + 1;
    return maxId;
  }

  List<Game2048Tile> createInitialTiles() {
    final first = spawnTile(const []);
    return spawnTile(first);
  }

  List<Game2048Tile> spawnTile(List<Game2048Tile> tiles) {
    final occupied = <Game2048Position>{
      for (final t in tiles) t.position,
    };

    final emptyPositions = <Game2048Position>[];
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        final pos = Game2048Position(r, c);
        if (!occupied.contains(pos)) {
          emptyPositions.add(pos);
        }
      }
    }

    if (emptyPositions.isEmpty) {
      return List<Game2048Tile>.from(tiles);
    }

    final selectedPos = emptyPositions[_random.nextInt(emptyPositions.length)];
    final value = _spawnValue();
    final newId = _generateTileId(tiles);

    final newTile = Game2048Tile(
      id: newId,
      value: value,
      position: selectedPos,
    );

    return [...tiles, newTile];
  }

  bool hasAvailableMove(List<Game2048Tile> tiles) {
    if (tiles.length < 16) return true;

    final grid = List.generate(
      4,
      (_) => List<int?>.filled(4, null),
    );

    for (final tile in tiles) {
      grid[tile.position.row][tile.position.col] = tile.value;
    }

    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        final current = grid[r][c];
        if (current == null) return true;

        if (c < 3 && grid[r][c + 1] == current) return true;
        if (r < 3 && grid[r + 1][c] == current) return true;
      }
    }

    return false;
  }

  Game2048MoveResult move(
    List<Game2048Tile> tiles,
    Game2048Direction direction,
  ) {
    var scoreGained = 0;
    var didMove = false;
    final transitions = <Game2048Transition>[];
    final merges = <Game2048Merge>[];
    final resultingTiles = <Game2048Tile>[];

    // Build grid lookup
    final grid = List.generate(
      4,
      (_) => List<Game2048Tile?>.filled(4, null),
    );
    for (final tile in tiles) {
      grid[tile.position.row][tile.position.col] = tile;
    }

    for (var lineIdx = 0; lineIdx < 4; lineIdx++) {
      final lineTiles = <Game2048Tile>[];

      for (var posIdx = 0; posIdx < 4; posIdx++) {
        final r = switch (direction) {
          Game2048Direction.left || Game2048Direction.right => lineIdx,
          Game2048Direction.up => posIdx,
          Game2048Direction.down => 3 - posIdx,
        };
        final c = switch (direction) {
          Game2048Direction.left => posIdx,
          Game2048Direction.right => 3 - posIdx,
          Game2048Direction.up || Game2048Direction.down => lineIdx,
        };

        final tile = grid[r][c];
        if (tile != null) {
          lineTiles.add(tile);
        }
      }

      var writePos = 0;
      var readIdx = 0;

      while (readIdx < lineTiles.length) {
        final current = lineTiles[readIdx];
        final destRow = switch (direction) {
          Game2048Direction.left || Game2048Direction.right => lineIdx,
          Game2048Direction.up => writePos,
          Game2048Direction.down => 3 - writePos,
        };
        final destCol = switch (direction) {
          Game2048Direction.left => writePos,
          Game2048Direction.right => 3 - writePos,
          Game2048Direction.up || Game2048Direction.down => lineIdx,
        };
        final destPos = Game2048Position(destRow, destCol);

        if (readIdx + 1 < lineTiles.length &&
            lineTiles[readIdx + 1].value == current.value) {
          final next = lineTiles[readIdx + 1];
          final mergedValue = current.value * 2;
          scoreGained += mergedValue;
          didMove = true;

          transitions.add(
            Game2048Transition(
              tileId: current.id,
              from: current.position,
              to: destPos,
            ),
          );
          transitions.add(
            Game2048Transition(
              tileId: next.id,
              from: next.position,
              to: destPos,
            ),
          );

          final resultTileId = _generateTileId([...tiles, ...resultingTiles]);
          merges.add(
            Game2048Merge(
              sourceTileIds: [current.id, next.id],
              resultTileId: resultTileId,
              value: mergedValue,
              position: destPos,
            ),
          );

          resultingTiles.add(
            Game2048Tile(
              id: resultTileId,
              value: mergedValue,
              position: destPos,
            ),
          );

          readIdx += 2;
          writePos++;
        } else {
          if (current.position != destPos) {
            didMove = true;
          }

          transitions.add(
            Game2048Transition(
              tileId: current.id,
              from: current.position,
              to: destPos,
            ),
          );

          resultingTiles.add(
            current.copyWith(position: destPos),
          );

          readIdx++;
          writePos++;
        }
      }
    }

    final finalTiles = didMove ? resultingTiles : tiles;
    var highestTile = 0;
    for (final tile in finalTiles) {
      if (tile.value > highestTile) {
        highestTile = tile.value;
      }
    }

    final isGameOver = !didMove && !hasAvailableMove(finalTiles);

    return Game2048MoveResult(
      tiles: finalTiles,
      transitions: transitions,
      merges: merges,
      scoreGained: scoreGained,
      didMove: didMove,
      isGameOver: isGameOver,
      highestTile: highestTile,
    );
  }
}
