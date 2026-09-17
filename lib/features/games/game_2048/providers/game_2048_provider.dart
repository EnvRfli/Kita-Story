import 'dart:math';

import 'package:flutter/foundation.dart';

import '../engine/game_2048_engine.dart';
import '../models/game_2048_move.dart';
import '../models/game_2048_snapshot.dart';
import '../models/game_2048_tile.dart';
import '../services/game_2048_local_storage.dart';

enum Game2048Status {
  loading,
  playing,
  celebrating2048,
  gameOver,
  saving,
  error,
}

class Game2048Provider extends ChangeNotifier {
  Game2048Provider({
    required Game2048Engine engine,
    required Game2048LocalStorage storage,
    this.animationDuration = const Duration(milliseconds: 170),
  })  : _engine = engine,
        _storage = storage;

  static const int _initialUndos = 3;

  final Game2048Engine _engine;
  final Game2048LocalStorage _storage;
  final Duration animationDuration;

  List<Game2048Tile> _tiles = const [];
  List<Game2048Tile> get tiles => List.unmodifiable(_tiles);

  List<Game2048Snapshot> _undoSnapshots = const [];
  List<Game2048Snapshot> get undoSnapshots => List.unmodifiable(_undoSnapshots);

  List<Game2048Transition> _transitions = const [];
  List<Game2048Transition> get transitions => List.unmodifiable(_transitions);

  List<Game2048Merge> _merges = const [];
  List<Game2048Merge> get merges => List.unmodifiable(_merges);

  final Set<int> _pendingMilestoneSet = <int>{};
  List<int> get pendingMilestones =>
      List.unmodifiable(_pendingMilestoneSet.toList()..sort());

  Game2048Status _status = Game2048Status.loading;
  Game2048Status get status => _status;

  int _score = 0;
  int get score => _score;

  int _bestScore = 0;
  int get bestScore => _bestScore;

  int _moveCount = 0;
  int get moveCount => _moveCount;

  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;

  int _undosLeft = _initialUndos;
  int get undosLeft => _undosLeft;

  int _highestTile = 0;
  int get highestTile => _highestTile;

  int _highestMilestone = 0;
  int get highestMilestone => _highestMilestone;

  bool _hasCelebrated2048 = false;
  bool get hasCelebrated2048 => _hasCelebrated2048;

  bool _isInputLocked = false;
  bool get isInputLocked => _isInputLocked;

  bool _celebrationPending = false;
  bool _gameOverPending = false;
  DateTime _startedAt = DateTime.now();

  Future<void> newGame() async {
    _status = Game2048Status.loading;
    notifyListeners();

    try {
      _bestScore = await _storage.loadBestScore();
      _tiles = List.of(_engine.createInitialTiles());
      _undoSnapshots = const [];
      _transitions = const [];
      _merges = const [];
      _pendingMilestoneSet.clear();
      _score = 0;
      _moveCount = 0;
      _elapsedSeconds = 0;
      _undosLeft = _initialUndos;
      _highestTile = _highestTileFor(_tiles);
      _highestMilestone = 0;
      _hasCelebrated2048 = false;
      _isInputLocked = false;
      _celebrationPending = false;
      _gameOverPending = false;
      _startedAt = DateTime.now();
      _status = Game2048Status.playing;
    } on Object {
      _status = Game2048Status.error;
    }
    notifyListeners();
  }

  Future<bool> restore() async {
    _status = Game2048Status.loading;
    notifyListeners();

    try {
      final snapshot = await _storage.load();
      if (snapshot == null) {
        return false;
      }

      _tiles = List.of(snapshot.tiles);
      _undoSnapshots = List.of(snapshot.undoSnapshots.take(_initialUndos));
      _transitions = const [];
      _merges = const [];
      _pendingMilestoneSet
        ..clear()
        ..addAll(_milestonesThrough(snapshot.highestMilestone));
      _score = snapshot.score;
      _bestScore = max(await _storage.loadBestScore(), snapshot.bestScore);
      _moveCount = snapshot.moveCount;
      _elapsedSeconds = snapshot.elapsedSeconds;
      _undosLeft = snapshot.undosLeft.clamp(0, _initialUndos);
      _highestTile = _highestTileFor(_tiles);
      _highestMilestone = snapshot.highestMilestone;
      _hasCelebrated2048 = snapshot.hasCelebrated2048;
      _isInputLocked = false;
      _celebrationPending = false;
      _gameOverPending = false;
      _startedAt = snapshot.startedAt;
      _status = _engine.hasAvailableMove(_tiles)
          ? Game2048Status.playing
          : Game2048Status.gameOver;
      notifyListeners();
      return true;
    } on Object {
      _status = Game2048Status.error;
      notifyListeners();
      return false;
    }
  }

  void swipe(Game2048Direction direction) {
    if (_status != Game2048Status.playing || _isInputLocked) return;

    final result = _engine.move(_tiles, direction);
    if (!result.didMove) return;

    _pushUndoSnapshot(_snapshot(includeUndoHistory: false));
    _tiles = List.of(_engine.spawnTile(result.tiles));
    _transitions = List.of(result.transitions);
    _merges = List.of(result.merges);
    _score += result.scoreGained;
    _bestScore = max(_bestScore, _score);
    _moveCount++;
    _highestTile = max(_highestTile, _highestTileFor(_tiles));
    _recordMilestones(result.highestTile);
    _celebrationPending = !_hasCelebrated2048 && result.highestTile >= 2048;
    if (_celebrationPending) _hasCelebrated2048 = true;
    _gameOverPending = result.isGameOver || !_engine.hasAvailableMove(_tiles);
    _isInputLocked = true;
    notifyListeners();
  }

  Future<void> completeAnimation() async {
    if (!_isInputLocked) return;

    _isInputLocked = false;
    final statusAfterSave = _celebrationPending
        ? Game2048Status.celebrating2048
        : _gameOverPending
            ? Game2048Status.gameOver
            : Game2048Status.playing;
    _celebrationPending = false;
    _gameOverPending = false;
    await _saveActive(statusAfterSave);
  }

  Future<bool> undo() async {
    if (_status != Game2048Status.playing ||
        _isInputLocked ||
        _undosLeft == 0 ||
        _undoSnapshots.isEmpty) {
      return false;
    }

    final snapshot = _undoSnapshots.last;
    final remainingSnapshots = List.of(_undoSnapshots)..removeLast();
    _undoSnapshots = remainingSnapshots;
    _tiles = List.of(snapshot.tiles);
    _transitions = const [];
    _merges = const [];
    _score = snapshot.score;
    _bestScore = max(_bestScore, snapshot.bestScore);
    _moveCount = snapshot.moveCount;
    _elapsedSeconds = snapshot.elapsedSeconds;
    _highestTile = _highestTileFor(_tiles);
    _highestMilestone = snapshot.highestMilestone;
    _hasCelebrated2048 = snapshot.hasCelebrated2048;
    _undosLeft--;
    await _saveActive(Game2048Status.playing);
    return true;
  }

  void continueAfter2048() {
    if (_status != Game2048Status.celebrating2048) return;
    _status = Game2048Status.playing;
    notifyListeners();
  }

  Future<void> finishRun() async {
    _status = Game2048Status.saving;
    notifyListeners();
    try {
      await _storage.clear();
      _status = Game2048Status.gameOver;
    } on Object {
      _status = Game2048Status.error;
    }
    notifyListeners();
  }

  Game2048Snapshot _snapshot({required bool includeUndoHistory}) =>
      Game2048Snapshot(
        schemaVersion: Game2048Snapshot.currentSchemaVersion,
        tiles: _tiles,
        score: _score,
        bestScore: _bestScore,
        undoSnapshots: includeUndoHistory ? _undoSnapshots : const [],
        undosLeft: _undosLeft,
        moveCount: _moveCount,
        elapsedSeconds: _elapsedSeconds,
        hasCelebrated2048: _hasCelebrated2048,
        highestMilestone: _highestMilestone,
        startedAt: _startedAt,
      );

  void _pushUndoSnapshot(Game2048Snapshot snapshot) {
    final snapshots = [..._undoSnapshots, snapshot];
    if (snapshots.length > _initialUndos) snapshots.removeAt(0);
    _undoSnapshots = snapshots;
  }

  void _recordMilestones(int highestTile) {
    for (final milestone in _milestonesThrough(highestTile)) {
      if (milestone > _highestMilestone) {
        _pendingMilestoneSet.add(milestone);
        _highestMilestone = milestone;
      }
    }
  }

  Future<void> _saveActive(Game2048Status statusAfterSave) async {
    _status = Game2048Status.saving;
    notifyListeners();
    try {
      await _storage.save(_snapshot(includeUndoHistory: true));
      await _storage.saveBestScore(_bestScore);
      _status = statusAfterSave;
    } on Object {
      _status = Game2048Status.error;
    }
    notifyListeners();
  }

  static int _highestTileFor(List<Game2048Tile> tiles) =>
      tiles.fold(0, (highest, tile) => max(highest, tile.value));

  static Iterable<int> _milestonesThrough(int highestTile) sync* {
    const initialMilestones = [128, 256, 512, 1024, 2048, 4096];
    for (final milestone in initialMilestones) {
      if (milestone <= highestTile) yield milestone;
    }
    for (var milestone = 8192; milestone <= highestTile; milestone *= 2) {
      yield milestone;
    }
  }
}
