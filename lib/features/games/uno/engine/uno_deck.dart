import 'dart:math';

import '../models/uno_card.dart';

/// Client-side mirror of `uno_build_deck()` in Supabase. The real game is
/// shuffled and dealt server-side; this is used for tests and local tooling.
class UnoDeck {
  const UnoDeck._();

  static const int totalCards = 116;

  static List<UnoCard> build() {
    final cards = <UnoCard>[];

    for (final color in UnoColor.values) {
      cards.add(UnoCard(
        id: '${color.name}-0-1',
        color: color,
        type: UnoCardType.number,
        number: 0,
      ));

      for (var number = 1; number <= 3; number++) {
        for (var copy = 1; copy <= 3; copy++) {
          cards.add(UnoCard(
            id: '${color.name}-$number-$copy',
            color: color,
            type: UnoCardType.number,
            number: number,
          ));
        }
      }

      for (var number = 4; number <= 9; number++) {
        for (var copy = 1; copy <= 2; copy++) {
          cards.add(UnoCard(
            id: '${color.name}-$number-$copy',
            color: color,
            type: UnoCardType.number,
            number: number,
          ));
        }
      }

      for (var copy = 1; copy <= 2; copy++) {
        cards.add(UnoCard(
          id: '${color.name}-skip-$copy',
          color: color,
          type: UnoCardType.skip,
        ));
        cards.add(UnoCard(
          id: '${color.name}-reverse-$copy',
          color: color,
          type: UnoCardType.reverse,
        ));
      }

      cards.add(UnoCard(
        id: '${color.name}-draw_one-1',
        color: color,
        type: UnoCardType.drawOne,
      ));
    }

    for (var copy = 1; copy <= 4; copy++) {
      cards.add(UnoCard(
        id: 'wild-$copy',
        type: UnoCardType.wild,
      ));
      cards.add(UnoCard(
        id: 'draw_two-$copy',
        type: UnoCardType.drawTwo,
      ));
    }

    return cards;
  }

  static List<UnoCard> shuffled({Random? random}) {
    final deck = build();
    deck.shuffle(random ?? Random());
    return deck;
  }
}
