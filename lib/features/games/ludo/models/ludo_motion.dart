import '../engine/ludo_board_path.dart';
import 'ludo_action.dart';
import 'ludo_player.dart';

class LudoMotion {
  final String id;
  final LudoColor color;
  final int tokenId;
  final List<LudoCoordinate> path;
  final List<LudoCapturedToken> capturedTokens;
  final bool reachedHome;
  final bool isYardExit;
  final int stepDurationMs;
  final int fromTurnIndex;

  const LudoMotion({
    required this.id,
    required this.color,
    required this.tokenId,
    required this.path,
    this.capturedTokens = const [],
    this.reachedHome = false,
    this.isYardExit = false,
    this.stepDurationMs = 150,
    required this.fromTurnIndex,
  });

  String get tokenKey => '${color.name}:$tokenId';

  Set<String> get hiddenTokenKeys => {
        tokenKey,
        ...capturedTokens.map((e) => '${e.color.name}:${e.tokenId}'),
      };
}
