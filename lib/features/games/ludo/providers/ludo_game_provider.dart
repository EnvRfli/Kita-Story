import 'dart:async';
import 'package:flutter/foundation.dart';
import '../engine/ludo_engine.dart';
import '../models/ludo_game_state.dart';
import '../models/ludo_player.dart';
import '../repositories/ludo_repository.dart';
import '../services/ludo_local_storage.dart';
import '../services/ludo_realtime_service.dart';

class LudoGameProvider extends ChangeNotifier {
  final LudoEngine _engine;
  final LudoLocalStorage _storage;
  final LudoRepository _repository;
  final LudoRealtimeService _realtime;

  LudoGameState _state;
  String? _matchId;
  String? _currentUserId;
  String? _partnerId;
  LudoColor? _myColor;
  DateTime? _startedAt;
  int _movesCount = 0;
  bool _isRollingAnimation = false;
  String? _incomingReaction;
  Timer? _reactionTimer;
  StreamSubscription? _realtimeSub;

  LudoGameProvider({
    LudoEngine? engine,
    LudoLocalStorage? storage,
    LudoRepository? repository,
    LudoRealtimeService? realtime,
  })  : _engine = engine ?? LudoEngine(),
        _storage = storage ?? LudoLocalStorage(),
        _repository = repository ?? LudoRepository(),
        _realtime = realtime ?? LudoRealtimeService(),
        _state = const LudoGameState(
          mode: LudoGameMode.offline2,
          players: [],
        );

  LudoGameState get state => _state;
  String? get matchId => _matchId;
  String? get currentUserId => _currentUserId;
  LudoColor? get myColor => _myColor;
  bool get isOnline => _state.mode == LudoGameMode.onlineCouple;
  bool get isRollingAnimation => _isRollingAnimation;
  String? get incomingReaction => _incomingReaction;
  int get movesCount => _movesCount;

  bool get isMyTurn {
    if (!isOnline || _myColor == null) return true;
    return _state.currentPlayer.color == _myColor;
  }

  bool canRoll() {
    if (_state.isGameOver || _isRollingAnimation) return false;
    if (_state.phase != LudoTurnPhase.waitingForRoll) return false;
    return isMyTurn;
  }

  bool canSelectToken(int tokenId) {
    if (_state.isGameOver || _isRollingAnimation) return false;
    if (_state.phase != LudoTurnPhase.waitingForTokenMove) return false;
    if (!isMyTurn) return false;
    return _state.movableTokenIds.contains(tokenId);
  }

  /// Initialize Offline Game
  Future<void> startOfflineGame({
    required LudoGameMode mode,
    required String player1Name,
    String? player1Avatar,
    String? player2Name,
    String? player2Avatar,
    String? player3Name,
    String? player4Name,
  }) async {
    _matchId = null;
    _currentUserId = null;
    _partnerId = null;
    _myColor = null;
    _movesCount = 0;
    _startedAt = DateTime.now();

    _state = _engine.createInitialState(
      mode: mode,
      player1Name: player1Name,
      player1Avatar: player1Avatar,
      player2Name: player2Name,
      player2Avatar: player2Avatar,
      player3Name: player3Name,
      player4Name: player4Name,
    );

    await _storage.saveActiveGame(_state);
    notifyListeners();
  }

  /// Initialize Online Game
  Future<void> startOnlineGame({
    required String matchId,
    required String currentUserId,
    required String? partnerId,
    required LudoColor myColor,
    required LudoGameState initialState,
  }) async {
    _matchId = matchId;
    _currentUserId = currentUserId;
    _partnerId = partnerId;
    _myColor = myColor;
    _movesCount = 0;
    _startedAt = DateTime.now();
    _state = initialState;

    // Connect to Realtime room channel
    await _realtimeSub?.cancel();
    await _realtime.connect(matchId);
    _realtimeSub = _realtime.onEvent.listen(_handleRealtimeEvent);

    notifyListeners();
  }

  void _handleRealtimeEvent(LudoRealtimeEvent event) {
    switch (event.event) {
      case 'dice_rolled':
        final val = (event.payload['diceValue'] as num?)?.toInt();
        if (val != null) {
          _applyDiceRoll(val, broadcast: false);
        }
        break;

      case 'token_moved':
        final tokenId = (event.payload['tokenId'] as num?)?.toInt();
        if (tokenId != null) {
          _applyTokenMove(tokenId, broadcast: false);
        }
        break;

      case 'sync_state':
        final stateMap = event.payload['state'] as Map<String, dynamic>?;
        if (stateMap != null) {
          _state = LudoGameState.fromJson(stateMap);
          notifyListeners();
        }
        break;

      case 'reaction':
        final emoji = event.payload['emoji'] as String?;
        if (emoji != null) {
          _incomingReaction = emoji;
          _reactionTimer?.cancel();
          _reactionTimer = Timer(const Duration(seconds: 3), () {
            _incomingReaction = null;
            notifyListeners();
          });
          notifyListeners();
        }
        break;

      case 'surrender':
        final leavingId = event.payload['playerId'] as String?;
        if (leavingId != null && leavingId != _currentUserId) {
          // Opponent surrendered -> I win!
          _state = _state.copyWith(
            phase: LudoTurnPhase.gameOver,
            winnerColor: _myColor,
            statusMessage: 'Pasangan menyerah. Kamu menang!',
          );
          _finalizeGame();
          notifyListeners();
        }
        break;
    }
  }

  /// Action: Roll the dice
  Future<void> rollDice() async {
    if (!canRoll()) return;

    _isRollingAnimation = true;
    notifyListeners();

    // Small dice shake delay for playful feedback
    await Future.delayed(const Duration(milliseconds: 400));
    final diceVal = _engine.rollDice();
    _isRollingAnimation = false;

    await _applyDiceRoll(diceVal, broadcast: isOnline);
  }

  Future<void> _applyDiceRoll(int diceVal, {required bool broadcast}) async {
    if (broadcast && _matchId != null && _currentUserId != null) {
      await _realtime.broadcastDiceRoll(
        diceValue: diceVal,
        playerId: _currentUserId!,
      );
    }

    _state = _engine.handleDiceRoll(_state, diceVal);
    _movesCount++;

    // If offline, save active game
    if (!isOnline) {
      await _storage.saveActiveGame(_state);
    } else if (_matchId != null) {
      await _repository.updateMatchState(
        matchId: _matchId!,
        state: _state,
        currentTurnColor: _state.currentPlayer.color,
      );
    }

    notifyListeners();

    // If game has only 1 movable token and it can move, or if turn auto passed
    if (_state.phase == LudoTurnPhase.waitingForTokenMove &&
        _state.movableTokenIds.length == 1 &&
        isMyTurn) {
      // Auto move single token for smooth experience
      await Future.delayed(const Duration(milliseconds: 300));
      await selectToken(_state.movableTokenIds.first);
    }
  }

  /// Action: Select a token to move
  Future<void> selectToken(int tokenId) async {
    if (!canSelectToken(tokenId)) return;

    await _applyTokenMove(tokenId, broadcast: isOnline);
  }

  Future<void> _applyTokenMove(int tokenId, {required bool broadcast}) async {
    if (broadcast && _matchId != null && _currentUserId != null) {
      await _realtime.broadcastTokenMove(
        tokenId: tokenId,
        playerId: _currentUserId!,
      );
    }

    final moveResult = _engine.executeMove(_state, tokenId);
    _state = moveResult.nextState;

    if (_state.isGameOver) {
      await _finalizeGame();
    } else {
      if (!isOnline) {
        await _storage.saveActiveGame(_state);
      } else if (_matchId != null) {
        await _repository.updateMatchState(
          matchId: _matchId!,
          state: _state,
          currentTurnColor: _state.currentPlayer.color,
        );
      }
    }

    notifyListeners();
  }

  Future<void> _finalizeGame() async {
    if (!isOnline) {
      await _storage.clearActiveGame();
      if (_state.winnerColor != null) {
        await _storage.incrementWinCount();
      }
    } else if (_matchId != null && _currentUserId != null) {
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
      }
    }
  }

  /// Send reaction emoji
  void sendReaction(String emoji) {
    if (!isOnline || _currentUserId == null) return;
    _realtime.broadcastReaction(
      emoji: emoji,
      senderId: _currentUserId!,
    );
  }

  /// Surrender match
  Future<void> surrender() async {
    if (isOnline && _currentUserId != null) {
      await _realtime.broadcastReaction(
        emoji: '🏳️',
        senderId: _currentUserId!,
      );
    }
    _state = _state.copyWith(
      phase: LudoTurnPhase.gameOver,
      statusMessage: 'Permainan telah diakhiri.',
    );
    if (!isOnline) {
      await _storage.clearActiveGame();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _reactionTimer?.cancel();
    _realtimeSub?.cancel();
    _realtime.disconnect();
    super.dispose();
  }
}
