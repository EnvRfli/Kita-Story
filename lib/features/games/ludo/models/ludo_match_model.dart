import 'package:flutter/foundation.dart';
import 'ludo_player.dart';

enum LudoMatchStatus {
  invited,
  accepted,
  rejected,
  inProgress,
  completed,
  cancelled,
  expired,
  abandoned;

  static LudoMatchStatus fromString(String value) {
    switch (value) {
      case 'invited':
        return LudoMatchStatus.invited;
      case 'accepted':
        return LudoMatchStatus.accepted;
      case 'rejected':
        return LudoMatchStatus.rejected;
      case 'in_progress':
        return LudoMatchStatus.inProgress;
      case 'completed':
        return LudoMatchStatus.completed;
      case 'cancelled':
        return LudoMatchStatus.cancelled;
      case 'expired':
        return LudoMatchStatus.expired;
      case 'abandoned':
        return LudoMatchStatus.abandoned;
      default:
        return LudoMatchStatus.invited;
    }
  }

  String toDbValue() {
    switch (this) {
      case LudoMatchStatus.invited:
        return 'invited';
      case LudoMatchStatus.accepted:
        return 'accepted';
      case LudoMatchStatus.rejected:
        return 'rejected';
      case LudoMatchStatus.inProgress:
        return 'in_progress';
      case LudoMatchStatus.completed:
        return 'completed';
      case LudoMatchStatus.cancelled:
        return 'cancelled';
      case LudoMatchStatus.expired:
        return 'expired';
      case LudoMatchStatus.abandoned:
        return 'abandoned';
    }
  }
}

@immutable
class LudoMatchModel {
  final String id;
  final String hostId;
  final String guestId;
  final LudoColor hostColor;
  final LudoColor guestColor;
  final LudoColor currentTurnColor;
  final LudoMatchStatus status;
  final String? winnerId;
  final Map<String, dynamic> gameState;
  final int gameVersion;
  final Map<String, dynamic>? lastAction;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? finishedAt;
  final String? abandonReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LudoMatchModel({
    required this.id,
    required this.hostId,
    required this.guestId,
    this.hostColor = LudoColor.green,
    this.guestColor = LudoColor.blue,
    this.currentTurnColor = LudoColor.green,
    this.status = LudoMatchStatus.invited,
    this.winnerId,
    this.gameState = const {},
    this.gameVersion = 0,
    this.lastAction,
    this.expiresAt,
    this.acceptedAt,
    this.finishedAt,
    this.abandonReason,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool isParticipant(String userId) => hostId == userId || guestId == userId;
  bool isHost(String userId) => hostId == userId;

  LudoColor colorForUser(String userId) {
    return isHost(userId) ? hostColor : guestColor;
  }

  factory LudoMatchModel.fromJson(Map<String, dynamic> json) {
    return LudoMatchModel(
      id: json['id'] as String,
      hostId: json['host_id'] as String,
      guestId: json['guest_id'] as String,
      hostColor: LudoColor.values.firstWhere(
        (e) => e.name == json['host_color'],
        orElse: () => LudoColor.green,
      ),
      guestColor: LudoColor.values.firstWhere(
        (e) => e.name == json['guest_color'],
        orElse: () => LudoColor.blue,
      ),
      currentTurnColor: LudoColor.values.firstWhere(
        (e) => e.name == json['current_turn_color'],
        orElse: () => LudoColor.green,
      ),
      status: LudoMatchStatus.fromString(json['status'] as String? ?? 'invited'),
      winnerId: json['winner_id'] as String?,
      gameState: (json['game_state'] as Map<String, dynamic>?) ?? const {},
      gameVersion: (json['game_version'] as num?)?.toInt() ?? 0,
      lastAction: json['last_action'] != null
          ? Map<String, dynamic>.from(json['last_action'] as Map)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'] as String)
          : null,
      finishedAt: json['finished_at'] != null
          ? DateTime.tryParse(json['finished_at'] as String)
          : null,
      abandonReason: json['abandon_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'host_id': hostId,
        'guest_id': guestId,
        'host_color': hostColor.name,
        'guest_color': guestColor.name,
        'current_turn_color': currentTurnColor.name,
        'status': status.toDbValue(),
        'winner_id': winnerId,
        'game_state': gameState,
        'game_version': gameVersion,
        'last_action': lastAction,
        'expires_at': expiresAt?.toIso8601String(),
        'accepted_at': acceptedAt?.toIso8601String(),
        'finished_at': finishedAt?.toIso8601String(),
        'abandon_reason': abandonReason,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
