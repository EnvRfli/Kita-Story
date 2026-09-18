import 'dart:math';

import 'package:flutter/foundation.dart';

import '../engine/game_2048_engine.dart';
import '../models/game_2048_move.dart';
import '../models/game_2048_snapshot.dart';
import '../models/game_2048_tile.dart';
import '../repositories/game_2048_repository.dart';
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
    required Game2048Repository repository,
    this.animationDuration = const Duration(milliseconds: 170),
    DateTime Function()? clock,
  })  : _engine = engine,
        _storage = storage,
        _repository = repository,
        _clock = clock ?? DateTime.now;

  static const int _initialUndos = 3;

  final Game2048Engine _engine;
  final Game2048LocalStorage _storage;
  final Game2048Repository _repository;
  final DateTime Function() _clock;
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
  int get elapsedSeconds =>
      _elapsedSeconds +
      (_isElapsedRunning
          ? max(0, _clock().difference(_elapsedLastResumedAt).inSeconds)
          : 0);

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
  bool _isClaimingMilestones = false;
  Game2048PendingFinalization? _pendingResultWrite;
  Future<void>? _endRunFuture;
  Future<void>? _animationCompletionFuture;
  bool _isEndRunRequested = false;

  bool get hasPendingWrite => _pendingResultWrite != null;
  bool _isElapsedRunning = false;
  late DateTime _elapsedLastResumedAt;
  late DateTime _startedAt;

  Future<void> newGame() async {
    if (_pendingResultWrite != null) {
      await retryPendingWrites();
      if (_pendingResultWrite != null) return;
    }
    _endRunFuture = null;
    _isEndRunRequested = false;
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
      _pendingResultWrite = null;
      _animationCompletionFuture = null;
      _startedAt = _clock();
      _resumeElapsed();
      _status = Game2048Status.playing;
    } on Object {
      _status = Game2048Status.error;
    }
    notifyListeners();
  }

  Future<bool> restore() async {
    _endRunFuture = null;
    _isEndRunRequested = false;
    _animationCompletionFuture = null;
    _status = Game2048Status.loading;
    notifyListeners();

    try {
      final snapshot = await _storage.load();
      final savedBestScore = await _storage.loadBestScore();
      if (snapshot == null) {
        _resetEmptyGame(savedBestScore);
        _status = Game2048Status.playing;
        notifyListeners();
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
      _bestScore = max(savedBestScore, snapshot.bestScore);
      _moveCount = snapshot.moveCount;
      _elapsedSeconds = snapshot.elapsedSeconds;
      _isElapsedRunning = false;
      _undosLeft = snapshot.undosLeft.clamp(0, _initialUndos);
      _highestTile = _highestTileFor(_tiles);
      _highestMilestone = snapshot.highestMilestone;
      _hasCelebrated2048 = snapshot.hasCelebrated2048;
      _isInputLocked = false;
      _celebrationPending = false;
      _gameOverPending = false;
      _pendingResultWrite = snapshot.pendingFinalization;
      _startedAt = snapshot.startedAt;
      if (_pendingResultWrite != null) {
        _status = Game2048Status.saving;
        notifyListeners();
        await retryPendingWrites();
        if (_pendingResultWrite == null) {
          _isEndRunRequested = true;
          _endRunFuture = Future.value();
        }
        return true;
      }
      _status = _engine.hasAvailableMove(_tiles)
          ? Game2048Status.playing
          : Game2048Status.gameOver;
      if (_status == Game2048Status.playing) _resumeElapsed();
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

  Future<void> completeAnimation() =>
      _completeAnimation(autoFinalizeGameOver: true);

  Future<void> _completeAnimation({
    required bool autoFinalizeGameOver,
  }) {
    final ongoing = _animationCompletionFuture;
    if (ongoing != null) return ongoing;
    if (!_isInputLocked) return Future.value();

    final completion = _completeAnimationCore(
      autoFinalizeGameOver: autoFinalizeGameOver,
    );
    _animationCompletionFuture = completion;
    return completion.whenComplete(() {
      if (identical(_animationCompletionFuture, completion)) {
        _animationCompletionFuture = null;
      }
    });
  }

  Future<void> _completeAnimationCore({
    required bool autoFinalizeGameOver,
  }) async {
    final finishesRun = _gameOverPending;

    _isInputLocked = false;
    final statusAfterSave = _celebrationPending
        ? Game2048Status.celebrating2048
        : _gameOverPending
            ? Game2048Status.gameOver
            : Game2048Status.playing;
    _celebrationPending = false;
    if (statusAfterSave != Game2048Status.celebrating2048) {
      _gameOverPending = false;
    }
    if (statusAfterSave != Game2048Status.playing) _pauseElapsed();
    final queuesFinalization =
        finishesRun && (autoFinalizeGameOver || _isEndRunRequested);
    if (queuesFinalization) _queuePendingResultWrite();
    await _saveActive(
      queuesFinalization ? Game2048Status.saving : statusAfterSave,
    );
    await claimPendingMilestones();
    if (finishesRun && autoFinalizeGameOver && !_isEndRunRequested) {
      await _endRunWithStatus(
        statusAfterSave,
        settleAnimation: false,
      );
    }
  }

  Future<void> claimPendingMilestones() async {
    if (_isInputLocked ||
        _isClaimingMilestones ||
        _pendingMilestoneSet.isEmpty) {
      return;
    }

    _isClaimingMilestones = true;
    final candidates = Set<int>.of(_pendingMilestoneSet);
    try {
      final claimed = await _repository.claimMilestones(candidates);
      _pendingMilestoneSet.removeAll(claimed);
    } on Object {
      // Keep every candidate pending for a later retry.
    } finally {
      _isClaimingMilestones = false;
      notifyListeners();
    }
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
    _resumeElapsed();
    await _saveActive(Game2048Status.playing);
    return true;
  }

  void continueAfter2048() {
    if (_status != Game2048Status.celebrating2048) return;
    _status =
        _gameOverPending ? Game2048Status.gameOver : Game2048Status.playing;
    _gameOverPending = false;
    if (_status == Game2048Status.playing) _resumeElapsed();
    notifyListeners();
  }

  Future<void> saveAndExit() async {
    if (_isInputLocked || _animationCompletionFuture != null) {
      await _completeAnimation(autoFinalizeGameOver: true);
      return;
    }
    if (_endRunFuture != null && _pendingResultWrite == null) return;
    await _saveActive(_status);
  }

  Future<void> endRun() => _endRunWithStatus(Game2048Status.gameOver);

  Future<void> _endRunWithStatus(
    Game2048Status statusAfterSuccess, {
    bool settleAnimation = true,
  }) {
    final existing = _endRunFuture;
    if (existing != null) return existing;

    _isEndRunRequested = true;
    final pending = _beginEndRun(
      statusAfterSuccess,
      settleAnimation: settleAnimation,
    );
    _endRunFuture = pending;
    return pending;
  }

  Future<void> retryPendingWrites() async {
    await claimPendingMilestones();
    if (_pendingResultWrite != null) {
      await _flushPendingResultWrite(Game2048Status.gameOver);
    }
  }

  Future<void> finishRun() async {
    await endRun();
  }

  Future<void> _beginEndRun(
    Game2048Status statusAfterSuccess, {
    required bool settleAnimation,
  }) async {
    if (settleAnimation &&
        (_isInputLocked || _animationCompletionFuture != null)) {
      await _completeAnimation(autoFinalizeGameOver: false);
    }
    _queuePendingResultWrite();
    try {
      await _storage.save(_snapshot(includeUndoHistory: true));
    } on Object {
      _status = Game2048Status.error;
      notifyListeners();
      return;
    }
    await claimPendingMilestones();
    if (_pendingResultWrite != null) {
      await _flushPendingResultWrite(statusAfterSuccess);
    }
  }

  void _queuePendingResultWrite() {
    _pauseElapsed();
    _pendingResultWrite ??= Game2048PendingFinalization(
      score: _score,
      highestTile: _highestTile,
      movesCount: _moveCount,
      durationSeconds: elapsedSeconds,
      resultConfirmed: false,
    );
  }

  Future<void> _flushPendingResultWrite(
    Game2048Status statusAfterSuccess,
  ) async {
    final pending = _pendingResultWrite;
    if (pending == null) return;

    _status = Game2048Status.saving;
    notifyListeners();
    try {
      if (!pending.resultConfirmed) {
        await _repository.saveResult(
          score: pending.score,
          highestTile: pending.highestTile,
          movesCount: pending.movesCount,
          durationSeconds: pending.durationSeconds,
        );
        _pendingResultWrite = Game2048PendingFinalization(
          score: pending.score,
          highestTile: pending.highestTile,
          movesCount: pending.movesCount,
          durationSeconds: pending.durationSeconds,
          resultConfirmed: true,
        );
        await _storage.save(_snapshot(includeUndoHistory: true));
      }
      await _storage.clear();
      _pendingResultWrite = null;
      _status = statusAfterSuccess;
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
        elapsedSeconds: elapsedSeconds,
        hasCelebrated2048: _hasCelebrated2048,
        highestMilestone: _highestMilestone,
        startedAt: _startedAt,
        pendingFinalization: _pendingResultWrite,
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
      _pauseElapsed();
      _status = Game2048Status.error;
    }
    notifyListeners();
  }

  void _resetEmptyGame(int bestScore) {
    _tiles = const [];
    _undoSnapshots = const [];
    _transitions = const [];
    _merges = const [];
    _pendingMilestoneSet.clear();
    _score = 0;
    _bestScore = bestScore;
    _moveCount = 0;
    _elapsedSeconds = 0;
    _undosLeft = _initialUndos;
    _highestTile = 0;
    _highestMilestone = 0;
    _hasCelebrated2048 = false;
    _isInputLocked = false;
    _celebrationPending = false;
    _gameOverPending = false;
    _pendingResultWrite = null;
    _endRunFuture = null;
    _animationCompletionFuture = null;
    _isEndRunRequested = false;
    _isElapsedRunning = false;
    _startedAt = _clock();
    _elapsedLastResumedAt = _startedAt;
  }

  void _pauseElapsed() {
    if (!_isElapsedRunning) return;
    _elapsedSeconds = elapsedSeconds;
    _isElapsedRunning = false;
  }

  void _resumeElapsed() {
    _elapsedLastResumedAt = _clock();
    _isElapsedRunning = true;
  }

  @override
  void dispose() {
    _pauseElapsed();
    super.dispose();
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
