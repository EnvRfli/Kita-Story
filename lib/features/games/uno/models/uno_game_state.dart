import 'package:flutter/foundation.dart';

import 'uno_card.dart';
import 'uno_match_model.dart';

@immutable
class UnoGameState {
  final UnoMatchModel match;
  final String myUserId;
  final List<UnoCard> myHand;

  const UnoGameState({
    required this.match,
    required this.myUserId,
    this.myHand = const [],
  });

  String get opponentId => match.opponentOf(myUserId);

  int get myCardCount => myHand.length;

  int get opponentCardCount => match.cardCountFor(opponentId);

  bool get isHost => match.hostId == myUserId;

  bool get isOpponentHost => match.hostId == opponentId;

  bool get isGameOver =>
      match.status == UnoMatchStatus.completed ||
      match.status == UnoMatchStatus.abandoned ||
      match.phase == UnoPhase.gameOver;

  bool get isPaused => match.status == UnoMatchStatus.paused;

  bool get isWaitingForOpponent => match.status == UnoMatchStatus.invited;

  bool get isMyTurn =>
      !isGameOver &&
      !isPaused &&
      match.phase == UnoPhase.playing &&
      match.currentActorId == myUserId;

  bool get isDrawResponseForMe =>
      !isGameOver &&
      !isPaused &&
      match.phase == UnoPhase.drawResponse &&
      match.pendingDrawTarget == myUserId;

  bool get isMyAction => isMyTurn || isDrawResponseForMe;

  bool get isOpponentTurn =>
      !isGameOver &&
      !isPaused &&
      ((match.phase == UnoPhase.playing &&
              match.currentActorId == opponentId) ||
          (match.phase == UnoPhase.drawResponse &&
              match.pendingDrawTarget == opponentId));

  UnoColor? get currentColor => match.chosenColor;

  UnoCard? get lastTurnCard =>
      match.turnCards.isEmpty ? null : match.turnCards.last;

  UnoCard? get topCard => match.topCard;

  bool get pauseRequested => match.pauseRequestedBy != null;

  bool get resumeRequested => match.resumeRequestedBy != null;

  bool get isPauseRequestForMe =>
      match.pauseRequestedBy != null && match.pauseRequestedBy != myUserId;

  bool get isResumeRequestForMe =>
      match.resumeRequestedBy != null && match.resumeRequestedBy != myUserId;

  String? get winnerId => match.winnerId;

  bool get didIWin => winnerId == myUserId;

  UnoGameState copyWith({
    UnoMatchModel? match,
    String? myUserId,
    List<UnoCard>? myHand,
  }) {
    return UnoGameState(
      match: match ?? this.match,
      myUserId: myUserId ?? this.myUserId,
      myHand: myHand ?? this.myHand,
    );
  }

  static UnoGameState fromMatch({
    required UnoMatchModel match,
    required String myUserId,
    required List<UnoCard> myHand,
  }) {
    return UnoGameState(
      match: match,
      myUserId: myUserId,
      myHand: myHand,
    );
  }
}
