import 'package:flutter/material.dart';
import '../models/ludo_player.dart';

class LudoTokenWidget extends StatefulWidget {
  final LudoColor color;
  final bool isMovable;
  final int count;
  final double size;
  final VoidCallback? onTap;

  const LudoTokenWidget({
    super.key,
    required this.color,
    this.isMovable = false,
    this.count = 1,
    this.size = 22,
    this.onTap,
  });

  @override
  State<LudoTokenWidget> createState() => _LudoTokenWidgetState();
}

class _LudoTokenWidgetState extends State<LudoTokenWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isMovable) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant LudoTokenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMovable && !oldWidget.isMovable) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isMovable && oldWidget.isMovable) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final primary = widget.color.primaryColor;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = widget.isMovable ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.isMovable ? widget.onTap : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: primary,
              width: size * 0.18,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
              if (widget.isMovable)
                BoxShadow(
                  color: primary.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Center(
            child: Container(
              width: size * 0.45,
              height: size * 0.45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary,
              ),
              child: widget.count > 1
                  ? Center(
                      child: Text(
                        '${widget.count}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
