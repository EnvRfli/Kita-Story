import 'package:flutter/material.dart';
import '../models/ludo_player.dart';
import 'ludo_dice_widget.dart';

enum LudoPlayerCardLayout {
  twoPlayerTop,
  twoPlayerBottom,
  fourPlayerTop,
  fourPlayerBottom,
}

class LudoPlayerCard extends StatelessWidget {
  final LudoPlayer player;
  final bool isCurrentTurn;
  final int? diceValue;
  final bool isRolling;
  final bool canRoll;
  final VoidCallback? onRollTap;
  final LudoPlayerCardLayout layout;

  const LudoPlayerCard({
    super.key,
    required this.player,
    required this.isCurrentTurn,
    this.diceValue,
    this.isRolling = false,
    this.canRoll = false,
    this.onRollTap,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case LudoPlayerCardLayout.twoPlayerTop:
        return _buildTwoPlayerTop();
      case LudoPlayerCardLayout.twoPlayerBottom:
        return _buildTwoPlayerBottom();
      case LudoPlayerCardLayout.fourPlayerTop:
        return _buildFourPlayerTop();
      case LudoPlayerCardLayout.fourPlayerBottom:
        return _buildFourPlayerBottom();
    }
  }

  Widget _buildAvatar() {
    final avatar = player.avatarUrl;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: player.color.lightColor,
        border: Border.all(
          color: isCurrentTurn ? player.color.primaryColor : Colors.white,
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
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
                : player.color.primaryColor.withValues(alpha: 0.35),
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
      size: 50,
    );
  }

  /// 2-Player Mode: Top Card (Screenshot 2: Green Pemain 1)
  Widget _buildTwoPlayerTop() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentTurn
            ? player.color.lightColor
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCurrentTurn
              ? player.color.primaryColor
              : const Color(0xFFE2E8F0),
          width: isCurrentTurn ? 1.8 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentTurn
                ? player.color.primaryColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Dice on Left
          _buildDice(),
          const Spacer(),
          // Name and Dots on Right
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                player.name,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              _buildTokenDots(),
            ],
          ),
          const SizedBox(width: 12),
          // Avatar
          _buildAvatar(),
        ],
      ),
    );
  }

  /// 2-Player Mode: Bottom Card (Screenshot 2: Blue Pemain 2)
  Widget _buildTwoPlayerBottom() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentTurn
            ? player.color.lightColor
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCurrentTurn
              ? player.color.primaryColor
              : const Color(0xFFE2E8F0),
          width: isCurrentTurn ? 1.8 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentTurn
                ? player.color.primaryColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar on Left
          _buildAvatar(),
          const SizedBox(width: 12),
          // Name and Dots
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              _buildTokenDots(),
            ],
          ),
          const Spacer(),
          // Dice on Right
          _buildDice(),
        ],
      ),
    );
  }

  /// 4-Player Mode: Top Dual Card (Screenshot 3: Red & Green)
  Widget _buildFourPlayerTop() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isCurrentTurn ? player.color.lightColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentTurn
              ? player.color.primaryColor
              : const Color(0xFFE2E8F0),
          width: isCurrentTurn ? 1.8 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentTurn
                ? player.color.primaryColor.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dice on top
          _buildDice(),
          const SizedBox(height: 6),
          // Token dots
          _buildTokenDots(),
          const SizedBox(height: 6),
          // Avatar & Name row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAvatar(),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 4-Player Mode: Bottom Dual Card (Screenshot 3: Blue & Yellow)
  Widget _buildFourPlayerBottom() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isCurrentTurn ? player.color.lightColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentTurn
              ? player.color.primaryColor
              : const Color(0xFFE2E8F0),
          width: isCurrentTurn ? 1.8 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentTurn
                ? player.color.primaryColor.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar & Name row on top
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAvatar(),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Token dots
          _buildTokenDots(),
          const SizedBox(height: 6),
          // Dice on bottom
          _buildDice(),
        ],
      ),
    );
  }
}
