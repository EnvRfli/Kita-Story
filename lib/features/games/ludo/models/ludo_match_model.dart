import 'package:flutter/foundation.dart';
import 'ludo_player.dart';

enum LudoMatchStatus {
  invited,
  accepted,
  rejected,
  inProgress,
  completed,
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
    required this.createdAt,
    required this.updatedAt,
  });

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
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
