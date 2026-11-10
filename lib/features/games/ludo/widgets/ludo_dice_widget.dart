import 'dart:math' as math;

import 'package:flutter/material.dart';

class LudoDiceWidget extends StatefulWidget {
  final int? value;
  final bool isRolling;
  final bool isEnabled;
  final VoidCallback? onTap;
  final double size;
  final Color accentColor;

  const LudoDiceWidget({
    super.key,
    required this.value,
    this.isRolling = false,
    this.isEnabled = true,
    this.onTap,
    this.size = 54,
    this.accentColor = const Color(0xFF0088FF),
  });

  @override
  State<LudoDiceWidget> createState() => _LudoDiceWidgetState();
}

class _LudoDiceWidgetState extends State<LudoDiceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    if (widget.isRolling) {
      _animController.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant LudoDiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final val = widget.value ?? 6;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final t = _animController.value;
        final shake = widget.isRolling ? math.sin(t * math.pi * 10) * 0.18 : 0.0;
        final scale = widget.isRolling
            ? 1.0 + math.sin(t * math.pi) * 0.16
            : 1.0;
        final flip = widget.isRolling ? math.sin(t * math.pi * 6) * 0.25 : 0.0;

        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: shake,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateY(flip),
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.isEnabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isEnabled
                  ? [Colors.white, widget.accentColor.lighten(0.86)]
                  : [Colors.white, const Color(0xFFF1F5F9)],
            ),
            borderRadius: BorderRadius.circular(size * 0.26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              if (widget.isEnabled && !widget.isRolling)
                BoxShadow(
                  color: widget.accentColor.withValues(alpha: 0.42),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
            ],
            border: Border.all(
              color: widget.isEnabled
                  ? widget.accentColor.withValues(alpha: 0.38)
                  : const Color(0xFFE2E8F0),
              width: 1.3,
            ),
          ),
          child: CustomPaint(
            size: Size(size, size),
            painter: _DicePipPainter(
              value: val,
              color: widget.isEnabled
                  ? const Color(0xFF1E293B)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}

extension _ColorBrighten on Color {
  Color lighten(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}

class _DicePipPainter extends CustomPainter {
  final int value;
  final Color color;

  _DicePipPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final pipPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final pipRadius = size.width * 0.085;
    final p1 = size.width * 0.28;
    final p2 = size.width * 0.50;
    final p3 = size.width * 0.72;

    void draw(double x, double y) {
      canvas.drawCircle(Offset(x, y), pipRadius, pipPaint);
    }

    switch (value) {
      case 1:
        draw(p2, p2);
        break;
      case 2:
        draw(p1, p1);
        draw(p3, p3);
        break;
      case 3:
        draw(p1, p1);
        draw(p2, p2);
        draw(p3, p3);
        break;
      case 4:
        draw(p1, p1);
        draw(p3, p1);
        draw(p1, p3);
        draw(p3, p3);
        break;
      case 5:
        draw(p1, p1);
        draw(p3, p1);
        draw(p2, p2);
        draw(p1, p3);
        draw(p3, p3);
        break;
      case 6:
      default:
        draw(p1, p1);
        draw(p1, p2);
        draw(p1, p3);
        draw(p3, p1);
        draw(p3, p2);
        draw(p3, p3);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DicePipPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
