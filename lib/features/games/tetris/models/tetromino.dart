import 'package:flutter/foundation.dart';

/// The seven classic tetromino shapes.
enum TetrominoType { i, o, t, s, z, j, l }

/// A row/column coordinate used both for relative shape cells and absolute
/// board cells.
@immutable
class TetrisCell {
  const TetrisCell(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TetrisCell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'TetrisCell($row, $col)';
}

/// Shape definitions are stored relative to the piece's top-left corner.
/// Rotation 0 is the spawn orientation.
const Map<TetrominoType, List<List<TetrisCell>>> tetrominoShapes = {
  TetrominoType.i: [
    [
      TetrisCell(1, 0),
      TetrisCell(1, 1),
      TetrisCell(1, 2),
      TetrisCell(1, 3),
    ],
    [
      TetrisCell(0, 2),
      TetrisCell(1, 2),
      TetrisCell(2, 2),
      TetrisCell(3, 2),
    ],
    [
      TetrisCell(2, 0),
      TetrisCell(2, 1),
      TetrisCell(2, 2),
      TetrisCell(2, 3),
    ],
    [
      TetrisCell(0, 1),
      TetrisCell(1, 1),
      TetrisCell(2, 1),
      TetrisCell(3, 1),
    ],
  ],
  TetrominoType.o: [
    [
      TetrisCell(0, 0),
      TetrisCell(0, 1),
      TetrisCell(1, 0),
      TetrisCell(1, 1),
    ],
    [
      TetrisCell(0, 0),
      TetrisCell(0, 1),
      TetrisCell(1, 0),
      TetrisCell(1, 1),
    ],
    [
      TetrisCell(0, 0),
      TetrisCell(0, 1),
      TetrisCell(1, 0),
      TetrisCell(1, 1),
    ],
    [
      TetrisCell(0, 0),
      TetrisCell(0, 1),
      TetrisCell(1, 0),
      TetrisCell(1, 1),
    ],
  ],
  TetrominoType.t: [
    [
      TetrisCell(0, 1),
      TetrisCell(1, 0),
      TetrisCell(1, 1),
      TetrisCell(1, 2),
    ],
    [
      TetrisCell(0, 1),
      TetrisCell(1, 1),
      TetrisCell(1, 2),
      TetrisCell(2, 1),
    ],
    [
      TetrisCell(1, 0),
      TetrisCell(1, 1),
      TetrisCell(1, 2),
      TetrisCell(2, 1),
    ],
    [
      TetrisCell(0, 1),
      TetrisCell(1, 0),
      TetrisCell(1, 1),
      TetrisCell(2, 1),
    ],
  ],
  TetrominoType.s: [
    [
      TetrisCell(0, 1),
      TetrisCell(0, 2),
      TetrisCell(1, 0),
      TetrisCell(1, 1),
    ],
    [
      TetrisCell(0, 1),
      TetrisCell(1, 1),
      TetrisCell(1, 2),
      TetrisCell(2, 2),
    ],
    [
      TetrisCell(1, 1),
      TetrisCell(1, 2),
      TetrisCell(2, 0),
      TetrisCell(2, 1),
    ],
    [
      TetrisCell(0, 0),
      TetrisCell(1, 0),
      TetrisCell(1, 1),
      TetrisCell(2, 1),
    ],
  ],
  TetrominoType.z: [
    [
      TetrisCell(0, 0),
      TetrisCell(0, 1),
      TetrisCell(1, 1),
      TetrisCell(1, 2),
    ],
    [
      TetrisCell(0, 2),
      TetrisCell(1, 1),
      TetrisCell(1, 2),
      TetrisCell(2, 1),
    ],
    [
      TetrisCell(1, 0),
      TetrisCell(1, 1),
      TetrisCell(2, 1),
      TetrisCell(2, 2),
    ],
    [
      TetrisCell(0, 1),
      TetrisCell(1, 0),
      TetrisCell(1, 1),
      TetrisCell(2, 0),
    ],
  ],
  TetrominoType.j: [
    [
      TetrisCell(0, 0),
      TetrisCell(1, 0),
      TetrisCell(1, 1),
      TetrisCell(1, 2),
    ],
    [
      TetrisCell(0, 1),
      TetrisCell(0, 2),
      TetrisCell(1, 1),
      TetrisCell(2, 1),
    ],
    [
      TetrisCell(1, 0),
      TetrisCell(1, 1),
      TetrisCell(1, 2),
      TetrisCell(2, 2),
    ],
    [
      TetrisCell(0, 1),
      TetrisCell(1, 1),
      TetrisCell(2, 0),
      TetrisCell(2, 1),
    ],
  ],
  TetrominoType.l: [
    [
      TetrisCell(0, 2),
      TetrisCell(1, 0),
      TetrisCell(1, 1),
      TetrisCell(1, 2),
    ],
    [
      TetrisCell(0, 1),
      TetrisCell(1, 1),
      TetrisCell(2, 1),
      TetrisCell(2, 2),
    ],
    [
      TetrisCell(1, 0),
      TetrisCell(1, 1),
      TetrisCell(1, 2),
      TetrisCell(2, 0),
    ],
    [
      TetrisCell(0, 0),
      TetrisCell(0, 1),
      TetrisCell(1, 1),
      TetrisCell(2, 1),
    ],
  ],
};

extension TetrominoTypeX on TetrominoType {
  String get label => switch (this) {
        TetrominoType.i => 'I',
        TetrominoType.o => 'O',
        TetrominoType.t => 'T',
        TetrominoType.s => 'S',
        TetrominoType.z => 'Z',
        TetrominoType.j => 'J',
        TetrominoType.l => 'L',
      };

  List<TetrisCell> cellsForRotation(int rotation) {
    final shapes = tetrominoShapes[this]!;
    return shapes[rotation % 4];
  }

  int widthForRotation(int rotation) {
    final cells = cellsForRotation(rotation);
    var maxCol = 0;
    for (final cell in cells) {
      if (cell.col > maxCol) maxCol = cell.col;
    }
    return maxCol + 1;
  }

  int heightForRotation(int rotation) {
    final cells = cellsForRotation(rotation);
    var maxRow = 0;
    for (final cell in cells) {
      if (cell.row > maxRow) maxRow = cell.row;
    }
    return maxRow + 1;
  }

  static TetrominoType? fromLabel(String label) {
    for (final type in TetrominoType.values) {
      if (type.label == label) return type;
    }
    return null;
  }
}

/// A placed or falling piece.
@immutable
class TetrisPiece {
  const TetrisPiece({
    required this.type,
    required this.rotation,
    required this.row,
    required this.col,
  });

  final TetrominoType type;
  final int rotation;
  final int row;
  final int col;

  List<TetrisCell> get cells => [
        for (final offset in type.cellsForRotation(rotation))
          TetrisCell(row + offset.row, col + offset.col),
      ];

  int get width => type.widthForRotation(rotation);
  int get height => type.heightForRotation(rotation);

  TetrisPiece copyWith({
    int? rotation,
    int? row,
    int? col,
  }) =>
      TetrisPiece(
        type: type,
        rotation: rotation ?? this.rotation,
        row: row ?? this.row,
        col: col ?? this.col,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TetrisPiece &&
          other.type == type &&
          other.rotation == rotation &&
          other.row == row &&
          other.col == col;

  @override
  int get hashCode => Object.hash(type, rotation, row, col);

  @override
  String toString() =>
      'TetrisPiece(${type.label}, rotation: $rotation, row: $row, col: $col)';
}
