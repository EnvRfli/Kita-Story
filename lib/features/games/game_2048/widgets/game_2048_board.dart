import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_2048_move.dart';
import '../models/game_2048_tile.dart';
import 'game_2048_tile_widget.dart';

class Game2048Board extends StatefulWidget {
  const Game2048Board({
    super.key,
    required this.tiles,
    required this.onSwipe,
    this.transitions = const [],
    this.merges = const [],
    this.animationDuration = const Duration(milliseconds: 170),
  });

  final List<Game2048Tile> tiles;
  final List<Game2048Transition> transitions;
  final List<Game2048Merge> merges;
  final ValueChanged<Game2048Direction> onSwipe;
  final Duration animationDuration;

  @override
  State<Game2048Board> createState() => _Game2048BoardState();
}

class _Game2048BoardState extends State<Game2048Board> {
  static const _swipeThreshold = 24.0;

  Offset _panStart = Offset.zero;
  Offset _panOffset = Offset.zero;
  bool _didDispatchSwipe = false;
  Set<int> _previousTileIds = <int>{};
  Set<int> _spawnedTileIds = <int>{};

  @override
  void initState() {
    super.initState();
    _previousTileIds = widget.tiles.map((tile) => tile.id).toSet();
  }

  @override
  void didUpdateWidget(Game2048Board oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIds = widget.tiles.map((tile) => tile.id).toSet();
    _spawnedTileIds = currentIds.difference(_previousTileIds);
    _previousTileIds = currentIds;
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final mergedTileIds = widget.merges
        .map((merge) => merge.resultTileId)
        .toSet();
    final movingTileIds = widget.transitions
        .where((transition) => transition.from != transition.to)
        .map((transition) => transition.tileId)
        .toSet();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        _panStart = details.localPosition;
        _panOffset = Offset.zero;
        _didDispatchSwipe = false;
      },
      onPanUpdate: (details) {
        _panOffset = details.localPosition - _panStart;
        _dispatchSwipeIfNeeded();
      },
      onPanEnd: (_) => _dispatchSwipeIfNeeded(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 440.0;
          final boardSize = math.min(availableWidth, 440.0);
          final padding = boardSize * 0.03;
          final gap = boardSize * 0.025;
          final tileSize = (boardSize - (padding * 2) - (gap * 3)) / 4;

          return SizedBox(
            width: boardSize,
            height: boardSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF5A3478),
                borderRadius: BorderRadius.circular(boardSize * 0.04),
              ),
              child: Stack(
                clipBehavior: Clip.antiAlias,
                children: [
                  for (var row = 0; row < 4; row++)
                    for (var col = 0; col < 4; col++)
                      Positioned(
                        left: padding + col * (tileSize + gap),
                        top: padding + row * (tileSize + gap),
                        width: tileSize,
                        height: tileSize,
                        child: Game2048BoardCell(row: row, col: col),
                      ),
                  for (final tile in widget.tiles)
                    Game2048TileWidget(
                      key: ValueKey('2048-tile-${tile.id}'),
                      tile: tile,
                      left: padding + tile.position.col * (tileSize + gap),
                      top: padding + tile.position.row * (tileSize + gap),
                      size: tileSize,
                      disableAnimations: disableAnimations,
                      isMoving: movingTileIds.contains(tile.id),
                      isMerged: mergedTileIds.contains(tile.id),
                      isSpawned: _spawnedTileIds.contains(tile.id),
                      animationDuration: widget.animationDuration,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _dispatchSwipeIfNeeded() {
    if (_didDispatchSwipe || _panOffset.distance < _swipeThreshold) return;

    _didDispatchSwipe = true;
    if (_panOffset.dx.abs() >= _panOffset.dy.abs()) {
      widget.onSwipe(
        _panOffset.dx.isNegative
            ? Game2048Direction.left
            : Game2048Direction.right,
      );
      return;
    }
    widget.onSwipe(
      _panOffset.dy.isNegative
          ? Game2048Direction.up
          : Game2048Direction.down,
    );
  }
}

class Game2048BoardCell extends StatelessWidget {
  Game2048BoardCell({required this.row, required this.col})
      : super(key: ValueKey('2048-background-cell-$row-$col'));

  final int row;
  final int col;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x52FFFFFF),
          borderRadius: BorderRadius.circular(10),
        ),
      );
}
