import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../engine/uno_engine.dart';
import '../models/uno_card.dart';
import '../models/uno_game_state.dart';
import '../models/uno_match_model.dart';
import '../repositories/uno_repository.dart';
import '../services/uno_realtime_service.dart';
import '../services/uno_sound_service.dart';

enum UnoHandSortMode {
  color('Warna'),
  type('Jenis');

  final String label;

  const UnoHandSortMode(this.label);
}

class UnoGameProvider extends ChangeNotifier {
  final UnoEngine _engine;
  final UnoRepository _repository;
  final UnoRealtimeService _realtime;
  final UnoSoundService _sound;

  UnoGameState? _state;
  String? _matchId;
  String? _currentUserId;
  String? _partnerId;
  String? _partnerName;
  bool _isWaitingForOpponent = false;
  bool _inviteRejected = false;
  bool _inviteExpired = false;
  bool _isPartnerOnline = false;
  bool _busy = false;
  String? _lastError;
  int? _lastVersion;
  int _movesCount = 0;
  DateTime? _startedAt;
  bool _historyRecorded = false;
  UnoHandSortMode _handSortMode = UnoHandSortMode.color;
  String? _incomingReaction;
  Timer? _reactionTimer;
  Timer? _syncTimer;
  Timer? _heartbeatTimer;
  Timer? _disconnectTimer;
  StreamSubscription<UnoMatchModel>? _matchSub;
  StreamSubscription<UnoRealtimeEvent>? _realtimeSub;
  StreamSubscription<Set<String>>? _presenceSub;
  UnoMatchModel? _queuedMatch;
  bool _disposed = false;

  UnoGameProvider({
    UnoEngine? engine,
    UnoRepository? repository,
    UnoRealtimeService? realtime,
    UnoSoundService? sound,
  })  : _engine = engine ?? const UnoEngine(),
        _repository = repository ?? UnoRepository(),
        _realtime = realtime ?? UnoRealtimeService(),
        _sound = sound ?? UnoSoundService.instance;

  UnoGameState? get state => _state;
  String? get matchId => _matchId;
  String? get currentUserId => _currentUserId;
  String? get partnerId => _partnerId;
  String? get partnerName => _partnerName;
  bool get isWaitingForOpponent => _isWaitingForOpponent;
  bool get inviteRejected => _inviteRejected;
  bool get inviteExpired => _inviteExpired;
  bool get isPartnerOnline => _isPartnerOnline;
  bool get busy => _busy;
  String? get lastError => _lastError;
  String? get incomingReaction => _incomingReaction;
  int get movesCount => _movesCount;
  bool get soundEnabled => _sound.enabled;
  bool get hasActiveGame => _state != null && !_state!.isGameOver;
  bool get isOnline => true;

  UnoEngine get engine => _engine;

  UnoHandSortMode get handSortMode => _handSortMode;

  List<UnoCard> get displayHand {
    final hand = _state?.myHand ?? const <UnoCard>[];
    final sorted = List<UnoCard>.from(hand);
    sorted.sort(_compareCards);
    return sorted;
  }

  void cycleHandSort() {
    _handSortMode = _handSortMode == UnoHandSortMode.color
        ? UnoHandSortMode.type
        : UnoHandSortMode.color;
    _notify();
  }

  int _compareCards(UnoCard a, UnoCard b) {
    if (_handSortMode == UnoHandSortMode.color) {
      final color = _colorRank(a.color).compareTo(_colorRank(b.color));
      if (color != 0) return color;
      final type = _typeRank(a.type).compareTo(_typeRank(b.type));
      if (type != 0) return type;
      return (a.number ?? 0).compareTo(b.number ?? 0);
    }

    final type = _typeRank(a.type).compareTo(_typeRank(b.type));
    if (type != 0) return type;
    final number = (a.number ?? 0).compareTo(b.number ?? 0);
    if (number != 0) return number;
    return _colorRank(a.color).compareTo(_colorRank(b.color));
  }

  int _colorRank(UnoColor? color) {
    switch (color) {
      case UnoColor.red:
        return 0;
      case UnoColor.yellow:
        return 1;
      case UnoColor.green:
        return 2;
      case UnoColor.blue:
        return 3;
      case null:
        return 4;
    }
  }

  int _typeRank(UnoCardType type) {
    switch (type) {
      case UnoCardType.number:
        return 0;
      case UnoCardType.skip:
        return 1;
      case UnoCardType.reverse:
        return 2;
      case UnoCardType.drawOne:
        return 3;
      case UnoCardType.drawTwo:
        return 4;
      case UnoCardType.wild:
        return 5;
    }
  }

  Future<void> initializeSounds() async {
    await _sound.initialize();
    _notify();
  }

  Future<void> toggleSound() async {
    await _sound.setEnabled(!_sound.enabled);
    _notify();
  }

  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    _notify();
  }

  // --- Session flows -------------------------------------------------------

  Future<void> createOnlineInvitation({
    required String hostId,
    required String hostName,
    String? hostAvatar,
    required String guestId,
    required String guestName,
    String? guestAvatar,
  }) async {
    final match = await _repository.createMatchInvitation(
      hostId: hostId,
      guestId: guestId,
    );

    await _cleanupConnections();
    _resetSession(notify: false);

    _matchId = match.id;
    _currentUserId = hostId;
    _partnerId = guestId;
    _partnerName = guestName;
    _isWaitingForOpponent = true;
    _startedAt = DateTime.now();
    _lastVersion = match.version;
    _state = UnoGameState(
      match: match,
      myUserId: hostId,
      myHand: const [],
    );

    await _connectToMatch(match.id, hostId);
    _notify();
  }

  Future<void> startOnlineGame({
    required String matchId,
    required String currentUserId,
    required String? partnerId,
    String? partnerName,
    required UnoStateSnapshot snapshot,
  }) async {
    await _cleanupConnections();
    _resetSession(notify: false);

    _matchId = matchId;
    _currentUserId = currentUserId;
    _partnerId = partnerId ?? snapshot.match.opponentOf(currentUserId);
    _partnerName = partnerName;
    _isWaitingForOpponent = false;
    _startedAt = DateTime.now();
    _lastVersion = snapshot.match.version;
    _state = UnoGameState(
      match: snapshot.match,
      myUserId: currentUserId,
      myHand: snapshot.myHand,
    );

    await _connectToMatch(matchId, currentUserId);
    _notify();
  }

  Future<void> resumeMatch({
    required String matchId,
    required String currentUserId,
    required String? partnerId,
    String? partnerName,
  }) async {
    final snapshot = await _repository.fetchState(matchId);

    await _cleanupConnections();
    _resetSession(notify: false);

    _matchId = matchId;
    _currentUserId = currentUserId;
    _partnerId = partnerId ?? snapshot.match.opponentOf(currentUserId);
    _partnerName = partnerName;
    _isWaitingForOpponent = snapshot.match.status == UnoMatchStatus.invited;
    _startedAt = DateTime.now();
    _lastVersion = snapshot.match.version;
    _state = UnoGameState(
      match: snapshot.match,
      myUserId: currentUserId,
      myHand: snapshot.myHand,
    );

    await _connectToMatch(matchId, currentUserId);
    _notify();
  }

  Future<void> _connectToMatch(String matchId, String currentUserId) async {
    _matchSub = _repository.watchMatch(matchId).listen(
      _handleMatchSnapshot,
      onError: (Object error) {
        debugPrint('UNO match stream error: $error');
      },
    );

    await _realtime.connect(matchId, currentUserId: currentUserId);
    _realtimeSub = _realtime.onEvent.listen(_handleRealtimeEvent);
    _presenceSub = _realtime.onPresence.listen(_handlePresence);

    _startSyncTimer();
    _startHeartbeatTimer();
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_disposed || _matchId == null) return;
      unawaited(refreshFromServer());
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (_disposed || _matchId == null) return;
      unawaited(refreshFromServer());
    });
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      final matchId = _matchId;
      if (_disposed || matchId == null) return;
      unawaited(_repository.heartbeat(matchId));
    });
  }

  Future<void> refreshFromServer() async {
    final matchId = _matchId;
    final userId = _currentUserId;
    if (_disposed || matchId == null || userId == null || _busy) return;

    try {
      final snapshot = await _repository.fetchState(matchId);
      if (_disposed) return;
      _applySnapshot(snapshot);
    } catch (e) {
      debugPrint('UNO refresh failed: $e');
    }
  }

  void _applySnapshot(UnoStateSnapshot snapshot) {
    final userId = _currentUserId;
    if (userId == null || _disposed) return;

    _lastVersion = snapshot.match.version;
    _state = UnoGameState(
      match: snapshot.match,
      myUserId: userId,
      myHand: snapshot.myHand,
    );

    switch (snapshot.match.status) {
      case UnoMatchStatus.invited:
        _isWaitingForOpponent = true;
        break;
      case UnoMatchStatus.rejected:
        _inviteRejected = true;
        _isWaitingForOpponent = false;
        break;
      case UnoMatchStatus.cancelled:
      case UnoMatchStatus.expired:
        _inviteExpired = true;
        _isWaitingForOpponent = false;
        break;
      case UnoMatchStatus.inProgress:
      case UnoMatchStatus.paused:
        _isWaitingForOpponent = false;
        break;
      case UnoMatchStatus.completed:
      case UnoMatchStatus.abandoned:
        _isWaitingForOpponent = false;
        _finalizeGame();
        break;
    }
    _notify();
  }

  void _handleMatchSnapshot(UnoMatchModel match) {
    final userId = _currentUserId;
    if (userId == null || _disposed) return;
    if (match.id != _matchId) return;

    final currentVersion = _lastVersion ?? 0;
    if (match.version < currentVersion) return;
    if (_busy && match.version <= currentVersion) return;

    if (_state == null) {
      _state = UnoGameState(
        match: match,
        myUserId: userId,
        myHand: const [],
      );
    } else {
      _state = _state!.copyWith(match: match);
    }

    switch (match.status) {
      case UnoMatchStatus.invited:
        _isWaitingForOpponent = true;
        break;
      case UnoMatchStatus.rejected:
        _inviteRejected = true;
        _isWaitingForOpponent = false;
        break;
      case UnoMatchStatus.cancelled:
      case UnoMatchStatus.expired:
        _inviteExpired = true;
        _isWaitingForOpponent = false;
        break;
      case UnoMatchStatus.inProgress:
      case UnoMatchStatus.paused:
        _isWaitingForOpponent = false;
        break;
      case UnoMatchStatus.completed:
      case UnoMatchStatus.abandoned:
        _isWaitingForOpponent = false;
        _finalizeGame();
        break;
    }

    if (match.version > currentVersion) {
      _lastVersion = match.version;
      if (_busy) {
        _queuedMatch = match;
      } else {
        unawaited(refreshFromServer());
      }
    } else {
      _notify();
    }
  }

  void _handlePresence(Set<String> userIds) {
    final partnerId = _partnerId;
    final online = partnerId != null && userIds.contains(partnerId);
    if (online == _isPartnerOnline) return;
    _isPartnerOnline = online;
    if (online) {
      _cancelDisconnectTimer();
    } else if (_state != null &&
        !_state!.isGameOver &&
        !_state!.isPaused &&
        !_isWaitingForOpponent) {
      _startDisconnectTimer();
    }
    _notify();
  }

  void _startDisconnectTimer() {
    _disconnectTimer?.cancel();
    _disconnectTimer = Timer(const Duration(minutes: 5), () {
      final state = _state;
      if (_disposed || state == null || state.isGameOver) return;
      if (_isPartnerOnline) return;
      unawaited(_claimTimeoutWin());
    });
  }

  void _cancelDisconnectTimer() {
    _disconnectTimer?.cancel();
    _disconnectTimer = null;
  }

  void _handleRealtimeEvent(UnoRealtimeEvent event) {
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
          unawaited(refreshFromServer());
        }
        break;
    }
  }

  void sendReaction(String emoji) {
    final userId = _currentUserId;
    if (userId == null) return;
    _realtime.broadcastReaction(emoji: emoji, senderId: userId);
  }

  // --- Actions -------------------------------------------------------------

  Future<void> playCard(UnoCard card, {UnoColor? chosenColor}) async {
    final state = _state;
    final matchId = _matchId;
    if (state == null || matchId == null || _busy) return;
    if (!_engine.canPlayCard(state, card)) return;

    final before = state;
    final expectedVersion = state.match.version;
    late final UnoGameState optimistic;
    try {
      optimistic = _engine.playCard(state, card, chosenColor: chosenColor);
    } catch (e) {
      _lastError = e.toString();
      _notify();
      return;
    }

    _busy = true;
    _state = optimistic;
    _movesCount++;
    _notify();

    try {
      final snapshot = await _repository.playCard(
        matchId: matchId,
        expectedVersion: expectedVersion,
        cardId: card.id,
        publicState: optimistic.match.toPublicPatch(),
      );
      unawaited(_playCardSound(card));
      _applySnapshot(snapshot);
    } on UnoVersionConflictException {
      _state = before;
      await refreshFromServer();
    } on UnoRepositoryException catch (e) {
      _state = before;
      _lastError = e.message;
      _notify();
    } catch (e) {
      _state = before;
      _lastError = 'Gagal memainkan kartu: $e';
      _notify();
    } finally {
      _busy = false;
      final queued = _queuedMatch;
      _queuedMatch = null;
      if (queued != null) {
        _handleMatchSnapshot(queued);
      }
    }
  }

  Future<void> endTurn() async {
    final state = _state;
    final matchId = _matchId;
    if (state == null || matchId == null || _busy || !state.isMyTurn) return;
    if (state.match.turnCards.isEmpty) return;

    final before = state;
    final expectedVersion = state.match.version;
    final optimistic = _engine.endTurn(state);

    _busy = true;
    _state = optimistic;
    _movesCount++;
    _notify();

    try {
      final match = await _repository.endTurn(
        matchId: matchId,
        expectedVersion: expectedVersion,
        publicState: optimistic.match.toPublicPatch(),
      );
      _lastVersion = match.version;
      _state = optimistic.copyWith(match: match);
      _notify();
    } on UnoVersionConflictException {
      _state = before;
      await refreshFromServer();
    } on UnoRepositoryException catch (e) {
      _state = before;
      _lastError = e.message;
      _notify();
    } catch (e) {
      _state = before;
      _lastError = 'Gagal menyelesaikan giliran: $e';
      _notify();
    } finally {
      _busy = false;
    }
  }

  Future<void> passDrawPenalty() async {
    final state = _state;
    final matchId = _matchId;
    if (state == null || matchId == null || _busy) return;
    if (!state.isDrawResponseForMe || !state.match.drawResponseStarted) return;

    final before = state;
    final expectedVersion = state.match.version;
    final optimistic = _engine.passDrawResponse(state);
    if (identical(optimistic, state)) return;

    _busy = true;
    _state = optimistic;
    _notify();

    try {
      final match = await _repository.endTurn(
        matchId: matchId,
        expectedVersion: expectedVersion,
        publicState: optimistic.match.toPublicPatch(),
      );
      _lastVersion = match.version;
      _state = optimistic.copyWith(match: match);
      _notify();
    } on UnoVersionConflictException {
      _state = before;
      await refreshFromServer();
    } on UnoRepositoryException catch (e) {
      _state = before;
      _lastError = e.message;
      _notify();
    } finally {
      _busy = false;
    }
  }

  bool get canDrawOne {
    final state = _state;
    if (state == null || _busy) return false;
    if (!state.isMyTurn || state.match.turnCards.isNotEmpty) return false;
    // Drawing is always allowed at the start of a turn — even when a
    // playable card exists. It is a tactical pass: draw one, then the turn
    // passes immediately and the drawn card cannot be played this turn.
    return true;
  }

  Future<void> drawOne() async {
    final state = _state;
    final matchId = _matchId;
    if (state == null || matchId == null || _busy) return;
    if (!canDrawOne) return;

    final before = state;
    final expectedVersion = state.match.version;
    final patch = _engine.matchAfterDrawOne(state);

    _busy = true;
    _notify();

    try {
      final result = await _repository.drawCards(
        matchId: matchId,
        expectedVersion: expectedVersion,
        count: 1,
        publicState: patch.toPublicPatch(),
      );
      _movesCount++;
      unawaited(_sound.play(UnoSfx.draw));
      _lastVersion = result.snapshot.match.version;
      _state = UnoGameState(
        match: result.snapshot.match,
        myUserId: state.myUserId,
        myHand: [...state.myHand, ...result.drawnCards],
      );
      _notify();
    } on UnoVersionConflictException {
      _state = before;
      await refreshFromServer();
    } on UnoRepositoryException catch (e) {
      _lastError = e.message;
      _notify();
    } catch (e) {
      _lastError = 'Gagal mengambil kartu: $e';
      _notify();
    } finally {
      _busy = false;
    }
  }

  Future<void> acceptDrawPenalty() async {
    final state = _state;
    final matchId = _matchId;
    if (state == null || matchId == null || _busy) return;
    if (!state.isDrawResponseForMe) return;
    if (state.match.pendingDraw <= 0) return;

    final before = state;
    final expectedVersion = state.match.version;
    final patch = _engine.matchAfterAcceptDraw(state);

    _busy = true;
    _notify();

    try {
      final result = await _repository.drawCards(
        matchId: matchId,
        expectedVersion: expectedVersion,
        count: state.match.pendingDraw,
        publicState: patch.toPublicPatch(),
      );
      _movesCount++;
      unawaited(_sound.play(UnoSfx.penalty));
      _lastVersion = result.snapshot.match.version;
      _state = UnoGameState(
        match: result.snapshot.match,
        myUserId: state.myUserId,
        myHand: [...state.myHand, ...result.drawnCards],
      );
      _notify();
    } on UnoVersionConflictException {
      _state = before;
      await refreshFromServer();
    } on UnoRepositoryException catch (e) {
      _state = before;
      _lastError = e.message;
      _notify();
    } catch (e) {
      _state = before;
      _lastError = 'Gagal mengambil penalti: $e';
      _notify();
    } finally {
      _busy = false;
    }
  }

  Future<void> pauseGame(String action) async {
    final matchId = _matchId;
    if (matchId == null || _busy) return;
    _busy = true;
    _notify();
    try {
      final match = await _repository.pause(matchId: matchId, action: action);
      _lastVersion = match.version;
      _state = _state?.copyWith(match: match);
      _notify();
    } on UnoRepositoryException catch (e) {
      _lastError = e.message;
      _notify();
    } finally {
      _busy = false;
    }
  }

  Future<void> surrender() async {
    final matchId = _matchId;
    final userId = _currentUserId;
    if (matchId == null || userId == null) return;

    await _realtime.broadcastSurrender(playerId: userId);
    try {
      final match = await _repository.abandon(
        matchId: matchId,
        reason: 'surrender',
      );
      _lastVersion = match.version;
      _state = _state?.copyWith(match: match);
      _finalizeGame();
      _notify();
    } on UnoRepositoryException catch (e) {
      _lastError = e.message;
      _notify();
    }
  }

  Future<void> _claimTimeoutWin() async {
    final matchId = _matchId;
    if (matchId == null) return;
    try {
      final match = await _repository.abandon(
        matchId: matchId,
        reason: 'timeout',
      );
      _lastVersion = match.version;
      _state = _state?.copyWith(match: match);
      _finalizeGame();
      _notify();
    } on UnoRepositoryException catch (e) {
      debugPrint('UNO timeout claim failed: $e');
    }
  }

  Future<UnoStateSnapshot?> rematch() async {
    final matchId = _matchId;
    final userId = _currentUserId;
    final partnerId = _partnerId;
    final partnerName = _partnerName;
    if (matchId == null || userId == null) return null;
    try {
      final snapshot = await _repository.rematch(matchId);
      if (snapshot.match.status == UnoMatchStatus.inProgress) {
        await startOnlineGame(
          matchId: snapshot.match.id,
          currentUserId: userId,
          partnerId: partnerId,
          partnerName: partnerName,
          snapshot: snapshot,
        );
      } else {
        await disconnectSession();
        _matchId = snapshot.match.id;
        _currentUserId = userId;
        _partnerId = partnerId;
        _partnerName = partnerName;
        _isWaitingForOpponent = true;
        _inviteRejected = false;
        _inviteExpired = false;
        _historyRecorded = false;
        _movesCount = 0;
        _startedAt = DateTime.now();
        _lastVersion = snapshot.match.version;
        _state = UnoGameState(
          match: snapshot.match,
          myUserId: userId,
          myHand: const [],
        );
        await _connectToMatch(snapshot.match.id, userId);
        _notify();
      }
      return snapshot;
    } on UnoRepositoryException catch (e) {
      _lastError = e.message;
      _notify();
      return null;
    }
  }

  Future<void> leaveGame({bool confirmSurrender = false}) async {
    if (confirmSurrender && hasActiveGame) {
      await surrender();
    }

    final matchId = _matchId;
    final userId = _currentUserId;
    if (_isWaitingForOpponent && matchId != null && userId != null) {
      await _repository.cancelMatch(matchId, userId);
    }

    await disconnectSession();
    _notify();
  }

  Future<void> disconnectSession() async {
    await _cleanupConnections();
    _resetSession(notify: false);
  }

  Future<void> _playCardSound(UnoCard card) async {
    if (card.isBlock) {
      await _sound.play(UnoSfx.skip);
    } else if (card.isDraw) {
      await _sound.play(UnoSfx.draw);
    } else {
      await _sound.play(UnoSfx.play);
    }
    await HapticFeedback.selectionClick();
  }

  void _finalizeGame() {
    final state = _state;
    final matchId = _matchId;
    final userId = _currentUserId;
    if (state == null || matchId == null || userId == null) return;
    if (!state.isGameOver || _historyRecorded) return;

    _historyRecorded = true;
    _syncTimer?.cancel();
    _syncTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _cancelDisconnectTimer();

    final isWinner = state.winnerId == userId;
    if (isWinner) {
      unawaited(_sound.play(UnoSfx.win));
    }

    final duration = _startedAt != null
        ? DateTime.now().difference(_startedAt!).inSeconds
        : 60;

    unawaited(_repository.recordGameHistory(
      matchId: matchId,
      userId: userId,
      partnerId: _partnerId,
      isWinner: isWinner,
      durationSeconds: duration,
      totalMoves: _movesCount,
    ));
  }

  Future<void> _cleanupConnections() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _cancelDisconnectTimer();
    _reactionTimer?.cancel();
    await _matchSub?.cancel();
    _matchSub = null;
    await _realtimeSub?.cancel();
    _realtimeSub = null;
    await _presenceSub?.cancel();
    _presenceSub = null;
    await _realtime.disconnect();
  }

  void _resetSession({bool notify = true}) {
    _matchId = null;
    _currentUserId = null;
    _partnerId = null;
    _partnerName = null;
    _isWaitingForOpponent = false;
    _inviteRejected = false;
    _inviteExpired = false;
    _isPartnerOnline = false;
    _busy = false;
    _lastError = null;
    _lastVersion = null;
    _movesCount = 0;
    _startedAt = null;
    _historyRecorded = false;
    _incomingReaction = null;
    _queuedMatch = null;
    _state = null;
    if (notify) _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _reactionTimer?.cancel();
    _syncTimer?.cancel();
    _heartbeatTimer?.cancel();
    _disconnectTimer?.cancel();
    _matchSub?.cancel();
    _realtimeSub?.cancel();
    _presenceSub?.cancel();
    _realtime.dispose();
    super.dispose();
  }
}
