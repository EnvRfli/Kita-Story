import 'dart:math';

import 'uno_card.dart';

/// Serializable description of the latest UNO action. Stored in
/// `uno_matches.last_action` so the other device can animate the same event.
class UnoAction {
  final String id;
  final String type;
  final String? actorId;
  final String? targetId;
  final UnoCard? card;
  final int? drawCount;
  final DateTime createdAt;

  const UnoAction({
    required this.id,
    required this.type,
    this.actorId,
    this.targetId,
    this.card,
    this.drawCount,
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
        if (targetId != null) 'target_id': targetId,
        if (card != null) 'card': card!.toJson(),
        if (drawCount != null) 'draw_count': drawCount,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory UnoAction.fromJson(Map<String, dynamic> json) {
    final cardJson = json['card'];
    return UnoAction(
      id: json['id'] as String? ?? newId(),
      type: json['type'] as String? ?? 'unknown',
      actorId: json['actor_id'] as String?,
      targetId: json['target_id'] as String?,
      card: cardJson is Map
          ? UnoCard.fromJson(Map<String, dynamic>.from(cardJson))
          : null,
      drawCount: (json['draw_count'] as num?)?.toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
