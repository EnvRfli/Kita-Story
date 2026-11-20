import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/uno/models/uno_card.dart';
import 'package:kita_story/features/games/uno/widgets/uno_card_widget.dart';
import 'package:kita_story/features/games/uno/widgets/uno_hand_widget.dart';
import 'package:kita_story/features/games/uno/widgets/uno_table_widgets.dart';

void main() {
  testWidgets('UnoCardWidget renders a number card and receives taps', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: UnoCardWidget(
              card: const UnoCard(
                id: 'red-7-1',
                color: UnoColor.red,
                type: UnoCardType.number,
                number: 7,
              ),
              width: 80,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('7'), findsWidgets);
    await tester.tap(find.byType(UnoCardWidget));
    expect(tapped, isTrue);
  });

  testWidgets('UnoCardWidget renders wild +2 without crashing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: UnoCardWidget(
              card: UnoCard(id: 'wild-2-1', type: UnoCardType.drawTwo),
              width: 80,
            ),
          ),
        ),
      ),
    );

    expect(find.text('+2'), findsWidgets);
  });

  testWidgets('UnoCardWidget renders the card back when face down', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: UnoCardWidget(
              card: UnoCard(id: 'back', type: UnoCardType.wild),
              width: 80,
              faceUp: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('UNO'), findsOneWidget);
    expect(find.text('EXPRESS'), findsOneWidget);
  });

  testWidgets('UnoHandWidget forwards a tap on the last visible card', (
    tester,
  ) async {
    UnoCard? tapped;
    final cards = [
      const UnoCard(
        id: 'red-1-1',
        color: UnoColor.red,
        type: UnoCardType.number,
        number: 1,
      ),
      const UnoCard(
        id: 'blue-2-1',
        color: UnoColor.blue,
        type: UnoCardType.number,
        number: 2,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: UnoHandWidget(
              cards: cards,
              playableIds: {'blue-2-1'},
              interactive: true,
              cardWidth: 64,
              maxWidth: 260,
              onCardTap: (card) => tapped = card,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(UnoCardWidget).last, warnIfMissed: false);
    expect(tapped?.id, 'blue-2-1');
  });

  testWidgets('UnoChainStrip gets bounded width inside a Row', (tester) async {
    final cards = [
      const UnoCard(
        id: 'red-4-chain',
        color: UnoColor.red,
        type: UnoCardType.number,
        number: 4,
      ),
      const UnoCard(
        id: 'blue-4-chain',
        color: UnoColor.blue,
        type: UnoCardType.number,
        number: 4,
      ),
      const UnoCard(
        id: 'green-4-chain',
        color: UnoColor.green,
        type: UnoCardType.number,
        number: 4,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              const Expanded(child: Text('Giliran kamu')),
              UnoChainStrip(cards: cards, width: 26),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(UnoChainStrip), findsOneWidget);
  });
}
