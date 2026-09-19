import 'dart:math';
import 'package:flutter/material.dart';

class LudoDiceWidget extends StatefulWidget {
  final int? value;
  final bool isRolling;
  final bool isEnabled;
  final VoidCallback? onTap;
  final double size;

  const LudoDiceWidget({
    super.key,
    required this.value,
    this.isRolling = false,
    this.isEnabled = true,
    this.onTap,
    this.size = 54,
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
      duration: const Duration(milliseconds: 400),
    );
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
        final shake = widget.isRolling
            ? sin(_animController.value * pi * 8) * 0.15
            : 0.0;
        final scale = widget.isRolling
            ? 1.0 + sin(_animController.value * pi) * 0.12
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: shake,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.isEnabled ? widget.onTap : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 0.26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              if (widget.isEnabled && !widget.isRolling)
                BoxShadow(
                  color: const Color(0xFF0088FF).withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
            ],
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: CustomPaint(
            size: Size(size, size),
            painter: _DicePipPainter(value: val),
          ),
        ),
      ),
    );
  }
}

class _DicePipPainter extends CustomPainter {
  final int value;

  _DicePipPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final pipPaint = Paint()
      ..color = const Color(0xFF1E293B)
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
      oldDelegate.value != value;
}
