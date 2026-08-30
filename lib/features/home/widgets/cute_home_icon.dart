import 'package:flutter/material.dart';

class CuteHomeIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CuteHomeIcon({
    super.key,
    this.size = 25,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CuteHomeIconPainter(color: color),
    );
  }
}

class _CuteHomeIconPainter extends CustomPainter {
  final Color color;

  _CuteHomeIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Pentagonal outer house with rounded apex & joints
    path.moveTo(w * 0.15, h * 0.44);
    path.lineTo(w * 0.50, h * 0.12);
    path.lineTo(w * 0.85, h * 0.44);
    path.lineTo(w * 0.85, h * 0.88);

    // Bottom right to door
    path.lineTo(w * 0.63, h * 0.88);

    // Arched door
    path.lineTo(w * 0.63, h * 0.56);
    path.arcToPoint(
      Offset(w * 0.37, h * 0.56),
      radius: Radius.circular(w * 0.13),
      clockwise: false,
    );
    path.lineTo(w * 0.37, h * 0.88);

    // Door to bottom left
    path.lineTo(w * 0.15, h * 0.88);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CuteHomeIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
