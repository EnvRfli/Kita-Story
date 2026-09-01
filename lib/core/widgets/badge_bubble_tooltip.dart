import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows an interactive 3D styled Chat Bubble Tooltip with a pointer arrow
/// pointing directly to the target widget represented by [targetKey].
void showBadgeBubbleTooltip({
  required BuildContext context,
  required GlobalKey targetKey,
  required String title,
  required String description,
  required Widget icon,
  required List<Color> gradientColors,
  String? badgeLabel,
  String? footerTip,
  Widget? customStatWidget,
}) {
  final renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null || !renderBox.hasSize) return;

  HapticFeedback.lightImpact();

  final targetPosition = renderBox.localToGlobal(Offset.zero);
  final targetSize = renderBox.size;
  final targetRect = targetPosition & targetSize;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'BadgeTooltip',
    barrierColor: Colors.black.withValues(alpha: 0.32),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _BadgeBubbleTooltipOverlay(
        targetRect: targetRect,
        title: title,
        description: description,
        icon: icon,
        gradientColors: gradientColors,
        badgeLabel: badgeLabel,
        footerTip: footerTip,
        customStatWidget: customStatWidget,
      );
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.78, end: 1.0).animate(curved),
          alignment: Alignment(
            ((targetRect.center.dx / MediaQuery.of(dialogContext).size.width) *
                    2) -
                1.0,
            ((targetRect.center.dy / MediaQuery.of(dialogContext).size.height) *
                    2) -
                1.0,
          ),
          child: child,
        ),
      );
    },
  );
}

class _BadgeBubbleTooltipOverlay extends StatelessWidget {
  final Rect targetRect;
  final String title;
  final String description;
  final Widget icon;
  final List<Color> gradientColors;
  final String? badgeLabel;
  final String? footerTip;
  final Widget? customStatWidget;

  const _BadgeBubbleTooltipOverlay({
    required this.targetRect,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    this.badgeLabel,
    this.footerTip,
    this.customStatWidget,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    const double bubbleWidth = 310.0;
    const double arrowWidth = 18.0;
    const double arrowHeight = 10.0;
    const double marginHorizontal = 18.0;
    const double gapFromTarget = 8.0;

    // Determine horizontal position (clamp so bubble stays inside screen margins)
    double bubbleLeft = targetRect.center.dx - (bubbleWidth / 2);
    if (bubbleLeft < marginHorizontal) {
      bubbleLeft = marginHorizontal;
    } else if (bubbleLeft + bubbleWidth > screenSize.width - marginHorizontal) {
      bubbleLeft = screenSize.width - marginHorizontal - bubbleWidth;
    }

    // Determine vertical position (below target by default, or above if close to bottom)
    final bool isBelow =
        (targetRect.bottom + 220 < screenSize.height - padding.bottom);
    final double bubbleTop = isBelow
        ? (targetRect.bottom + gapFromTarget + arrowHeight)
        : (targetRect.top - gapFromTarget - arrowHeight - 210);

    // Arrow pointer horizontal center relative to the bubble
    final double arrowCenterXInBubble =
        (targetRect.center.dx - bubbleLeft).clamp(
      24.0,
      bubbleWidth - 24.0,
    );

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            // Positioned Bubble & Arrow
            Positioned(
              left: bubbleLeft,
              top: isBelow ? (targetRect.bottom + gapFromTarget) : bubbleTop,
              width: bubbleWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Arrow if bubble is below target
                  if (isBelow)
                    Padding(
                      padding: EdgeInsets.only(
                        left: math.max(
                            0, arrowCenterXInBubble - (arrowWidth / 2)),
                      ),
                      child: CustomPaint(
                        size: const Size(arrowWidth, arrowHeight),
                        painter: _TrianglePointerPainter(
                          color: Colors.white,
                          borderColor:
                              gradientColors[0].withValues(alpha: 0.35),
                          isPointingUp: true,
                        ),
                      ),
                    ),

                  // Main Bubble Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: gradientColors[0].withValues(alpha: 0.28),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withValues(alpha: 0.22),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 3D Header with Gradient
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.4),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Center(child: icon),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      if (badgeLabel != null)
                                        Text(
                                          badgeLabel!,
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.88),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bubble Body Content
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (customStatWidget != null) ...[
                                  customStatWidget!,
                                  const SizedBox(height: 12),
                                ],
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF334155),
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                if (footerTip != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: gradientColors[0]
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: gradientColors[0]
                                            .withValues(alpha: 0.18),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.lightbulb_outline_rounded,
                                          size: 14,
                                          color: gradientColors[0],
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            footerTip!,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: gradientColors[0],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Arrow if bubble is above target
                  if (!isBelow)
                    Padding(
                      padding: EdgeInsets.only(
                        left: math.max(
                            0, arrowCenterXInBubble - (arrowWidth / 2)),
                      ),
                      child: CustomPaint(
                        size: const Size(arrowWidth, arrowHeight),
                        painter: _TrianglePointerPainter(
                          color: Colors.white,
                          borderColor:
                              gradientColors[0].withValues(alpha: 0.35),
                          isPointingUp: false,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePointerPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool isPointingUp;

  _TrianglePointerPainter({
    required this.color,
    required this.borderColor,
    required this.isPointingUp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final paintStroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    if (isPointingUp) {
      // Triangle pointing up: tip at top center, base at bottom
      path.moveTo(size.width / 2, 0);
      path.lineTo(size.width, size.height + 0.5);
      path.lineTo(0, size.height + 0.5);
      path.close();
    } else {
      // Triangle pointing down: base at top, tip at bottom center
      path.moveTo(0, -0.5);
      path.lineTo(size.width, -0.5);
      path.lineTo(size.width / 2, size.height);
      path.close();
    }

    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintStroke);
  }

  @override
  bool shouldRepaint(covariant _TrianglePointerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isPointingUp != isPointingUp;
  }
}
