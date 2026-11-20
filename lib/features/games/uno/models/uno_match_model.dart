import 'package:flutter/foundation.dart';

import 'uno_card.dart';

enum UnoMatchStatus {
  invited,
  inProgress,
  paused,
  completed,
  cancelled,
  expired,
  abandoned,
  rejected;

  static UnoMatchStatus fromString(String? value) {
    switch (value) {
      case 'in_progress':
        return UnoMatchStatus.inProgress;
      case 'paused':
        return UnoMatchStatus.paused;
      case 'completed':
        return UnoMatchStatus.completed;
      case 'cancelled':
        return UnoMatchStatus.cancelled;
      case 'expired':
        return UnoMatchStatus.expired;
      case 'abandoned':
        return UnoMatchStatus.abandoned;
      case 'rejected':
        return UnoMatchStatus.rejected;
      default:
        return UnoMatchStatus.invited;
    }
  }

  String get dbValue {
    switch (this) {
      case UnoMatchStatus.invited:
        return 'invited';
      case UnoMatchStatus.inProgress:
        return 'in_progress';
      case UnoMatchStatus.paused:
        return 'paused';
      case UnoMatchStatus.completed:
        return 'completed';
      case UnoMatchStatus.cancelled:
        return 'cancelled';
      case UnoMatchStatus.expired:
        return 'expired';
      case UnoMatchStatus.abandoned:
        return 'abandoned';
      case UnoMatchStatus.rejected:
        return 'rejected';
    }
  }

  bool get isActive =>
      this == UnoMatchStatus.inProgress || this == UnoMatchStatus.paused;
}

enum UnoPhase {
  playing,
  drawResponse,
  gameOver;

  static UnoPhase fromString(String? value) {
    switch (value) {
      case 'draw_response':
        return UnoPhase.drawResponse;
      case 'game_over':
        return UnoPhase.gameOver;
      default:
        return UnoPhase.playing;
    }
  }

  String get dbValue {
    switch (this) {
      case UnoPhase.playing:
        return 'playing';
      case UnoPhase.drawResponse:
        return 'draw_response';
      case UnoPhase.gameOver:
        return 'game_over';
    }
  }
}

@immutable
class UnoMatchModel {
  static const Object _unset = Object();

  final String id;
  final String hostId;
  final String guestId;
  final UnoMatchStatus status;
  final UnoPhase phase;
  final String? currentActorId;
  final int hostCardCount;
  final int guestCardCount;
  final UnoCard? topCard;
  final UnoColor? chosenColor;
  final int deckCount;
  final List<UnoCard> discard;
  final List<UnoCard> turnCards;
  final int pendingDraw;
  final String? pendingDrawTarget;
  final bool drawResponseStarted;
  final int extraTurns;
  final int version;
  final Map<String, dynamic>? lastAction;
  final String? winnerId;
  final String? unoCalledBy;
  final String? pauseRequestedBy;
  final String? resumeRequestedBy;
  final String? rematchRequestedBy;
  final String? abandonReason;
  final DateTime? hostLastSeenAt;
  final DateTime? guestLastSeenAt;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UnoMatchModel({
    required this.id,
    required this.hostId,
    required this.guestId,
    this.status = UnoMatchStatus.invited,
    this.phase = UnoPhase.playing,
    this.currentActorId,
    this.hostCardCount = 0,
    this.guestCardCount = 0,
    this.topCard,
    this.chosenColor,
    this.deckCount = 0,
    this.discard = const [],
    this.turnCards = const [],
    this.pendingDraw = 0,
    this.pendingDrawTarget,
    this.drawResponseStarted = false,
    this.extraTurns = 0,
    this.version = 0,
    this.lastAction,
    this.winnerId,
    this.unoCalledBy,
    this.pauseRequestedBy,
    this.resumeRequestedBy,
    this.rematchRequestedBy,
    this.abandonReason,
    this.hostLastSeenAt,
    this.guestLastSeenAt,
    this.expiresAt,
    this.acceptedAt,
    this.startedAt,
    this.finishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool isParticipant(String userId) => hostId == userId || guestId == userId;

  String opponentOf(String userId) => hostId == userId ? guestId : hostId;

  int cardCountFor(String userId) =>
      hostId == userId ? hostCardCount : guestCardCount;

  factory UnoMatchModel.fromJson(Map<String, dynamic> json) {
    final topCardJson = json['top_card'];
    final chosenColor = UnoColor.fromName(json['chosen_color'] as String?);

    return UnoMatchModel(
      id: json['id'] as String,
      hostId: json['host_id'] as String,
      guestId: json['guest_id'] as String,
      status: UnoMatchStatus.fromString(json['status'] as String?),
      phase: UnoPhase.fromString(json['phase'] as String?),
      currentActorId: json['current_actor_id'] as String?,
      hostCardCount: (json['host_card_count'] as num?)?.toInt() ?? 0,
      guestCardCount: (json['guest_card_count'] as num?)?.toInt() ?? 0,
      topCard: topCardJson is Map
          ? UnoCard.fromJson(Map<String, dynamic>.from(topCardJson))
          : null,
      chosenColor: chosenColor,
      deckCount: (json['deck_count'] as num?)?.toInt() ?? 0,
      discard: _parseCards(json['discard']),
      turnCards: _parseCards(json['turn_cards']),
      pendingDraw: (json['pending_draw'] as num?)?.toInt() ?? 0,
      pendingDrawTarget: json['pending_draw_target'] as String?,
      drawResponseStarted: (json['draw_response_started'] as bool?) ?? false,
      extraTurns: (json['extra_turns'] as num?)?.toInt() ?? 0,
      version: (json['version'] as num?)?.toInt() ?? 0,
      lastAction: json['last_action'] is Map
          ? Map<String, dynamic>.from(json['last_action'] as Map)
          : null,
      winnerId: json['winner_id'] as String?,
      unoCalledBy: json['uno_called_by'] as String?,
      pauseRequestedBy: json['pause_requested_by'] as String?,
      resumeRequestedBy: json['resume_requested_by'] as String?,
      rematchRequestedBy: json['rematch_requested_by'] as String?,
      abandonReason: json['abandon_reason'] as String?,
      hostLastSeenAt: _parseDate(json['host_last_seen_at']),
      guestLastSeenAt: _parseDate(json['guest_last_seen_at']),
      expiresAt: _parseDate(json['expires_at']),
      acceptedAt: _parseDate(json['accepted_at']),
      startedAt: _parseDate(json['started_at']),
      finishedAt: _parseDate(json['finished_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  static List<UnoCard> _parseCards(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => UnoCard.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Payload sent to RPCs. Nullable fields are included on purpose so the
  /// server can clear values such as pending_draw_target.
  Map<String, dynamic> toPublicPatch() => {
        'phase': phase.dbValue,
        'current_actor_id': currentActorId,
        'host_card_count': hostCardCount,
        'guest_card_count': guestCardCount,
        'top_card': topCard?.toJson(),
        'chosen_color': chosenColor?.name,
        'deck_count': deckCount,
        'discard': discard.map((c) => c.toJson()).toList(),
        'turn_cards': turnCards.map((c) => c.toJson()).toList(),
        'pending_draw': pendingDraw,
        'pending_draw_target': pendingDrawTarget,
        'draw_response_started': drawResponseStarted,
        'extra_turns': extraTurns,
        'last_action': lastAction,
        'winner_id': winnerId,
        'uno_called_by': unoCalledBy,
        'status': status.dbValue,
        'finished_at': finishedAt?.toUtc().toIso8601String(),
      };

  UnoMatchModel copyWith({
    String? id,
    String? hostId,
    String? guestId,
    UnoMatchStatus? status,
    UnoPhase? phase,
    Object? currentActorId = _unset,
    int? hostCardCount,
    int? guestCardCount,
    Object? topCard = _unset,
    Object? chosenColor = _unset,
    int? deckCount,
    List<UnoCard>? discard,
    List<UnoCard>? turnCards,
    int? pendingDraw,
    Object? pendingDrawTarget = _unset,
    bool? drawResponseStarted,
    int? extraTurns,
    int? version,
    Object? lastAction = _unset,
    Object? winnerId = _unset,
    Object? unoCalledBy = _unset,
    Object? pauseRequestedBy = _unset,
    Object? resumeRequestedBy = _unset,
    Object? rematchRequestedBy = _unset,
    Object? abandonReason = _unset,
    Object? hostLastSeenAt = _unset,
    Object? guestLastSeenAt = _unset,
    Object? expiresAt = _unset,
    Object? acceptedAt = _unset,
    Object? startedAt = _unset,
    Object? finishedAt = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UnoMatchModel(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      guestId: guestId ?? this.guestId,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      currentActorId: identical(currentActorId, _unset)
          ? this.currentActorId
          : currentActorId as String?,
      hostCardCount: hostCardCount ?? this.hostCardCount,
      guestCardCount: guestCardCount ?? this.guestCardCount,
      topCard:
          identical(topCard, _unset) ? this.topCard : topCard as UnoCard?,
      chosenColor: identical(chosenColor, _unset)
          ? this.chosenColor
          : chosenColor as UnoColor?,
      deckCount: deckCount ?? this.deckCount,
      discard: discard ?? this.discard,
      turnCards: turnCards ?? this.turnCards,
      pendingDraw: pendingDraw ?? this.pendingDraw,
      pendingDrawTarget: identical(pendingDrawTarget, _unset)
          ? this.pendingDrawTarget
          : pendingDrawTarget as String?,
      drawResponseStarted: drawResponseStarted ?? this.drawResponseStarted,
      extraTurns: extraTurns ?? this.extraTurns,
      version: version ?? this.version,
      lastAction: identical(lastAction, _unset)
          ? this.lastAction
          : lastAction as Map<String, dynamic>?,
      winnerId:
          identical(winnerId, _unset) ? this.winnerId : winnerId as String?,
      unoCalledBy: identical(unoCalledBy, _unset)
          ? this.unoCalledBy
          : unoCalledBy as String?,
      pauseRequestedBy: identical(pauseRequestedBy, _unset)
          ? this.pauseRequestedBy
          : pauseRequestedBy as String?,
      resumeRequestedBy: identical(resumeRequestedBy, _unset)
          ? this.resumeRequestedBy
          : resumeRequestedBy as String?,
      rematchRequestedBy: identical(rematchRequestedBy, _unset)
          ? this.rematchRequestedBy
          : rematchRequestedBy as String?,
      abandonReason: identical(abandonReason, _unset)
          ? this.abandonReason
          : abandonReason as String?,
      hostLastSeenAt: identical(hostLastSeenAt, _unset)
          ? this.hostLastSeenAt
          : hostLastSeenAt as DateTime?,
      guestLastSeenAt: identical(guestLastSeenAt, _unset)
          ? this.guestLastSeenAt
          : guestLastSeenAt as DateTime?,
      expiresAt:
          identical(expiresAt, _unset) ? this.expiresAt : expiresAt as DateTime?,
      acceptedAt: identical(acceptedAt, _unset)
          ? this.acceptedAt
          : acceptedAt as DateTime?,
      startedAt:
          identical(startedAt, _unset) ? this.startedAt : startedAt as DateTime?,
      finishedAt: identical(finishedAt, _unset)
          ? this.finishedAt
          : finishedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
