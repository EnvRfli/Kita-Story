import 'package:flutter/foundation.dart';
import 'game_2048_tile.dart';

enum Game2048Direction {
  left,
  right,
  up,
  down,
}

@immutable
class Game2048Transition {
  final int tileId;
  final Game2048Position from;
  final Game2048Position to;

  const Game2048Transition({
    required this.tileId,
    required this.from,
    required this.to,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Game2048Transition &&
          runtimeType == other.runtimeType &&
          tileId == other.tileId &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(tileId, from, to);

  @override
  String toString() => 'Game2048Transition(id: $tileId, $from -> $to)';
}

@immutable
class Game2048Merge {
  final List<int> sourceTileIds;
  final int resultTileId;
  final int value;
  final Game2048Position position;

  Game2048Merge({
    required List<int> sourceTileIds,
    required this.resultTileId,
    required this.value,
    required this.position,
  }) : sourceTileIds = List.unmodifiable(sourceTileIds);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Game2048Merge &&
          runtimeType == other.runtimeType &&
          listEquals(sourceTileIds, other.sourceTileIds) &&
          resultTileId == other.resultTileId &&
          value == other.value &&
          position == other.position;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(sourceTileIds),
        resultTileId,
        value,
        position,
      );

  @override
  String toString() =>
      'Game2048Merge(sources: $sourceTileIds -> $resultTileId = $value at $position)';
}

@immutable
class Game2048MoveResult {
  final List<Game2048Tile> tiles;
  final List<Game2048Transition> transitions;
  final List<Game2048Merge> merges;
  final int scoreGained;
  final bool didMove;
  final bool isGameOver;
  final int highestTile;

  Game2048MoveResult({
    required List<Game2048Tile> tiles,
    required List<Game2048Transition> transitions,
    required List<Game2048Merge> merges,
    required this.scoreGained,
    required this.didMove,
    required this.isGameOver,
    required this.highestTile,
  })  : tiles = List.unmodifiable(tiles),
        transitions = List.unmodifiable(transitions),
        merges = List.unmodifiable(merges);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Game2048MoveResult &&
          runtimeType == other.runtimeType &&
          listEquals(tiles, other.tiles) &&
          listEquals(transitions, other.transitions) &&
          listEquals(merges, other.merges) &&
          scoreGained == other.scoreGained &&
          didMove == other.didMove &&
          isGameOver == other.isGameOver &&
          highestTile == other.highestTile;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(tiles),
        Object.hashAll(transitions),
        Object.hashAll(merges),
        scoreGained,
        didMove,
        isGameOver,
        highestTile,
      );
}
