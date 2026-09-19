import 'package:flutter/foundation.dart';
import 'ludo_player.dart';

enum LudoGameMode {
  offline2,
  offline3,
  offline4,
  onlineCouple;

  String get displayName {
    switch (this) {
      case LudoGameMode.offline2:
        return 'Offline (2 Pemain)';
      case LudoGameMode.offline3:
        return 'Offline (3 Pemain)';
      case LudoGameMode.offline4:
        return 'Offline (4 Pemain)';
      case LudoGameMode.onlineCouple:
        return 'Online Bersama Pasangan';
    }
  }

  int get playerCount {
    switch (this) {
      case LudoGameMode.offline2:
      case LudoGameMode.onlineCouple:
        return 2;
      case LudoGameMode.offline3:
        return 3;
      case LudoGameMode.offline4:
        return 4;
    }
  }
}

enum LudoTurnPhase {
  waitingForRoll,
  waitingForTokenMove,
  animatingMove,
  turnEnded,
  gameOver,
}

@immutable
class LudoGameState {
  final LudoGameMode mode;
  final List<LudoPlayer> players;
  final int currentTurnIndex;
  final LudoTurnPhase phase;
  final int? diceValue;
  final bool isRolling;
  final List<int> movableTokenIds;
  final LudoColor? winnerColor;
  final bool bonusRollEarned;
  final String? statusMessage;

  const LudoGameState({
    required this.mode,
    required this.players,
    this.currentTurnIndex = 0,
    this.phase = LudoTurnPhase.waitingForRoll,
    this.diceValue,
    this.isRolling = false,
    this.movableTokenIds = const [],
    this.winnerColor,
    this.bonusRollEarned = false,
    this.statusMessage,
  });

  LudoPlayer get currentPlayer => players[currentTurnIndex];

  bool get isGameOver => phase == LudoTurnPhase.gameOver || winnerColor != null;

  LudoPlayer? get winner =>
      winnerColor != null ? playerByColor(winnerColor!) : null;

  LudoPlayer? playerByColor(LudoColor color) {
    for (final p in players) {
      if (p.color == color) return p;
    }
    return null;
  }

  LudoGameState copyWith({
    LudoGameMode? mode,
    List<LudoPlayer>? players,
    int? currentTurnIndex,
    LudoTurnPhase? phase,
    int? diceValue,
    bool? isRolling,
    List<int>? movableTokenIds,
    LudoColor? winnerColor,
    bool? bonusRollEarned,
    String? statusMessage,
    bool clearDice = false,
  }) {
    return LudoGameState(
      mode: mode ?? this.mode,
      players: players ?? this.players,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      phase: phase ?? this.phase,
      diceValue: clearDice ? null : (diceValue ?? this.diceValue),
      isRolling: isRolling ?? this.isRolling,
      movableTokenIds: movableTokenIds ?? this.movableTokenIds,
      winnerColor: winnerColor ?? this.winnerColor,
      bonusRollEarned: bonusRollEarned ?? this.bonusRollEarned,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'players': players.map((p) => p.toJson()).toList(),
        'current_turn_index': currentTurnIndex,
        'phase': phase.name,
        'dice_value': diceValue,
        'movable_token_ids': movableTokenIds,
        'winner_color': winnerColor?.name,
        'bonus_roll_earned': bonusRollEarned,
        'status_message': statusMessage,
      };

  factory LudoGameState.fromJson(Map<String, dynamic> json) {
    final mode = LudoGameMode.values.firstWhere(
      (e) => e.name == json['mode'],
      orElse: () => LudoGameMode.offline2,
    );
    final players = (json['players'] as List<dynamic>?)
            ?.map((p) => LudoPlayer.fromJson(p as Map<String, dynamic>))
            .toList() ??
        const [];
    final phase = LudoTurnPhase.values.firstWhere(
      (e) => e.name == json['phase'],
      orElse: () => LudoTurnPhase.waitingForRoll,
    );
    final winnerStr = json['winner_color'] as String?;
    final winnerColor = winnerStr != null
        ? LudoColor.values.firstWhere(
            (e) => e.name == winnerStr,
            orElse: () => LudoColor.green,
          )
        : null;

    return LudoGameState(
      mode: mode,
      players: players,
      currentTurnIndex: (json['current_turn_index'] as num?)?.toInt() ?? 0,
      phase: phase,
      diceValue: (json['dice_value'] as num?)?.toInt(),
      isRolling: false,
      movableTokenIds: (json['movable_token_ids'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      winnerColor: winnerColor,
      bonusRollEarned: (json['bonus_roll_earned'] as bool?) ?? false,
      statusMessage: json['status_message'] as String?,
    );
  }
}
