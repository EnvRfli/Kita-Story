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

  // Palette matched exactly to user's reference mockup
  static const valueColors = <int, Color>{
    2: Color(0xFF8ED1C6), // Light pastel cyan/teal
    4: Color(0xFF487B97), // Slate blue
    8: Color(0xFF6A984D), // Olive green
    16: Color(0xFFE5B540), // Warm amber/mustard
    32: Color(0xFFED832F), // Vibrant orange
    64: Color(0xFFDE6646), // Coral red-orange
    128: Color(0xFFDF2D41), // Vibrant crimson red
    256: Color(0xFFC01553), // Magenta/crimson
    512: Color(0xFF8F52D9), // Bright violet/purple
    1024: Color(0xFF5663CC), // Royal blue/indigo
    2048: Color(0xFF2E1C7E), // Deep dark indigo/navy
    4096: Color(0xFF00B0E8), // Bright sky cyan
    8192: Color(0xFF00A389), // Emerald teal
    16384: Color(0xFF3880F5), // Vibrant cobalt blue
    32768: Color(0xFF7047F6), // Rich purple
    65536: Color(0xFFA5D643), // Lime green
  };

  static const _overflowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E1C7E), Color(0xFF14041F)],
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

  static Color foregroundColorFor(int value) => Colors.white;

  @override
  Widget build(BuildContext context) {
    final scale = disableAnimations
        ? 1.0
        : isMerged
            ? 1.28
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
        curve: isMerged ? Curves.elasticOut : Curves.easeOut,
        tween: Tween<double>(begin: scale, end: 1),
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: child,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorFor(tile.value),
                  gradient: gradientFor(tile.value),
                  borderRadius: BorderRadius.circular(size * 0.16),
                  boxShadow: [
                    if (isMerged && !disableAnimations)
                      BoxShadow(
                        color: colorFor(tile.value).withValues(alpha: 0.55),
                        blurRadius: 14,
                        spreadRadius: 2,
                        offset: const Offset(0, 3),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
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
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (isMerged && !disableAnimations)
              Positioned(
                top: 4,
                right: 4,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, val, child) => Opacity(
                    opacity: 1.0 - (val * 0.6),
                    child: Transform.scale(
                      scale: 0.6 + (val * 0.4),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static double _fontSizeFor(int value, double size) {
    final digits = value.toString().length;
    final multiplier = switch (digits) {
      <= 2 => 0.44,
      3 => 0.36,
      4 => 0.30,
      5 => 0.25,
      _ => 0.20,
    };
    return size * multiplier;
  }
}
