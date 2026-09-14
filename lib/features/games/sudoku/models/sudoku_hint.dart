import 'package:kita_story/features/games/sudoku/models/sudoku_cell.dart';

class SudokuHint {
  final int row;
  final int col;
  final int value;
  final String title;
  final String reason;
  final List<SudokuPosition> relatedAreas;
  final List<SudokuPosition> evidenceCells;

  const SudokuHint({
    required this.row,
    required this.col,
    required this.value,
    required this.title,
    required this.reason,
    this.relatedAreas = const [],
    this.evidenceCells = const [],
  });
}
