import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/ludo/engine/ludo_engine.dart';
import 'package:kita_story/features/games/ludo/models/ludo_game_state.dart';
import 'package:kita_story/features/games/ludo/providers/ludo_game_provider.dart';
import 'package:kita_story/features/games/ludo/services/ludo_sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedDiceEngine extends LudoEngine {
  final int value;

  _FixedDiceEngine(this.value);

  @override
  int rollDice() => value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LudoGameProvider offline flow', () {
    test('rolls dice, opens step animation, and completes the move', () async {
      final provider = LudoGameProvider(
        engine: _FixedDiceEngine(6),
        sound: LudoSoundService.forTesting(),
      );

      await provider.startOfflineGame(
        mode: LudoGameMode.offline2,
        player1Name: 'Alya',
        player2Name: 'Reza',
      );

      expect(provider.state.players.length, 2);
      expect(provider.canRoll(), isTrue);

      final rollFuture = provider.rollDice();
      await Future.delayed(const Duration(milliseconds: 120));

      expect(provider.isRollingForIndex(0), isTrue);
      expect(provider.isRollingForIndex(1), isFalse);
      expect(provider.diceValueForPlayer(0), isNotNull);

      await rollFuture;

      expect(provider.state.phase, LudoTurnPhase.waitingForTokenMove);
      expect(provider.state.diceValue, 6);
      expect(provider.state.movableTokenIds.length, 4);

      await provider.selectToken(0);

      final motion = provider.activeMotion;
      expect(motion, isNotNull);
      // Yard exit has a two-point path, not an instant teleport.
      expect(motion!.path.length, 2);

      provider.completeMotion(motion.id);

      expect(provider.activeMotion, isNull);
      expect(provider.state.players.first.tokens.first.isOnTrack, isTrue);
      expect(provider.state.currentTurnIndex, 0);
      // Rolling a six grants a bonus roll.
      expect(provider.state.phase, LudoTurnPhase.waitingForRoll);

      provider.dispose();
    });
  });
}
