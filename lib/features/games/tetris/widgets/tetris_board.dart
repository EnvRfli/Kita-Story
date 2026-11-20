import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/tetris_game_state.dart';
import '../models/tetromino.dart';
import 'tetris_mino.dart';

class TetrisBoard extends StatelessWidget {
  const TetrisBoard({
    super.key,
    required this.board,
    required this.activePiece,
    required this.ghostRow,
    required this.clearingRows,
  });

  final List<List<int?>> board;
  final TetrisPiece? activePiece;
  final int ghostRow;
  final List<int> clearingRows;

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
        final maxHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 640.0;
        final boardWidth = math.min(maxWidth, maxHeight / 2);
        final padding = boardWidth * 0.016;
        final innerWidth = boardWidth - (padding * 2);
        final cell = innerWidth / TetrisGameState.columns;
        final boardHeight = (cell * TetrisGameState.rows) + (padding * 2);

        final activeCells = <TetrisCell, TetrominoType>{};
        if (activePiece != null) {
          for (final cellPosition in activePiece!.cells) {
            activeCells[cellPosition] = activePiece!.type;
          }
        }

        final ghostCells = <TetrisCell, TetrominoType>{};
        if (activePiece != null && ghostRow > activePiece!.row) {
          for (final offset
              in activePiece!.type.cellsForRotation(activePiece!.rotation)) {
            final position = TetrisCell(
              ghostRow + offset.row,
              activePiece!.col + offset.col,
            );
            if (position.row < 0 || position.row >= TetrisGameState.rows) {
              continue;
            }
            if (position.col < 0 || position.col >= TetrisGameState.columns) {
              continue;
            }
            if (board[position.row][position.col] != null) continue;
            if (activeCells.containsKey(position)) continue;
            ghostCells[position] = activePiece!.type;
          }
        }

        return Semantics(
          label: 'Papan permainan Tetris',
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(boardWidth * 0.055),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF64748B).withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var row = 0; row < TetrisGameState.rows; row++)
                      _BoardRow(
                        row: row,
                        cell: cell,
                        board: board,
                        activeCells: activeCells,
                        ghostCells: ghostCells,
                        isClearing: clearingRows.contains(row),
                        disableAnimations: disableAnimations,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({
    required this.row,
    required this.cell,
    required this.board,
    required this.activeCells,
    required this.ghostCells,
    required this.isClearing,
    required this.disableAnimations,
  });

  final int row;
  final double cell;
  final List<List<int?>> board;
  final Map<TetrisCell, TetrominoType> activeCells;
  final Map<TetrisCell, TetrominoType> ghostCells;
  final bool isClearing;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cell,
      child: Stack(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var col = 0; col < TetrisGameState.columns; col++)
                _BoardCell(
                  row: row,
                  col: col,
                  cell: cell,
                  board: board,
                  activeCells: activeCells,
                  ghostCells: ghostCells,
                ),
            ],
          ),
          if (isClearing)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.20),
                        Colors.white.withValues(alpha: 0.78),
                        Colors.white.withValues(alpha: 0.20),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(cell * 0.18),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    required this.row,
    required this.col,
    required this.cell,
    required this.board,
    required this.activeCells,
    required this.ghostCells,
  });

  final int row;
  final int col;
  final double cell;
  final List<List<int?>> board;
  final Map<TetrisCell, TetrominoType> activeCells;
  final Map<TetrisCell, TetrominoType> ghostCells;

  @override
  Widget build(BuildContext context) {
    final position = TetrisCell(row, col);
    final boardValue = board[row][col];
    final boardType =
        boardValue == null ? null : TetrominoType.values[boardValue];
    final activeType = activeCells[position];
    final ghostType = ghostCells[position];

    Widget child;
    if (boardType != null) {
      child = TetrisMino(type: boardType, size: cell);
    } else if (activeType != null) {
      child = TetrisMino(type: activeType, size: cell);
    } else if (ghostType != null) {
      child = TetrisMino(type: ghostType, size: cell, isGhost: true);
    } else {
      child = TetrisEmptyCell(size: cell);
    }

    return SizedBox(
      key: ValueKey('tetris-cell-$row-$col'),
      width: cell,
      height: cell,
      child: Padding(
        padding: EdgeInsets.all(cell * 0.055),
        child: child,
      ),
    );
  }
}
