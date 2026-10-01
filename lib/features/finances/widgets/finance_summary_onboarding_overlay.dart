import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinanceSummaryOnboardingOverlay {
  static const String _prefKey = 'has_seen_finance_summary_date_onboarding_v1';

  static Future<void> checkAndShow(
    BuildContext context, {
    required GlobalKey targetKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(_prefKey) ?? false;
    if (hasSeen || !context.mounted) return;

    // Small delay to ensure layout is completely settled
    await Future.delayed(const Duration(milliseconds: 350));
    if (!context.mounted) return;

    final renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final targetOffset = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;
    final targetRect = targetOffset & targetSize;

    if (!context.mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Onboarding',
      barrierColor: Colors.transparent, // Background barrier drawn by CustomPainter
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        return _OnboardingDialogContent(
          targetRect: targetRect,
          onDismiss: () async {
            await prefs.setBool(_prefKey, true);
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
        );
      },
    );
  }
}

class _OnboardingDialogContent extends StatefulWidget {
  final Rect targetRect;
  final VoidCallback onDismiss;

  const _OnboardingDialogContent({
    required this.targetRect,
    required this.onDismiss,
  });

  @override
  State<_OnboardingDialogContent> createState() =>
      _OnboardingDialogContentState();
}

class _OnboardingDialogContentState extends State<_OnboardingDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final target = widget.targetRect;

    // Determine bubble position: below the target if target is in upper half
    final isBelow = target.bottom < screenSize.height * 0.65;
    final bubbleTop = isBelow ? target.bottom + 14 : null;
    final bubbleBottom = !isBelow ? screenSize.height - target.top + 14 : null;

    return Stack(
      children: [
        // 1. Semi-transparent backdrop with cutout on target
        GestureDetector(
          onTap: widget.onDismiss,
          child: CustomPaint(
            size: screenSize,
            painter: _SpotlightCutoutPainter(targetRect: target),
          ),
        ),

        // 2. Animated Speech Bubble Tooltip
        Positioned(
          left: 20,
          right: 20,
          top: bubbleTop,
          bottom: bubbleBottom,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Triangle Pointer Arrow
                    if (isBelow)
                      Align(
                        alignment: Alignment.center,
                        child: CustomPaint(
                          size: const Size(18, 10),
                          painter: _TrianglePainter(isPointingUp: true),
                        ),
                      ),

                    // Speech Bubble Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badge & Title
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7A00)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFFFF7A00),
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Filter Ringkasan Keuangan! ✨',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Description
                          const Text(
                            'Sekarang kamu bisa mengatur tanggal mulai siklus bulanan (misal tanggal 25) atau beralih melihat total pengeluaran & pemasukan dari awal data dicatat.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Button "Mengerti"
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.onDismiss,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF7A00),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 46),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Mengerti 👍',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!isBelow)
                      Align(
                        alignment: Alignment.center,
                        child: CustomPaint(
                          size: const Size(18, 10),
                          painter: _TrianglePainter(isPointingUp: false),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// CustomPainter for Spotlight cutout with rounded rectangle and highlight border
class _SpotlightCutoutPainter extends CustomPainter {
  final Rect targetRect;

  _SpotlightCutoutPainter({required this.targetRect});

  @override
  void paint(Canvas canvas, Size size) {
    const inflateAmount = 6.0;
    const cornerRadius = 18.0;

    final inflatedRect = targetRect.inflate(inflateAmount);
    final targetRRect =
        RRect.fromRectAndRadius(inflatedRect, const Radius.circular(cornerRadius));

    // Outer dark barrier with cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(targetRRect)
      ..fillType = PathFillType.evenOdd;

    final barrierPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, barrierPaint);

    // Glowing border around spotlight
    final borderPaint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawRRect(targetRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightCutoutPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}

/// Triangle pointer arrow for tooltip bubble
class _TrianglePainter extends CustomPainter {
  final bool isPointingUp;

  _TrianglePainter({required this.isPointingUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isPointingUp) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.isPointingUp != isPointingUp;
  }
}
