import 'dart:async';
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
  List<Game2048Tile> _mergeSourceTiles = const [];
  Map<int, Game2048Position> _mergeDestinations = const {};
  Set<int> _hiddenMergeResultIds = <int>{};
  Timer? _mergePhaseTimer;
  var _mergeAnimationGeneration = 0;
  var _moveMergeSources = false;
  var _disableAnimations = false;

  @override
  void initState() {
    super.initState();
    _previousTileIds = widget.tiles.map((tile) => tile.id).toSet();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_disableAnimations && _mergeSourceTiles.isNotEmpty) {
      _cancelMergeAnimation();
      _clearMergeVisuals();
    }
  }

  @override
  void didUpdateWidget(Game2048Board oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIds = widget.tiles.map((tile) => tile.id).toSet();
    _spawnedTileIds = currentIds.difference(_previousTileIds);
    _previousTileIds = currentIds;

    if (widget.merges.isEmpty && oldWidget.merges.isNotEmpty) {
      _cancelMergeAnimation();
      _clearMergeVisuals();
    } else if (widget.merges.isNotEmpty &&
        !_sameMergeBatch(widget.merges, oldWidget.merges)) {
      _startMergeAnimation(oldWidget.tiles);
    }
  }

  @override
  void dispose() {
    _cancelMergeAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mergedTileIds =
        widget.merges.map((merge) => merge.resultTileId).toSet();
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
          final availableWidth =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 440.0;
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
                    if (!_hiddenMergeResultIds.contains(tile.id))
                      Game2048TileWidget(
                        key: ValueKey('2048-tile-${tile.id}'),
                        tile: tile,
                        left: padding + tile.position.col * (tileSize + gap),
                        top: padding + tile.position.row * (tileSize + gap),
                        size: tileSize,
                        disableAnimations: _disableAnimations,
                        isMoving: movingTileIds.contains(tile.id),
                        isMerged: mergedTileIds.contains(tile.id),
                        isSpawned: _spawnedTileIds.contains(tile.id),
                        animationDuration: widget.animationDuration,
                      ),
                  for (final tile in _mergeSourceTiles)
                    Game2048TileWidget(
                      key: ValueKey('2048-tile-${tile.id}'),
                      tile: tile,
                      left: padding +
                          (_mergeSourcePosition(tile).col) * (tileSize + gap),
                      top: padding +
                          (_mergeSourcePosition(tile).row) * (tileSize + gap),
                      size: tileSize,
                      disableAnimations: _disableAnimations,
                      isMoving: _moveMergeSources,
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

  Game2048Position _mergeSourcePosition(Game2048Tile tile) => _moveMergeSources
      ? _mergeDestinations[tile.id] ?? tile.position
      : tile.position;

  void _startMergeAnimation(List<Game2048Tile> previousTiles) {
    _cancelMergeAnimation();

    final previousById = {
      for (final tile in previousTiles) tile.id: tile,
    };
    final transitionById = {
      for (final transition in widget.transitions)
        transition.tileId: transition,
    };
    final sourceTiles = <Game2048Tile>[];
    final destinations = <int, Game2048Position>{};

    for (final merge in widget.merges) {
      for (final sourceId in merge.sourceTileIds) {
        final source = previousById[sourceId];
        if (source == null) continue;
        final transition = transitionById[sourceId];
        sourceTiles.add(
          source.copyWith(position: transition?.from ?? source.position),
        );
        destinations[sourceId] = transition?.to ?? merge.position;
      }
    }

    if (_disableAnimations ||
        widget.animationDuration == Duration.zero ||
        sourceTiles.isEmpty) {
      _clearMergeVisuals();
      return;
    }

    _mergeSourceTiles = sourceTiles;
    _mergeDestinations = destinations;
    _hiddenMergeResultIds = {
      for (final merge in widget.merges) merge.resultTileId,
    };
    _moveMergeSources = false;
    final generation = _mergeAnimationGeneration;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _mergeAnimationGeneration) return;
      setState(() => _moveMergeSources = true);
      _mergePhaseTimer = Timer(widget.animationDuration, () {
        if (!mounted || generation != _mergeAnimationGeneration) return;
        setState(_clearMergeVisuals);
      });
    });
  }

  void _cancelMergeAnimation() {
    _mergeAnimationGeneration++;
    _mergePhaseTimer?.cancel();
    _mergePhaseTimer = null;
  }

  void _clearMergeVisuals() {
    _mergeSourceTiles = const [];
    _mergeDestinations = const {};
    _hiddenMergeResultIds = <int>{};
    _moveMergeSources = false;
  }

  static bool _sameMergeBatch(
    List<Game2048Merge> current,
    List<Game2048Merge> previous,
  ) {
    if (current.length != previous.length) return false;
    for (var index = 0; index < current.length; index++) {
      final a = current[index];
      final b = previous[index];
      if (a.resultTileId != b.resultTileId ||
          a.value != b.value ||
          a.position != b.position ||
          !_sameIds(a.sourceTileIds, b.sourceTileIds)) {
        return false;
      }
    }
    return true;
  }

  static bool _sameIds(List<int> current, List<int> previous) {
    if (current.length != previous.length) return false;
    for (var index = 0; index < current.length; index++) {
      if (current[index] != previous[index]) return false;
    }
    return true;
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
      _panOffset.dy.isNegative ? Game2048Direction.up : Game2048Direction.down,
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
