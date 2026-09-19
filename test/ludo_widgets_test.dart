import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/ludo/engine/ludo_engine.dart';
import 'package:kita_story/features/games/ludo/models/ludo_game_state.dart';
import 'package:kita_story/features/games/ludo/models/ludo_player.dart';
import 'package:kita_story/features/games/ludo/providers/ludo_game_provider.dart';
import 'package:kita_story/features/games/ludo/providers/ludo_invite_provider.dart';
import 'package:kita_story/features/games/ludo/ui/ludo_start_screen.dart';
import 'package:kita_story/features/games/ludo/widgets/ludo_board_widget.dart';
import 'package:kita_story/features/games/ludo/widgets/ludo_dice_widget.dart';
import 'package:kita_story/features/games/ludo/widgets/ludo_invite_banner.dart';
import 'package:kita_story/features/games/ludo/widgets/ludo_player_card.dart';
import 'package:provider/provider.dart';

Widget _wrapWithProviders({
  required Widget child,
  LudoGameProvider? gameProvider,
  LudoInviteProvider? inviteProvider,
}) {
  return MultiProvider(
    providers: [
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

      // Roll a 6 to make yard tokens movable
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

      // Tap on one of the green movable tokens in yard
      final tokenFinder = find.byType(GestureDetector);
      expect(tokenFinder, findsWidgets);

      await tester.tap(tokenFinder.first);
      await tester.pump();

      expect(selectedId, isNotNull);
    });

    testWidgets('LudoPlayerCard renders 2-player top and bottom layouts correctly',
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
      expect(find.byType(LudoDiceWidget), findsNWidgets(2));
    });

    testWidgets('LudoPlayerCard renders 4-player top and bottom dual cards',
        (tester) async {
      final p1 = LudoPlayer.initial(id: '1', name: 'P1', color: LudoColor.red);
      final p2 = LudoPlayer.initial(id: '2', name: 'P2', color: LudoColor.green);
      final p3 = LudoPlayer.initial(id: '3', name: 'P3', color: LudoColor.blue);
      final p4 = LudoPlayer.initial(id: '4', name: 'P4', color: LudoColor.yellow);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LudoPlayerCard(
                        player: p1,
                        isCurrentTurn: true,
                        layout: LudoPlayerCardLayout.fourPlayerTop,
                      ),
                    ),
                    Expanded(
                      child: LudoPlayerCard(
                        player: p2,
                        isCurrentTurn: false,
                        layout: LudoPlayerCardLayout.fourPlayerTop,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: LudoPlayerCard(
                        player: p3,
                        isCurrentTurn: false,
                        layout: LudoPlayerCardLayout.fourPlayerBottom,
                      ),
                    ),
                    Expanded(
                      child: LudoPlayerCard(
                        player: p4,
                        isCurrentTurn: false,
                        layout: LudoPlayerCardLayout.fourPlayerBottom,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('P1'), findsOneWidget);
      expect(find.text('P2'), findsOneWidget);
      expect(find.text('P3'), findsOneWidget);
      expect(find.text('P4'), findsOneWidget);
    });

    testWidgets('LudoInviteBanner displays invitation and handles accept/reject',
        (tester) async {
      var accepted = false;
      var rejected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LudoInviteBanner(
              partnerName: 'Sayang',
              onAccept: () => accepted = true,
              onReject: () => rejected = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sayang Mengajak Main!'), findsOneWidget);
      expect(find.text('Ayo tanding Ludo bersama!'), findsOneWidget);

      await tester.tap(find.text('Terima'));
      expect(accepted, isTrue);

      await tester.tap(find.text('Tolak'));
      expect(rejected, isTrue);
    });

    testWidgets('LudoStartScreen renders all mockup elements and opens mode sheet',
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
      expect(find.text('Mulai'), findsOneWidget);

      // Tap Mulai opens bottom sheet
      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Mode Permainan Ludo'), findsOneWidget);
      expect(find.text('Mode Offline (Pass & Play)'), findsOneWidget);
      expect(find.text('Mode Online (Bersama Pasangan)'), findsOneWidget);
      expect(find.text('2 Pemain'), findsOneWidget);
      expect(find.text('4 Pemain'), findsOneWidget);
    });
  });
}
