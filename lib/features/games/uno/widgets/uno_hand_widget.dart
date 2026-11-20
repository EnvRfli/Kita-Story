import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/uno_card.dart';
import 'uno_card_widget.dart';

class UnoHandWidget extends StatelessWidget {
  final List<UnoCard> cards;
  final Set<String> playableIds;
  final bool interactive;
  final double cardWidth;
  final double maxWidth;
  final ValueChanged<UnoCard> onCardTap;

  const UnoHandWidget({
    super.key,
    required this.cards,
    required this.playableIds,
    required this.interactive,
    required this.cardWidth,
    required this.maxWidth,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return SizedBox(height: cardWidth * 1.46);
    }

    final count = cards.length;
    final contentWidth = math.max(
      maxWidth,
      cardWidth + math.max(0, count - 1) * 34.0,
    );
    final step = count <= 1
        ? 0.0
        : math.min(
            cardWidth * 0.72,
            (contentWidth - cardWidth - 16) / (count - 1),
          );
    final totalWidth = cardWidth + step * (count - 1) + 16;
    final height = cardWidth * 1.46 + 26;

    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: math.max(totalWidth, maxWidth),
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(count, (index) {
              final card = cards[index];
              final playable = playableIds.contains(card.id) && interactive;
              final center = (count - 1) / 2;
              final distance = index - center;
              final top = 8 + distance.abs() * 2.4 - (playable ? 7 : 0);
              final left = 8 + index * step;

              return AnimatedPositioned(
                key: ValueKey(card.id),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: left,
                top: top,
                child: Transform.rotate(
                  angle: distance * 0.035,
                  alignment: Alignment.bottomCenter,
                  child: UnoCardWidget(
                    card: card,
                    width: cardWidth,
                    playable: playable,
                    dimmed: !playable,
                    elevated: playable,
                    onTap: () => onCardTap(card),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
