import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/uno_card.dart';
import 'uno_card_widget.dart';

class UnoDrawPile extends StatelessWidget {
  final double width;
  final int deckCount;
  final bool active;
  final Animation<double>? pulse;
  final VoidCallback? onTap;

  const UnoDrawPile({
    super.key,
    required this.width,
    required this.deckCount,
    this.active = false,
    this.pulse,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget pile = UnoCardWidget(
      card: const UnoCard(id: 'deck-back', type: UnoCardType.wild),
      width: width,
      faceUp: false,
      playable: active,
    );

    if (active && pulse != null) {
      pile = ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.06).animate(pulse!),
        child: pile,
      );
    }

    return GestureDetector(
      onTap: active ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              pile,
              if (active)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(width * 0.14),
                        border: Border.all(
                          color: const Color(0xFFF9A825),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Text(
              '$deckCount kartu',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UnoDiscardPile extends StatelessWidget {
  final UnoCard? card;
  final double width;

  const UnoDiscardPile({super.key, required this.card, required this.width});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: card == null
          ? Container(
              key: const ValueKey('empty-discard'),
              width: width,
              height: width * 1.46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(width * 0.14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Text(
                  'UNO',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          : UnoCardWidget(
              key: ValueKey(card!.id),
              card: card!,
              width: width,
              playable: false,
            ),
    );
  }
}

class UnoColorPill extends StatelessWidget {
  final UnoColor? color;

  const UnoColorPill({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final value = color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: value?.primaryColor.withValues(alpha: 0.16) ??
            Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value?.primaryColor.withValues(alpha: 0.6) ??
              Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: value?.primaryColor ?? const Color(0xFF94A3B8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value?.label ?? 'Belum ada warna',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: value?.lightColor ?? const Color(0xFFCBD5E1),
            ),
          ),
        ],
      ),
    );
  }
}

class UnoPendingDrawBadge extends StatelessWidget {
  final int count;

  const UnoPendingDrawBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE53935).withValues(alpha: 0.6),
        ),
      ),
      child: Text(
        'Penalti +$count',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: Color(0xFFFFCDD2),
        ),
      ),
    );
  }
}

class UnoChainStrip extends StatelessWidget {
  final List<UnoCard> cards;
  final double width;

  const UnoChainStrip({super.key, required this.cards, required this.width});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final visible = cards.length > 6 ? cards.sublist(cards.length - 6) : cards;
    final totalWidth = width + (visible.length - 1) * (width * 0.58);
    return SizedBox(
      width: totalWidth,
      height: width * 1.46 + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(visible.length, (index) {
          return Positioned(
            left: index * (width * 0.58),
            top: (visible.length - 1 - index) * 1.2,
            child: Transform.rotate(
              angle: (index - visible.length / 2) * 0.025,
              child: UnoCardWidget(
                card: visible[index],
                width: width,
                playable: false,
                dimmed: index != visible.length - 1,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class UnoOpponentCardFan extends StatelessWidget {
  final int count;
  final double width;

  const UnoOpponentCardFan({
    super.key,
    required this.count,
    this.width = 24,
  });

  @override
  Widget build(BuildContext context) {
    final visible = math.min(count, 6);
    if (visible == 0) {
      return const SizedBox(width: 10, height: 1);
    }

    return SizedBox(
      width: width + (visible - 1) * (width * 0.5),
      height: width * 1.46,
      child: Stack(
        children: List.generate(visible, (index) {
          return Positioned(
            left: index * (width * 0.5),
            top: (index - (visible - 1) / 2).abs() * 1.4,
            child: Transform.rotate(
              angle: (index - (visible - 1) / 2) * 0.05,
              child: UnoCardWidget(
                card: const UnoCard(id: 'opp-back', type: UnoCardType.wild),
                width: width,
                faceUp: false,
                playable: false,
              ),
            ),
          );
        }),
      ),
    );
  }
}
