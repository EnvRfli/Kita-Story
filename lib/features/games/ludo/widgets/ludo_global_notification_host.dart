import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../models/ludo_game_state.dart';
import '../providers/ludo_game_provider.dart';
import '../providers/ludo_invite_provider.dart';
import 'ludo_invite_banner.dart';
import 'ludo_invite_dialog.dart';

class LudoGlobalNotificationHost extends StatefulWidget {
  final Widget child;

  const LudoGlobalNotificationHost({super.key, required this.child});

  @override
  State<LudoGlobalNotificationHost> createState() =>
      _LudoGlobalNotificationHostState();
}

class _LudoGlobalNotificationHostState extends State<LudoGlobalNotificationHost> {
  String? _lastInitializedKey;
  String? _dismissedInviteId;
  LudoInviteOutcome? _notice;
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
    final inviteProvider = context.watch<LudoInviteProvider>();
    final hasRunningGame = context.select<LudoGameProvider, bool>(
      (provider) => provider.hasActiveGame && !provider.state.isGameOver,
    );

    _initializeInvites(user?.id, partner?.id, partner?.name);
    final invite = inviteProvider.pendingInvite;
    final showInvite = invite != null &&
        invite.id != _dismissedInviteId &&
        !hasRunningGame;

    final outcome = inviteProvider.outcome;
    if (outcome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final taken = inviteProvider.takeOutcome();
        if (taken == null) return;
        final path = appRouter.routerDelegate.currentConfiguration.uri.path;
        if (path.startsWith('/ludo')) return;
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
              child: LudoInviteBanner(
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

  void _initializeInvites(String? userId, String? partnerId, String? partnerName) {
    if (userId == null) return;
    final key = '$userId:${partnerId ?? ''}:${partnerName ?? ''}';
    if (_lastInitializedKey == key) return;
    _lastInitializedKey = key;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LudoInviteProvider>().initialize(
            currentUserId: userId,
            partnerId: partnerId,
            partnerName: partnerName,
          );
    });
  }

  void _showNotice(LudoInviteOutcome outcome) {
    _noticeTimer?.cancel();
    setState(() => _notice = outcome);
    _noticeTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  Widget _buildNoticeBanner(LudoInviteOutcome outcome) {
    switch (outcome.type) {
      case LudoInviteOutcomeType.accepted:
        return LudoNoticeBanner(
          title: '${outcome.partnerName} menerima ajakanmu!',
          subtitle: 'Game seru kalian sudah siap dimulai.',
          actionLabel: 'Buka Game',
          accentColor: const Color(0xFF22C55E),
          onTap: _openGame,
          onDismiss: () => setState(() => _notice = null),
        );

      case LudoInviteOutcomeType.rejected:
        return LudoNoticeBanner(
          title: 'Yah, ${outcome.partnerName} menolak ajakanmu',
          subtitle: 'Jangan sedih, coba ajak lagi yuk.',
          actionLabel: 'Ajak Lagi',
          accentColor: const Color(0xFFFF7A00),
          onTap: _inviteAgain,
          onDismiss: () => setState(() => _notice = null),
        );

      case LudoInviteOutcomeType.expired:
        return LudoNoticeBanner(
          title: 'Ajakanmu kedaluwarsa',
          subtitle: 'Kirim ajakan baru biar pasangan langsung lihat.',
          actionLabel: 'Ajak Lagi',
          accentColor: const Color(0xFF0088FF),
          onTap: _inviteAgain,
          onDismiss: () => setState(() => _notice = null),
        );

      case LudoInviteOutcomeType.cancelled:
        return LudoNoticeBanner(
          title: 'Ajakan dibatalkan',
          subtitle: 'Buat ajakan baru kapan saja.',
          actionLabel: 'Ajak Lagi',
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
      builder: (dialogContext) => LudoInviteDialog(
        hostName: hostName,
        hostAvatarUrl: hostAvatar,
        onAccept: () async {
          Navigator.of(dialogContext).pop();
          await _acceptInvite();
        },
        onReject: () async {
          Navigator.of(dialogContext).pop();
          await context.read<LudoInviteProvider>().rejectInvite();
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
      final inviteProvider = context.read<LudoInviteProvider>();
      final gameProvider = context.read<LudoGameProvider>();

      final match = await inviteProvider.acceptInvite();
      if (match == null) {
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
        matchId: match.id,
        currentUserId: user.id,
        partnerId: partner?.id,
        partnerName: partner?.name,
        myColor: match.guestColor,
        initialState: LudoGameState.fromJson(match.gameState),
      );

      if (!mounted) return;
      appRouter.push('/ludo/game');
    } catch (e) {
      if (!mounted) return;
      final navContext = rootNavigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        AppSnackBar.error(navContext, 'Gagal memulai permainan: $e');
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
      final gameProvider = context.read<LudoGameProvider>();
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
      appRouter.push('/ludo/game');
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

  void _openGame() {
    setState(() => _notice = null);
    appRouter.push('/ludo/game');
  }
}
