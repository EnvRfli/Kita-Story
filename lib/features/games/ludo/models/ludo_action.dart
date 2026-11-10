import 'dart:math';
import 'ludo_player.dart';
import 'ludo_token.dart';

class LudoCapturedToken {
  final LudoColor color;
  final int tokenId;
  final LudoTokenState fromState;
  final int fromStep;

  const LudoCapturedToken({
    required this.color,
    required this.tokenId,
    required this.fromState,
    required this.fromStep,
  });

  Map<String, dynamic> toJson() => {
        'color': color.name,
        'token_id': tokenId,
        'from_state': fromState.name,
        'from_step': fromStep,
      };

  factory LudoCapturedToken.fromJson(Map<String, dynamic> json) {
    return LudoCapturedToken(
      color: LudoColor.values.firstWhere(
        (e) => e.name == json['color'],
        orElse: () => LudoColor.blue,
      ),
      tokenId: (json['token_id'] as num?)?.toInt() ?? 0,
      fromState: LudoTokenState.values.firstWhere(
        (e) => e.name == json['from_state'],
        orElse: () => LudoTokenState.track,
      ),
      fromStep: (json['from_step'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Serializable description of the latest game action. It is stored alongside
/// the game state so the other device can replay the same animation.
class LudoAction {
  final String id;
  final String type;
  final String? actorId;
  final LudoColor? actorColor;
  final int? diceValue;
  final int? tokenId;
  final LudoTokenState? fromState;
  final int? fromStep;
  final LudoTokenState? toState;
  final int? toStep;
  final bool didCapture;
  final List<LudoCapturedToken> capturedTokens;
  final bool reachedHome;
  final bool bonusRoll;
  final bool noMoves;
  final DateTime createdAt;

  const LudoAction({
    required this.id,
    required this.type,
    this.actorId,
    this.actorColor,
    this.diceValue,
    this.tokenId,
    this.fromState,
    this.fromStep,
    this.toState,
    this.toStep,
    this.didCapture = false,
    this.capturedTokens = const [],
    this.reachedHome = false,
    this.bonusRoll = false,
    this.noMoves = false,
    required this.createdAt,
  });

  static String newId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = Random().nextInt(1 << 31);
    return '$now-$random';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        if (actorId != null) 'actor_id': actorId,
        if (actorColor != null) 'actor_color': actorColor!.name,
        if (diceValue != null) 'dice_value': diceValue,
        if (tokenId != null) 'token_id': tokenId,
        if (fromState != null) 'from_state': fromState!.name,
        if (fromStep != null) 'from_step': fromStep,
        if (toState != null) 'to_state': toState!.name,
        if (toStep != null) 'to_step': toStep,
        'did_capture': didCapture,
        'captured_tokens': capturedTokens.map((e) => e.toJson()).toList(),
        'reached_home': reachedHome,
        'bonus_roll': bonusRoll,
        'no_moves': noMoves,
        'created_at': createdAt.toIso8601String(),
      };

  factory LudoAction.fromJson(Map<String, dynamic> json) {
    LudoColor? color;
    final colorName = json['actor_color'] as String?;
    if (colorName != null) {
      color = LudoColor.values.firstWhere(
        (e) => e.name == colorName,
        orElse: () => LudoColor.green,
      );
    }

    LudoTokenState? fromState;
    final fromStateName = json['from_state'] as String?;
    if (fromStateName != null) {
      fromState = LudoTokenState.values.firstWhere(
        (e) => e.name == fromStateName,
        orElse: () => LudoTokenState.yard,
      );
    }

    LudoTokenState? toState;
    final toStateName = json['to_state'] as String?;
    if (toStateName != null) {
      toState = LudoTokenState.values.firstWhere(
        (e) => e.name == toStateName,
        orElse: () => LudoTokenState.yard,
      );
    }

    return LudoAction(
      id: json['id'] as String? ?? newId(),
      type: json['type'] as String? ?? 'roll',
      actorId: json['actor_id'] as String?,
      actorColor: color,
      diceValue: (json['dice_value'] as num?)?.toInt(),
      tokenId: (json['token_id'] as num?)?.toInt(),
      fromState: fromState,
      fromStep: (json['from_step'] as num?)?.toInt(),
      toState: toState,
      toStep: (json['to_step'] as num?)?.toInt(),
      didCapture: (json['did_capture'] as bool?) ?? false,
      capturedTokens: (json['captured_tokens'] as List<dynamic>?)
              ?.map((e) => LudoCapturedToken.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList() ??
          const [],
      reachedHome: (json['reached_home'] as bool?) ?? false,
      bonusRoll: (json['bonus_roll'] as bool?) ?? false,
      noMoves: (json['no_moves'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
