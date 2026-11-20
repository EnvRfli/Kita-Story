import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../engine/tetris_engine.dart';
import '../models/tetris_game_state.dart';
import '../models/tetris_move_result.dart';
import '../models/tetris_snapshot.dart';
import '../models/tetromino.dart';
import '../repositories/tetris_repository.dart';
import '../services/tetris_local_storage.dart';

enum TetrisStatus {
  loading,
  playing,
  paused,
  clearing,
  gameOver,
  saving,
  error
}

class TetrisProvider extends ChangeNotifier {
  TetrisProvider({
    required TetrisEngine engine,
    required TetrisLocalStorage storage,
    required TetrisRepository repository,
    this.autoGravity = true,
    this.lockDelay = const Duration(milliseconds: 500),
    this.lineClearDuration = const Duration(milliseconds: 180),
    DateTime Function()? clock,
    String Function()? runIdGenerator,
  })  : _engine = engine,
        _storage = storage,
        _repository = repository,
        _clock = clock ?? DateTime.now,
        _runIdGenerator = runIdGenerator ?? _generateRunId {
    _game = TetrisGameState(
      board: TetrisGameState.emptyBoard(),
      activePiece: null,
      nextQueue: const [],
      score: 0,
      lines: 0,
      level: 1,
      piecesPlaced: 0,
      clearingRows: const [],
      isGameOver: false,
    );
    _startedAt = _clock();
    _elapsedLastResumedAt = _startedAt;
  }

  static const int _maxLockResets = 15;

  final TetrisEngine _engine;
  final TetrisLocalStorage _storage;
  final TetrisRepository _repository;
  final DateTime Function() _clock;
  final String Function() _runIdGenerator;
  final bool autoGravity;
  final Duration lockDelay;
  final Duration lineClearDuration;

  late TetrisGameState _game;

  TetrisGameState get game => _game;
  List<List<int?>> get board => _game.board;
  TetrisPiece? get activePiece => _game.activePiece;
  List<TetrominoType> get nextQueue => _game.nextQueue;
  int get score => _game.score;
  int get lines => _game.lines;
  int get level => _game.level;
  int get piecesPlaced => _game.piecesPlaced;
  List<int> get clearingRows => _game.clearingRows;
  bool get isGameOver => _game.isGameOver;
  Duration get gravityInterval => _engine.gravityIntervalForLevel(level);
  int get ghostRow => _game.activePiece == null ? 0 : _engine.ghostRow(_game);

  TetrisStatus _status = TetrisStatus.loading;
  TetrisStatus get status => _status;

  int _bestScore = 0;
  int get bestScore => _bestScore;
  int _startingBestScore = 0;
  bool get isNewRecord => _game.score > 0 && _game.score > _startingBestScore;

  int _elapsedSeconds = 0;
  bool _isElapsedRunning = false;
  late DateTime _elapsedLastResumedAt;
  late DateTime _startedAt;

  final Set<int> _pendingMilestoneSet = <int>{};
  final Set<int> _claimedMilestoneSet = <int>{};
  final Set<int> _sessionClaimedMilestones = <int>{};

  List<int> get pendingMilestones =>
      List.unmodifiable(_pendingMilestoneSet.toList()..sort());
  Set<int> get claimedMilestones => Set.unmodifiable(_claimedMilestoneSet);
  Set<int> get sessionClaimedMilestones =>
      Set.unmodifiable(_sessionClaimedMilestones);

  int? _newlyUnlockedMilestone;
  int? get newlyUnlockedMilestone => _newlyUnlockedMilestone;
  void clearNewlyUnlockedMilestone() {
    if (_newlyUnlockedMilestone != null) {
      _newlyUnlockedMilestone = null;
      _notify();
    }
  }

  int get sessionPointsEarned {
    var total = 0;
    for (final milestone in _sessionClaimedMilestones) {
      total += TetrisRepository.rewardPointsFor(milestone) ?? 0;
    }
    return total;
  }

  int get elapsedSeconds =>
      _elapsedSeconds +
      (_isElapsedRunning
          ? max(0, _clock().difference(_elapsedLastResumedAt).inSeconds)
          : 0);

  bool get isInputLocked =>
      _status == TetrisStatus.loading ||
      _status == TetrisStatus.saving ||
      _status == TetrisStatus.clearing ||
      _isResolvingClear;

  TetrisPendingFinalization? _pendingResultWrite;
  bool get hasPendingWrite => _pendingResultWrite != null;

  Timer? _gravityTimer;
  Timer? _lockDelayTimer;
  Timer? _lineClearTimer;
  Future<void> _saveChain = Future<void>.value();
  Future<void>? _endRunFuture;
  bool _isClaimingMilestones = false;
  bool _isLockDelayActive = false;
  bool _isResolvingClear = false;
  bool _pauseRequested = false;
  int _lockResets = 0;
  bool _disposed = false;

  void setClaimedMilestones(Set<int> milestones) {
    _claimedMilestoneSet
      ..clear()
      ..addAll(milestones);
    _notify();
  }

  Future<void> newGame() async {
    if (_pendingResultWrite != null) {
      await retryPendingWrites();
      if (_pendingResultWrite != null) return;
    }

    _status = TetrisStatus.loading;
    _endRunFuture = null;
    _notify();

    try {
      _bestScore = await _storage.loadBestScore();
      _startingBestScore = _bestScore;
      _game = _engine.createInitialState();
      _pendingMilestoneSet.clear();
      _sessionClaimedMilestones.clear();
      _newlyUnlockedMilestone = null;
      _pendingResultWrite = null;
      _pauseRequested = false;
      _isResolvingClear = false;
      _elapsedSeconds = 0;
      _startedAt = _clock();
      _isElapsedRunning = false;
      _elapsedLastResumedAt = _startedAt;
      _status = TetrisStatus.playing;
      _resumeElapsed();
      _resetLockState();
      _scheduleGravity();
    } on Object {
      _status = TetrisStatus.error;
    }
    _notify();
  }

  Future<bool> restore() async {
    _status = TetrisStatus.loading;
    _endRunFuture = null;
    _notify();

    try {
      final snapshot = await _storage.load();
      final savedBest = await _storage.loadBestScore();
      if (snapshot == null) {
        _game = _emptyGame();
        _bestScore = savedBest;
        _startingBestScore = savedBest;
        _pendingMilestoneSet.clear();
        _sessionClaimedMilestones.clear();
        _newlyUnlockedMilestone = null;
        _pendingResultWrite = null;
        _status = TetrisStatus.playing;
        _notify();
        return false;
      }

      _game = TetrisGameState(
        board: snapshot.board,
        activePiece: snapshot.activePiece,
        nextQueue: snapshot.nextQueue,
        score: snapshot.score,
        lines: snapshot.lines,
        level: snapshot.level,
        piecesPlaced: snapshot.piecesPlaced,
        clearingRows: snapshot.clearingRows,
        isGameOver: snapshot.activePiece == null &&
            snapshot.clearingRows.isEmpty &&
            snapshot.pendingFinalization == null,
      );
      _bestScore = max(savedBest, snapshot.bestScore);
      _startingBestScore = snapshot.startingBestScore ?? _bestScore;
      _pendingMilestoneSet
        ..clear()
        ..addAll(snapshot.pendingMilestones);
      _sessionClaimedMilestones.clear();
      _newlyUnlockedMilestone = null;
      _pendingResultWrite = snapshot.pendingFinalization;
      _pauseRequested = false;
      _isResolvingClear = false;
      _startedAt = snapshot.startedAt;
      _elapsedSeconds = snapshot.elapsedSeconds;
      _isElapsedRunning = false;
      _resetLockState();

      if (_pendingResultWrite != null) {
        final pending = _pendingResultWrite!;
        if (pending.runId == null) {
          _pendingResultWrite = TetrisPendingFinalization(
            runId: _runIdGenerator(),
            score: pending.score,
            lines: pending.lines,
            level: pending.level,
            piecesPlaced: pending.piecesPlaced,
            durationSeconds: pending.durationSeconds,
            resultConfirmed: pending.resultConfirmed,
          );
          await _saveActive();
        }
        _status = TetrisStatus.saving;
        _notify();
        await retryPendingWrites();
        if (_pendingResultWrite == null) {
          _status = TetrisStatus.gameOver;
        } else {
          _status = TetrisStatus.error;
        }
        _notify();
        return true;
      }

      if (_game.clearingRows.isNotEmpty) {
        _status = TetrisStatus.clearing;
        _scheduleLineClear();
      } else if (_game.activePiece == null) {
        _status = TetrisStatus.gameOver;
      } else {
        _status = TetrisStatus.playing;
        _resumeElapsed();
        _scheduleGravity();
        if (_pendingMilestoneSet.isNotEmpty) {
          unawaited(claimPendingMilestones());
        }
      }
      _notify();
      return true;
    } on Object {
      _status = TetrisStatus.error;
      _notify();
      return false;
    }
  }

  void tick() {
    if (_status != TetrisStatus.playing ||
        _isResolvingClear ||
        _isLockDelayActive ||
        _game.activePiece == null) {
      return;
    }
    final result = _engine.tick(_game);
    if (result.didMove) {
      _game = result.state;
      _notify();
    } else {
      _startLockDelay();
    }
  }

  void moveLeft() => _applyMove(_engine.moveLeft(_game));

  void moveRight() => _applyMove(_engine.moveRight(_game));

  void rotate() {
    if (_status != TetrisStatus.playing || isInputLocked) return;
    final result = _engine.rotate(_game);
    if (!result.didMove) return;
    _game = result.state;
    _resetLockDelayIfActive();
    _notify();
  }

  void softDrop() {
    if (_status != TetrisStatus.playing || isInputLocked) return;
    final result = _engine.softDrop(_game);
    if (!result.didMove) {
      _lockActivePiece();
      return;
    }
    _game = result.state;
    _bestScore = max(_bestScore, _game.score);
    _resetLockDelayIfActive();
    _notify();
  }

  void hardDrop() {
    if (_status != TetrisStatus.playing || isInputLocked) return;
    final result = _engine.hardDrop(_game);
    if (!result.didMove) return;
    _clearLockDelay();
    _applyLockResult(result);
  }

  Future<void> completeLineClear() async {
    if (_status != TetrisStatus.clearing || _game.clearingRows.isEmpty) {
      return;
    }

    _lineClearTimer?.cancel();
    _lineClearTimer = null;
    _game = _engine.completeClear(_game);
    _resetLockState();
    _isResolvingClear = true;

    if (_game.isGameOver) {
      _status = TetrisStatus.gameOver;
      _pauseRequested = false;
      _pauseElapsed();
      _queuePendingResultWrite();
      _notify();
      await claimPendingMilestones();
      await _saveActive();
      _isResolvingClear = false;
      _notify();
      return;
    }

    _status = TetrisStatus.playing;
    _resumeElapsed();
    _notify();
    await claimPendingMilestones();
    await _saveActive();
    _isResolvingClear = false;
    _notify();
    if (_pauseRequested) {
      _pauseRequested = false;
      pause();
    } else {
      _scheduleGravity();
    }
  }

  void pause() {
    if (_status == TetrisStatus.clearing || _isResolvingClear) {
      _pauseRequested = true;
      return;
    }
    if (_status != TetrisStatus.playing) return;
    _cancelGravity();
    _clearLockDelay();
    _pauseElapsed();
    _status = TetrisStatus.paused;
    _notify();
    unawaited(_saveActive());
  }

  void resume() {
    if (_status != TetrisStatus.paused) return;
    _pauseRequested = false;
    _status = TetrisStatus.playing;
    _resumeElapsed();
    _notify();
    _scheduleGravity();
  }

  void togglePause() {
    if (_status == TetrisStatus.playing) {
      pause();
    } else if (_status == TetrisStatus.paused) {
      resume();
    }
  }

  Future<void> saveAndExit() async {
    if (_status == TetrisStatus.clearing) {
      await completeLineClear();
    }
    if (_status == TetrisStatus.saving ||
        _status == TetrisStatus.loading ||
        _status == TetrisStatus.error) {
      return;
    }
    await _saveActive();
  }

  Future<void> endRun() => _endRun();

  Future<void> retryPendingWrites() async {
    await claimPendingMilestones();
    if (_pendingResultWrite != null) {
      await _flushPendingResultWrite(TetrisStatus.gameOver);
    }
  }

  Future<void> claimPendingMilestones() async {
    if (_isClaimingMilestones ||
        _status == TetrisStatus.clearing ||
        _pendingMilestoneSet.isEmpty) {
      return;
    }

    _isClaimingMilestones = true;
    final candidates = Set<int>.of(_pendingMilestoneSet);
    try {
      final claimed = await _repository.claimMilestones(candidates);
      _pendingMilestoneSet.removeAll(claimed);
      _claimedMilestoneSet.addAll(claimed);
      _sessionClaimedMilestones.addAll(claimed);
    } on Object {
      // Keep pending milestones for the next retry.
    } finally {
      _isClaimingMilestones = false;
      _notify();
    }
  }

  void _applyMove(TetrisActionResult result) {
    if (_status != TetrisStatus.playing || isInputLocked) return;
    if (!result.didMove) return;
    _game = result.state;
    _resetLockDelayIfActive();
    _notify();
  }

  void _applyLockResult(TetrisActionResult result) {
    _clearLockDelay();
    _game = result.state;
    _bestScore = max(_bestScore, _game.score);
    _recordMilestones(_game.lines);

    if (_game.clearingRows.isNotEmpty) {
      _cancelGravity();
      _status = TetrisStatus.clearing;
      _notify();
      _scheduleLineClear();
      return;
    }

    if (_game.isGameOver) {
      _pauseRequested = false;
      _status = TetrisStatus.gameOver;
      _pauseElapsed();
      _queuePendingResultWrite();
      _notify();
      unawaited(_saveActive());
      return;
    }

    _status = TetrisStatus.playing;
    _notify();
    _scheduleGravity();
    unawaited(_saveActive());
  }

  void _lockActivePiece() {
    if (_game.activePiece == null) return;
    if (_status != TetrisStatus.playing) return;
    final result = _engine.lockPiece(_game);
    if (!result.didMove) return;
    _applyLockResult(result);
  }

  void _startLockDelay() {
    if (_isLockDelayActive) return;
    _isLockDelayActive = true;
    _lockResets = 0;
    _lockDelayTimer?.cancel();
    _lockDelayTimer = Timer(lockDelay, _lockActivePiece);
  }

  void _resetLockDelayIfActive() {
    if (!_isLockDelayActive) return;
    if (_lockResets >= _maxLockResets) return;
    _lockResets++;
    _lockDelayTimer?.cancel();
    _lockDelayTimer = Timer(lockDelay, _lockActivePiece);
  }

  void _clearLockDelay() {
    _lockDelayTimer?.cancel();
    _lockDelayTimer = null;
    _isLockDelayActive = false;
    _lockResets = 0;
  }

  void _resetLockState() {
    _clearLockDelay();
    _cancelGravity();
  }

  void _scheduleLineClear() {
    _lineClearTimer?.cancel();
    _lineClearTimer = Timer(lineClearDuration, () {
      unawaited(completeLineClear());
    });
  }

  void _scheduleGravity() {
    if (!autoGravity) return;
    _cancelGravity();
    if (_status != TetrisStatus.playing) return;
    _gravityTimer = Timer.periodic(gravityInterval, (_) => tick());
  }

  void _cancelGravity() {
    _gravityTimer?.cancel();
    _gravityTimer = null;
  }

  void _recordMilestones(int lines) {
    final candidates = TetrisRepository.milestoneCandidatesFor(lines);
    for (final milestone in candidates) {
      if (_claimedMilestoneSet.contains(milestone) ||
          _pendingMilestoneSet.contains(milestone)) {
        continue;
      }
      _pendingMilestoneSet.add(milestone);
      _newlyUnlockedMilestone = milestone;
    }
  }

  Future<void> _endRun() {
    final existing = _endRunFuture;
    if (existing != null) return existing;

    final future = _beginEndRun();
    _endRunFuture = future;
    return future.whenComplete(() {
      if (identical(_endRunFuture, future)) {
        _endRunFuture = null;
      }
    });
  }

  Future<void> _beginEndRun() async {
    if (_status == TetrisStatus.clearing) {
      await completeLineClear();
    }
    if (_pendingResultWrite == null) {
      _queuePendingResultWrite();
    }
    _cancelGravity();
    _clearLockDelay();
    _pauseElapsed();
    await _saveActive();
    await claimPendingMilestones();
    await _flushPendingResultWrite(TetrisStatus.gameOver);
  }

  void _queuePendingResultWrite() {
    _pauseElapsed();
    _pendingResultWrite ??= TetrisPendingFinalization(
      runId: _runIdGenerator(),
      score: _game.score,
      lines: _game.lines,
      level: _game.level,
      piecesPlaced: _game.piecesPlaced,
      durationSeconds: elapsedSeconds,
      resultConfirmed: false,
    );
  }

  Future<void> _flushPendingResultWrite(
    TetrisStatus statusAfterSuccess,
  ) async {
    final pending = _pendingResultWrite;
    if (pending == null) return;

    _status = TetrisStatus.saving;
    _notify();
    try {
      if (!pending.resultConfirmed) {
        await _repository.saveResult(
          runId: pending.runId!,
          score: pending.score,
          linesCleared: pending.lines,
          levelReached: pending.level,
          piecesPlaced: pending.piecesPlaced,
          durationSeconds: pending.durationSeconds,
        );
        _pendingResultWrite = TetrisPendingFinalization(
          runId: pending.runId,
          score: pending.score,
          lines: pending.lines,
          level: pending.level,
          piecesPlaced: pending.piecesPlaced,
          durationSeconds: pending.durationSeconds,
          resultConfirmed: true,
        );
        await _saveActive();
      }
      await _saveChain;
      await _storage.clear();
      _pendingResultWrite = null;
      _status = statusAfterSuccess;
    } on Object {
      _status = TetrisStatus.error;
    }
    _notify();
  }

  Future<void> _saveActive() {
    final next = _saveChain.then((_) => _performSave());
    _saveChain = next;
    return next;
  }

  Future<void> _performSave() async {
    if (_disposed) return;
    try {
      await _storage.save(_snapshot());
      await _storage.saveBestScore(_bestScore);
    } on Object {
      _status = TetrisStatus.error;
      _notify();
    }
  }

  TetrisSnapshot _snapshot() => TetrisSnapshot(
        schemaVersion: TetrisSnapshot.currentSchemaVersion,
        board: _game.board,
        activePiece: _game.activePiece,
        nextQueue: _game.nextQueue,
        score: _game.score,
        bestScore: _bestScore,
        startingBestScore: _startingBestScore,
        lines: _game.lines,
        level: _game.level,
        piecesPlaced: _game.piecesPlaced,
        elapsedSeconds: elapsedSeconds,
        clearingRows: _game.clearingRows,
        pendingMilestones: _pendingMilestoneSet.toList()..sort(),
        startedAt: _startedAt,
        pendingFinalization: _pendingResultWrite,
      );

  TetrisGameState _emptyGame() => TetrisGameState(
        board: TetrisGameState.emptyBoard(),
        activePiece: null,
        nextQueue: const [],
        score: 0,
        lines: 0,
        level: 1,
        piecesPlaced: 0,
        clearingRows: const [],
        isGameOver: false,
      );

  void _pauseElapsed() {
    if (!_isElapsedRunning) return;
    _elapsedSeconds = elapsedSeconds;
    _isElapsedRunning = false;
  }

  void _resumeElapsed() {
    if (_isElapsedRunning) return;
    _isElapsedRunning = true;
    _elapsedLastResumedAt = _clock();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelGravity();
    _lockDelayTimer?.cancel();
    _lineClearTimer?.cancel();
    _pauseElapsed();
    super.dispose();
  }

  static String _generateRunId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
