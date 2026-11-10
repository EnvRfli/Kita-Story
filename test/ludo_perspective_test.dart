import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/ludo/models/ludo_player.dart';
import 'package:kita_story/features/games/ludo/utils/ludo_perspective.dart';

void main() {
  final players = [
    LudoPlayer.initial(id: 'p1', name: 'Host', color: LudoColor.green),
    LudoPlayer.initial(id: 'p2', name: 'Guest', color: LudoColor.blue),
  ];

  group('LudoPerspective', () {
    test('host (green) is moved to the bottom and the board is rotated', () {
      final perspective = LudoPerspective.forPlayers(
        isOnline: true,
        players: players,
        myColor: LudoColor.green,
      );

      expect(perspective.topIndex, 1);
      expect(perspective.bottomIndex, 0);
      expect(perspective.rotateBoard, isTrue);
    });

    test('guest (blue) stays at the bottom without board rotation', () {
      final perspective = LudoPerspective.forPlayers(
        isOnline: true,
        players: players,
        myColor: LudoColor.blue,
      );

      expect(perspective.topIndex, 0);
      expect(perspective.bottomIndex, 1);
      expect(perspective.rotateBoard, isFalse);
    });

    test('offline keeps the natural orientation', () {
      final perspective = LudoPerspective.forPlayers(
        isOnline: false,
        players: players,
        myColor: LudoColor.blue,
      );

      expect(perspective.topIndex, 0);
      expect(perspective.bottomIndex, 1);
      expect(perspective.rotateBoard, isFalse);
    });

    test('missing local color falls back to the natural orientation', () {
      final perspective = LudoPerspective.forPlayers(
        isOnline: true,
        players: players,
        myColor: LudoColor.red,
      );

      expect(perspective.topIndex, 0);
      expect(perspective.bottomIndex, 1);
      expect(perspective.rotateBoard, isFalse);
    });
  });
}
