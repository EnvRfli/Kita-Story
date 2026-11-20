import 'package:flutter/material.dart';

class UnoInviteBanner extends StatelessWidget {
  final String hostName;
  final String? hostAvatarUrl;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  const UnoInviteBanner({
    super.key,
    required this.hostName,
    this.hostAvatarUrl,
    required this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return _UnoBannerShell(
      title: '$hostName mengajakmu main UNO!',
      subtitle: 'Ketuk untuk lihat ajakan',
      leadingEmoji: '🃏',
      avatarUrl: hostAvatarUrl,
      onTap: onTap,
      onDismiss: onDismiss,
      accentColor: const Color(0xFFE53935),
    );
  }
}

class UnoNoticeBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final Color accentColor;

  const UnoNoticeBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onTap,
    this.onDismiss,
    this.accentColor = const Color(0xFFE53935),
  });

  @override
  Widget build(BuildContext context) {
    return _UnoBannerShell(
      title: title,
      subtitle: subtitle,
      leadingEmoji: '🎴',
      onTap: onTap,
      onDismiss: onDismiss,
      accentColor: accentColor,
      actionLabel: actionLabel,
    );
  }
}

class UnoInviteDialog extends StatelessWidget {
  final String hostName;
  final String? hostAvatarUrl;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const UnoInviteDialog({
    super.key,
    required this.hostName,
    this.hostAvatarUrl,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _avatar(),
            const SizedBox(height: 16),
            Text(
              '$hostName mengajakmu main UNO!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                height: 1.2,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tumpuk kartu, balas draw, dan habiskan tangan duluan!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: onAccept,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Terima & Main',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: onReject,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Tolak dulu',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    final avatar = hostAvatarUrl;
    final hasAvatar = avatar != null && avatar.isNotEmpty;

    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFEBEE), Color(0xFFFFF8E1)],
        ),
        border: Border.all(
          color: const Color(0xFFE53935).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? Image.network(
              avatar,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return const Center(child: Text('🃏', style: TextStyle(fontSize: 38)));
  }
}

class _UnoBannerShell extends StatefulWidget {
  final String title;
  final String subtitle;
  final String leadingEmoji;
  final String? avatarUrl;
  final String? actionLabel;
  final Color accentColor;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _UnoBannerShell({
    required this.title,
    required this.subtitle,
    required this.leadingEmoji,
    this.avatarUrl,
    this.actionLabel,
    this.accentColor = const Color(0xFFE53935),
    this.onTap,
    this.onDismiss,
  });

  @override
  State<_UnoBannerShell> createState() => _UnoBannerShellState();
}

class _UnoBannerShellState extends State<_UnoBannerShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.55),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(22),
                child: Ink(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.16),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Row(
                      children: [
                        _avatar(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (widget.actionLabel != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.accentColor
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        widget.actionLabel!,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: widget.accentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (widget.onDismiss != null)
                          IconButton(
                            onPressed: widget.onDismiss,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                          )
                        else
                          Icon(
                            Icons.chevron_right_rounded,
                            color: widget.accentColor,
                            size: 22,
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

  Widget _avatar() {
    final avatar = widget.avatarUrl;
    final hasAvatar = avatar != null && avatar.isNotEmpty;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.accentColor.withValues(alpha: 0.22),
            widget.accentColor.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? Image.network(
              avatar,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _emojiAvatar(),
            )
          : _emojiAvatar(),
    );
  }

  Widget _emojiAvatar() {
    return Center(
      child: Text(widget.leadingEmoji, style: const TextStyle(fontSize: 24)),
    );
  }
}
