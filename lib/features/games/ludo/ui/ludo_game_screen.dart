import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../models/ludo_game_state.dart';
import '../providers/ludo_game_provider.dart';
import '../utils/ludo_perspective.dart';
import '../widgets/ludo_board_widget.dart';
import '../widgets/ludo_game_over_dialog.dart';
import '../widgets/ludo_player_card.dart';

class LudoGameScreen extends StatefulWidget {
  const LudoGameScreen({super.key});

  @override
  State<LudoGameScreen> createState() => _LudoGameScreenState();
}

class _LudoGameScreenState extends State<LudoGameScreen>
    with WidgetsBindingObserver {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LudoGameProvider>();
      provider.initializeSounds();
      provider.refreshFromServer();
      if (!provider.hasActiveGame) {
        _goToLobby();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<LudoGameProvider>().refreshFromServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LudoGameProvider>();
    final state = provider.state;
    final hasGame = state.players.length >= 2;

    if (provider.isGameOverVisible && !_dialogShown && hasGame) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showGameOverDialog(context, provider);
      });
    }

    if (!provider.isGameOverVisible && _dialogShown) {
      _dialogShown = false;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmExit(context, provider);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFCFD),
        body: SafeArea(
          child: Stack(
            children: [
              if (hasGame)
                Column(
                  children: [
                    _buildAppBar(context, provider, state),
                    _buildStatusBar(provider, state),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildTwoPlayerLayout(provider, state),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                )
              else
                _buildEmptyState(),
              if (provider.incomingReaction != null)
                Positioned(
                  top: 70,
                  right: 22,
                  child: _ReactionBubble(
                    key: ValueKey(provider.incomingReaction),
                    emoji: provider.incomingReaction!,
                  ),
                ),
              if (provider.isWaitingForOpponent)
                Positioned.fill(child: _buildWaitingOverlay(provider)),
              if (provider.inviteRejected || provider.inviteExpired)
                Positioned.fill(child: _buildInviteFailedOverlay(provider)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    LudoGameProvider provider,
    LudoGameState state,
  ) {
    final partnerOnline = !provider.isOnline || provider.isPartnerOnline;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF1E293B),
              size: 22,
            ),
            onPressed: () => _confirmExit(context, provider),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ludo',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                if (provider.isOnline)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: partnerOnline
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        partnerOnline ? 'Lawan online' : 'Menunggu lawan',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (provider.isOnline)
            IconButton(
              tooltip: 'Kirim reaksi',
              icon: const Icon(
                Icons.add_reaction_rounded,
                color: Color(0xFF0088FF),
                size: 22,
              ),
              onPressed: () => _showReactionSheet(context, provider),
            ),
          IconButton(
            tooltip: provider.soundEnabled ? 'Matikan suara' : 'Nyalakan suara',
            icon: Icon(
              provider.soundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: const Color(0xFF64748B),
              size: 21,
            ),
            onPressed: provider.toggleSound,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(LudoGameProvider provider, LudoGameState state) {
    final message = state.statusMessage ??
        (provider.isMyTurn
            ? 'Giliran kamu! Lempar dadu dan gerakkan pion.'
            : 'Menunggu lawan bergerak...');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: Text(
          message,
          key: ValueKey(message),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: state.players.isNotEmpty
                ? state.currentPlayer.color.darkColor
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildTwoPlayerLayout(
    LudoGameProvider provider,
    LudoGameState state,
  ) {
    final displayTurn = provider.displayTurnIndex;

    final perspective = LudoPerspective.forPlayers(
      isOnline: provider.isOnline,
      players: state.players,
      myColor: provider.myColor,
    );
    final topIndex = perspective.topIndex;
    final bottomIndex = perspective.bottomIndex;
    final rotateBoard = perspective.rotateBoard;
    final myIndex = bottomIndex;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        LudoPlayerCard(
          player: state.players[topIndex],
          isCurrentTurn: displayTurn == topIndex,
          diceValue: provider.diceValueForPlayer(topIndex),
          isRolling: provider.isRollingForIndex(topIndex),
          canRoll: provider.canRoll() && displayTurn == topIndex,
          onRollTap: provider.rollDice,
          layout: LudoPlayerCardLayout.twoPlayerTop,
          isOnline: provider.isOnline,
          isPartnerOnline: provider.isPartnerOnline,
          turnLabel: _turnLabel(provider, isMyIndex: topIndex == myIndex),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: LudoBoardWidget(
              state: state,
              motion: provider.activeMotion,
              onTokenSelected: provider.selectToken,
              onMotionCompleted: provider.completeMotion,
              onStep: provider.playStepSound,
              rotationQuarterTurns: rotateBoard ? 2 : 0,
            ),
          ),
        ),
        LudoPlayerCard(
          player: state.players[bottomIndex],
          isCurrentTurn: displayTurn == bottomIndex,
          diceValue: provider.diceValueForPlayer(bottomIndex),
          isRolling: provider.isRollingForIndex(bottomIndex),
          canRoll: provider.canRoll() && displayTurn == bottomIndex,
          onRollTap: provider.rollDice,
          layout: LudoPlayerCardLayout.twoPlayerBottom,
          isOnline: provider.isOnline,
          isPartnerOnline: true,
          turnLabel: _turnLabel(provider, isMyIndex: bottomIndex == myIndex),
        ),
      ],
    );
  }

  String _turnLabel(LudoGameProvider provider, {required bool isMyIndex}) {
    if (!provider.isOnline) return 'GILIRAN';
    return isMyIndex ? 'KAMU' : 'LAWAN';
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🎲', style: TextStyle(fontSize: 48)),
          SizedBox(height: 10),
          Text(
            'Belum ada permainan aktif',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingOverlay(LudoGameProvider provider) {
    final partner = provider.partnerName ?? 'Pemain 2';
    return _OverlayShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BouncingDice(),
          const SizedBox(height: 18),
          Text(
            'Menunggu $partner menerima ajakan...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              height: 1.3,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Notifikasi sudah dikirim ke HP $partner. Sabar sedikit ya.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: provider.isOnline
                ? () async {
                    await provider.leaveGame();
                    if (mounted) _goToLobby();
                  }
                : null,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Batalkan Ajakan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteFailedOverlay(LudoGameProvider provider) {
    final partner = provider.partnerName ?? 'Pemain 2';
    final rejected = provider.inviteRejected;
    return _OverlayShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rejected ? '🙈' : '⌛',
            style: const TextStyle(fontSize: 54),
          ),
          const SizedBox(height: 12),
          Text(
            rejected
                ? '$partner menolak ajakanmu'
                : 'Ajakanmu kedaluwarsa',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tidak apa-apa, kamu masih bisa mengajak lagi kapan saja.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _inviteAgain(provider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Ajak Lagi',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0088FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await provider.leaveGame();
              if (mounted) _goToLobby();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteAgain(LudoGameProvider provider) async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUserProfile;
    final partner = auth.partnerProfile;
    if (user == null || partner == null) {
      AppSnackBar.warning(
        context,
        'Hubungkan akun dengan pemain lain dulu di menu Profil.',
      );
      return;
    }

    try {
      await provider.createOnlineInvitation(
        hostId: user.id,
        hostName: user.name,
        hostAvatar: user.photoUrl,
        guestId: partner.id,
        guestName: partner.name,
        guestAvatar: partner.photoUrl,
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, e.toString());
      }
    }
  }

  void _showReactionSheet(BuildContext context, LudoGameProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final emojis = ['❤️', '😂', '🔥', '👏', '🎉', '🎲', '😱', '👍'];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kirim Reaksi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: emojis.map((e) {
                  return GestureDetector(
                    onTap: () {
                      provider.sendReaction(e);
                      Navigator.of(context).pop();
                    },
                    child: Text(e, style: const TextStyle(fontSize: 30)),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGameOverDialog(BuildContext context, LudoGameProvider provider) {
    final winner = provider.state.winner ?? provider.state.currentPlayer;
    final isLocal = !provider.isOnline || provider.myColor == winner.color;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LudoGameOverDialog(
        winner: winner,
        isWinnerLocal: isLocal,
        isOnline: provider.isOnline,
        totalMoves: provider.movesCount,
        onPlayAgain: () async {
          Navigator.of(context).pop();
          await _playAgain(provider);
        },
        onExit: () async {
          Navigator.of(context).pop();
          await provider.leaveGame();
          if (mounted) _goToLobby();
        },
      ),
    );
  }

  Future<void> _playAgain(LudoGameProvider provider) async {
    if (!provider.isOnline) {
      final players = provider.state.players;
      await provider.startOfflineGame(
        mode: LudoGameMode.offline2,
        player1Name: players[0].name,
        player1Avatar: players[0].avatarUrl,
        player2Name: players[1].name,
        player2Avatar: players[1].avatarUrl,
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.currentUserProfile;
    final partner = auth.partnerProfile;
    if (user == null || partner == null) return;

    try {
      await provider.createOnlineInvitation(
        hostId: user.id,
        hostName: user.name,
        hostAvatar: user.photoUrl,
        guestId: partner.id,
        guestName: partner.name,
        guestAvatar: partner.photoUrl,
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, e.toString());
      }
    }
  }

  void _confirmExit(BuildContext context, LudoGameProvider provider) {
    if (!provider.hasActiveGame) {
      _goToLobby();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          provider.isWaitingForOpponent
              ? 'Batalkan ajakan?'
              : 'Keluar dari Ludo?',
        ),
        content: Text(
          provider.isWaitingForOpponent
              ? 'Ajakan yang belum diterima akan dibatalkan.'
              : provider.isOnline
                  ? 'Jika kamu keluar, pertandingan ini akan dinyatakan menyerah.'
                  : 'Kemajuan permainan offline tersimpan di perangkatmu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await provider.leaveGame(
                confirmSurrender:
                    !provider.isWaitingForOpponent && !provider.state.isGameOver,
              );
              if (mounted) _goToLobby();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _goToLobby() {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      context.go('/ludo');
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

class _OverlayShell extends StatelessWidget {
  final Widget child;

  const _OverlayShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFCFCFD).withValues(alpha: 0.9),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 34),
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BouncingDice extends StatefulWidget {
  const _BouncingDice();

  @override
  State<_BouncingDice> createState() => _BouncingDiceState();
}

class _BouncingDiceState extends State<_BouncingDice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -8 * _controller.value),
          child: Transform.rotate(
            angle: (_controller.value - 0.5) * 0.3,
            child: child,
          ),
        );
      },
      child: const Text('🎲', style: TextStyle(fontSize: 54)),
    );
  }
}

class _ReactionBubble extends StatelessWidget {
  final String emoji;

  const _ReactionBubble({super.key, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.2, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Text(emoji, style: const TextStyle(fontSize: 30)),
    );
  }
}
