import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/game_2048/models/game_2048_move.dart';
import 'package:kita_story/features/games/game_2048/models/game_2048_tile.dart';

void main() {
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
