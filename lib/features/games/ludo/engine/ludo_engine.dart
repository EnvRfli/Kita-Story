import 'dart:math';
import '../models/ludo_game_state.dart';
import '../models/ludo_player.dart';
import '../models/ludo_token.dart';
import 'ludo_board_path.dart';

class LudoMoveResult {
  final LudoGameState nextState;
  final LudoToken movedToken;
  final bool didCapture;
  final LudoToken? capturedToken;
  final LudoColor? capturedColor;
  final bool didReachHome;
  final bool getsBonusRoll;

  const LudoMoveResult({
    required this.nextState,
    required this.movedToken,
    this.didCapture = false,
    this.capturedToken,
    this.capturedColor,
    this.didReachHome = false,
    this.getsBonusRoll = false,
  });
}

class LudoEngine {
  final Random _random;

  LudoEngine({Random? random}) : _random = random ?? Random();

  /// Roll the dice (1..6)
  int rollDice() {
    return _random.nextInt(6) + 1;
  }

  /// Initial game setup for given mode
  LudoGameState createInitialState({
    required LudoGameMode mode,
    required String player1Name,
    String? player1Avatar,
    String? player2Name,
    String? player2Avatar,
    String? player3Name,
    String? player4Name,
  }) {
    final List<LudoPlayer> players;

    switch (mode) {
      case LudoGameMode.offline2:
      case LudoGameMode.onlineCouple:
        // 2 players: Green (Top) vs Blue (Bottom) as in the screenshot
        players = [
          LudoPlayer.initial(
            id: 'p1',
            name: player1Name,
            color: LudoColor.green,
            avatarUrl: player1Avatar,
            isHost: true,
          ),
          LudoPlayer.initial(
            id: 'p2',
            name: player2Name ?? 'Pemain 2',
            color: LudoColor.blue,
            avatarUrl: player2Avatar,
            isHost: false,
          ),
        ];
        break;

      case LudoGameMode.offline3:
        players = [
          LudoPlayer.initial(
            id: 'p1',
            name: player1Name,
            color: LudoColor.red,
            avatarUrl: player1Avatar,
            isHost: true,
          ),
          LudoPlayer.initial(
            id: 'p2',
            name: player2Name ?? 'Pemain 2',
            color: LudoColor.green,
          ),
          LudoPlayer.initial(
            id: 'p3',
            name: player3Name ?? 'Pemain 3',
            color: LudoColor.yellow,
          ),
        ];
        break;

      case LudoGameMode.offline4:
        players = [
          LudoPlayer.initial(
            id: 'p1',
            name: player1Name,
            color: LudoColor.red,
            avatarUrl: player1Avatar,
            isHost: true,
          ),
          LudoPlayer.initial(
            id: 'p2',
            name: player2Name ?? 'Pemain 2',
            color: LudoColor.green,
          ),
          LudoPlayer.initial(
            id: 'p3',
            name: player3Name ?? 'Pemain 3',
            color: LudoColor.blue,
          ),
          LudoPlayer.initial(
            id: 'p4',
            name: player4Name ?? 'Pemain 4',
            color: LudoColor.yellow,
          ),
        ];
        break;
    }

    return LudoGameState(
      mode: mode,
      players: players,
      currentTurnIndex: 0,
      phase: LudoTurnPhase.waitingForRoll,
      statusMessage: 'Giliran ${players.first.name} untuk melempar dadu',
    );
  }

  /// Check if a single token can make a legal move with the rolled dice
  bool canTokenMove(LudoToken token, int diceRoll) {
    if (token.isHome) return false;

    if (token.isInYard) {
      return diceRoll == 6;
    }

    if (token.isOnTrack) {
      final newStep = token.step + diceRoll;
      if (newStep <= 50) return true;
      // Moving into home stretch
      final homeStretchIndex = newStep - 51;
      return homeStretchIndex <= 5; // 0..4 = stretch, 5 = reached home
    }

    if (token.isInHomeStretch) {
      final newStretch = token.step + diceRoll;
      return newStretch <= 5; // 0..4 = stretch, 5 = reached home
    }

    return false;
  }

  /// Get all token IDs that can move for the active player with diceRoll
  List<int> getMovableTokenIds(LudoPlayer player, int diceRoll) {
    final movable = <int>[];
    for (final token in player.tokens) {
      if (canTokenMove(token, diceRoll)) {
        movable.add(token.id);
      }
    }
    return movable;
  }

  /// Process a dice roll for current turn
  LudoGameState handleDiceRoll(LudoGameState state, int diceRoll) {
    if (state.phase != LudoTurnPhase.waitingForRoll) return state;

    final currentPlayer = state.currentPlayer;
    final newConsecutiveSixes =
        diceRoll == 6 ? currentPlayer.consecutiveSixes + 1 : 0;

    // Rule: 3 consecutive sixes penalty - turn skips immediately!
    if (newConsecutiveSixes >= 3) {
      final updatedPlayer = currentPlayer.copyWith(consecutiveSixes: 0);
      final updatedPlayers = List<LudoPlayer>.from(state.players);
      updatedPlayers[state.currentTurnIndex] = updatedPlayer;

      final nextTurnIndex = (state.currentTurnIndex + 1) % state.players.length;
      final nextPlayer = updatedPlayers[nextTurnIndex];

      return state.copyWith(
        players: updatedPlayers,
        diceValue: diceRoll,
        currentTurnIndex: nextTurnIndex,
        phase: LudoTurnPhase.waitingForRoll,
        clearDice: true,
        movableTokenIds: const [],
        statusMessage:
            '3 kali berturut-turut dadu 6! Giliran berpindah ke ${nextPlayer.name}',
      );
    }

    final movableIds = getMovableTokenIds(currentPlayer, diceRoll);

    // If no moves are possible, turn passes to next player
    if (movableIds.isEmpty) {
      final updatedPlayer =
          currentPlayer.copyWith(consecutiveSixes: newConsecutiveSixes);
      final updatedPlayers = List<LudoPlayer>.from(state.players);
      updatedPlayers[state.currentTurnIndex] = updatedPlayer;

      final nextTurnIndex = (state.currentTurnIndex + 1) % state.players.length;
      final nextPlayer = updatedPlayers[nextTurnIndex];

      return state.copyWith(
        players: updatedPlayers,
        diceValue: diceRoll,
        currentTurnIndex: nextTurnIndex,
        phase: LudoTurnPhase.waitingForRoll,
        movableTokenIds: const [],
        statusMessage:
            '${currentPlayer.name} tidak memiliki langkah. Giliran ${nextPlayer.name}',
      );
    }

    final updatedPlayer =
        currentPlayer.copyWith(consecutiveSixes: newConsecutiveSixes);
    final updatedPlayers = List<LudoPlayer>.from(state.players);
    updatedPlayers[state.currentTurnIndex] = updatedPlayer;

    return state.copyWith(
      players: updatedPlayers,
      diceValue: diceRoll,
      phase: LudoTurnPhase.waitingForTokenMove,
      movableTokenIds: movableIds,
      statusMessage: movableIds.length == 1
          ? '${currentPlayer.name} melempar $diceRoll'
          : '${currentPlayer.name} melempar $diceRoll. Pilih pion untuk digerakkan',
    );
  }

  /// Execute movement of a specific token
  LudoMoveResult executeMove(LudoGameState state, int tokenId) {
    if (state.phase != LudoTurnPhase.waitingForTokenMove) {
      throw StateError('Cannot move token when not in waitingForTokenMove phase');
    }

    final diceRoll = state.diceValue;
    if (diceRoll == null) {
      throw StateError('Cannot move token without dice value');
    }

    final currentPlayer = state.currentPlayer;
    final token = currentPlayer.tokens.firstWhere((t) => t.id == tokenId);

    if (!canTokenMove(token, diceRoll)) {
      throw ArgumentError('Token $tokenId cannot legally move with roll $diceRoll');
    }

    // 1. Calculate new token state
    LudoToken updatedToken;
    bool reachedHome = false;

    if (token.isInYard) {
      // Moves out of yard to start tile (step 0)
      updatedToken = token.copyWith(
        state: LudoTokenState.track,
        step: 0,
      );
    } else if (token.isOnTrack) {
      final newStep = token.step + diceRoll;
      if (newStep <= 50) {
        updatedToken = token.copyWith(step: newStep);
      } else {
        final remaining = newStep - 51;
        if (remaining == 5) {
          reachedHome = true;
          updatedToken = token.copyWith(
            state: LudoTokenState.home,
            step: 5,
          );
        } else {
          updatedToken = token.copyWith(
            state: LudoTokenState.homeStretch,
            step: remaining,
          );
        }
      }
    } else if (token.isInHomeStretch) {
      final newStretch = token.step + diceRoll;
      if (newStretch == 5) {
        reachedHome = true;
        updatedToken = token.copyWith(
          state: LudoTokenState.home,
          step: 5,
        );
      } else {
        updatedToken = token.copyWith(step: newStretch);
      }
    } else {
      updatedToken = token;
    }

    // 2. Check for captures on opponents
    bool didCapture = false;
    LudoToken? capturedToken;
    LudoColor? capturedColor;
    final updatedPlayers = List<LudoPlayer>.from(state.players);

    if (updatedToken.isOnTrack) {
      final landingGlobalIndex = LudoBoardPath.relativeStepToGlobalIndex(
        currentPlayer.color,
        updatedToken.step,
      );

      final isSafeZone = LudoBoardPath.isSafeGlobalIndex(landingGlobalIndex);

      if (!isSafeZone) {
        for (var i = 0; i < updatedPlayers.length; i++) {
          if (i == state.currentTurnIndex) continue;
          final opponent = updatedPlayers[i];
          final opponentTokens = List<LudoToken>.from(opponent.tokens);
          var opponentModified = false;

          for (var t = 0; t < opponentTokens.length; t++) {
            final opToken = opponentTokens[t];
            if (opToken.isOnTrack) {
              final opGlobalIndex = LudoBoardPath.relativeStepToGlobalIndex(
                opponent.color,
                opToken.step,
              );
              if (opGlobalIndex == landingGlobalIndex) {
                // CAPTURE!
                didCapture = true;
                capturedToken = opToken;
                capturedColor = opponent.color;
                opponentTokens[t] = opToken.copyWith(
                  state: LudoTokenState.yard,
                  step: 0,
                );
                opponentModified = true;
              }
            }
          }

          if (opponentModified) {
            updatedPlayers[i] = opponent.copyWith(tokens: opponentTokens);
          }
        }
      }
    }

    // 3. Update current player's token list
    final currentPlayerTokens = List<LudoToken>.from(currentPlayer.tokens);
    final tokenIndex = currentPlayerTokens.indexWhere((t) => t.id == tokenId);
    currentPlayerTokens[tokenIndex] = updatedToken;

    final updatedCurrentPlayer =
        currentPlayer.copyWith(tokens: currentPlayerTokens);
    updatedPlayers[state.currentTurnIndex] = updatedCurrentPlayer;

    // 4. Check for game win
    final hasWon = updatedCurrentPlayer.isWinner;
    final getsBonusRoll = !hasWon && (diceRoll == 6 || didCapture || reachedHome);

    final int nextTurnIndex = getsBonusRoll || hasWon
        ? state.currentTurnIndex
        : (state.currentTurnIndex + 1) % updatedPlayers.length;

    String statusMsg;
    if (hasWon) {
      statusMsg = '🎉 Selamat! ${updatedCurrentPlayer.name} memenangkan permainan Ludo!';
    } else if (didCapture) {
      statusMsg =
          '💥 ${updatedCurrentPlayer.name} memakan pion lawan! Dapat lemparan bonus!';
    } else if (reachedHome) {
      statusMsg =
          '🌟 Pion ${updatedCurrentPlayer.name} masuk rumah! Dapat lemparan bonus!';
    } else if (diceRoll == 6) {
      statusMsg = '🎲 Dadu 6! ${updatedCurrentPlayer.name} melempar lagi!';
    } else {
      final nextPlayer = updatedPlayers[nextTurnIndex];
      statusMsg = 'Giliran ${nextPlayer.name} untuk melempar dadu';
    }

    final nextState = state.copyWith(
      players: updatedPlayers,
      currentTurnIndex: nextTurnIndex,
      phase: hasWon ? LudoTurnPhase.gameOver : LudoTurnPhase.waitingForRoll,
      winnerColor: hasWon ? updatedCurrentPlayer.color : null,
      movableTokenIds: const [],
      bonusRollEarned: getsBonusRoll,
      statusMessage: statusMsg,
      clearDice: !getsBonusRoll,
    );

    return LudoMoveResult(
      nextState: nextState,
      movedToken: updatedToken,
      didCapture: didCapture,
      capturedToken: capturedToken,
      capturedColor: capturedColor,
      didReachHome: reachedHome,
      getsBonusRoll: getsBonusRoll,
    );
  }
}
