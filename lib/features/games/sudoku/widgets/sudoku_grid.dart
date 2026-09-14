import 'package:flutter/material.dart';
import 'package:kita_story/features/games/sudoku/models/sudoku_cell.dart';

import 'package:kita_story/features/games/sudoku/models/sudoku_hint.dart';

class SudokuGrid extends StatefulWidget {
  final List<List<SudokuCell>> grid;
  final SudokuPosition? selectedCell;
  final SudokuHint? currentHint;
  final Function(int row, int col) onCellTap;

  const SudokuGrid({
    super.key,
    required this.grid,
    this.selectedCell,
    this.currentHint,
    required this.onCellTap,
  });

  @override
  State<SudokuGrid> createState() => _SudokuGridState();
}

class _SudokuGridState extends State<SudokuGrid> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<Color?> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnimation = ColorTween(
      begin: const Color(0xFFE6F4FF),
      end: const Color(0xFFBAE0FF),
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(SudokuGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentHint != null && oldWidget.currentHint == null) {
      _pulseController.repeat(reverse: true);
    } else if (widget.currentHint == null && oldWidget.currentHint != null) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.grid.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(9, (row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(9, (col) {
              return _buildCell(row, col);
            }),
          );
        }),
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    final cell = widget.grid[row][col];
    final isSelected = widget.selectedCell?.row == row && widget.selectedCell?.col == col;
    final hint = widget.currentHint;

    bool isTarget = hint != null && hint.row == row && hint.col == col;
    bool isRelated = hint != null && hint.relatedAreas.any((pos) => pos.row == row && pos.col == col);
    bool isEvidence = hint != null && hint.evidenceCells.any((pos) => pos.row == row && pos.col == col);

    bool isRelatedToSelection = false;
    bool isSameNumber = false;

    if (widget.selectedCell != null && hint == null) {
      int sRow = widget.selectedCell!.row;
      int sCol = widget.selectedCell!.col;
      
      // Check related to selection (same row, col, or block)
      if (row == sRow || col == sCol) {
        isRelatedToSelection = true;
      } else if ((row ~/ 3) == (sRow ~/ 3) && (col ~/ 3) == (sCol ~/ 3)) {
        isRelatedToSelection = true;
      }

      // Check same number
      int sVal = widget.grid[sRow][sCol].value;
      if (sVal != 0 && cell.value == sVal) {
        isSameNumber = true;
      }
    }

    final topBorder = row % 3 == 0 && row != 0 ? 1.5 : 0.5;
    final leftBorder = col % 3 == 0 && col != 0 ? 1.5 : 0.5;
    const bottomBorder = 0.5;
    const rightBorder = 0.5;

    Color bgColor = Colors.white;
    if (cell.hasError) {
      bgColor = const Color(0xFFFFF1F0); // Red error
    } else if (isTarget) {
      // Background handled by AnimatedBuilder below
    } else if (isSameNumber) {
      bgColor = const Color(0xFFBAE0FF); // Stronger blue for same numbers
    } else if (isSelected) {
      bgColor = const Color(0xFFE6F4FF); // Light blue for selection
    } else if (isRelated && !isTarget) {
      bgColor = const Color(0xFFFFFBE6); // Light yellow for related hint areas
    } else if (isRelatedToSelection && !isSelected) {
      bgColor = const Color(0xFFF1F5F9); // Sangat soft slate grey/blue untuk area terkait seleksi
    }

    Color textColor = const Color(0xFF1E293B);
    if (cell.hasError) {
      textColor = const Color(0xFFFF4D4F); // Red error text
    } else if (isEvidence) {
      textColor = const Color(0xFFFA541C); // Bright orange for evidence numbers
    } else if (!cell.isFixed && cell.value != 0) {
      textColor = const Color(0xFF0088FF); // Blue user text
    }

    Widget cellContent = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: const Color(0xFF1E293B), width: topBorder),
          left: BorderSide(color: const Color(0xFF1E293B), width: leftBorder),
          bottom: const BorderSide(color: Color(0xFFCBD5E1), width: bottomBorder),
          right: const BorderSide(color: Color(0xFFCBD5E1), width: rightBorder),
        ),
      ),
      alignment: Alignment.center,
      child: cell.value != 0
          ? Text(
              cell.value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: cell.isFixed || isEvidence ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
            )
          : null,
    );

    if (isTarget) {
      cellContent = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _pulseAnimation.value,
              border: Border(
                top: BorderSide(color: const Color(0xFF1E293B), width: topBorder),
                left: BorderSide(color: const Color(0xFF1E293B), width: leftBorder),
                bottom: const BorderSide(color: Color(0xFFCBD5E1), width: bottomBorder),
                right: const BorderSide(color: Color(0xFFCBD5E1), width: rightBorder),
              ),
            ),
            alignment: Alignment.center,
            child: child,
          );
        },
        child: cell.value != 0
            ? Text(
                cell.value.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              )
            : null,
      );
    } else {
      // Use AnimatedContainer for smooth transition of background colors when hints appear/disappear
      cellContent = AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            top: BorderSide(color: const Color(0xFF1E293B), width: topBorder),
            left: BorderSide(color: const Color(0xFF1E293B), width: leftBorder),
            bottom: const BorderSide(color: Color(0xFFCBD5E1), width: bottomBorder),
            right: const BorderSide(color: Color(0xFFCBD5E1), width: rightBorder),
          ),
        ),
        alignment: Alignment.center,
        child: cell.value != 0
            ? Text(
                cell.value.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: cell.isFixed || isEvidence ? FontWeight.w700 : FontWeight.w600,
                  color: textColor,
                ),
              )
            : null,
      );
    }

    return GestureDetector(
      onTap: () => widget.onCellTap(row, col),
      child: cellContent,
    );
  }
}
