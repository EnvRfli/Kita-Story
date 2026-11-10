import '../models/ludo_player.dart';

/// Decides which player card sits at the top/bottom and whether the board
/// should be rotated so the local player's yard is always at the bottom.
class LudoPerspective {
  final int topIndex;
  final int bottomIndex;
  final bool rotateBoard;

  const LudoPerspective({
    required this.topIndex,
    required this.bottomIndex,
    required this.rotateBoard,
  });

  factory LudoPerspective.forPlayers({
    required bool isOnline,
    required List<LudoPlayer> players,
    required LudoColor? myColor,
  }) {
    // Offline pass-and-play keeps the natural red/green-style orientation.
    if (!isOnline || players.length < 2 || myColor == null) {
      return const LudoPerspective(
        topIndex: 0,
        bottomIndex: 1,
        rotateBoard: false,
      );
    }

    final localIndex = players.indexWhere((player) => player.color == myColor);
    if (localIndex < 0) {
      return const LudoPerspective(
        topIndex: 0,
        bottomIndex: 1,
        rotateBoard: false,
      );
    }

    // In the raw board, index 0 (green) starts at the top and index 1 (blue)
    // starts at the bottom. Rotate only when the local player is at the top.
    return LudoPerspective(
      topIndex: 1 - localIndex,
      bottomIndex: localIndex,
      rotateBoard: localIndex == 0,
    );
  }
}
