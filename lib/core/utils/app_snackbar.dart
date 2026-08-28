import 'package:flutter/material.dart';

enum SnackBarType { success, error, warning, info }

class AppSnackBar {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    // Dismiss any active toast immediately (No queueing)
    _dismissCurrent();

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Navigator.of(context, rootNavigator: true).overlay;

    if (overlay == null) return;

    final config = _getConfig(type);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopFloatingToast(
        message: message,
        title: title,
        config: config,
        duration: duration,
        onDismiss: () {
          if (_currentEntry == entry) {
            _dismissCurrent();
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void _dismissCurrent() {
    try {
      _currentEntry?.remove();
    } catch (_) {}
    _currentEntry = null;
  }

  static void success(BuildContext context, String message, {String? title}) {
    show(
      context,
      message: message,
      title: title ?? 'Yay! Berhasil',
      type: SnackBarType.success,
    );
  }

  static void error(BuildContext context, String message, {String? title}) {
    show(
      context,
      message: message,
      title: title ?? 'Ups, Perhatian',
      type: SnackBarType.error,
    );
  }

  static void warning(BuildContext context, String message, {String? title}) {
    show(
      context,
      message: message,
      title: title ?? 'Peringatan',
      type: SnackBarType.warning,
    );
  }

  static void info(BuildContext context, String message, {String? title}) {
    show(
      context,
      message: message,
      title: title,
      type: SnackBarType.info,
    );
  }

  static _SnackBarConfig _getConfig(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return const _SnackBarConfig(
          icon: Icons.check_circle_rounded,
          iconColor: Color(0xFF2E7D32),
          badgeBgColor: Color(0xFFE8F8EE),
          accentColor: Color(0xFF81C784),
        );
      case SnackBarType.error:
        return const _SnackBarConfig(
          icon: Icons.error_outline_rounded,
          iconColor: Color(0xFFD32F2F),
          badgeBgColor: Color(0xFFFFEBEE),
          accentColor: Color(0xFFEF9A9A),
        );
      case SnackBarType.warning:
        return const _SnackBarConfig(
          icon: Icons.warning_amber_rounded,
          iconColor: Color(0xFFE65100),
          badgeBgColor: Color(0xFFFFF3E0),
          accentColor: Color(0xFFFFCC80),
        );
      case SnackBarType.info:
        return const _SnackBarConfig(
          icon: Icons.auto_awesome_rounded,
          iconColor: Color(0xFF0288D1),
          badgeBgColor: Color(0xFFE1F5FE),
          accentColor: Color(0xFF81D4FA),
        );
    }
  }
}

class _TopFloatingToast extends StatefulWidget {
  final String message;
  final String? title;
  final _SnackBarConfig config;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopFloatingToast({
    required this.message,
    this.title,
    required this.config,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopFloatingToast> createState() => _TopFloatingToastState();
}

class _TopFloatingToastState extends State<_TopFloatingToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _animateOut();
      }
    });
  }

  Future<void> _animateOut() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.horizontal,
            onDismissed: (_) => widget.onDismiss(),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF432835), // Deep cozy pastel maroon
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            widget.config.accentColor.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color:
                              widget.config.accentColor.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Playful Icon Badge
                        Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            color: widget.config.badgeBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.config.icon,
                            color: widget.config.iconColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Message Content
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.title != null &&
                                  widget.title!.isNotEmpty) ...[
                                Text(
                                  widget.title!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: widget.config.accentColor,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                widget.message,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFFFF6F8),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Dismiss / Close Action
                        InkWell(
                          onTap: _animateOut,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFFFFF6F8),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnackBarConfig {
  final IconData icon;
  final Color iconColor;
  final Color badgeBgColor;
  final Color accentColor;

  const _SnackBarConfig({
    required this.icon,
    required this.iconColor,
    required this.badgeBgColor,
    required this.accentColor,
  });
}
