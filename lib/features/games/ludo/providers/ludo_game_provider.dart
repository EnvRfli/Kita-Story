import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../engine/ludo_board_path.dart';
import '../engine/ludo_engine.dart';
import '../models/ludo_action.dart';
import '../models/ludo_game_state.dart';
import '../models/ludo_match_model.dart';
import '../models/ludo_motion.dart';
import '../models/ludo_player.dart';
import '../models/ludo_token.dart';
import '../repositories/ludo_repository.dart';
import '../services/ludo_local_storage.dart';
import '../services/ludo_realtime_service.dart';
import '../services/ludo_sound_service.dart';

class LudoGameProvider extends ChangeNotifier {
  final LudoEngine _engine;
  final LudoLocalStorage _storage;
  final LudoRepository _repository;
  final LudoRealtimeService _realtime;
  final LudoSoundService _sound;
  final Random _random;

  LudoGameState _state;
  String? _matchId;
  String? _currentUserId;
  String? _partnerId;
  String? _partnerName;
  LudoColor? _myColor;
  bool _isOnline = false;
  bool _isWaitingForOpponent = false;
  bool _inviteRejected = false;
  bool _inviteExpired = false;
  bool _isPartnerOnline = false;
  int? _lastGameVersion;
  String? _lastAppliedActionId;
  String? _pendingLocalActionId;
  DateTime? _startedAt;
  int _movesCount = 0;
  bool _historyRecorded = false;
  bool _offlineFinalized = false;
  bool _isRollingAnimation = false;
  int? _rollingPlayerIndex;
  int? _displayDiceValue;
  LudoMotion? _activeMotion;
  int? _displayTurnIndex;
  bool _isTurnTransitioning = false;
  String? _incomingReaction;
  Timer? _reactionTimer;
  Timer? _diceTimer;
  Timer? _turnTransitionTimer;
  Timer? _motionSafetyTimer;
  Timer? _syncTimer;
  StreamSubscription<LudoMatchModel>? _matchSub;
  StreamSubscription<LudoRealtimeEvent>? _realtimeSub;
  StreamSubscription<Set<String>>? _presenceSub;
  LudoMatchModel? _queuedMatch;
  bool _disposed = false;

  LudoGameProvider({
    LudoEngine? engine,
    LudoLocalStorage? storage,
    LudoRepository? repository,
    LudoRealtimeService? realtime,
    LudoSoundService? sound,
    Random? random,
  })  : _engine = engine ?? LudoEngine(),
        _storage = storage ?? LudoLocalStorage(),
        _repository = repository ?? LudoRepository(),
        _realtime = realtime ?? LudoRealtimeService(),
        _sound = sound ?? LudoSoundService.instance,
        _random = random ?? Random(),
        _state = const LudoGameState(
          mode: LudoGameMode.offline2,
          players: [],
        );

  LudoGameState get state => _state;
  String? get matchId => _matchId;
  String? get currentUserId => _currentUserId;
  String? get partnerId => _partnerId;
  String? get partnerName => _partnerName;
  LudoColor? get myColor => _myColor;
  bool get isOnline => _isOnline;
  bool get isRollingAnimation => _isRollingAnimation;
  String? get incomingReaction => _incomingReaction;
  int get movesCount => _movesCount;
  LudoMotion? get activeMotion => _activeMotion;
  bool get isWaitingForOpponent => _isWaitingForOpponent;
  bool get inviteRejected => _inviteRejected;
  bool get inviteExpired => _inviteExpired;
  bool get isPartnerOnline => _isPartnerOnline;
  bool get hasActiveGame => _state.players.isNotEmpty;
  int? get displayDiceValue => _displayDiceValue;
  bool get soundEnabled => _sound.enabled;

  int get displayTurnIndex =>
      _displayTurnIndex ?? (_state.players.isEmpty ? 0 : _state.currentTurnIndex);

  bool get isGameOverVisible =>
      _state.isGameOver && _activeMotion == null;

  bool get isMyTurn {
    if (_state.players.isEmpty) return false;
    if (!_isOnline || _myColor == null) return true;
    return _state.currentPlayer.color == _myColor;
  }

  bool isRollingForIndex(int index) {
    return _isRollingAnimation && _rollingPlayerIndex == index;
  }

  int? diceValueForPlayer(int index) {
    if (_displayDiceValue != null) {
      if (_isRollingAnimation && _rollingPlayerIndex == index) {
        return _displayDiceValue;
      }
      if (!_isRollingAnimation && _state.lastRolledByIndex == index) {
        return _displayDiceValue;
      }
    }
    if (_state.lastRolledByIndex == index) return _state.diceValue;
    return null;
  }

  bool canRoll() {
    if (!hasActiveGame || _state.isGameOver || _activeMotion != null) {
      return false;
    }
    if (_isRollingAnimation || _isTurnTransitioning) return false;
    if (_isOnline && (_isWaitingForOpponent || _inviteRejected || _inviteExpired)) {
      return false;
    }
    if (_state.phase != LudoTurnPhase.waitingForRoll) return false;
    return isMyTurn;
  }

  bool canSelectToken(int tokenId) {
    if (!hasActiveGame || _state.isGameOver || _activeMotion != null) {
      return false;
    }
    if (_isRollingAnimation || _isTurnTransitioning) return false;
    if (_state.phase != LudoTurnPhase.waitingForTokenMove) return false;
    if (!isMyTurn) return false;
    return _state.movableTokenIds.contains(tokenId);
  }

  Future<void> initializeSounds() async {
    await _sound.initialize();
    notifyListeners();
  }

  Future<void> toggleSound() async {
    await _sound.setEnabled(!_sound.enabled);
    notifyListeners();
  }

  Future<void> playStepSound() => _sound.play(LudoSfx.step);

  /// Initialize a local two-player pass-and-play game.
  Future<void> startOfflineGame({
    required LudoGameMode mode,
    required String player1Name,
    String? player1Avatar,
    String? player2Name,
    String? player2Avatar,
  }) async {
    await _cleanupConnections();
    _resetInMemorySession(notify: false);

    _isOnline = false;
    _state = _engine.createInitialState(
      mode: LudoGameMode.offline2,
      player1Name: player1Name,
      player1Avatar: player1Avatar,
      player2Name: player2Name,
      player2Avatar: player2Avatar,
    );
    _startedAt = DateTime.now();
    _movesCount = 0;
    _historyRecorded = false;
    _offlineFinalized = false;
    _lastGameVersion = null;
    _displayTurnIndex = 0;
    _displayDiceValue = null;

    await _storage.saveActiveGame(_state);
    await _sound.play(LudoSfx.turn);
    notifyListeners();
  }

  Future<void> resumeOfflineGame(LudoGameState state) async {
    await _cleanupConnections();
    _resetInMemorySession(notify: false);
    _isOnline = false;
    _state = state;
    _startedAt = DateTime.now();
    _displayTurnIndex = state.currentTurnIndex;
    _offlineFinalized = state.isGameOver;
    notifyListeners();
  }

  /// Host flow: create an invitation and wait for the partner to accept.
  Future<void> createOnlineInvitation({
    required String hostId,
    required String hostName,
    String? hostAvatar,
    required String guestId,
    required String guestName,
    String? guestAvatar,
  }) async {
    final initialState = _engine.createInitialState(
      mode: LudoGameMode.onlineCouple,
      player1Name: hostName,
      player1Avatar: hostAvatar,
      player2Name: guestName,
      player2Avatar: guestAvatar,
    );

    // Create first so an active match throws without tearing down the session.
    final match = await _repository.createMatchInvitation(
      hostId: hostId,
      guestId: guestId,
      hostColor: LudoColor.green,
      guestColor: LudoColor.blue,
      initialState: initialState,
    );

    await _cleanupConnections();
    _resetInMemorySession(notify: false);

    _isOnline = true;
    _isWaitingForOpponent = true;
    _inviteRejected = false;
    _inviteExpired = false;
    _matchId = match.id;
    _currentUserId = hostId;
    _partnerId = guestId;
    _partnerName = guestName;
    _myColor = LudoColor.green;
    _state = match.gameState.isNotEmpty
        ? LudoGameState.fromJson(match.gameState)
        : initialState;
    _lastGameVersion = match.gameVersion;
    _lastAppliedActionId = match.lastAction?['id'] as String?;
    _startedAt = DateTime.now();
    _movesCount = 0;
    _historyRecorded = false;
    _offlineFinalized = false;
    _displayTurnIndex = _state.currentTurnIndex;

    await _connectToMatch(match.id, hostId);
    notifyListeners();
  }

  /// Guest flow: join an accepted match.
  Future<void> startOnlineGame({
    required String matchId,
    required String currentUserId,
    required String? partnerId,
    String? partnerName,
    required LudoColor myColor,
    required LudoGameState initialState,
  }) async {
    await _cleanupConnections();
    _resetInMemorySession(notify: false);

    _isOnline = true;
    _matchId = matchId;
    _currentUserId = currentUserId;
    _partnerId = partnerId;
    _partnerName = partnerName;
    _myColor = myColor;
    _state = initialState;
    _startedAt = DateTime.now();
    _movesCount = 0;
    _historyRecorded = false;
    _offlineFinalized = false;
    _isWaitingForOpponent = false;
    _inviteRejected = false;
    _inviteExpired = false;
    _displayTurnIndex = _state.currentTurnIndex;

    final match = await _repository.fetchMatch(matchId);
    if (match != null) {
      _lastGameVersion = match.gameVersion;
      _lastAppliedActionId = match.lastAction?['id'] as String?;
      if (match.gameState.isNotEmpty) {
        _state = LudoGameState.fromJson(match.gameState);
      }
      _isWaitingForOpponent = match.status == LudoMatchStatus.invited;
    }

    await _connectToMatch(matchId, currentUserId);
    notifyListeners();
  }

  Future<void> _connectToMatch(String matchId, String currentUserId) async {
    _matchSub = _repository.watchMatch(matchId).listen(
      _handleMatchSnapshot,
      onError: (Object error) {
        debugPrint('Ludo match stream error: $error');
      },
    );

    await _realtime.connect(matchId, currentUserId: currentUserId);
    _realtimeSub = _realtime.onEvent.listen(_handleRealtimeEvent);
    _presenceSub = _realtime.onPresence.listen(_handlePresence);
    _startSyncTimer();
  }

  void _handlePresence(Set<String> userIds) {
    final partnerOnline = _partnerId != null && userIds.contains(_partnerId);
    if (partnerOnline != _isPartnerOnline) {
      _isPartnerOnline = partnerOnline;
      _notify();
    }
  }

  /// Pull the authoritative match row. Used as a safety net when a realtime
  /// event is missed, after app resume, and while waiting for an invitation.
  Future<void> refreshFromServer() async {
    final matchId = _matchId;
    if (!_isOnline || matchId == null) return;

    final latest = await _repository.fetchMatch(matchId);
    if (latest == null || _disposed) return;
    _handleMatchSnapshot(latest);
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_disposed || !_isOnline || _matchId == null) return;
      unawaited(refreshFromServer());
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (_disposed || !_isOnline) return;
      unawaited(refreshFromServer());
    });
  }

  void _handleMatchSnapshot(LudoMatchModel match) {
    if (!_isOnline || match.id != _matchId) return;
    if (_activeMotion != null) {
      _queuedMatch = match;
      return;
    }
    _applyMatch(match);
  }

  void _applyMatch(LudoMatchModel match) {
    switch (match.status) {
      case LudoMatchStatus.invited:
        _isWaitingForOpponent = true;
        _notify();
        return;

      case LudoMatchStatus.accepted:
        _isWaitingForOpponent = false;
        _inviteRejected = false;
        _inviteExpired = false;
        break;

      case LudoMatchStatus.rejected:
        _isWaitingForOpponent = false;
        _inviteRejected = true;
        _state = _state.copyWith(
          statusMessage: 'Ajakan ditolak. Coba ajak lagi ya.',
        );
        _notify();
        return;

      case LudoMatchStatus.cancelled:
      case LudoMatchStatus.expired:
        _isWaitingForOpponent = false;
        _inviteExpired = true;
        _state = _state.copyWith(
          statusMessage: 'Ajakan kedaluwarsa. Kirim ajakan baru yuk.',
        );
        _notify();
        return;

      case LudoMatchStatus.completed:
      case LudoMatchStatus.abandoned:
        final version = match.gameVersion;
        if (_lastGameVersion != null && version < _lastGameVersion!) return;
        final next = match.gameState.isNotEmpty
            ? LudoGameState.fromJson(match.gameState)
            : _state;
        final winnerColor = match.winnerId == null
            ? next.winnerColor
            : (match.winnerId == match.hostId
                ? match.hostColor
                : match.guestColor);
        _state = next.copyWith(
          phase: LudoTurnPhase.gameOver,
          winnerColor: winnerColor,
          statusMessage: winnerColor == _myColor
              ? 'Yeay! Kamu memenangkan permainan.'
              : 'Lawan memenangkan permainan ini.',
        );
        _lastGameVersion = version;
        _displayTurnIndex = _state.currentTurnIndex;
        _syncTimer?.cancel();
        _syncTimer = null;
        _finalizeGame();
        _notify();
        return;

      case LudoMatchStatus.inProgress:
        _isWaitingForOpponent = false;
        break;
    }

    final version = match.gameVersion;
    if (_lastGameVersion != null && version < _lastGameVersion!) return;
    if (_pendingLocalActionId != null &&
        _lastGameVersion != null &&
        version <= _lastGameVersion!) {
      return;
    }

    final remoteActionId = match.lastAction?['id'] as String?;
    if (_lastGameVersion == version && hasActiveGame) {
      if (remoteActionId == null || remoteActionId == _lastAppliedActionId) {
        _finalizeGameIfNeeded();
        _notify();
        return;
      }
    }

    final previousState = _state;
    final nextState = match.gameState.isNotEmpty
        ? LudoGameState.fromJson(match.gameState)
        : _state;

    _lastGameVersion = version;
    _lastAppliedActionId = remoteActionId;
    _state = nextState;

    final action = match.lastAction != null
        ? LudoAction.fromJson(match.lastAction!)
        : null;
    if (action != null && action.actorId != _currentUserId) {
      _applyRemoteAction(action, previousState, nextState);
    } else {
      _displayTurnIndex = _state.currentTurnIndex;
    }

    _finalizeGameIfNeeded();
    _notify();
  }

  void _applyRemoteAction(
    LudoAction action,
    LudoGameState previousState,
    LudoGameState nextState,
  ) {
    if (action.type == 'roll') {
      final dice = action.diceValue;
      if (dice != null) {
        _animateRemoteDice(dice);
      }
      return;
    }

    if (action.type != 'move' || action.tokenId == null) return;

    final fromState = action.fromState ?? LudoTokenState.track;
    final fromStep = action.fromStep ?? 0;
    final dice = action.diceValue ?? nextState.diceValue ?? 0;
    final path = LudoBoardPath.buildMovePath(
      color: action.actorColor ?? previousState.currentPlayer.color,
      tokenId: action.tokenId!,
      fromState: fromState,
      fromStep: fromStep,
      diceRoll: dice,
    );

    _displayTurnIndex = previousState.currentTurnIndex;
    _isTurnTransitioning = true;
    final motion = LudoMotion(
      id: action.id,
      color: action.actorColor ?? previousState.currentPlayer.color,
      tokenId: action.tokenId!,
      path: path,
      capturedTokens: action.capturedTokens,
      reachedHome: action.reachedHome,
      isYardExit: fromState == LudoTokenState.yard,
      stepDurationMs: 180,
      fromTurnIndex: previousState.currentTurnIndex,
    );
    _activeMotion = motion;
    _armMotionSafety(motion);
    _sound.play(LudoSfx.turn);
  }

  void _animateRemoteDice(int value) {
    _displayDiceValue = value;
    _rollingPlayerIndex = _state.lastRolledByIndex;
    _isRollingAnimation = true;
    _notify();

    Future.delayed(const Duration(milliseconds: 620), () {
      if (_disposed) return;
      _isRollingAnimation = false;
      _notify();
    });
  }

  Future<void> rollDice() async {
    if (!canRoll()) return;

    _isRollingAnimation = true;
    _rollingPlayerIndex = _state.currentTurnIndex;
    _displayDiceValue = _random.nextInt(6) + 1;
    _notify();

    unawaited(_sound.play(LudoSfx.diceRoll));
    HapticFeedback.lightImpact();

    _diceTimer?.cancel();
    _diceTimer = Timer.periodic(const Duration(milliseconds: 70), (_) {
      if (_disposed) return;
      _displayDiceValue = _random.nextInt(6) + 1;
      _notify();
    });

    await Future.delayed(const Duration(milliseconds: 650));
    _diceTimer?.cancel();

    if (_disposed ||
        !hasActiveGame ||
        _state.phase != LudoTurnPhase.waitingForRoll ||
        !isMyTurn) {
      _isRollingAnimation = false;
      _notify();
      return;
    }

    final diceValue = _engine.rollDice();
    _displayDiceValue = diceValue;
    _isRollingAnimation = false;
    unawaited(_sound.play(LudoSfx.diceLand));
    HapticFeedback.mediumImpact();

    final previousState = _state;
    final nextState = _engine.handleDiceRoll(previousState, diceValue);
    final action = LudoAction(
      id: LudoAction.newId(),
      type: 'roll',
      actorId: _currentUserId,
      actorColor: previousState.currentPlayer.color,
      diceValue: diceValue,
      noMoves: nextState.phase == LudoTurnPhase.waitingForRoll,
      createdAt: DateTime.now(),
    );

    final isPassingTurn = nextState.phase == LudoTurnPhase.waitingForRoll;
    _pendingLocalActionId = action.id;
    _state = nextState;
    _lastAppliedActionId = action.id;
    _movesCount++;
    _displayTurnIndex = previousState.currentTurnIndex;
    _isTurnTransitioning = isPassingTurn;
    _notify();

    await _persistAction(action);
    _notify();

    if (isPassingTurn) {
      _turnTransitionTimer?.cancel();
      _turnTransitionTimer = Timer(const Duration(milliseconds: 950), () {
        if (_disposed || !hasActiveGame) return;
        _isTurnTransitioning = false;
        _displayTurnIndex = _state.currentTurnIndex;
        _notify();
      });
      return;
    }

    if (nextState.phase == LudoTurnPhase.waitingForTokenMove &&
        nextState.movableTokenIds.length == 1) {
      await Future.delayed(const Duration(milliseconds: 480));
      if (_disposed || !hasActiveGame) return;
      final tokenId = nextState.movableTokenIds.first;
      if (canSelectToken(tokenId)) {
        await selectToken(tokenId);
      }
    }
  }

  Future<void> selectToken(int tokenId) async {
    if (!canSelectToken(tokenId)) return;

    final previousState = _state;
    final moveResult = _engine.executeMove(previousState, tokenId);
    final token = previousState.currentPlayer.tokens
        .firstWhere((t) => t.id == tokenId);
    final diceValue = previousState.diceValue ?? 0;
    final capturedTokens = _capturedTokensForMove(previousState, moveResult);

    final action = LudoAction(
      id: LudoAction.newId(),
      type: 'move',
      actorId: _currentUserId,
      actorColor: previousState.currentPlayer.color,
      diceValue: diceValue,
      tokenId: tokenId,
      fromState: token.state,
      fromStep: token.step,
      toState: moveResult.movedToken.state,
      toStep: moveResult.movedToken.step,
      didCapture: capturedTokens.isNotEmpty,
      capturedTokens: capturedTokens,
      reachedHome: moveResult.didReachHome,
      bonusRoll: moveResult.getsBonusRoll,
      createdAt: DateTime.now(),
    );

    final motion = LudoMotion(
      id: action.id,
      color: previousState.currentPlayer.color,
      tokenId: tokenId,
      path: LudoBoardPath.buildMovePath(
        color: previousState.currentPlayer.color,
        tokenId: tokenId,
        fromState: token.state,
        fromStep: token.step,
        diceRoll: diceValue,
      ),
      capturedTokens: action.capturedTokens,
      reachedHome: moveResult.didReachHome,
      isYardExit: token.state == LudoTokenState.yard,
      stepDurationMs: 180,
      fromTurnIndex: previousState.currentTurnIndex,
    );

    _pendingLocalActionId = action.id;
    _state = moveResult.nextState;
    _lastAppliedActionId = action.id;
    _movesCount++;
    _activeMotion = motion;
    _isTurnTransitioning = true;
    _armMotionSafety(motion);
    _displayTurnIndex = previousState.currentTurnIndex;
    _displayDiceValue = previousState.diceValue;
    HapticFeedback.selectionClick();
    _notify();

    await _persistAction(action);
    _notify();
  }

  List<LudoCapturedToken> _capturedTokensForMove(
    LudoGameState previousState,
    LudoMoveResult moveResult,
  ) {
    final movedToken = moveResult.movedToken;
    if (!movedToken.isOnTrack) return const [];

    final actorColor = previousState.currentPlayer.color;
    final landingGlobalIndex = LudoBoardPath.relativeStepToGlobalIndex(
      actorColor,
      movedToken.step,
    );
    if (LudoBoardPath.isSafeGlobalIndex(landingGlobalIndex)) return const [];

    final captured = <LudoCapturedToken>[];
    for (final player in previousState.players) {
      if (player.color == actorColor) continue;
      for (final token in player.tokens) {
        if (!token.isOnTrack) continue;
        final globalIndex = LudoBoardPath.relativeStepToGlobalIndex(
          player.color,
          token.step,
        );
        if (globalIndex == landingGlobalIndex) {
          captured.add(LudoCapturedToken(
            color: player.color,
            tokenId: token.id,
            fromState: token.state,
            fromStep: token.step,
          ));
        }
      }
    }
    return captured;
  }

  void _armMotionSafety(LudoMotion motion) {
    _motionSafetyTimer?.cancel();
    final expectedMs = motion.isYardExit
        ? 480
        : (motion.path.length - 1) * motion.stepDurationMs;
    _motionSafetyTimer = Timer(
      Duration(milliseconds: expectedMs + 2500),
      () {
        if (_disposed) return;
        if (_activeMotion?.id == motion.id) {
          completeMotion(motion.id);
        }
      },
    );
  }

  void completeMotion(String motionId) {
    final motion = _activeMotion;
    if (motion == null || motion.id != motionId) return;

    _motionSafetyTimer?.cancel();
    _motionSafetyTimer = null;
    _activeMotion = null;
    _isTurnTransitioning = false;
    _displayTurnIndex = _state.currentTurnIndex;
    _displayDiceValue = _state.diceValue;

    if (motion.capturedTokens.isNotEmpty) {
      unawaited(_sound.play(LudoSfx.capture));
      HapticFeedback.heavyImpact();
    } else if (motion.reachedHome) {
      unawaited(_sound.play(LudoSfx.home));
      HapticFeedback.mediumImpact();
    } else {
      unawaited(_sound.play(LudoSfx.turn));
    }

    _notify();
    _finalizeGameIfNeeded();

    final queued = _queuedMatch;
    _queuedMatch = null;
    if (queued != null) {
      _applyMatch(queued);
    }
  }

  Future<void> _persistAction(LudoAction action) async {
    if (!_isOnline) {
      await _storage.saveActiveGame(_state);
      return;
    }

    final matchId = _matchId;
    if (matchId == null) return;

    final isCompleted = _state.isGameOver;
    final winnerId = _state.winnerColor == null
        ? null
        : (_state.winnerColor == _myColor ? _currentUserId : _partnerId);

    _pendingLocalActionId = action.id;
    try {
      final updated = await _repository.applyMatchAction(
        matchId: matchId,
        expectedVersion: _lastGameVersion ?? 0,
        state: _state,
        currentTurnColor: _state.currentPlayer.color,
        action: action,
        winnerId: winnerId,
        isCompleted: isCompleted,
      );

      if (updated != null) {
        _lastGameVersion = updated.gameVersion;
        return;
      }

      final latest = await _repository.fetchMatch(matchId);
      if (latest == null) return;
      _pendingLocalActionId = null;
      _handleMatchSnapshot(latest);
    } finally {
      if (_pendingLocalActionId == action.id) {
        _pendingLocalActionId = null;
      }
    }
  }

  void _handleRealtimeEvent(LudoRealtimeEvent event) {
    switch (event.event) {
      case 'reaction':
        final emoji = event.payload['emoji'] as String?;
        final senderId = event.payload['senderId'] as String?;
        if (emoji != null && senderId != _currentUserId) {
          _incomingReaction = emoji;
          _reactionTimer?.cancel();
          _reactionTimer = Timer(const Duration(seconds: 3), () {
            _incomingReaction = null;
            _notify();
          });
          _notify();
        }
        break;

      case 'surrender':
        final leavingId = event.payload['playerId'] as String?;
        if (leavingId != null && leavingId != _currentUserId) {
          final myColor = _myColor;
          if (myColor != null) {
            _state = _state.copyWith(
              phase: LudoTurnPhase.gameOver,
              winnerColor: myColor,
              statusMessage: 'Lawan menyerah. Kamu menang!',
            );
            _displayTurnIndex = _state.currentTurnIndex;
            _finalizeGame();
            _notify();
          }
        }
        break;
    }
  }

  void sendReaction(String emoji) {
    if (!_isOnline || _currentUserId == null) return;
    _realtime.broadcastReaction(
      emoji: emoji,
      senderId: _currentUserId!,
    );
  }

  Future<void> surrender() async {
    if (_isOnline && _matchId != null && _currentUserId != null) {
      final partnerColor = _myColor == LudoColor.green
          ? LudoColor.blue
          : LudoColor.green;

      await _realtime.broadcastSurrender(playerId: _currentUserId!);

      if (_partnerId != null) {
        await _repository.abandonMatch(
          matchId: _matchId!,
          winnerId: _partnerId!,
          reason: 'surrender',
        );
      }

      _state = _state.copyWith(
        phase: LudoTurnPhase.gameOver,
        winnerColor: partnerColor,
        statusMessage: 'Kamu menyerah. Lawan menang.',
      );
      _displayTurnIndex = _state.currentTurnIndex;
      await _finalizeGame();
      unawaited(_sound.play(LudoSfx.turn));
      _notify();
      return;
    }

    _state = _state.copyWith(
      phase: LudoTurnPhase.gameOver,
      statusMessage: 'Permainan telah diakhiri.',
    );
    await _storage.clearActiveGame();
    _notify();
  }

  Future<void> leaveGame({bool confirmSurrender = false}) async {
    if (confirmSurrender && hasActiveGame && !_state.isGameOver) {
      await surrender();
    }

    if (_isOnline &&
        _isWaitingForOpponent &&
        _matchId != null &&
        _currentUserId != null) {
      await _repository.cancelMatch(_matchId!, _currentUserId!);
    }

    await _cleanupConnections();
    _resetInMemorySession(notify: false);
    _notify();
  }

  void _finalizeGameIfNeeded() {
    if (_state.isGameOver && _activeMotion == null) {
      _finalizeGame();
    }
  }

  Future<void> _finalizeGame() async {
    if (_isOnline) {
      if (_historyRecorded ||
          _matchId == null ||
          _currentUserId == null ||
          _state.isGameOver == false) {
        return;
      }
      _historyRecorded = true;
      final isWinner = _state.winnerColor == _myColor;
      final duration = _startedAt != null
          ? DateTime.now().difference(_startedAt!).inSeconds
          : 60;

      await _repository.recordGameHistory(
        matchId: _matchId!,
        userId: _currentUserId!,
        partnerId: _partnerId,
        isWinner: isWinner,
        durationSeconds: duration,
        totalMoves: _movesCount,
      );

      if (isWinner) {
        await _storage.incrementWinCount();
        unawaited(_sound.play(LudoSfx.win));
      }
      return;
    }

    if (_offlineFinalized) return;
    _offlineFinalized = true;
    await _storage.clearActiveGame();
    if (_state.winnerColor != null) {
      await _storage.incrementWinCount();
      unawaited(_sound.play(LudoSfx.win));
    }
  }

  Future<void> _cleanupConnections() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    await _matchSub?.cancel();
    _matchSub = null;
    await _realtimeSub?.cancel();
    _realtimeSub = null;
    await _presenceSub?.cancel();
    _presenceSub = null;
    await _realtime.disconnect();
  }

  void _resetInMemorySession({bool notify = true}) {
    _matchId = null;
    _currentUserId = null;
    _partnerId = null;
    _partnerName = null;
    _myColor = null;
    _isOnline = false;
    _isWaitingForOpponent = false;
    _inviteRejected = false;
    _inviteExpired = false;
    _isPartnerOnline = false;
    _lastGameVersion = null;
    _lastAppliedActionId = null;
    _pendingLocalActionId = null;
    _startedAt = null;
    _movesCount = 0;
    _historyRecorded = false;
    _offlineFinalized = false;
    _isRollingAnimation = false;
    _rollingPlayerIndex = null;
    _displayDiceValue = null;
    _activeMotion = null;
    _displayTurnIndex = null;
    _isTurnTransitioning = false;
    _incomingReaction = null;
    _queuedMatch = null;
    _state = const LudoGameState(
      mode: LudoGameMode.offline2,
      players: [],
    );
    _reactionTimer?.cancel();
    _diceTimer?.cancel();
    _turnTransitionTimer?.cancel();
    _motionSafetyTimer?.cancel();
    if (notify) _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _reactionTimer?.cancel();
    _diceTimer?.cancel();
    _turnTransitionTimer?.cancel();
    _motionSafetyTimer?.cancel();
    _syncTimer?.cancel();
    _matchSub?.cancel();
    _realtimeSub?.cancel();
    _presenceSub?.cancel();
    _realtime.dispose();
    super.dispose();
  }
}
