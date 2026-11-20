import '../models/uno_action.dart';
import '../models/uno_card.dart';
import '../models/uno_game_state.dart';
import '../models/uno_match_model.dart';

/// Pure Dart rules engine for UNO Express house rules.
///
/// The engine only knows the local player's hand and the public match state.
/// Opponent hands are resolved by the server and never needed here.
class UnoEngine {
  const UnoEngine();

  bool canPlayCard(UnoGameState state, UnoCard card) {
    if (state.isGameOver || state.isPaused) return false;
    if (!state.myHand.any((c) => c.id == card.id)) return false;

    if (state.match.phase == UnoPhase.drawResponse) {
      if (state.match.pendingDrawTarget != state.myUserId) return false;
      if (!card.isDraw) return false;
      if (!state.match.drawResponseStarted) {
        if (card.type == UnoCardType.drawTwo) return true;
        return card.type == UnoCardType.drawOne &&
            card.color == state.match.chosenColor;
      }
      return true;
    }

    if (state.match.phase != UnoPhase.playing) return false;
    if (state.match.currentActorId != state.myUserId) return false;

    final chain = state.match.turnCards;
    if (chain.isNotEmpty) {
      final last = chain.last;
      if (last.isNumber) {
        return card.isNumber && card.number == last.number;
      }
      if (last.isBlock) {
        // Skip/reverse may be chained with either symbol, but the color
        // must follow the last block card (e.g. red reverse -> red skip).
        return card.isBlock && card.color == last.color;
      }
      if (last.isDraw) return card.isDraw;
      return false;
    }

    return _matchesTop(state, card);
  }

  bool _matchesTop(UnoGameState state, UnoCard card) {
    final top = state.match.topCard;
    if (top == null) return true;

    if (card.type == UnoCardType.wild || card.type == UnoCardType.drawTwo) {
      return true;
    }

    final chosen = state.match.chosenColor;
    if (card.color != null && card.color == chosen) return true;

    switch (top.type) {
      case UnoCardType.number:
        return card.isNumber && card.number == top.number;
      case UnoCardType.skip:
      case UnoCardType.reverse:
        // Same-color blocks were already accepted above. A block of a
        // different color cannot cover a block.
        return false;
      case UnoCardType.drawOne:
      case UnoCardType.drawTwo:
        return card.isDraw;
      case UnoCardType.wild:
        return false;
    }
  }

  List<UnoCard> playableCards(UnoGameState state) {
    return state.myHand.where((card) => canPlayCard(state, card)).toList();
  }

  /// Plays a card. If [state] is in [UnoPhase.drawResponse], this becomes a
  /// draw-stack response and keeps the turn with the responder until they pass
  /// the penalty back.
  UnoGameState playCard(
    UnoGameState state,
    UnoCard card, {
    UnoColor? chosenColor,
  }) {
    if (!canPlayCard(state, card)) {
      throw StateError('Kartu tidak bisa dimainkan sekarang.');
    }
    if (state.match.phase == UnoPhase.drawResponse) {
      return _playDrawResponse(state, card, chosenColor: chosenColor);
    }
    if (card.type == UnoCardType.wild && chosenColor == null) {
      throw ArgumentError('Wild membutuhkan pilihan warna.');
    }

    final newHand = state.myHand.where((c) => c.id != card.id).toList();
    final now = DateTime.now();
    final action = UnoAction(
      id: UnoAction.newId(),
      type: 'play',
      actorId: state.myUserId,
      card: card,
      createdAt: now,
    );
    final color = card.color ?? chosenColor;

    var match = state.match.copyWith(
      topCard: card,
      chosenColor: color,
      discard: [...state.match.discard, card],
      turnCards: [...state.match.turnCards, card],
      pendingDraw:
          state.match.pendingDraw + (card.isDraw ? card.drawValue : 0),
      unoCalledBy: null,
      lastAction: action.toJson(),
      hostCardCount: state.isHost ? newHand.length : state.match.hostCardCount,
      guestCardCount: state.isHost ? state.match.guestCardCount : newHand.length,
    );

    if (newHand.isEmpty) {
      match = match.copyWith(
        status: UnoMatchStatus.completed,
        phase: UnoPhase.gameOver,
        currentActorId: state.myUserId,
        winnerId: state.myUserId,
        finishedAt: now,
      );
    }

    return state.copyWith(match: match, myHand: newHand);
  }

  UnoGameState _playDrawResponse(
    UnoGameState state,
    UnoCard card, {
    UnoColor? chosenColor,
  }) {
    if (card.type == UnoCardType.drawTwo && chosenColor == null) {
      throw ArgumentError('Wild +2 membutuhkan pilihan warna.');
    }

    final newHand = state.myHand.where((c) => c.id != card.id).toList();
    final now = DateTime.now();
    final action = UnoAction(
      id: UnoAction.newId(),
      type: 'draw_response',
      actorId: state.myUserId,
      card: card,
      drawCount: state.match.pendingDraw + card.drawValue,
      createdAt: now,
    );
    final color = card.color ?? chosenColor;

    var match = state.match.copyWith(
      topCard: card,
      chosenColor: color,
      discard: [...state.match.discard, card],
      turnCards: [...state.match.turnCards, card],
      pendingDraw: state.match.pendingDraw + card.drawValue,
      pendingDrawTarget: state.myUserId,
      drawResponseStarted: true,
      currentActorId: state.myUserId,
      unoCalledBy: null,
      lastAction: action.toJson(),
      hostCardCount: state.isHost ? newHand.length : state.match.hostCardCount,
      guestCardCount: state.isHost ? state.match.guestCardCount : newHand.length,
    );

    if (newHand.isEmpty) {
      match = match.copyWith(
        status: UnoMatchStatus.completed,
        phase: UnoPhase.gameOver,
        currentActorId: state.myUserId,
        winnerId: state.myUserId,
        finishedAt: now,
      );
    }

    return state.copyWith(match: match, myHand: newHand);
  }

  /// Ends the current chain. Draw chains open a response window for the
  /// opponent; any block chain (skip/reverse, one or many cards) grants only
  /// one extra turn.
  UnoGameState endTurn(UnoGameState state) {
    if (!state.isMyTurn) return state;
    if (state.match.turnCards.isEmpty) return state;

    final last = state.match.turnCards.last;
    final now = DateTime.now();

    if (last.isDraw) {
      final match = state.match.copyWith(
        phase: UnoPhase.drawResponse,
        currentActorId: state.opponentId,
        pendingDrawTarget: state.opponentId,
        drawResponseStarted: false,
        lastAction: UnoAction(
          id: UnoAction.newId(),
          type: 'draw_response_prompt',
          actorId: state.myUserId,
          targetId: state.opponentId,
          drawCount: state.match.pendingDraw,
          createdAt: now,
        ).toJson(),
      );
      return state.copyWith(match: match);
    }

    final action = UnoAction(
      id: UnoAction.newId(),
      type: 'end_turn',
      actorId: state.myUserId,
      drawCount: state.match.pendingDraw,
      createdAt: now,
    );
    return state.copyWith(
      match: _advanceTurn(
        state,
        addExtra: last.isBlock ? 1 : 0,
        action: action,
      ),
    );
  }

  UnoMatchModel _advanceTurn(
    UnoGameState state, {
    int addExtra = 0,
    required UnoAction action,
  }) {
    final extra = state.match.extraTurns + addExtra;
    if (extra > 0) {
      return state.match.copyWith(
        currentActorId: state.myUserId,
        extraTurns: extra - 1,
        turnCards: const [],
        pendingDraw: 0,
        pendingDrawTarget: null,
        drawResponseStarted: false,
        phase: UnoPhase.playing,
        lastAction: action.toJson(),
      );
    }
    return state.match.copyWith(
      currentActorId: state.opponentId,
      extraTurns: 0,
      turnCards: const [],
      pendingDraw: 0,
      pendingDrawTarget: null,
      drawResponseStarted: false,
      phase: UnoPhase.playing,
      lastAction: action.toJson(),
    );
  }

  /// Passes the accumulated draw penalty back to the opponent.
  UnoGameState passDrawResponse(UnoGameState state) {
    if (!state.isDrawResponseForMe) return state;
    if (!state.match.drawResponseStarted) return state;
    if (state.match.turnCards.isEmpty ||
        !state.match.turnCards.last.isDraw) {
      return state;
    }

    final match = state.match.copyWith(
      currentActorId: state.opponentId,
      pendingDrawTarget: state.opponentId,
      drawResponseStarted: false,
      lastAction: UnoAction(
        id: UnoAction.newId(),
        type: 'pass_draw',
        actorId: state.myUserId,
        targetId: state.opponentId,
        drawCount: state.match.pendingDraw,
        createdAt: DateTime.now(),
      ).toJson(),
    );
    return state.copyWith(match: match);
  }

  /// Public state patch after the target accepts the accumulated draw penalty.
  /// The provider performs the actual draw RPC and appends the drawn cards.
  UnoMatchModel matchAfterAcceptDraw(UnoGameState state) {
    return state.match.copyWith(
      phase: UnoPhase.playing,
      currentActorId: state.opponentId,
      pendingDraw: 0,
      pendingDrawTarget: null,
      drawResponseStarted: false,
      turnCards: const [],
      extraTurns: 0,
      lastAction: UnoAction(
        id: UnoAction.newId(),
        type: 'draw_penalty',
        actorId: state.myUserId,
        drawCount: state.match.pendingDraw,
        createdAt: DateTime.now(),
      ).toJson(),
    );
  }

  /// Public state patch after drawing one card because no card is playable.
  /// Extra turns are forfeited when the player cannot play.
  UnoMatchModel matchAfterDrawOne(UnoGameState state) {
    return state.match.copyWith(
      phase: UnoPhase.playing,
      currentActorId: state.opponentId,
      pendingDraw: 0,
      pendingDrawTarget: null,
      drawResponseStarted: false,
      turnCards: const [],
      extraTurns: 0,
      lastAction: UnoAction(
        id: UnoAction.newId(),
        type: 'draw',
        actorId: state.myUserId,
        createdAt: DateTime.now(),
      ).toJson(),
    );
  }

}
