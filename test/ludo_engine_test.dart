import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/ludo/engine/ludo_engine.dart';
import 'package:kita_story/features/games/ludo/models/ludo_game_state.dart';
import 'package:kita_story/features/games/ludo/models/ludo_player.dart';
import 'package:kita_story/features/games/ludo/models/ludo_token.dart';

void main() {
  group('LudoEngine', () {
    late LudoEngine engine;

    setUp(() {
      engine = LudoEngine();
    });

    test('initializes 2-player game with Green (p1) and Blue (p2)', () {
      final state = engine.createInitialState(
        mode: LudoGameMode.offline2,
        player1Name: 'Alya',
        player2Name: 'Reza',
      );

      expect(state.players.length, 2);
      expect(state.players[0].name, 'Alya');
      expect(state.players[0].color, LudoColor.green);
      expect(state.players[0].tokens.length, 4);
      expect(state.players[0].tokens.every((t) => t.isInYard), isTrue);

      expect(state.players[1].name, 'Reza');
      expect(state.players[1].color, LudoColor.blue);
      expect(state.currentTurnIndex, 0);
      expect(state.phase, LudoTurnPhase.waitingForRoll);
    });

    test('rolling 1..5 when all tokens are in yard yields no movable tokens and passes turn', () {
      final state = engine.createInitialState(
        mode: LudoGameMode.offline2,
        player1Name: 'P1',
        player2Name: 'P2',
      );

      final nextState = engine.handleDiceRoll(state, 3);
      expect(nextState.phase, LudoTurnPhase.waitingForRoll);
      // Turn automatically passed to player 2!
      expect(nextState.currentTurnIndex, 1);
      expect(nextState.movableTokenIds, isEmpty);
    });

    test('rolling 6 when tokens are in yard enables all yard tokens to move out', () {
      final state = engine.createInitialState(
        mode: LudoGameMode.offline2,
        player1Name: 'P1',
        player2Name: 'P2',
      );

      final nextState = engine.handleDiceRoll(state, 6);
      expect(nextState.phase, LudoTurnPhase.waitingForTokenMove);
      expect(nextState.movableTokenIds, [0, 1, 2, 3]);
      expect(nextState.currentTurnIndex, 0); // Still player 1's turn
    });

    test('moving token out of yard places it at step 0 and awards bonus roll', () {
      final state = engine.createInitialState(
        mode: LudoGameMode.offline2,
        player1Name: 'P1',
        player2Name: 'P2',
      );

      final rollState = engine.handleDiceRoll(state, 6);
      final moveResult = engine.executeMove(rollState, 0);

      expect(moveResult.movedToken.state, LudoTokenState.track);
      expect(moveResult.movedToken.step, 0);
      expect(moveResult.getsBonusRoll, isTrue);
      // Still player 1's turn because rolled 6!
      expect(moveResult.nextState.currentTurnIndex, 0);
      expect(moveResult.nextState.phase, LudoTurnPhase.waitingForRoll);
    });

    test('moving token on track advances step and passes turn on 1..5 without bonus', () {
      final p1 = LudoPlayer.initial(
        id: 'p1',
        name: 'P1',
        color: LudoColor.green,
      ).copyWith(
        tokens: [
          const LudoToken(id: 0, state: LudoTokenState.track, step: 0),
          const LudoToken(id: 1),
          const LudoToken(id: 2),
          const LudoToken(id: 3),
        ],
      );
      final p2 = LudoPlayer.initial(
        id: 'p2',
        name: 'P2',
        color: LudoColor.blue,
      );

      final state = LudoGameState(
        mode: LudoGameMode.offline2,
        players: [p1, p2],
        currentTurnIndex: 0,
        phase: LudoTurnPhase.waitingForRoll,
      );

      final rolled = engine.handleDiceRoll(state, 4);
      expect(rolled.movableTokenIds, [0]);

      final moveResult = engine.executeMove(rolled, 0);
      expect(moveResult.movedToken.step, 4);
      expect(moveResult.getsBonusRoll, isFalse);
      // Passed turn to P2
      expect(moveResult.nextState.currentTurnIndex, 1);
    });

    test('captures opponent token on non-safe square and sends it back to yard', () {
      // P1 (Green, start 13) token on relative step 10 -> global index (13+10) = 23 (non-safe)
      // P2 (Blue, start 39) token on relative step 36 -> global index (39+36)%52 = 23!
      // Let P1 be at relative step 7 -> global index 20.
      // P1 rolls 3 -> lands on step 10 (global index 23)!
      final p1 = LudoPlayer.initial(
        id: 'p1',
        name: 'P1',
        color: LudoColor.green,
      ).copyWith(
        tokens: [
          const LudoToken(id: 0, state: LudoTokenState.track, step: 7),
          const LudoToken(id: 1),
          const LudoToken(id: 2),
          const LudoToken(id: 3),
        ],
      );

      final p2 = LudoPlayer.initial(
        id: 'p2',
        name: 'P2',
        color: LudoColor.blue,
      ).copyWith(
        tokens: [
          const LudoToken(id: 0, state: LudoTokenState.track, step: 36),
          const LudoToken(id: 1),
          const LudoToken(id: 2),
          const LudoToken(id: 3),
        ],
      );

      final state = LudoGameState(
        mode: LudoGameMode.offline2,
        players: [p1, p2],
        currentTurnIndex: 0,
        phase: LudoTurnPhase.waitingForRoll,
      );

      final rolled = engine.handleDiceRoll(state, 3);
      final moveResult = engine.executeMove(rolled, 0);

      expect(moveResult.didCapture, isTrue);
      expect(moveResult.capturedToken?.id, 0);
      expect(moveResult.capturedColor, LudoColor.blue);
      expect(moveResult.getsBonusRoll, isTrue);

      // Verify opponent's token was sent back to yard
      final updatedP2 = moveResult.nextState.playerByColor(LudoColor.blue)!;
      expect(updatedP2.tokens[0].isInYard, isTrue);

      // P1 keeps turn because of capture bonus roll!
      expect(moveResult.nextState.currentTurnIndex, 0);
    });

    test('does NOT capture opponent token on safe star square', () {
      // Star index 21 is safe!
      // P1 (Green, start 13) at step 8 -> global index (13+8) = 21 (Star square).
      // P2 (Blue, start 39) at step 34 -> global index (39+34)%52 = 21 (Star square).
      final p1 = LudoPlayer.initial(
        id: 'p1',
        name: 'P1',
        color: LudoColor.green,
      ).copyWith(
        tokens: [
          const LudoToken(id: 0, state: LudoTokenState.track, step: 5),
          const LudoToken(id: 1),
          const LudoToken(id: 2),
          const LudoToken(id: 3),
        ],
      );

      final p2 = LudoPlayer.initial(
        id: 'p2',
        name: 'P2',
        color: LudoColor.blue,
      ).copyWith(
        tokens: [
          const LudoToken(id: 0, state: LudoTokenState.track, step: 34),
          const LudoToken(id: 1),
          const LudoToken(id: 2),
          const LudoToken(id: 3),
        ],
      );

      final state = LudoGameState(
        mode: LudoGameMode.offline2,
        players: [p1, p2],
        currentTurnIndex: 0,
        phase: LudoTurnPhase.waitingForRoll,
      );

      final rolled = engine.handleDiceRoll(state, 3); // step 5 + 3 = 8 (global 21)
      final moveResult = engine.executeMove(rolled, 0);

      expect(moveResult.didCapture, isFalse);
      final updatedP2 = moveResult.nextState.playerByColor(LudoColor.blue)!;
      expect(updatedP2.tokens[0].isOnTrack, isTrue); // Not sent to yard!
    });

    test('token enters home stretch and requires exact roll to reach home goal', () {
      // Token at step 50 (last outer track square).
      // Roll 1: lands on home stretch step 0.
      final p1 = LudoPlayer.initial(
        id: 'p1',
        name: 'P1',
        color: LudoColor.green,
      ).copyWith(
        tokens: [
          const LudoToken(id: 0, state: LudoTokenState.track, step: 50),
          const LudoToken(id: 1),
          const LudoToken(id: 2),
          const LudoToken(id: 3),
        ],
      );

      final state = LudoGameState(
        mode: LudoGameMode.offline2,
        players: [p1, LudoPlayer.initial(id: 'p2', name: 'P2', color: LudoColor.blue)],
        currentTurnIndex: 0,
        phase: LudoTurnPhase.waitingForRoll,
      );

      final rolled1 = engine.handleDiceRoll(state, 1);
      final movedToStretch = engine.executeMove(rolled1, 0);

      expect(movedToStretch.movedToken.state, LudoTokenState.homeStretch);
      expect(movedToStretch.movedToken.step, 0);

      // Now token is in home stretch at step 3. Needs exact 2 to reach 5.
      final inStretchPlayer = p1.copyWith(
        tokens: [
          const LudoToken(id: 0, state: LudoTokenState.homeStretch, step: 3),
          const LudoToken(id: 1),
          const LudoToken(id: 2),
          const LudoToken(id: 3),
        ],
      );

      final stretchState = state.copyWith(players: [
        inStretchPlayer,
        LudoPlayer.initial(id: 'p2', name: 'P2', color: LudoColor.blue)
      ]);

      // Roll 3 -> overshoots! (3 + 3 = 6 > 5)
      final overshootRoll = engine.handleDiceRoll(stretchState, 3);
      expect(overshootRoll.movableTokenIds, isEmpty);

      // Roll 2 -> exact! (3 + 2 = 5 -> reaches Home Goal)
      final exactRoll = engine.handleDiceRoll(stretchState, 2);
      expect(exactRoll.movableTokenIds, [0]);
      final homeMove = engine.executeMove(exactRoll, 0);
      expect(homeMove.movedToken.isHome, isTrue);
      expect(homeMove.didReachHome, isTrue);
      expect(homeMove.getsBonusRoll, isTrue);
    });

    test('declares winner when 4th token reaches home', () {
      final p1 = LudoPlayer.initial(
        id: 'p1',
        name: 'P1',
        color: LudoColor.green,
      ).copyWith(
        tokens: [
          const LudoToken(id: 0, state: LudoTokenState.home, step: 5),
          const LudoToken(id: 1, state: LudoTokenState.home, step: 5),
          const LudoToken(id: 2, state: LudoTokenState.home, step: 5),
          const LudoToken(id: 3, state: LudoTokenState.homeStretch, step: 4),
        ],
      );

      final state = LudoGameState(
        mode: LudoGameMode.offline2,
        players: [p1, LudoPlayer.initial(id: 'p2', name: 'P2', color: LudoColor.blue)],
        currentTurnIndex: 0,
        phase: LudoTurnPhase.waitingForRoll,
      );

      final rolled = engine.handleDiceRoll(state, 1);
      final moveResult = engine.executeMove(rolled, 3);

      expect(moveResult.nextState.isGameOver, isTrue);
      expect(moveResult.nextState.winnerColor, LudoColor.green);
      expect(moveResult.nextState.phase, LudoTurnPhase.gameOver);
    });

    test('three consecutive sixes skips turn', () {
      final p1 = LudoPlayer.initial(
        id: 'p1',
        name: 'P1',
        color: LudoColor.green,
      ).copyWith(consecutiveSixes: 2);

      final state = LudoGameState(
        mode: LudoGameMode.offline2,
        players: [p1, LudoPlayer.initial(id: 'p2', name: 'P2', color: LudoColor.blue)],
        currentTurnIndex: 0,
        phase: LudoTurnPhase.waitingForRoll,
      );

      // Third 6!
      final thirdSixState = engine.handleDiceRoll(state, 6);
      expect(thirdSixState.currentTurnIndex, 1); // Turn skipped to P2
      expect(thirdSixState.movableTokenIds, isEmpty);
      expect(thirdSixState.players[0].consecutiveSixes, 0); // Reset
    });
  });
}
