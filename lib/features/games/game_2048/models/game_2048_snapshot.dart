import 'game_2048_tile.dart';

class Game2048Snapshot {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final List<Game2048Tile> tiles;
  final int score;
  final int bestScore;
  final List<Game2048Snapshot> undoSnapshots;
  final int undosLeft;
  final int moveCount;
  final int elapsedSeconds;
  final bool hasCelebrated2048;
  final int highestMilestone;
  final DateTime startedAt;

  Game2048Snapshot({
    required this.schemaVersion,
    required List<Game2048Tile> tiles,
    required this.score,
    required this.bestScore,
    required List<Game2048Snapshot> undoSnapshots,
    required this.undosLeft,
    required this.moveCount,
    required this.elapsedSeconds,
    required this.hasCelebrated2048,
    required this.highestMilestone,
    required this.startedAt,
  })  : tiles = List.unmodifiable(tiles),
        undoSnapshots = List.unmodifiable(undoSnapshots) {
    if (schemaVersion != currentSchemaVersion) {
      throw ArgumentError.value(
        schemaVersion,
        'schemaVersion',
        'must be $currentSchemaVersion',
      );
    }
  }

  Map<String, Object?> toJson() => _toJson(includeUndoHistory: true);

  Map<String, Object?> _toJson({required bool includeUndoHistory}) => {
        'schema_version': currentSchemaVersion,
        'tiles': [for (final tile in tiles) _tileToJson(tile)],
        'score': score,
        'best_score': bestScore,
        'undo_snapshots': includeUndoHistory
            ? [
                for (final snapshot in undoSnapshots)
                  snapshot._toJson(includeUndoHistory: false),
              ]
            : <Object?>[],
        'undos_left': undosLeft,
        'move_count': moveCount,
        'elapsed_seconds': elapsedSeconds,
        'has_celebrated_2048': hasCelebrated2048,
        'highest_milestone': highestMilestone,
        'started_at': startedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _tileToJson(Game2048Tile tile) => {
        'id': tile.id,
        'value': tile.value,
        'row': tile.position.row,
        'col': tile.position.col,
      };

  factory Game2048Snapshot.fromJson(Map<String, dynamic> json) {
    try {
      final schemaVersion = _requiredInt(json, 'schema_version');
      if (schemaVersion != currentSchemaVersion) {
        throw const FormatException('Unsupported 2048 snapshot schema.');
      }

      final undoSnapshots = _requiredList(json, 'undo_snapshots')
          .map((value) => _snapshotFromJson(value, isUndoSnapshot: true))
          .toList(growable: false);

      return Game2048Snapshot(
        schemaVersion: schemaVersion,
        tiles: _requiredList(json, 'tiles')
            .map(_tileFromJson)
            .toList(growable: false),
        score: _requiredInt(json, 'score'),
        bestScore: _requiredInt(json, 'best_score'),
        undoSnapshots: undoSnapshots,
        undosLeft: _requiredInt(json, 'undos_left'),
        moveCount: _requiredInt(json, 'move_count'),
        elapsedSeconds: _requiredInt(json, 'elapsed_seconds'),
        hasCelebrated2048: _requiredBool(json, 'has_celebrated_2048'),
        highestMilestone: _requiredInt(json, 'highest_milestone'),
        startedAt: _requiredDateTime(json, 'started_at'),
      );
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('Malformed 2048 snapshot.');
    }
  }

  static Game2048Snapshot _snapshotFromJson(
    Object? value, {
    required bool isUndoSnapshot,
  }) {
    if (value is! Map) {
      throw const FormatException('Snapshot must be a JSON object.');
    }

    final json = Map<String, dynamic>.from(value);
    if (isUndoSnapshot &&
        json.containsKey('undo_snapshots') &&
        _requiredList(json, 'undo_snapshots').isNotEmpty) {
      throw const FormatException(
          'Undo snapshots cannot contain undo history.');
    }
    return Game2048Snapshot.fromJson(json);
  }

  static Game2048Tile _tileFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Tile must be a JSON object.');
    }
    final json = Map<String, dynamic>.from(value);
    return Game2048Tile(
      id: _requiredInt(json, 'id'),
      value: _requiredInt(json, 'value'),
      position: Game2048Position(
        _requiredInt(json, 'row'),
        _requiredInt(json, 'col'),
      ),
    );
  }

  static List<dynamic> _requiredList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) {
      throw FormatException('Expected "$key" to be a list.');
    }
    return value;
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int) {
      throw FormatException('Expected "$key" to be an integer.');
    }
    return value;
  }

  static bool _requiredBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! bool) {
      throw FormatException('Expected "$key" to be a boolean.');
    }
    return value;
  }

  static DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('Expected "$key" to be an ISO date string.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Expected "$key" to be an ISO date string.');
    }
    return parsed;
  }
}
