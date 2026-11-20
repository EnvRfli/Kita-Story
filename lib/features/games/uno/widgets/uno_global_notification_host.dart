import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../providers/uno_game_provider.dart';
import '../providers/uno_invite_provider.dart';
import '../repositories/uno_repository.dart';
import 'uno_invite_banner.dart';

class UnoGlobalNotificationHost extends StatefulWidget {
  final Widget child;

  const UnoGlobalNotificationHost({super.key, required this.child});

  @override
  State<UnoGlobalNotificationHost> createState() =>
      _UnoGlobalNotificationHostState();
}

class _UnoGlobalNotificationHostState extends State<UnoGlobalNotificationHost> {
  String? _lastInitializedKey;
  String? _dismissedInviteId;
  UnoInviteOutcome? _notice;
  Timer? _noticeTimer;
  bool _actionInProgress = false;

  @override
  void dispose() {
    _noticeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUserProfile;
    final partner = auth.partnerProfile;
    final inviteProvider = context.watch<UnoInviteProvider>();
    final hasRunningGame = context.select<UnoGameProvider, bool>(
      (provider) => provider.hasActiveGame,
    );

    _initializeInvites(user?.id, partner?.id, partner?.name);

    final invite = inviteProvider.pendingInvite;
    final showInvite =
        invite != null && invite.id != _dismissedInviteId && !hasRunningGame;

    final outcome = inviteProvider.outcome;
    if (outcome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final taken = inviteProvider.takeOutcome();
        if (taken == null) return;
        final path = appRouter.routerDelegate.currentConfiguration.uri.path;
        if (path.startsWith('/uno')) return;
        _showNotice(taken);
      });
    }

    final hostName = partner?.name ?? inviteProvider.partnerName ?? 'Pasangan';
    final hostAvatar = partner?.photoUrl;

    return Stack(
      children: [
        widget.child,
        if (showInvite)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: UnoInviteBanner(
                hostName: hostName,
                hostAvatarUrl: hostAvatar,
                onTap: () => _openInviteDialog(hostName, hostAvatar),
                onDismiss: () {
                  setState(() => _dismissedInviteId = invite.id);
                  inviteProvider.dismissInvite();
                },
              ),
            ),
          ),
        if (_notice != null && !showInvite)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: _buildNoticeBanner(_notice!),
            ),
          ),
      ],
    );
  }

  void _initializeInvites(
    String? userId,
    String? partnerId,
    String? partnerName,
  ) {
    if (userId == null) return;
    final key = '$userId:${partnerId ?? ''}:${partnerName ?? ''}';
    if (_lastInitializedKey == key) return;
    _lastInitializedKey = key;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UnoInviteProvider>().initialize(
            currentUserId: userId,
            partnerId: partnerId,
            partnerName: partnerName,
          );
    });
  }

  void _showNotice(UnoInviteOutcome outcome) {
    _noticeTimer?.cancel();
    setState(() => _notice = outcome);
    _noticeTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  Widget _buildNoticeBanner(UnoInviteOutcome outcome) {
    switch (outcome.type) {
      case UnoInviteOutcomeType.accepted:
        return UnoNoticeBanner(
          title: '${outcome.partnerName} menerima ajakan UNO!',
          subtitle: 'Meja UNO kalian sudah siap.',
          actionLabel: 'Buka Game',
          accentColor: const Color(0xFF2E9E4F),
          onTap: _openGame,
          onDismiss: () => setState(() => _notice = null),
        );
      case UnoInviteOutcomeType.rejected:
        return UnoNoticeBanner(
          title: 'Yah, ${outcome.partnerName} menolak ajakanmu',
          subtitle: 'Jangan sedih, coba ajak lagi yuk.',
          actionLabel: 'Ajak Lagi',
          accentColor: const Color(0xFFF9A825),
          onTap: _inviteAgain,
          onDismiss: () => setState(() => _notice = null),
        );
      case UnoInviteOutcomeType.expired:
        return UnoNoticeBanner(
          title: 'Ajakan UNO kedaluwarsa',
          subtitle: 'Kirim ajakan baru biar pasangan langsung lihat.',
          actionLabel: 'Ajak Lagi',
          accentColor: const Color(0xFF1E88E5),
          onTap: _inviteAgain,
          onDismiss: () => setState(() => _notice = null),
        );
      case UnoInviteOutcomeType.cancelled:
        return UnoNoticeBanner(
          title: 'Ajakan UNO dibatalkan',
          subtitle: 'Buat ajakan baru kapan saja.',
          actionLabel: 'Ajak Lagi',
          accentColor: const Color(0xFF64748B),
          onTap: _inviteAgain,
          onDismiss: () => setState(() => _notice = null),
        );
    }
  }

  Future<void> _openInviteDialog(
    String hostName,
    String? hostAvatar,
  ) async {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    await showDialog<void>(
      context: navContext,
      barrierDismissible: false,
      builder: (dialogContext) => UnoInviteDialog(
        hostName: hostName,
        hostAvatarUrl: hostAvatar,
        onAccept: () async {
          Navigator.of(dialogContext).pop();
          await _acceptInvite();
        },
        onReject: () async {
          Navigator.of(dialogContext).pop();
          await context.read<UnoInviteProvider>().rejectInvite();
        },
      ),
    );
  }

  Future<void> _acceptInvite() async {
    if (_actionInProgress) return;
    _actionInProgress = true;
    try {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUserProfile;
      final partner = auth.partnerProfile;
      final inviteProvider = context.read<UnoInviteProvider>();
      final gameProvider = context.read<UnoGameProvider>();

      final snapshot = await inviteProvider.acceptInvite();
      if (snapshot == null) {
        if (!mounted) return;
        final navContext = rootNavigatorKey.currentContext;
        if (navContext != null && navContext.mounted) {
          AppSnackBar.warning(
            navContext,
            'Ajakan sudah tidak tersedia. Minta pasangan mengirim ulang ya.',
          );
        }
        return;
      }
      if (user == null) return;

      await gameProvider.startOnlineGame(
        matchId: snapshot.match.id,
        currentUserId: user.id,
        partnerId: partner?.id ?? snapshot.match.opponentOf(user.id),
        partnerName: partner?.name,
        snapshot: snapshot,
      );

      if (!mounted) return;
      appRouter.push('/uno/game');
    } catch (e) {
      if (!mounted) return;
      final navContext = rootNavigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        AppSnackBar.error(navContext, 'Gagal memulai UNO: $e');
      }
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> _inviteAgain() async {
    if (_actionInProgress) return;
    final auth = context.read<AuthProvider>();
    final user = auth.currentUserProfile;
    final partner = auth.partnerProfile;
    if (user == null || partner == null) return;

    _actionInProgress = true;
    try {
      final gameProvider = context.read<UnoGameProvider>();
      await gameProvider.createOnlineInvitation(
        hostId: user.id,
        hostName: user.name,
        hostAvatar: user.photoUrl,
        guestId: partner.id,
        guestName: partner.name,
        guestAvatar: partner.photoUrl,
      );

      if (!mounted) return;
      setState(() => _notice = null);
      appRouter.push('/uno/game');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        title: 'Gagal mengirim ajakan',
      );
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> _openGame() async {
    setState(() => _notice = null);
    final gameProvider = context.read<UnoGameProvider>();
    if (gameProvider.state == null) {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUserProfile;
      if (user != null) {
        final match = await UnoRepository().fetchActiveMatch(user.id);
        if (match != null) {
          await gameProvider.resumeMatch(
            matchId: match.id,
            currentUserId: user.id,
            partnerId: match.opponentOf(user.id),
            partnerName: auth.partnerProfile?.name,
          );
        }
      }
    }
    if (mounted) appRouter.push('/uno/game');
  }
}
