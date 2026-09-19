import 'package:flutter/foundation.dart';
import '../models/ludo_player.dart';

@immutable
class LudoCoordinate {
  final int row;
  final int col;

  const LudoCoordinate(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LudoCoordinate &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row, $col)';
}

class LudoBoardPath {
  static const int trackLength = 52;
  static const int homeStretchLength = 5;
  static const int totalStepsToHome = 56; // 0..50 on track (51 steps), + 5 on stretch = 56 = Home

  // 52 Outer Track Coordinates starting from Red Start (6, 1) clockwise
  static const List<LudoCoordinate> globalTrack = [
    // 0..4: Left arm upper row going right (Red Start at 0)
    LudoCoordinate(6, 1),
    LudoCoordinate(6, 2),
    LudoCoordinate(6, 3),
    LudoCoordinate(6, 4),
    LudoCoordinate(6, 5),
    // 5..10: Top arm left column going up
    LudoCoordinate(5, 6),
    LudoCoordinate(4, 6),
    LudoCoordinate(3, 6),
    LudoCoordinate(2, 6), // Star Safe (Index 8)
    LudoCoordinate(1, 6),
    LudoCoordinate(0, 6),
    // 11..12: Across the top
    LudoCoordinate(0, 7),
    LudoCoordinate(0, 8),
    // 13..17: Top arm right column going down (Green Start at 13)
    LudoCoordinate(1, 8),
    LudoCoordinate(2, 8),
    LudoCoordinate(3, 8),
    LudoCoordinate(4, 8),
    LudoCoordinate(5, 8),
    // 18..23: Right arm top row going right
    LudoCoordinate(6, 9),
    LudoCoordinate(6, 10),
    LudoCoordinate(6, 11),
    LudoCoordinate(6, 12), // Star Safe (Index 21)
    LudoCoordinate(6, 13),
    LudoCoordinate(6, 14),
    // 24..25: Across the right end
    LudoCoordinate(7, 14),
    LudoCoordinate(8, 14),
    // 26..30: Right arm bottom row going left (Yellow Start at 26)
    LudoCoordinate(8, 13),
    LudoCoordinate(8, 12),
    LudoCoordinate(8, 11),
    LudoCoordinate(8, 10),
    LudoCoordinate(8, 9),
    // 31..36: Bottom arm right column going down
    LudoCoordinate(9, 8),
    LudoCoordinate(10, 8),
    LudoCoordinate(11, 8),
    LudoCoordinate(12, 8), // Star Safe (Index 34)
    LudoCoordinate(13, 8),
    LudoCoordinate(14, 8),
    // 37..38: Across the bottom
    LudoCoordinate(14, 7),
    LudoCoordinate(14, 6),
    // 39..43: Bottom arm left column going up (Blue Start at 39)
    LudoCoordinate(13, 6),
    LudoCoordinate(12, 6),
    LudoCoordinate(11, 6),
    LudoCoordinate(10, 6),
    LudoCoordinate(9, 6),
    // 44..49: Left arm bottom row going left
    LudoCoordinate(8, 5),
    LudoCoordinate(8, 4),
    LudoCoordinate(8, 3),
    LudoCoordinate(8, 2), // Star Safe (Index 47)
    LudoCoordinate(8, 1),
    LudoCoordinate(8, 0),
    // 50..51: Across the left end
    LudoCoordinate(7, 0),
    LudoCoordinate(6, 0),
  ];

  // Starting track index for each color
  static int startIndexFor(LudoColor color) {
    switch (color) {
      case LudoColor.red:
        return 0;
      case LudoColor.green:
        return 13;
      case LudoColor.yellow:
        return 26;
      case LudoColor.blue:
        return 39;
    }
  }

  // 4 Safe Star Coordinates
  static const Set<int> starTrackIndices = {8, 21, 34, 47};

  // Check if a global track index is a safe zone (either a start square or a star square)
  static bool isSafeGlobalIndex(int index) {
    return index == 0 ||
        index == 13 ||
        index == 26 ||
        index == 39 ||
        starTrackIndices.contains(index);
  }

  // Home Stretch coordinates (5 steps for each color)
  static const Map<LudoColor, List<LudoCoordinate>> homeStretches = {
    LudoColor.red: [
      LudoCoordinate(7, 1),
      LudoCoordinate(7, 2),
      LudoCoordinate(7, 3),
      LudoCoordinate(7, 4),
      LudoCoordinate(7, 5),
    ],
    LudoColor.green: [
      LudoCoordinate(1, 7),
      LudoCoordinate(2, 7),
      LudoCoordinate(3, 7),
      LudoCoordinate(4, 7),
      LudoCoordinate(5, 7),
    ],
    LudoColor.yellow: [
      LudoCoordinate(7, 13),
      LudoCoordinate(7, 12),
      LudoCoordinate(7, 11),
      LudoCoordinate(7, 10),
      LudoCoordinate(7, 9),
    ],
    LudoColor.blue: [
      LudoCoordinate(13, 7),
      LudoCoordinate(12, 7),
      LudoCoordinate(11, 7),
      LudoCoordinate(10, 7),
      LudoCoordinate(9, 7),
    ],
  };

  // Center Home Triangle targets (used for drawing / centering final tokens)
  static const Map<LudoColor, LudoCoordinate> homeCenterTargets = {
    LudoColor.red: LudoCoordinate(7, 6),
    LudoColor.green: LudoCoordinate(6, 7),
    LudoColor.yellow: LudoCoordinate(7, 8),
    LudoColor.blue: LudoCoordinate(8, 7),
  };

  // 4 Yard slot coordinates for each color
  static const Map<LudoColor, List<LudoCoordinate>> yardSlots = {
    LudoColor.red: [
      LudoCoordinate(1, 1),
      LudoCoordinate(1, 4),
      LudoCoordinate(4, 1),
      LudoCoordinate(4, 4),
    ],
    LudoColor.green: [
      LudoCoordinate(1, 10),
      LudoCoordinate(1, 13),
      LudoCoordinate(4, 10),
      LudoCoordinate(4, 13),
    ],
    LudoColor.blue: [
      LudoCoordinate(10, 1),
      LudoCoordinate(10, 4),
      LudoCoordinate(13, 1),
      LudoCoordinate(13, 4),
    ],
    LudoColor.yellow: [
      LudoCoordinate(10, 10),
      LudoCoordinate(10, 13),
      LudoCoordinate(13, 10),
      LudoCoordinate(13, 13),
    ],
  };

  // Convert player relative step to global track index (0..51)
  static int relativeStepToGlobalIndex(LudoColor color, int relativeStep) {
    final start = startIndexFor(color);
    return (start + relativeStep) % trackLength;
  }

  // Get physical coordinate on the 15x15 board for any token state
  static LudoCoordinate coordinateForToken({
    required LudoColor color,
    required int tokenId,
    required bool isInYard,
    required bool isOnTrack,
    required bool isInHomeStretch,
    required bool isHome,
    required int step,
  }) {
    if (isInYard) {
      final slots = yardSlots[color]!;
      return slots[tokenId % slots.length];
    }
    if (isHome) {
      return homeCenterTargets[color]!;
    }
    if (isInHomeStretch) {
      final stretch = homeStretches[color]!;
      final idx = step.clamp(0, stretch.length - 1);
      return stretch[idx];
    }
    // isOnTrack: step is 0..50
    final globalIdx = relativeStepToGlobalIndex(color, step);
    return globalTrack[globalIdx];
  }
}
