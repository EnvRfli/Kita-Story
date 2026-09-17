import 'package:flutter/material.dart';

import '../models/game_2048_tile.dart';

class Game2048TileWidget extends StatelessWidget {
  const Game2048TileWidget({
    super.key,
    required this.tile,
    required this.left,
    required this.top,
    required this.size,
    required this.disableAnimations,
    this.isMoving = false,
    this.isMerged = false,
    this.isSpawned = false,
    this.animationDuration = const Duration(milliseconds: 170),
  });

  static const valueColors = <int, Color>{
    2: Color(0xFFF4EAFB),
    4: Color(0xFFE4D5F3),
    8: Color(0xFFC49AE8),
    16: Color(0xFFAA72D6),
    32: Color(0xFF914CC4),
    64: Color(0xFF762EAB),
    128: Color(0xFF5D248B),
    256: Color(0xFF4B1D74),
    512: Color(0xFF3E1761),
    1024: Color(0xFF33134F),
    2048: Color(0xFF29103F),
    4096: Color(0xFF220C35),
    8192: Color(0xFF1C092C),
    16384: Color(0xFF160723),
    32768: Color(0xFF11051B),
    65536: Color(0xFF0D0314),
  };

  static const _overflowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF35115C), Color(0xFF14041F)],
  );

  final Game2048Tile tile;
  final double left;
  final double top;
  final double size;
  final bool disableAnimations;
  final bool isMoving;
  final bool isMerged;
  final bool isSpawned;
  final Duration animationDuration;

  static Color colorFor(int value) =>
      valueColors[value] ?? _overflowGradient.colors.first;

  static LinearGradient? gradientFor(int value) =>
      valueColors.containsKey(value) ? null : _overflowGradient;

  static Color foregroundColorFor(int value) =>
      value <= 4 ? const Color(0xFF35134F) : Colors.white;

  @override
  Widget build(BuildContext context) {
    final scale = disableAnimations
        ? 1.0
        : isMerged
            ? 1.14
            : isSpawned
                ? 0.0
                : 1.0;
    final duration = disableAnimations || !(isMoving || isMerged || isSpawned)
        ? Duration.zero
        : animationDuration;

    return AnimatedPositioned(
      duration: duration,
      curve: Curves.easeInOutCubic,
      left: left,
      top: top,
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        duration: duration,
        curve: isMerged ? Curves.easeOutBack : Curves.easeOut,
        tween: Tween<double>(begin: scale, end: 1),
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: child,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorFor(tile.value),
            gradient: gradientFor(tile.value),
            borderRadius: BorderRadius.circular(size * 0.11),
            boxShadow: const [
              BoxShadow(
                color: Color(0x260B0313),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.all(size * 0.08),
                child: Text(
                  '${tile.value}',
                  style: TextStyle(
                    color: foregroundColorFor(tile.value),
                    fontSize: _fontSizeFor(tile.value, size),
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static double _fontSizeFor(int value, double size) {
    final digits = value.toString().length;
    final multiplier = switch (digits) {
      <= 2 => 0.42,
      3 => 0.35,
      4 => 0.30,
      5 => 0.25,
      _ => 0.20,
    };
    return size * multiplier;
  }
}
