import 'package:flutter/foundation.dart';

@immutable
class Game2048Position {
  final int row;
  final int col;

  const Game2048Position(this.row, this.col);

  factory Game2048Position.fromJson(Map<String, dynamic> json) {
    return Game2048Position(
      json['row'] as int,
      json['col'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'row': row,
        'col': col,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Game2048Position &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row, $col)';
}

@immutable
class Game2048Tile {
  final int id;
  final int value;
  final Game2048Position position;

  const Game2048Tile({
    required this.id,
    required this.value,
    required this.position,
  });

  factory Game2048Tile.fromJson(Map<String, dynamic> json) {
    return Game2048Tile(
      id: json['id'] as int,
      value: json['value'] as int,
      position: Game2048Position.fromJson(
        Map<String, dynamic>.from(json['position'] as Map),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'value': value,
        'position': position.toJson(),
      };

  Game2048Tile copyWith({
    int? value,
    Game2048Position? position,
  }) {
    return Game2048Tile(
      id: id,
      value: value ?? this.value,
      position: position ?? this.position,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Game2048Tile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          value == other.value &&
          position == other.position;

  @override
  int get hashCode => Object.hash(id, value, position);

  @override
  String toString() => 'Game2048Tile(id: $id, value: $value, pos: $position)';
}
