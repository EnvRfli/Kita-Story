import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WavyMenuCard extends StatefulWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;
  final double? imageTop;
  final double? imageBottom;
  final double? imageRight;
  final double? imageLeft;
  final double? imageWidth;
  final double? imageHeight;
  final Color waveColor;

  const WavyMenuCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onTap,
    this.imageTop,
    this.imageBottom,
    this.imageRight = 0,
    this.imageLeft,
    this.imageWidth = 70,
    this.imageHeight,
    this.waveColor = const Color(0xFFFF7A00),
  });

  @override
  State<WavyMenuCard> createState() => _WavyMenuCardState();
}

class _WavyMenuCardState extends State<WavyMenuCard>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  late AnimationController _iconPopController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotateAnimation;

  Offset _tapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();

    // 1. Press Scale Bounce
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 320),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeInOut,
        reverseCurve: Curves.elasticOut,
      ),
    );

    // 2. Internal Liquid Wave Ripple
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _waveAnimation = CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeOutCubic,
    );

    // 3. 3D Icon Playful Pop
    _iconPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _iconScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_iconPopController);

    _iconRotateAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.08)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.08, end: 0.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.05, end: 0.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_iconPopController);
  }

  @override
  void dispose() {
    _pressController.dispose();
    _waveController.dispose();
    _iconPopController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _tapPosition = details.localPosition;
    });
    HapticFeedback.lightImpact();
    _pressController.forward();
    _waveController.forward(from: 0.0);
    _iconPopController.forward(from: 0.0);
  }

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) {
        widget.onTap();
      }
    });
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2C5FF6).withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // 1. Interactive Wavy Liquid Ripple Layer
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, _) {
                      if (!_waveController.isAnimating &&
                          _waveAnimation.value == 0.0) {
                        return const SizedBox.shrink();
                      }
                      return CustomPaint(
                        painter: _WavyRipplePainter(
                          progress: _waveAnimation.value,
                          center: _tapPosition,
                          color: widget.waveColor,
                        ),
                      );
                    },
                  ),
                ),

                // 2. Menu Title
                Positioned(
                  left: 18,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF222222),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),

                // 3. Animated 3D Illustration with Pop & Tilt
                Positioned(
                  top: widget.imageTop,
                  bottom: widget.imageBottom ??
                      (widget.imageTop == null ? 0 : null),
                  right: widget.imageRight,
                  left: widget.imageLeft,
                  child: AnimatedBuilder(
                    animation: _iconPopController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _iconRotateAnimation.value,
                        child: Transform.scale(
                          scale: _iconScaleAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: (widget.imageTop == null &&
                            widget.imageBottom == null)
                        ? Center(
                            child: Image.asset(
                              widget.imagePath,
                              width: widget.imageWidth,
                              height: widget.imageHeight,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.widgets_rounded,
                                color: Color(0xFF6155F5),
                                size: 34,
                              ),
                            ),
                          )
                        : Image.asset(
                            widget.imagePath,
                            width: widget.imageWidth,
                            height: widget.imageHeight,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.widgets_rounded,
                              color: Color(0xFF6155F5),
                              size: 34,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Painter for Organic Multi-Ring Liquid Waves inside Container
class _WavyRipplePainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0
  final Offset center;
  final Color color;

  _WavyRipplePainter({
    required this.progress,
    required this.center,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) * 0.9;
    final currentRadius = progress * maxRadius;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    // Wave 1: Soft expanding radial wash
    final washPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (center.dx / size.width) * 2 - 1,
          (center.dy / size.height) * 2 - 1,
        ),
        radius: 0.8 * progress + 0.2,
        colors: [
          color.withValues(alpha: 0.22 * opacity),
          color.withValues(alpha: 0.08 * opacity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), washPaint);

    // Wave 2: Outer liquid sine-distorted wave ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.32 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * (1.0 - progress * 0.5);

    final path = Path();
    const int segments = 36;
    for (int i = 0; i <= segments; i++) {
      final theta = (i / segments) * 2 * math.pi;
      // Multi-frequency harmonic wave distortion for water wave look
      final waveOffset = math.sin(theta * 4 + progress * math.pi * 3) * (4.0 * (1.0 - progress));
      final r = currentRadius + waveOffset;
      final x = center.dx + r * math.cos(theta);
      final y = center.dy + r * math.sin(theta);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, ringPaint);

    // Wave 3: Secondary trailing ripple
    if (progress > 0.2) {
      final innerProgress = (progress - 0.2) / 0.8;
      final innerRadius = innerProgress * maxRadius * 0.75;
      final innerOpacity = (1.0 - innerProgress).clamp(0.0, 1.0);

      final innerRingPaint = Paint()
        ..color = color.withValues(alpha: 0.20 * innerOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final innerPath = Path();
      for (int i = 0; i <= segments; i++) {
        final theta = (i / segments) * 2 * math.pi;
        final waveOffset = math.cos(theta * 3 + innerProgress * math.pi * 2) * (3.0 * (1.0 - innerProgress));
        final r = innerRadius + waveOffset;
        final x = center.dx + r * math.cos(theta);
        final y = center.dy + r * math.sin(theta);
        if (i == 0) {
          innerPath.moveTo(x, y);
        } else {
          innerPath.lineTo(x, y);
        }
      }
      innerPath.close();
      canvas.drawPath(innerPath, innerRingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavyRipplePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.center != center ||
        oldDelegate.color != color;
  }
}
