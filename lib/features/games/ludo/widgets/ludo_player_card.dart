import 'package:flutter/material.dart';

import '../models/ludo_player.dart';
import 'ludo_dice_widget.dart';

enum LudoPlayerCardLayout {
  twoPlayerTop,
  twoPlayerBottom,
}

class LudoPlayerCard extends StatelessWidget {
  final LudoPlayer player;
  final bool isCurrentTurn;
  final int? diceValue;
  final bool isRolling;
  final bool canRoll;
  final VoidCallback? onRollTap;
  final LudoPlayerCardLayout layout;
  final bool isOnline;
  final bool isPartnerOnline;
  final String? turnLabel;

  const LudoPlayerCard({
    super.key,
    required this.player,
    required this.isCurrentTurn,
    this.diceValue,
    this.isRolling = false,
    this.canRoll = false,
    this.onRollTap,
    required this.layout,
    this.isOnline = false,
    this.isPartnerOnline = false,
    this.turnLabel,
  });

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case LudoPlayerCardLayout.twoPlayerTop:
        return _buildCard(isTop: true);
      case LudoPlayerCardLayout.twoPlayerBottom:
        return _buildCard(isTop: false);
    }
  }

  Widget _buildCard({required bool isTop}) {
    final borderColor = isCurrentTurn
        ? player.color.primaryColor
        : const Color(0xFFE2E8F0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: isCurrentTurn
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  player.color.lightColor,
                  Colors.white,
                ],
              )
            : null,
        color: isCurrentTurn ? null : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
          width: isCurrentTurn ? 1.8 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentTurn
                ? player.color.primaryColor.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isCurrentTurn ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isTop ? _buildTopContent() : _buildBottomContent(),
    );
  }

  Widget _buildTopContent() {
    return Row(
      children: [
        _buildDice(),
        const Spacer(),
        _buildIdentity(crossAxisAlignment: CrossAxisAlignment.end),
        const SizedBox(width: 10),
        _buildAvatar(),
      ],
    );
  }

  Widget _buildBottomContent() {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 10),
        _buildIdentity(crossAxisAlignment: CrossAxisAlignment.start),
        const Spacer(),
        _buildDice(),
      ],
    );
  }

  Widget _buildIdentity({required CrossAxisAlignment crossAxisAlignment}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            if (isOnline) ...[
              const SizedBox(width: 5),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPartnerOnline
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentTurn && turnLabel != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: player.color.primaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  turnLabel!,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: player.color.darkColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            _buildTokenDots(),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final avatar = player.avatarUrl;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: player.color.lightColor,
        border: Border.all(
          color: isCurrentTurn ? player.color.primaryColor : Colors.white,
          width: isCurrentTurn ? 2.5 : 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentTurn
                ? player.color.primaryColor.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: isCurrentTurn ? 12 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: avatar != null && avatar.isNotEmpty
          ? Image.network(
              avatar,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _defaultAvatar(),
            )
          : _defaultAvatar(),
    );
  }

  Widget _defaultAvatar() {
    return Center(
      child: Text(
        player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
        style: TextStyle(
          color: player.color.darkColor,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildTokenDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final token = player.tokens[index];
        final isHome = token.isHome;
        return Container(
          width: 8.5,
          height: 8.5,
          margin: const EdgeInsets.symmetric(horizontal: 2.2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isHome
                ? player.color.primaryColor
                : player.color.primaryColor.withValues(alpha: 0.3),
            border: Border.all(
              color: isHome ? player.color.darkColor : Colors.transparent,
              width: 1.0,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDice() {
    return LudoDiceWidget(
      value: diceValue,
      isRolling: isRolling && isCurrentTurn,
      isEnabled: canRoll && isCurrentTurn,
      onTap: onRollTap,
      size: 52,
      accentColor: player.color.primaryColor,
    );
  }
}
