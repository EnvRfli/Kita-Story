import 'package:flutter/material.dart';
import 'ludo_token.dart';

enum LudoColor {
  red,
  green,
  blue,
  yellow;

  String get displayName {
    switch (this) {
      case LudoColor.red:
        return 'Merah';
      case LudoColor.green:
        return 'Hijau';
      case LudoColor.blue:
        return 'Biru';
      case LudoColor.yellow:
        return 'Kuning';
    }
  }

  Color get primaryColor {
    switch (this) {
      case LudoColor.red:
        return const Color(0xFFEF4444);
      case LudoColor.green:
        return const Color(0xFF22C55E);
      case LudoColor.blue:
        return const Color(0xFF0088FF);
      case LudoColor.yellow:
        return const Color(0xFFEAB308);
    }
  }

  Color get lightColor {
    switch (this) {
      case LudoColor.red:
        return const Color(0xFFFEE2E2);
      case LudoColor.green:
        return const Color(0xFFDCFCE7);
      case LudoColor.blue:
        return const Color(0xFFE0F2FE);
      case LudoColor.yellow:
        return const Color(0xFFFEF9C3);
    }
  }

  Color get darkColor {
    switch (this) {
      case LudoColor.red:
        return const Color(0xFFB91C1C);
      case LudoColor.green:
        return const Color(0xFF15803D);
      case LudoColor.blue:
        return const Color(0xFF0369A1);
      case LudoColor.yellow:
        return const Color(0xFFA16207);
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case LudoColor.red:
        return const [Color(0xFFF87171), Color(0xFFEF4444)];
      case LudoColor.green:
        return const [Color(0xFF4ADE80), Color(0xFF22C55E)];
      case LudoColor.blue:
        return const [Color(0xFF38BDF8), Color(0xFF0088FF)];
      case LudoColor.yellow:
        return const [Color(0xFFFACC15), Color(0xFFEAB308)];
    }
  }
}

@immutable
class LudoPlayer {
  final String id;
  final String name;
  final LudoColor color;
  final String? avatarUrl;
  final bool isHost;
  final List<LudoToken> tokens;
  final bool hasFinished;
  final int? finishRank;
  final int consecutiveSixes;

  const LudoPlayer({
    required this.id,
    required this.name,
    required this.color,
    this.avatarUrl,
    this.isHost = false,
    required this.tokens,
    this.hasFinished = false,
    this.finishRank,
    this.consecutiveSixes = 0,
  });

  factory LudoPlayer.initial({
    required String id,
    required String name,
    required LudoColor color,
    String? avatarUrl,
    bool isHost = false,
  }) {
    return LudoPlayer(
      id: id,
      name: name,
      color: color,
      avatarUrl: avatarUrl,
      isHost: isHost,
      tokens: List.generate(4, (i) => LudoToken(id: i)),
      hasFinished: false,
      finishRank: null,
      consecutiveSixes: 0,
    );
  }

  int get tokensHomeCount => tokens.where((t) => t.isHome).length;
  int get tokensInYardCount => tokens.where((t) => t.isInYard).length;
  int get tokensOnBoardCount =>
      tokens.where((t) => t.isOnTrack || t.isInHomeStretch).length;

  bool get isWinner => tokensHomeCount == 4;

  LudoPlayer copyWith({
    String? id,
    String? name,
    LudoColor? color,
    String? avatarUrl,
    bool? isHost,
    List<LudoToken>? tokens,
    bool? hasFinished,
    int? finishRank,
    int? consecutiveSixes,
  }) {
    return LudoPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isHost: isHost ?? this.isHost,
      tokens: tokens ?? this.tokens,
      hasFinished: hasFinished ?? this.hasFinished,
      finishRank: finishRank ?? this.finishRank,
      consecutiveSixes: consecutiveSixes ?? this.consecutiveSixes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.name,
        'avatar_url': avatarUrl,
        'is_host': isHost,
        'tokens': tokens.map((t) => t.toJson()).toList(),
        'has_finished': hasFinished,
        'finish_rank': finishRank,
        'consecutive_sixes': consecutiveSixes,
      };

  factory LudoPlayer.fromJson(Map<String, dynamic> json) {
    return LudoPlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      color: LudoColor.values.firstWhere(
        (e) => e.name == json['color'],
        orElse: () => LudoColor.green,
      ),
      avatarUrl: json['avatar_url'] as String?,
      isHost: (json['is_host'] as bool?) ?? false,
      tokens: (json['tokens'] as List<dynamic>?)
              ?.map((t) => LudoToken.fromJson(t as Map<String, dynamic>))
              .toList() ??
          List.generate(4, (i) => LudoToken(id: i)),
      hasFinished: (json['has_finished'] as bool?) ?? false,
      finishRank: (json['finish_rank'] as num?)?.toInt(),
      consecutiveSixes: (json['consecutive_sixes'] as num?)?.toInt() ?? 0,
    );
  }
}
