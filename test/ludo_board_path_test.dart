import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/ludo/engine/ludo_board_path.dart';
import 'package:kita_story/features/games/ludo/models/ludo_player.dart';

void main() {
  group('LudoBoardPath', () {
    test('global track contains exactly 52 unique non-null coordinates', () {
      expect(LudoBoardPath.globalTrack.length, 52);
      final set = LudoBoardPath.globalTrack.toSet();
      expect(set.length, 52);
    });

    test('validates start coordinates for all 4 colors', () {
      // Red starts at (6, 1)
      expect(LudoBoardPath.globalTrack[0], const LudoCoordinate(6, 1));
      // Green starts at (1, 8)
      expect(LudoBoardPath.globalTrack[13], const LudoCoordinate(1, 8));
      // Yellow starts at (8, 13)
      expect(LudoBoardPath.globalTrack[26], const LudoCoordinate(8, 13));
      // Blue starts at (13, 6)
      expect(LudoBoardPath.globalTrack[39], const LudoCoordinate(13, 6));
    });

    test('validates safe star coordinates at indices 8, 21, 34, 47', () {
      expect(LudoBoardPath.globalTrack[8], const LudoCoordinate(2, 6));
      expect(LudoBoardPath.globalTrack[21], const LudoCoordinate(6, 12));
      expect(LudoBoardPath.globalTrack[34], const LudoCoordinate(12, 8));
      expect(LudoBoardPath.globalTrack[47], const LudoCoordinate(8, 2));

      expect(LudoBoardPath.isSafeGlobalIndex(8), isTrue);
      expect(LudoBoardPath.isSafeGlobalIndex(21), isTrue);
      expect(LudoBoardPath.isSafeGlobalIndex(34), isTrue);
      expect(LudoBoardPath.isSafeGlobalIndex(47), isTrue);

      // Start squares are also safe
      expect(LudoBoardPath.isSafeGlobalIndex(0), isTrue);
      expect(LudoBoardPath.isSafeGlobalIndex(13), isTrue);
      expect(LudoBoardPath.isSafeGlobalIndex(26), isTrue);
      expect(LudoBoardPath.isSafeGlobalIndex(39), isTrue);

      // Non-safe index
      expect(LudoBoardPath.isSafeGlobalIndex(1), isFalse);
      expect(LudoBoardPath.isSafeGlobalIndex(7), isFalse);
    });

    test('home stretches contain 5 coordinates each leading towards center', () {
      for (final color in LudoColor.values) {
        final stretch = LudoBoardPath.homeStretches[color]!;
        expect(stretch.length, 5);
      }

      // Red stretch goes horizontally (7, 1) -> (7, 5)
      expect(LudoBoardPath.homeStretches[LudoColor.red]!.first,
          const LudoCoordinate(7, 1));
      expect(LudoBoardPath.homeStretches[LudoColor.red]!.last,
          const LudoCoordinate(7, 5));

      // Green stretch goes vertically (1, 7) -> (5, 7)
      expect(LudoBoardPath.homeStretches[LudoColor.green]!.first,
          const LudoCoordinate(1, 7));
      expect(LudoBoardPath.homeStretches[LudoColor.green]!.last,
          const LudoCoordinate(5, 7));
    });

    test('yard slots contain 4 distinct slots per color', () {
      for (final color in LudoColor.values) {
        final slots = LudoBoardPath.yardSlots[color]!;
        expect(slots.length, 4);
        expect(slots.toSet().length, 4);
      }
    });

    test('relativeStepToGlobalIndex wraps around 52 correctly', () {
      // Red (start 0): step 0 -> 0, step 50 -> 50
      expect(LudoBoardPath.relativeStepToGlobalIndex(LudoColor.red, 0), 0);
      expect(LudoBoardPath.relativeStepToGlobalIndex(LudoColor.red, 50), 50);

      // Green (start 13): step 0 -> 13, step 40 -> (13+40)%52 = 1
      expect(LudoBoardPath.relativeStepToGlobalIndex(LudoColor.green, 0), 13);
      expect(LudoBoardPath.relativeStepToGlobalIndex(LudoColor.green, 40), 1);
    });
  });
}
