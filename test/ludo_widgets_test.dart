import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/auth/providers/auth_provider.dart';
import 'package:kita_story/features/games/ludo/engine/ludo_board_path.dart';
import 'package:kita_story/features/games/ludo/engine/ludo_engine.dart';
import 'package:kita_story/features/games/ludo/models/ludo_game_state.dart';
import 'package:kita_story/features/games/ludo/models/ludo_motion.dart';
import 'package:kita_story/features/games/ludo/models/ludo_player.dart';
import 'package:kita_story/features/games/ludo/models/ludo_token.dart';
import 'package:kita_story/features/games/ludo/providers/ludo_game_provider.dart';
import 'package:kita_story/features/games/ludo/providers/ludo_invite_provider.dart';
import 'package:kita_story/features/games/ludo/ui/ludo_start_screen.dart';
import 'package:kita_story/features/games/ludo/widgets/ludo_board_widget.dart';
import 'package:kita_story/features/games/ludo/widgets/ludo_dice_widget.dart';
import 'package:kita_story/features/games/ludo/widgets/ludo_invite_banner.dart';
import 'package:kita_story/features/games/ludo/widgets/ludo_invite_dialog.dart';
import 'package:kita_story/features/games/ludo/widgets/ludo_player_card.dart';
import 'package:kita_story/features/games/ludo/widgets/ludo_token_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrapWithProviders({
  required Widget child,
  LudoGameProvider? gameProvider,
  LudoInviteProvider? inviteProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider<LudoGameProvider>(
        create: (_) => gameProvider ?? LudoGameProvider(),
      ),
      ChangeNotifierProvider<LudoInviteProvider>(
        create: (_) => inviteProvider ?? LudoInviteProvider(),
      ),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Ludo Widgets', () {
    testWidgets('LudoDiceWidget renders pips and responds to taps when enabled',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LudoDiceWidget(
                value: 5,
                isEnabled: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LudoDiceWidget), findsOneWidget);
      await tester.tap(find.byType(LudoDiceWidget));
      expect(tapped, isTrue);
    });

    testWidgets('LudoBoardWidget renders 15x15 board and selects movable token',
        (tester) async {
      final engine = LudoEngine();
      final state = engine.createInitialState(
        mode: LudoGameMode.offline2,
        player1Name: 'Alya',
        player2Name: 'Reza',
      );

      final rolledState = engine.handleDiceRoll(state, 6);
      int? selectedId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 360,
                child: LudoBoardWidget(
                  state: rolledState,
                  onTokenSelected: (id) => selectedId = id,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LudoBoardWidget), findsOneWidget);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(selectedId, isNotNull);
    });

    testWidgets('LudoBoardWidget completes step motion animation',
        (tester) async {
      final p1 = LudoPlayer.initial(
        id: 'p1',
        name: 'Alya',
        color: LudoColor.green,
      ).copyWith(
        tokens: [
          const LudoToken(id: 0, state: LudoTokenState.track, step: 10),
          const LudoToken(id: 1),
          const LudoToken(id: 2),
          const LudoToken(id: 3),
        ],
      );

      final state = LudoGameState(
        mode: LudoGameMode.offline2,
        players: [
          p1,
          LudoPlayer.initial(
            id: 'p2',
            name: 'Reza',
            color: LudoColor.blue,
          ),
        ],
        currentTurnIndex: 0,
        phase: LudoTurnPhase.waitingForTokenMove,
        diceValue: 3,
        lastRolledByIndex: 0,
        movableTokenIds: const [0],
      );

      final motion = LudoMotion(
        id: 'motion-1',
        color: LudoColor.green,
        tokenId: 0,
        path: LudoBoardPath.buildMovePath(
          color: LudoColor.green,
          tokenId: 0,
          fromState: LudoTokenState.track,
          fromStep: 10,
          diceRoll: 3,
        ),
        stepDurationMs: 60,
        fromTurnIndex: 0,
      );

      String? completedId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 360,
                child: LudoBoardWidget(
                  state: state,
                  motion: motion,
                  onMotionCompleted: (id) => completedId = id,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(completedId, motion.id);
    });

    testWidgets('LudoBoardWidget rotates the whole board for mirrored view',
        (tester) async {
      final state = LudoEngine().createInitialState(
        mode: LudoGameMode.onlineCouple,
        player1Name: 'Host',
        player2Name: 'Guest',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 360,
                child: LudoBoardWidget(
                  state: state,
                  rotationQuarterTurns: 2,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final rotatedBox = tester.widget<RotatedBox>(find.byType(RotatedBox));
      expect(rotatedBox.quarterTurns, 2);
    });

    testWidgets('LudoBoardWidget splits different colors sharing one cell',
        (tester) async {
      // Green step 0 and blue step 26 both land on global track index 13.
      final p1 = LudoPlayer.initial(
        id: 'p1',
        name: 'Alya',
        color: LudoColor.green,
      ).copyWith(
        tokens: [
          const LudoToken(id: 0, state: LudoTokenState.track, step: 0),
          const LudoToken(id: 1, state: LudoTokenState.home, step: 5),
          const LudoToken(id: 2, state: LudoTokenState.home, step: 5),
          const LudoToken(id: 3, state: LudoTokenState.home, step: 5),
        ],
      );
      final p2 = LudoPlayer.initial(
        id: 'p2',
        name: 'Reza',
        color: LudoColor.blue,
      ).copyWith(
        tokens: [
          const LudoToken(id: 0, state: LudoTokenState.track, step: 26),
          const LudoToken(id: 1, state: LudoTokenState.home, step: 5),
          const LudoToken(id: 2, state: LudoTokenState.home, step: 5),
          const LudoToken(id: 3, state: LudoTokenState.home, step: 5),
        ],
      );

      final state = LudoGameState(
        mode: LudoGameMode.offline2,
        players: [p1, p2],
        currentTurnIndex: 0,
        phase: LudoTurnPhase.waitingForRoll,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 360,
                child: LudoBoardWidget(state: state),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Two home stacks (one per color) plus two split tokens in the shared cell.
      expect(find.byType(LudoTokenWidget), findsNWidgets(4));
    });

    testWidgets('LudoPlayerCard renders two-player top and bottom layouts',
        (tester) async {
      final p1 = LudoPlayer.initial(
        id: 'p1',
        name: 'Alya',
        color: LudoColor.green,
      );
      final p2 = LudoPlayer.initial(
        id: 'p2',
        name: 'Reza',
        color: LudoColor.blue,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LudoPlayerCard(
                  player: p1,
                  isCurrentTurn: true,
                  diceValue: 6,
                  canRoll: true,
                  layout: LudoPlayerCardLayout.twoPlayerTop,
                  turnLabel: 'KAMU',
                ),
                LudoPlayerCard(
                  player: p2,
                  isCurrentTurn: false,
                  diceValue: null,
                  canRoll: false,
                  layout: LudoPlayerCardLayout.twoPlayerBottom,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alya'), findsOneWidget);
      expect(find.text('Reza'), findsOneWidget);
      expect(find.text('KAMU'), findsOneWidget);
      expect(find.byType(LudoDiceWidget), findsNWidgets(2));
    });

    testWidgets('LudoInviteBanner shows invitation and handles tap',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LudoInviteBanner(
              hostName: 'Sayang',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Sayang mengajak anda bermain Ludo sekarang!'),
        findsOneWidget,
      );
      expect(find.text('Ketuk untuk lihat ajakan'), findsOneWidget);

      await tester.tap(find.byType(LudoInviteBanner));
      expect(tapped, isTrue);
    });

    testWidgets('LudoInviteDialog handles accept and reject', (tester) async {
      var accepted = false;
      var rejected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LudoInviteDialog(
              hostName: 'Rafli',
              onAccept: () => accepted = true,
              onReject: () => rejected = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rafli mengajakmu main Ludo!'), findsOneWidget);

      await tester.tap(find.text('Terima dan Main'));
      expect(accepted, isTrue);

      await tester.tap(find.text('Tolak dulu'));
      expect(rejected, isTrue);
    });

    testWidgets('LudoStartScreen renders couple lobby and offline option',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          child: const LudoStartScreen(
            currentUserId: 'test-user',
            partnerName: 'Sayang',
            hasPartner: true,
            initialPoints: 125,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Ludo'), findsOneWidget);
      expect(find.text('Menang'), findsOneWidget);
      expect(find.text('Main Berdua di HP Ini'), findsOneWidget);
      expect(find.text('2 Pemain'), findsOneWidget);
    });
  });
}
