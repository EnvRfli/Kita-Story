import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/uno_card.dart';

class UnoCardWidget extends StatefulWidget {
  final UnoCard card;
  final double width;
  final bool faceUp;
  final bool playable;
  final bool dimmed;
  final bool elevated;
  final VoidCallback? onTap;

  const UnoCardWidget({
    super.key,
    required this.card,
    this.width = 78,
    this.faceUp = true,
    this.playable = true,
    this.dimmed = false,
    this.elevated = false,
    this.onTap,
  });

  @override
  State<UnoCardWidget> createState() => _UnoCardWidgetState();
}

class _UnoCardWidgetState extends State<UnoCardWidget> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = width * 1.46;

    return GestureDetector(
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : (widget.elevated ? 1.04 : 1),
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: widget.dimmed ? 0.42 : 1,
          duration: const Duration(milliseconds: 180),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(width * 0.14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: widget.elevated ? 18 : 10,
                  offset: Offset(0, widget.elevated ? 8 : 4),
                ),
                if (widget.playable && !widget.dimmed)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(width * 0.14),
              child: widget.faceUp ? _buildFace(width) : _buildBack(width),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFace(double width) {
    final card = widget.card;
    final isWild = card.isWild;
    final bodyColor = card.color?.primaryColor ?? const Color(0xFF171717);
    final darkColor = card.color?.darkColor ?? const Color(0xFF000000);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bodyColor, darkColor],
        ),
        border: Border.all(color: Colors.white, width: width * 0.045),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Transform.rotate(
              angle: -0.32,
              child: Container(
                margin: EdgeInsets.all(width * 0.11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(width * 0.55, width * 0.72),
                  ),
                ),
              ),
            ),
          ),
          if (isWild) _buildWildCenter(width),
          if (!isWild) _buildNumberCenter(width),
          Positioned(
            left: width * 0.08,
            top: width * 0.06,
            child: _cornerLabel(width, false),
          ),
          Positioned(
            right: width * 0.08,
            bottom: width * 0.06,
            child: Transform.rotate(
              angle: math.pi,
              child: _cornerLabel(width, true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cornerLabel(double width, bool mirrored) {
    final card = widget.card;
    final color = card.isWild ? Colors.white : (card.color?.darkColor ?? Colors.black);
    final text = card.isWild
        ? (card.type == UnoCardType.drawTwo ? '+2' : 'W')
        : card.symbol;

    return Text(
      text,
      style: TextStyle(
        fontSize: width * 0.15,
        fontWeight: FontWeight.w900,
        color: color,
        shadows: card.isWild
            ? [const Shadow(color: Colors.black54, blurRadius: 2)]
            : null,
      ),
    );
  }

  Widget _buildNumberCenter(double width) {
    final card = widget.card;
    final color = card.color?.darkColor ?? Colors.black;

    if (card.type == UnoCardType.skip) {
      return Center(
        child: Icon(Icons.block_rounded, size: width * 0.48, color: color),
      );
    }
    if (card.type == UnoCardType.reverse) {
      return Center(
        child: Icon(Icons.swap_horiz_rounded, size: width * 0.52, color: color),
      );
    }
    return Center(
      child: Text(
        card.symbol,
        style: TextStyle(
          fontSize: width * 0.42,
          fontWeight: FontWeight.w900,
          color: color,
          height: 1,
          letterSpacing: -1.5,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.12),
              offset: const Offset(1, 2),
              blurRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWildCenter(double width) {
    final isDrawTwo = widget.card.type == UnoCardType.drawTwo;
    final gridSize = width * (isDrawTwo ? 0.34 : 0.4);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: gridSize,
            height: gridSize,
            padding: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(width * 0.08),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _wildSwatch(UnoColor.red, width)),
                      SizedBox(width: width * 0.025),
                      Expanded(child: _wildSwatch(UnoColor.yellow, width)),
                    ],
                  ),
                ),
                SizedBox(height: width * 0.025),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _wildSwatch(UnoColor.blue, width)),
                      SizedBox(width: width * 0.025),
                      Expanded(child: _wildSwatch(UnoColor.green, width)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: width * 0.025),
          Text(
            isDrawTwo ? '+2' : 'WILD',
            style: TextStyle(
              fontSize: width * (isDrawTwo ? 0.15 : 0.12),
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.3,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 3)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wildSwatch(UnoColor color, double width) {
    return Container(
      decoration: BoxDecoration(
        color: color.primaryColor,
        borderRadius: BorderRadius.circular(width * 0.04),
      ),
    );
  }

  Widget _buildBack(double width) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF232323), Color(0xFF0B0B0B)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Transform.rotate(
              angle: -0.32,
              child: Container(
                margin: EdgeInsets.all(width * 0.1),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(width * 0.55, width * 0.72),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.1,
                vertical: width * 0.06,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(width * 0.07),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'UNO',
                    style: TextStyle(
                      fontSize: width * 0.17,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFE53935),
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'EXPRESS',
                    style: TextStyle(
                      fontSize: width * 0.06,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
