import 'package:flutter/foundation.dart';

import 'tetris_game_state.dart';
import 'tetromino.dart';

@immutable
class TetrisPendingFinalization {
  const TetrisPendingFinalization({
    this.runId,
    required this.score,
    required this.lines,
    required this.level,
    required this.piecesPlaced,
    required this.durationSeconds,
    required this.resultConfirmed,
  });

  final String? runId;
  final int score;
  final int lines;
  final int level;
  final int piecesPlaced;
  final int durationSeconds;
  final bool resultConfirmed;

  Map<String, Object?> toJson() => {
        'run_id': runId,
        'score': score,
        'lines': lines,
        'level': level,
        'pieces_placed': piecesPlaced,
        'duration_seconds': durationSeconds,
        'result_confirmed': resultConfirmed,
      };

  factory TetrisPendingFinalization.fromJson(Map<String, dynamic> json) =>
      TetrisPendingFinalization(
        runId: json['run_id'] == null
            ? null
            : TetrisSnapshot._requiredString(json, 'run_id'),
        score: TetrisSnapshot._requiredInt(json, 'score'),
        lines: TetrisSnapshot._requiredInt(json, 'lines'),
        level: TetrisSnapshot._requiredInt(json, 'level'),
        piecesPlaced: TetrisSnapshot._requiredInt(json, 'pieces_placed'),
        durationSeconds: TetrisSnapshot._requiredInt(json, 'duration_seconds'),
        resultConfirmed: TetrisSnapshot._requiredBool(json, 'result_confirmed'),
      );
}

@immutable
class TetrisSnapshot {
  static const int currentSchemaVersion = 1;

  TetrisSnapshot({
    required this.schemaVersion,
    required List<List<int?>> board,
    required this.activePiece,
    required List<TetrominoType> nextQueue,
    required this.score,
    required this.bestScore,
    this.startingBestScore,
    required this.lines,
    required this.level,
    required this.piecesPlaced,
    required this.elapsedSeconds,
    required List<int> clearingRows,
    required List<int> pendingMilestones,
    required this.startedAt,
    this.pendingFinalization,
  })  : board = List.unmodifiable(
          board.map((row) => List<int?>.unmodifiable(row)),
        ),
        nextQueue = List.unmodifiable(nextQueue),
        clearingRows = List.unmodifiable(clearingRows),
        pendingMilestones = List.unmodifiable(pendingMilestones) {
    if (schemaVersion != currentSchemaVersion) {
      throw ArgumentError.value(
        schemaVersion,
        'schemaVersion',
        'must be $currentSchemaVersion',
      );
    }
  }

  final int schemaVersion;
  final List<List<int?>> board;
  final TetrisPiece? activePiece;
  final List<TetrominoType> nextQueue;
  final int score;
  final int bestScore;
  final int? startingBestScore;
  final int lines;
  final int level;
  final int piecesPlaced;
  final int elapsedSeconds;
  final List<int> clearingRows;
  final List<int> pendingMilestones;
  final DateTime startedAt;
  final TetrisPendingFinalization? pendingFinalization;

  Map<String, Object?> toJson() => {
        'schema_version': currentSchemaVersion,
        'board': [for (final row in board) List<int?>.of(row)],
        'active_piece': activePiece == null ? null : _pieceToJson(activePiece!),
        'next_queue': [for (final type in nextQueue) type.label],
        'score': score,
        'best_score': bestScore,
        'starting_best_score': startingBestScore,
        'lines': lines,
        'level': level,
        'pieces_placed': piecesPlaced,
        'elapsed_seconds': elapsedSeconds,
        'clearing_rows': clearingRows,
        'pending_milestones': pendingMilestones,
        'started_at': startedAt.toUtc().toIso8601String(),
        'pending_finalization': pendingFinalization?.toJson(),
      };

  static Map<String, Object?> _pieceToJson(TetrisPiece piece) => {
        'type': piece.type.label,
        'rotation': piece.rotation,
        'row': piece.row,
        'col': piece.col,
      };

  factory TetrisSnapshot.fromJson(Map<String, dynamic> json) {
    try {
      final schemaVersion = _requiredInt(json, 'schema_version');
      if (schemaVersion != currentSchemaVersion) {
        throw const FormatException('Unsupported Tetris snapshot schema.');
      }

      return TetrisSnapshot(
        schemaVersion: schemaVersion,
        board: _boardFromJson(json['board']),
        activePiece: _pieceFromJson(json['active_piece']),
        nextQueue: _queueFromJson(json['next_queue']),
        score: _requiredInt(json, 'score'),
        bestScore: _requiredInt(json, 'best_score'),
        startingBestScore: json['starting_best_score'] is int
            ? json['starting_best_score'] as int
            : null,
        lines: _requiredInt(json, 'lines'),
        level: _requiredInt(json, 'level'),
        piecesPlaced: _requiredInt(json, 'pieces_placed'),
        elapsedSeconds: _requiredInt(json, 'elapsed_seconds'),
        clearingRows: _clearingRowsFromJson(json['clearing_rows']),
        pendingMilestones: _milestonesFromJson(json['pending_milestones']),
        startedAt: _requiredDateTime(json, 'started_at'),
        pendingFinalization:
            _pendingFinalizationFromJson(json['pending_finalization']),
      );
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('Malformed Tetris snapshot.');
    }
  }

  static List<List<int?>> _boardFromJson(Object? value) {
    if (value is! List || value.length != TetrisGameState.rows) {
      throw const FormatException(
        'Board must contain ${TetrisGameState.rows} rows.',
      );
    }
    return [
      for (final row in value)
        if (row is List && row.length == TetrisGameState.columns)
          [
            for (final cell in row)
              if (cell == null)
                null
              else if (cell is int &&
                  cell >= 0 &&
                  cell < TetrominoType.values.length)
                cell
              else
                throw const FormatException('Invalid board cell.'),
          ]
        else
          throw const FormatException('Invalid board row.'),
    ];
  }

  static TetrisPiece? _pieceFromJson(Object? value) {
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException('Active piece must be a JSON object.');
    }
    final json = Map<String, dynamic>.from(value);
    final typeLabel = _requiredString(json, 'type');
    final type = TetrominoTypeX.fromLabel(typeLabel);
    if (type == null) {
      throw const FormatException('Unknown tetromino type.');
    }
    final rotation = _requiredInt(json, 'rotation');
    if (rotation < 0 || rotation > 3) {
      throw const FormatException('Invalid piece rotation.');
    }
    return TetrisPiece(
      type: type,
      rotation: rotation,
      row: _requiredInt(json, 'row'),
      col: _requiredInt(json, 'col'),
    );
  }

  static List<TetrominoType> _queueFromJson(Object? value) {
    if (value is! List) {
      throw const FormatException('Next queue must be a list.');
    }
    return [
      for (final entry in value)
        if (entry is String && TetrominoTypeX.fromLabel(entry) != null)
          TetrominoTypeX.fromLabel(entry)!
        else
          throw const FormatException('Invalid next queue entry.'),
    ];
  }

  static List<int> _clearingRowsFromJson(Object? value) {
    if (value is! List) {
      throw const FormatException('Clearing rows must be a list.');
    }
    return [
      for (final entry in value)
        if (entry is int && entry >= 0 && entry < TetrisGameState.rows)
          entry
        else
          throw const FormatException('Invalid clearing row.'),
    ];
  }

  static List<int> _milestonesFromJson(Object? value) {
    if (value is! List) {
      throw const FormatException('Pending milestones must be a list.');
    }
    return [
      for (final entry in value)
        if (entry is int && entry > 0)
          entry
        else
          throw const FormatException('Invalid pending milestone.'),
    ];
  }

  static TetrisPendingFinalization? _pendingFinalizationFromJson(
    Object? value,
  ) {
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException(
        'Pending finalization must be a JSON object.',
      );
    }
    return TetrisPendingFinalization.fromJson(
      Map<String, dynamic>.from(value),
    );
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

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('Expected "$key" to be a string.');
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
