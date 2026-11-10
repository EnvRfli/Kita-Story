import 'package:flutter/material.dart';

class LudoInviteBanner extends StatelessWidget {
  final String hostName;
  final String? hostAvatarUrl;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  const LudoInviteBanner({
    super.key,
    required this.hostName,
    this.hostAvatarUrl,
    required this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return LudoAnnouncementBanner(
      title: '$hostName mengajak anda bermain Ludo sekarang!',
      subtitle: 'Ketuk untuk lihat ajakan',
      leadingEmoji: '🎲',
      avatarUrl: hostAvatarUrl,
      onTap: onTap,
      onDismiss: onDismiss,
      accentColor: const Color(0xFF0088FF),
    );
  }
}

class LudoNoticeBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final Color accentColor;

  const LudoNoticeBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onTap,
    this.onDismiss,
    this.accentColor = const Color(0xFF0088FF),
  });

  @override
  Widget build(BuildContext context) {
    return LudoAnnouncementBanner(
      title: title,
      subtitle: subtitle,
      leadingEmoji: '💌',
      onTap: onTap,
      onDismiss: onDismiss,
      accentColor: accentColor,
      actionLabel: actionLabel,
    );
  }
}

class LudoAnnouncementBanner extends StatefulWidget {
  final String title;
  final String subtitle;
  final String leadingEmoji;
  final String? avatarUrl;
  final String? actionLabel;
  final Color accentColor;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const LudoAnnouncementBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leadingEmoji,
    this.avatarUrl,
    this.actionLabel,
    this.accentColor = const Color(0xFF0088FF),
    this.onTap,
    this.onDismiss,
  });

  @override
  State<LudoAnnouncementBanner> createState() => _LudoAnnouncementBannerState();
}

class _LudoAnnouncementBannerState extends State<LudoAnnouncementBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
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
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.16),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Row(
                      children: [
                        _buildAvatar(),
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
                                  Text(
                                    widget.subtitle,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
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

  Widget _buildAvatar() {
    final avatarUrl = widget.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

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
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _emojiAvatar(),
            )
          : _emojiAvatar(),
    );
  }

  Widget _emojiAvatar() {
    return Center(
      child: Text(
        widget.leadingEmoji,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
