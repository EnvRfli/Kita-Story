import 'package:flutter/foundation.dart';

enum LudoTokenState {
  yard,
  track,
  homeStretch,
  home,
}

@immutable
class LudoToken {
  final int id; // 0..3
  final LudoTokenState state;
  final int step; // 0..50 on track; 0..4 on home stretch; 5 = reached home

  const LudoToken({
    required this.id,
    this.state = LudoTokenState.yard,
    this.step = 0,
  });

  bool get isInYard => state == LudoTokenState.yard;
  bool get isOnTrack => state == LudoTokenState.track;
  bool get isInHomeStretch => state == LudoTokenState.homeStretch;
  bool get isHome => state == LudoTokenState.home;

  LudoToken copyWith({
    int? id,
    LudoTokenState? state,
    int? step,
  }) {
    return LudoToken(
      id: id ?? this.id,
      state: state ?? this.state,
      step: step ?? this.step,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'state': state.name,
        'step': step,
      };

  factory LudoToken.fromJson(Map<String, dynamic> json) {
    return LudoToken(
      id: json['id'] as int,
      state: LudoTokenState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => LudoTokenState.yard,
      ),
      step: (json['step'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LudoToken &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          state == other.state &&
          step == other.step;

  @override
  int get hashCode => Object.hash(id, state, step);
}
