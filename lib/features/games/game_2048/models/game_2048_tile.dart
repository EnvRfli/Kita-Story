class Game2048Position {
  final int row;
  final int col;

  const Game2048Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is Game2048Position && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

class Game2048Tile {
  final int id;
  final int value;
  final Game2048Position position;

  const Game2048Tile({
    required this.id,
    required this.value,
    required this.position,
  });

  Game2048Tile copyWith({int? value, Game2048Position? position}) =>
      Game2048Tile(
        id: id,
        value: value ?? this.value,
        position: position ?? this.position,
      );
}
