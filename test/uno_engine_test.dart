import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/uno/engine/uno_deck.dart';
import 'package:kita_story/features/games/uno/engine/uno_engine.dart';
import 'package:kita_story/features/games/uno/models/uno_card.dart';
import 'package:kita_story/features/games/uno/models/uno_game_state.dart';
import 'package:kita_story/features/games/uno/models/uno_match_model.dart';

void main() {
  const engine = UnoEngine();

  UnoCard number(String id, UnoColor color, int value) => UnoCard(
        id: id,
        color: color,
        type: UnoCardType.number,
        number: value,
      );

  UnoCard skip(String id, UnoColor color) => UnoCard(
        id: id,
        color: color,
        type: UnoCardType.skip,
      );

  UnoCard reverse(String id, UnoColor color) => UnoCard(
        id: id,
        color: color,
        type: UnoCardType.reverse,
      );

  UnoCard drawOne(String id, UnoColor color) => UnoCard(
        id: id,
        color: color,
        type: UnoCardType.drawOne,
      );

  UnoCard drawTwo(String id) => UnoCard(
        id: id,
        type: UnoCardType.drawTwo,
      );

  UnoCard wild(String id) => UnoCard(
        id: id,
        type: UnoCardType.wild,
      );

  UnoMatchModel match({
    UnoCard? topCard,
    UnoColor? chosenColor,
    String? currentActorId = 'me',
    int hostCardCount = 7,
    int guestCardCount = 7,
    List<UnoCard> turnCards = const [],
    UnoPhase phase = UnoPhase.playing,
    int pendingDraw = 0,
    String? pendingDrawTarget,
    bool drawResponseStarted = false,
    int extraTurns = 0,
    String? unoCalledBy,
    UnoMatchStatus status = UnoMatchStatus.inProgress,
    String? winnerId,
    DateTime? finishedAt,
  }) {
    return UnoMatchModel(
      id: 'match-1',
      hostId: 'me',
      guestId: 'opp',
      status: status,
      phase: phase,
      currentActorId: currentActorId,
      hostCardCount: hostCardCount,
      guestCardCount: guestCardCount,
      topCard: topCard,
      chosenColor: chosenColor,
      discard: topCard == null ? const [] : [topCard],
      turnCards: turnCards,
      pendingDraw: pendingDraw,
      pendingDrawTarget: pendingDrawTarget,
      drawResponseStarted: drawResponseStarted,
      extraTurns: extraTurns,
      unoCalledBy: unoCalledBy,
      winnerId: winnerId,
      finishedAt: finishedAt,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  UnoGameState state({
    required List<UnoCard> hand,
    UnoCard? topCard,
    UnoColor? chosenColor,
    String? currentActorId = 'me',
    List<UnoCard> turnCards = const [],
    UnoPhase phase = UnoPhase.playing,
    int pendingDraw = 0,
    String? pendingDrawTarget,
    bool drawResponseStarted = false,
    int extraTurns = 0,
    String? unoCalledBy,
    int hostCardCount = 7,
    int guestCardCount = 7,
  }) {
    return UnoGameState(
      match: match(
        topCard: topCard,
        chosenColor: chosenColor,
        currentActorId: currentActorId,
        turnCards: turnCards,
        phase: phase,
        pendingDraw: pendingDraw,
        pendingDrawTarget: pendingDrawTarget,
        drawResponseStarted: drawResponseStarted,
        extraTurns: extraTurns,
        unoCalledBy: unoCalledBy,
        hostCardCount: hostCardCount,
        guestCardCount: guestCardCount,
      ),
      myUserId: 'me',
      myHand: hand,
    );
  }

  group('UnoDeck', () {
    test('builds 116 unique cards with the agreed composition', () {
      final deck = UnoDeck.build();

      expect(deck.length, 116);
      expect(deck.map((c) => c.id).toSet().length, 116);
      expect(deck.where((c) => c.type == UnoCardType.wild).length, 4);
      expect(deck.where((c) => c.type == UnoCardType.drawTwo).length, 4);
      expect(deck.where((c) => c.type == UnoCardType.drawOne).length, 4);
      expect(deck.where((c) => c.type == UnoCardType.skip).length, 8);
      expect(deck.where((c) => c.type == UnoCardType.reverse).length, 8);
      expect(deck.where((c) => c.isNumber).length, 88);
    });
  });

  group('legal first play', () {
    test('matches color or number, rejects unrelated cards', () {
      final hand = [
        number('blue-4', UnoColor.blue, 4),
        number('green-4', UnoColor.green, 4),
        number('yellow-7', UnoColor.yellow, 7),
      ];
      final game = state(
        hand: hand,
        topCard: number('red-4', UnoColor.red, 4),
        chosenColor: UnoColor.red,
      );

      expect(engine.canPlayCard(game, hand[0]), isTrue);
      expect(engine.canPlayCard(game, hand[1]), isTrue);
      expect(engine.canPlayCard(game, hand[2]), isFalse);
    });

    test('rejects out-of-turn plays', () {
      final hand = [number('red-9', UnoColor.red, 9)];
      final game = state(
        hand: hand,
        topCard: number('red-4', UnoColor.red, 4),
        chosenColor: UnoColor.red,
        currentActorId: 'opp',
      );

      expect(engine.canPlayCard(game, hand[0]), isFalse);
    });
  });

  group('number chain', () {
    test('can chain same numbers across colors, final card sets color', () {
      final blue4 = number('blue-4', UnoColor.blue, 4);
      final green4 = number('green-4', UnoColor.green, 4);
      final yellow7 = number('yellow-7', UnoColor.yellow, 7);

      var game = state(
        hand: [blue4, green4, yellow7],
        topCard: number('red-4', UnoColor.red, 4),
        chosenColor: UnoColor.red,
      );

      game = engine.playCard(game, blue4);
      expect(game.match.turnCards.length, 1);
      expect(game.match.currentActorId, 'me');
      expect(engine.canPlayCard(game, green4), isTrue);

      game = engine.playCard(game, green4);
      expect(game.match.chosenColor, UnoColor.green);
      expect(engine.canPlayCard(game, yellow7), isFalse);

      game = engine.endTurn(game);
      expect(game.match.currentActorId, 'opp');
      expect(game.match.turnCards, isEmpty);
      expect(game.match.chosenColor, UnoColor.green);
    });

    test('cannot mix categories inside a chain', () {
      final red4 = number('red-4', UnoColor.red, 4);
      final blue4 = number('blue-4', UnoColor.blue, 4);
      final blueSkip = skip('blue-skip', UnoColor.blue);

      var game = state(
        hand: [red4, blue4, blueSkip],
        topCard: number('green-4', UnoColor.green, 4),
        chosenColor: UnoColor.green,
      );

      game = engine.playCard(game, red4);
      game = engine.playCard(game, blue4);
      expect(engine.canPlayCard(game, blueSkip), isFalse);
    });
  });

  group('block chain and extra turns', () {
    test('three block cards still grant only one extra turn', () {
      final redSkip = skip('red-skip', UnoColor.red);
      final redReverse = reverse('red-reverse', UnoColor.red);
      final redSkip2 = skip('red-skip-2', UnoColor.red);
      final red9 = number('red-9', UnoColor.red, 9);
      final red2 = number('red-2', UnoColor.red, 2);

      var game = state(
        hand: [redSkip, redReverse, redSkip2, red9, red2],
        topCard: number('red-4', UnoColor.red, 4),
        chosenColor: UnoColor.red,
      );

      game = engine.playCard(game, redSkip);
      game = engine.playCard(game, redReverse);
      game = engine.playCard(game, redSkip2);
      expect(game.match.turnCards.length, 3);

      game = engine.endTurn(game);
      expect(game.match.currentActorId, 'me');
      expect(game.match.extraTurns, 0);
      expect(game.match.chosenColor, UnoColor.red);

      // The single extra turn ends normally; no second bonus turn.
      game = engine.playCard(game, red9);
      game = engine.endTurn(game);
      expect(game.match.currentActorId, 'opp');
      expect(game.match.extraTurns, 0);
    });

    test('block chain requires the same color', () {
      final redSkip = skip('red-skip-color', UnoColor.red);
      final blueReverse = reverse('blue-reverse-color', UnoColor.blue);
      final redReverse = reverse('red-reverse-color', UnoColor.red);

      var game = state(
        hand: [redSkip, blueReverse, redReverse],
        topCard: number('red-4', UnoColor.red, 4),
        chosenColor: UnoColor.red,
      );

      game = engine.playCard(game, redSkip);
      expect(engine.canPlayCard(game, blueReverse), isFalse);
      expect(engine.canPlayCard(game, redReverse), isTrue);
    });
  });

  group('draw stack', () {
    test('self-chains draw cards and opens a response window', () {
      final redOne = drawOne('red-one', UnoColor.red);
      final wildTwo = drawTwo('wild-two');
      final blueSeven = number('blue-7', UnoColor.blue, 7);

      var game = state(
        hand: [redOne, wildTwo, blueSeven],
        topCard: number('red-4', UnoColor.red, 4),
        chosenColor: UnoColor.red,
      );

      game = engine.playCard(game, redOne);
      expect(game.match.pendingDraw, 1);
      expect(game.match.phase, UnoPhase.playing);
      expect(engine.canPlayCard(game, wildTwo), isTrue);

      game = engine.playCard(game, wildTwo, chosenColor: UnoColor.blue);
      expect(game.match.pendingDraw, 3);
      expect(game.match.chosenColor, UnoColor.blue);

      game = engine.endTurn(game);
      expect(game.match.phase, UnoPhase.drawResponse);
      expect(game.match.pendingDrawTarget, 'opp');
      expect(game.match.pendingDraw, 3);
      expect(game.match.drawResponseStarted, isFalse);
    });

    test('first response must be +1 of chosen color or any +2', () {
      final blueOne = drawOne('blue-one', UnoColor.blue);
      final redOne = drawOne('red-one', UnoColor.red);
      final wildTwo = drawTwo('wild-two');
      final blueSkip = skip('blue-skip-draw', UnoColor.blue);
      final blueReverse = reverse('blue-reverse-draw', UnoColor.blue);

      final game = UnoGameState(
        match: match(
          topCard: drawOne('top-one', UnoColor.blue),
          chosenColor: UnoColor.blue,
          currentActorId: 'opp',
          phase: UnoPhase.drawResponse,
          pendingDraw: 3,
          pendingDrawTarget: 'opp',
          drawResponseStarted: false,
          turnCards: [drawOne('top-one', UnoColor.blue)],
        ),
        myUserId: 'opp',
        myHand: [blueOne, redOne, wildTwo, blueSkip, blueReverse],
      );

      expect(engine.canPlayCard(game, blueOne), isTrue);
      expect(engine.canPlayCard(game, redOne), isFalse);
      expect(engine.canPlayCard(game, wildTwo), isTrue);
      // Blocks/reverse cannot answer a draw penalty, even with the same color.
      expect(engine.canPlayCard(game, blueSkip), isFalse);
      expect(engine.canPlayCard(game, blueReverse), isFalse);
    });

    test('response can self-chain, then pass the accumulated penalty', () {
      final blueOne = drawOne('blue-one', UnoColor.blue);
      final wildTwo = drawTwo('wild-two');
      final blueSeven = number('blue-7', UnoColor.blue, 7);

      final game = UnoGameState(
        match: match(
          topCard: drawOne('top-one', UnoColor.blue),
          chosenColor: UnoColor.blue,
          currentActorId: 'opp',
          phase: UnoPhase.drawResponse,
          pendingDraw: 3,
          pendingDrawTarget: 'opp',
          drawResponseStarted: false,
          turnCards: [drawOne('top-one', UnoColor.blue)],
        ),
        myUserId: 'opp',
        myHand: [blueOne, wildTwo, blueSeven],
      );

      var next = engine.playCard(game, blueOne);
      expect(next.match.pendingDraw, 4);
      expect(next.match.pendingDrawTarget, 'opp');
      expect(next.match.drawResponseStarted, isTrue);
      expect(engine.canPlayCard(next, wildTwo), isTrue);

      next = engine.playCard(next, wildTwo, chosenColor: UnoColor.green);
      expect(next.match.pendingDraw, 6);
      expect(next.match.pendingDrawTarget, 'opp');

      next = engine.passDrawResponse(next);
      expect(next.match.pendingDrawTarget, 'me');
      expect(next.match.currentActorId, 'me');
      expect(next.match.drawResponseStarted, isFalse);
      expect(next.match.pendingDraw, 6);
    });

    test('accepting the penalty clears the stack and passes turn to last draw player', () {
      final game = UnoGameState(
        match: match(
          topCard: drawOne('top-one', UnoColor.blue),
          chosenColor: UnoColor.blue,
          currentActorId: 'me',
          phase: UnoPhase.drawResponse,
          pendingDraw: 6,
          pendingDrawTarget: 'me',
          drawResponseStarted: false,
          turnCards: [drawOne('top-one', UnoColor.blue)],
        ),
        myUserId: 'me',
        myHand: [number('blue-7-penalty', UnoColor.blue, 7)],
      );

      final patch = engine.matchAfterAcceptDraw(game);
      expect(patch.phase, UnoPhase.playing);
      expect(patch.currentActorId, 'opp');
      expect(patch.pendingDraw, 0);
      expect(patch.pendingDrawTarget, isNull);
      expect(patch.turnCards, isEmpty);
      expect(patch.lastAction?['type'], 'draw_penalty');
    });
  });

  group('wild and drawing', () {
    test('wild requires a chosen color and ends the chain', () {
      final wildCard = wild('wild-1');
      final redFive = number('red-5', UnoColor.red, 5);
      final game = state(
        hand: [wildCard, redFive],
        topCard: number('red-4', UnoColor.red, 4),
        chosenColor: UnoColor.red,
      );

      expect(engine.canPlayCard(game, wildCard), isTrue);
      expect(
        () => engine.playCard(game, wildCard),
        throwsArgumentError,
      );

      var next = engine.playCard(game, wildCard, chosenColor: UnoColor.red);
      expect(next.match.chosenColor, UnoColor.red);
      expect(engine.canPlayCard(next, redFive), isFalse);

      next = engine.endTurn(next);
      expect(next.match.currentActorId, 'opp');
    });

    test('drawing one card ends the turn and forfeits extra turns', () {
      final game = state(
        hand: [number('blue-7', UnoColor.blue, 7)],
        topCard: number('red-4', UnoColor.red, 4),
        chosenColor: UnoColor.red,
        extraTurns: 2,
      );

      final patch = engine.matchAfterDrawOne(game);
      expect(patch.currentActorId, 'opp');
      expect(patch.extraTurns, 0);
      expect(patch.phase, UnoPhase.playing);
      expect(patch.lastAction?['type'], 'draw');
    });
  });

  group('win and UNO', () {
    test('emptying the hand ends the game immediately', () {
      final redFive = number('red-5', UnoColor.red, 5);
      final game = state(
        hand: [redFive],
        topCard: number('red-4', UnoColor.red, 4),
        chosenColor: UnoColor.red,
      );

      final next = engine.playCard(game, redFive);
      expect(next.myHand, isEmpty);
      expect(next.match.status, UnoMatchStatus.completed);
      expect(next.match.phase, UnoPhase.gameOver);
      expect(next.match.winnerId, 'me');
      expect(next.match.finishedAt, isNotNull);
    });

    test('playing from two cards leaves exactly one card', () {
      final redFive = number('red-5', UnoColor.red, 5);
      final blueSeven = number('blue-7', UnoColor.blue, 7);
      final game = state(
        hand: [redFive, blueSeven],
        topCard: number('red-4', UnoColor.red, 4),
        chosenColor: UnoColor.red,
      );

      final next = engine.playCard(game, redFive);
      expect(next.myCardCount, 1);
      expect(next.match.status, UnoMatchStatus.inProgress);
    });
  });
}
