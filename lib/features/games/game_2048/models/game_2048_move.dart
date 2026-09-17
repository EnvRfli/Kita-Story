import 'game_2048_tile.dart';

enum Game2048Direction { left, right, up, down }

class Game2048Transition {
  final int tileId;
  final Game2048Position from;
  final Game2048Position to;

  const Game2048Transition({
    required this.tileId,
    required this.from,
    required this.to,
  });
}

class Game2048Merge {
  final List<int> sourceTileIds;
  final int resultTileId;
  final int value;
  final Game2048Position position;

  const Game2048Merge({
    required this.sourceTileIds,
    required this.resultTileId,
    required this.value,
    required this.position,
  });
}

class Game2048MoveResult {
  final List<Game2048Tile> tiles;
  final List<Game2048Transition> transitions;
  final List<Game2048Merge> merges;
  final int scoreGained;
  final bool didMove;
  final bool isGameOver;
  final int highestTile;

  const Game2048MoveResult({
    required this.tiles,
    required this.transitions,
    required this.merges,
    required this.scoreGained,
    required this.didMove,
    required this.isGameOver,
    required this.highestTile,
  });
}
