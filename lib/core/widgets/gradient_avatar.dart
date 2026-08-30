import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class GradientAvatar extends StatefulWidget {
  final String? photoUrl;
  final double size;
  final double strokeWidth;
  final double gap;
  final Gradient gradient;
  final Widget? fallback;
  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enablePreviewOnLongPress;
  final String? previewTitle;

  const GradientAvatar({
    super.key,
    this.photoUrl,
    this.size = 85,
    this.strokeWidth = 2.5,
    this.gap = 3.0,
    this.gradient = AppColors.gradientAvatarRing,
    this.fallback,
    this.child,
    this.onTap,
    this.onLongPress,
    this.enablePreviewOnLongPress = true,
    this.previewTitle,
  });

  @override
  State<GradientAvatar> createState() => _GradientAvatarState();
}

class _GradientAvatarState extends State<GradientAvatar> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final innerSize = (widget.size - (widget.strokeWidth * 2) - (widget.gap * 2))
        .clamp(0.0, widget.size);

    final avatarBody = SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _GradientRingPainter(
          gradient: widget.gradient,
          strokeWidth: widget.strokeWidth,
        ),
        child: Center(
          child: SizedBox(
            width: innerSize,
            height: innerSize,
            child: ClipOval(
              child: widget.child ??
                  (widget.photoUrl != null && widget.photoUrl!.trim().isNotEmpty
                      ? Image.network(
                          widget.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              widget.fallback ?? _defaultAvatar(),
                        )
                      : (widget.fallback ?? _defaultAvatar())),
            ),
          ),
        ),
      ),
    );

    final hasAction = widget.onTap != null ||
        widget.onLongPress != null ||
        (widget.enablePreviewOnLongPress &&
            widget.photoUrl != null &&
            widget.photoUrl!.trim().isNotEmpty);

    if (!hasAction) return avatarBody;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: () {
        setState(() => _isPressed = false);
        HapticFeedback.mediumImpact();
        if (widget.onLongPress != null) {
          widget.onLongPress!();
        } else if (widget.enablePreviewOnLongPress &&
            widget.photoUrl != null &&
            widget.photoUrl!.trim().isNotEmpty) {
          showProfilePhotoPreview(
            context,
            photoUrl: widget.photoUrl,
            title: widget.previewTitle,
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.84 : 1.0,
          duration: const Duration(milliseconds: 130),
          child: avatarBody,
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: const Color(0xFF0B192C),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: Color(0xFFFFCC00),
          size: 40,
        ),
      ),
    );
  }
}

/// Generic Bouncy Pressable Wrapper that provides smooth scale down on long-press/tap
class BouncyPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final BorderRadius? borderRadius;

  const BouncyPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.93,
    this.borderRadius,
  });

  @override
  State<BouncyPressable> createState() => _BouncyPressableState();
}

class _BouncyPressableState extends State<BouncyPressable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPress: () {
        setState(() => _isPressed = false);
        HapticFeedback.mediumImpact();
        widget.onLongPress?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.86 : 1.0,
          duration: const Duration(milliseconds: 130),
          child: widget.child,
        ),
      ),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  final Gradient gradient;
  final double strokeWidth;

  _GradientRingPainter({
    required this.gradient,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter oldDelegate) {
    return oldDelegate.gradient != gradient ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Instagram-style Profile Photo Preview with Zoom & Pan Gestures
void showProfilePhotoPreview(
  BuildContext context, {
  required String? photoUrl,
  String? title,
}) {
  if (photoUrl == null || photoUrl.trim().isEmpty) return;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup Preview',
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, anim1, anim2) {
      final screenSize = MediaQuery.of(ctx).size;

      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Tap outside to close
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),

              // Centered Interactive Image
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null && title.isNotEmpty) ...[
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Zoomable Full Profile Container (Zooms the entire card container with original ratio)
                      InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.8,
                        maxScale: 4.5,
                        clipBehavior: Clip.none,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth:
                                (screenSize.width * 0.86).clamp(280.0, 360.0),
                            maxHeight: screenSize.height * 0.55,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.55),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22.5),
                            child: Image.network(
                              photoUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  width: 280,
                                  height: 280,
                                  color: const Color(0xFF0F172A),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                width: 280,
                                height: 280,
                                color: const Color(0xFF0F172A),
                                child: const Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFFFFCC00),
                                    size: 80,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Close Button (Top Right)
              Positioned(
                top: MediaQuery.of(ctx).padding.top + 12,
                right: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        ),
        child: FadeTransition(
          opacity: anim1,
          child: child,
        ),
      );
    },
  );
}
