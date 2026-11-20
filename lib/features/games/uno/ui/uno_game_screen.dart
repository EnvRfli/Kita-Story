import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../models/uno_action.dart';
import '../models/uno_card.dart';
import '../models/uno_game_state.dart';
import '../models/uno_match_model.dart';
import '../providers/uno_game_provider.dart';
import '../services/uno_sound_service.dart';
import '../widgets/uno_card_widget.dart';
import '../widgets/uno_color_picker.dart';
import '../widgets/uno_game_over_dialog.dart';
import '../widgets/uno_hand_widget.dart';
import '../widgets/uno_rules_sheet.dart';
import '../widgets/uno_table_widgets.dart';

class UnoGameScreen extends StatefulWidget {
  const UnoGameScreen({super.key});

  @override
  State<UnoGameScreen> createState() => _UnoGameScreenState();
}

class _UnoGameScreenState extends State<UnoGameScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _discardKey = GlobalKey();
  final GlobalKey _drawKey = GlobalKey();
  final GlobalKey _opponentKey = GlobalKey();
  final GlobalKey _handKey = GlobalKey();

  UnoGameProvider? _provider;
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  String? _lastActionId;
  String? _lastError;
  int? _lastMyCardCount;
  int? _lastOpponentCardCount;
  bool _gameOverShown = false;
  bool _pauseDialogShown = false;
  bool _resumeDialogShown = false;
  bool _exitDialogShown = false;
  bool _rematchLoading = false;
  OverlayEntry? _flightEntry;
  OverlayEntry? _momentEntry;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _provider = context.read<UnoGameProvider>();
      _provider!.addListener(_onProviderChanged);
      final state = _provider!.state;
      _lastActionId = state?.match.lastAction?['id'] as String?;
      _lastMyCardCount = state?.myCardCount;
      _lastOpponentCardCount = state?.opponentCardCount;
      _lastError = _provider!.lastError;
      _onProviderChanged();
    });
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChanged);
    _flightEntry?.remove();
    _flightEntry = null;
    _momentEntry?.remove();
    _momentEntry = null;
    _pulseController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    final provider = _provider;
    if (provider == null || !mounted) return;
    final state = provider.state;
    if (state == null) {
      _lastMyCardCount = null;
      _lastOpponentCardCount = null;
      return;
    }

    if (state.match.status == UnoMatchStatus.inProgress &&
        _gameOverShown) {
      _gameOverShown = false;
    }

    final lastActionJson = state.match.lastAction;
    final actionId = lastActionJson?['id'] as String?;
    if (actionId != null && actionId != _lastActionId) {
      _lastActionId = actionId;
      final action = UnoAction.fromJson(lastActionJson!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _animateAction(action, state);
      });
    }

    // Fire the center "UNO!" notification only on the 2 -> 1 transition.
    // Never on load, resume, or repeated rebuilds that are already at 1.
    final myCount = state.myCardCount;
    final opponentCount = state.opponentCardCount;
    if (_lastMyCardCount == 2 && myCount == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showUnoLeftMoment(mine: true);
      });
    }
    if (_lastOpponentCardCount == 2 && opponentCount == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showUnoLeftMoment(mine: false);
      });
    }
    _lastMyCardCount = myCount;
    _lastOpponentCardCount = opponentCount;

    if (provider.lastError != null && provider.lastError != _lastError) {
      _lastError = provider.lastError;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppSnackBar.warning(context, provider.lastError!);
        _lastError = null;
        provider.clearError();
      });
    }

    if (state.isGameOver && !_gameOverShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showGameOver();
      });
    }
    if (state.isPauseRequestForMe && !_pauseDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showPauseDialog();
      });
    }
    if (state.isResumeRequestForMe && !_resumeDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showResumeDialog();
      });
    }
    if ((provider.inviteRejected || provider.inviteExpired) &&
        !_exitDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showInviteEnded(provider.inviteRejected);
      });
    }
  }

  Future<void> _showInviteEnded(bool rejected) async {
    if (_exitDialogShown || !mounted) return;
    _exitDialogShown = true;
    final provider = _provider;
    if (provider == null) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(rejected ? 'Ajakan ditolak' : 'Ajakan berakhir'),
        content: Text(
          rejected
              ? 'Pasangan menolak ajakan UNO. Coba ajak lagi nanti ya.'
              : 'Ajakan UNO sudah kedaluwarsa atau dibatalkan.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
    await provider.disconnectSession();
    if (mounted) context.go('/uno');
  }

  // --- Animation helpers ---------------------------------------------------

  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Rect _cardRect(Rect area, {double maxWidth = 60}) {
    final width = math.min(maxWidth, area.width * 0.8);
    final height = width * 1.46;
    return Rect.fromCenter(
      center: area.center,
      width: width,
      height: height,
    );
  }

  void _animateAction(UnoAction action, UnoGameState state) {
    final discardArea = _rectOf(_discardKey);
    if (discardArea == null) return;
    final discardRect = _cardRect(discardArea, maxWidth: 76);
    final isMine = action.actorId == state.myUserId;

    switch (action.type) {
      case 'play':
      case 'draw_response':
        final card = action.card;
        if (card == null) return;
        final sourceArea = isMine ? _rectOf(_handKey) : _rectOf(_opponentKey);
        if (sourceArea == null) return;
        _flyCard(
          from: _cardRect(sourceArea, maxWidth: 62),
          to: discardRect,
          card: card,
          faceUp: true,
        );
        break;
      case 'draw':
      case 'draw_penalty':
        final drawArea = _rectOf(_drawKey);
        if (drawArea == null) return;
        final targetArea = isMine ? _rectOf(_handKey) : _rectOf(_opponentKey);
        if (targetArea == null) return;
        _flyCard(
          from: _cardRect(drawArea, maxWidth: 62),
          to: _cardRect(targetArea, maxWidth: 52),
          card: const UnoCard(id: 'flight-back', type: UnoCardType.wild),
          faceUp: false,
        );
        break;
      default:
        break;
    }
  }

  void _showUnoLeftMoment({required bool mine}) {
    final opponentName = context.read<AuthProvider>().partnerProfile?.name ??
        _provider?.partnerName ??
        'Lawan';
    _showUnoMoment(
      badge: 'UNO!',
      title: mine ? 'Kamu tinggal 1 kartu!' : '$opponentName tinggal 1 kartu!',
      subtitle: mine
          ? 'Fokus. Habiskan kartu terakhirmu!'
          : 'Waspada, kartu terakhir lawan bisa habis kapan saja.',
      color: mine ? const Color(0xFFE53935) : const Color(0xFFF9A825),
    );
    unawaited(UnoSoundService.instance.play(UnoSfx.unoCall));
    HapticFeedback.mediumImpact();
  }

  void _showUnoMoment({
    required String badge,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    _momentEntry?.remove();
    _momentEntry = null;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _UnoMomentOverlay(
        badge: badge,
        title: title,
        subtitle: subtitle,
        color: color,
        onDone: () {
          entry.remove();
          if (identical(_momentEntry, entry)) _momentEntry = null;
        },
      ),
    );
    _momentEntry = entry;
    overlay.insert(entry);
  }

  void _flyCard({
    required Rect from,
    required Rect to,
    required UnoCard card,
    required bool faceUp,
  }) {
    _flightEntry?.remove();
    _flightEntry = null;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          _FlyingCard(
            from: from,
            to: to,
            card: card,
            faceUp: faceUp,
            onDone: () {
              entry.remove();
              if (identical(_flightEntry, entry)) _flightEntry = null;
            },
          ),
        ],
      ),
    );
    _flightEntry = entry;
    overlay.insert(entry);
  }

  // --- Dialogs -------------------------------------------------------------

  Future<void> _showGameOver() async {
    if (_gameOverShown || !mounted) return;
    _gameOverShown = true;
    final provider = _provider!;
    final state = provider.state;
    if (state == null) return;

    final auth = context.read<AuthProvider>();
    final myName = auth.currentUserProfile?.name ?? 'Kamu';
    final opponentName =
        auth.partnerProfile?.name ?? provider.partnerName ?? 'Lawan';
    final winnerName = state.didIWin ? myName : opponentName;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => UnoGameOverDialog(
        winnerName: winnerName,
        isWinnerLocal: state.didIWin,
        totalMoves: provider.movesCount,
        rematchWaiting: _rematchLoading,
        onRematch: () async {
          Navigator.of(dialogContext).pop();
          setState(() => _rematchLoading = true);
          final snapshot = await provider.rematch();
          if (!mounted) return;
          setState(() {
            _rematchLoading = false;
            _gameOverShown = false;
          });
          if (snapshot == null && mounted) {
            AppSnackBar.warning(
              context,
              provider.lastError ?? 'Gagal mengirim rematch.',
            );
          }
        },
        onExit: () async {
          Navigator.of(dialogContext).pop();
          await provider.disconnectSession();
          if (mounted) context.go('/uno');
        },
      ),
    );
  }

  Future<void> _showPauseDialog() async {
    if (_pauseDialogShown || !mounted) return;
    _pauseDialogShown = true;
    final provider = _provider!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lawan minta pause'),
        content: const Text(
          'Setujui untuk menghentikan permainan sementara? State kartu tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              provider.pauseGame('reject');
            },
            child: const Text('Tolak'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              provider.pauseGame('approve');
            },
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
    _pauseDialogShown = false;
  }

  Future<void> _showResumeDialog() async {
    if (_resumeDialogShown || !mounted) return;
    _resumeDialogShown = true;
    final provider = _provider!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lawan ingin melanjutkan'),
        content: const Text('Setujui untuk lanjut bermain UNO?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              provider.pauseGame('resume_reject');
            },
            child: const Text('Nanti dulu'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              provider.pauseGame('resume_approve');
            },
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    _resumeDialogShown = false;
  }

  Future<void> _confirmExit() async {
    if (_exitDialogShown || !mounted) return;
    final provider = _provider;
    if (provider == null) return;
    final state = provider.state;
    if (state == null) {
      context.go('/uno');
      return;
    }
    if (state.isGameOver) {
      await provider.disconnectSession();
      if (mounted) context.go('/uno');
      return;
    }

    _exitDialogShown = true;
    final active = state.match.status == UnoMatchStatus.inProgress ||
        state.match.status == UnoMatchStatus.paused;
    final shouldSurrender = active;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(provider.isWaitingForOpponent ? 'Batalkan ajakan?' : 'Keluar dari UNO?'),
        content: Text(
          provider.isWaitingForOpponent
              ? 'Ajakan yang belum diterima akan dibatalkan.'
              : shouldSurrender
                  ? 'Kamu akan dianggap menyerah dan lawan menang.'
                  : 'Permainan akan ditutup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await provider.leaveGame(confirmSurrender: shouldSurrender);
              if (mounted) context.go('/uno');
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    _exitDialogShown = false;
  }

  Future<void> _openReactions() async {
    final provider = _provider;
    if (provider == null) return;
    const emojis = ['👍', '😂', '😱', '🔥', '😭', '🎉'];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Kirim reaksi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: emojis.map((emoji) {
                  return InkWell(
                    onTap: () {
                      provider.sendReaction(emoji);
                      Navigator.of(ctx).pop();
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickColorAndPlay(UnoCard card) async {
    final color = await showUnoColorPicker(context, card: card);
    if (color == null || !mounted) return;
    await _provider?.playCard(card, chosenColor: color);
  }

  Future<void> _onCardTap(UnoCard card) async {
    final provider = _provider;
    final state = provider?.state;
    if (provider == null || state == null || provider.busy) return;

    if (!state.isMyAction) {
      AppSnackBar.warning(context, 'Tunggu giliran lawan dulu ya.');
      return;
    }
    if (!provider.engine.canPlayCard(state, card)) {
      AppSnackBar.warning(context, 'Kartu itu belum cocok dengan meja.');
      return;
    }

    if (card.isWild) {
      await _pickColorAndPlay(card);
    } else {
      await provider.playCard(card);
    }
  }

  // --- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UnoGameProvider>();
    final auth = context.watch<AuthProvider>();
    final state = provider.state;

    if (state == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🃏', style: TextStyle(fontSize: 54)),
                const SizedBox(height: 12),
                const Text(
                  'Tidak ada permainan UNO aktif',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/uno'),
                  child: const Text('Kembali ke Lobby'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final myName = auth.currentUserProfile?.name ?? 'Kamu';
    final opponentName = auth.partnerProfile?.name ??
        provider.partnerName ??
        'Lawan';
    final myAvatar = auth.currentUserProfile?.photoUrl;
    final opponentAvatar = auth.partnerProfile?.photoUrl;
    final size = MediaQuery.sizeOf(context);
    final cardWidth = (size.width * 0.16).clamp(54.0, 74.0);
    final isWaiting = provider.isWaitingForOpponent &&
        state.match.status == UnoMatchStatus.invited;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: Stack(
          children: [
            _background(),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(provider, state),
                  _buildOpponentPanel(
                    state,
                    opponentName,
                    opponentAvatar,
                  ),
                  Expanded(
                    child: _buildTable(provider, state, cardWidth),
                  ),
                  _buildStatusArea(provider, state, opponentName),
                  _buildMyPanel(provider, state, myName, myAvatar),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
                    child: UnoHandWidget(
                      key: _handKey,
                      cards: provider.displayHand,
                      playableIds: provider.engine
                          .playableCards(state)
                          .map((c) => c.id)
                          .toSet(),
                      interactive: state.isMyAction && !provider.busy,
                      cardWidth: cardWidth,
                      maxWidth: size.width - 16,
                      onCardTap: _onCardTap,
                    ),
                  ),
                  _buildActionArea(provider, state, opponentName),
                ],
              ),
            ),
            if (isWaiting)
              _waitingOverlay(provider, opponentName, opponentAvatar),
            if (state.isPaused && !isWaiting) _pausedOverlay(provider, state),
            if (provider.incomingReaction != null)
              _reactionFloat(provider.incomingReaction!),
          ],
        ),
      ),
    );
  }

  Widget _background() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1220), Color(0xFF111827), Color(0xFF0F172A)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: _Glow(color: const Color(0xFFE53935), size: 260),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _Glow(color: const Color(0xFF1E88E5), size: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(UnoGameProvider provider, UnoGameState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 2),
      child: Row(
        children: [
          _TopBarButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _confirmExit,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'UNO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
              ),
            ),
          ),
          _TopBarButton(
            icon: state.isPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            onTap: () {
              if (state.isPaused) {
                if (!state.resumeRequested) {
                  provider.pauseGame('resume_request');
                }
              } else if (state.match.status == UnoMatchStatus.inProgress) {
                if (!state.pauseRequested) {
                  provider.pauseGame('request');
                }
              }
            },
          ),
          _TopBarButton(
            icon: provider.soundEnabled
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            onTap: provider.toggleSound,
          ),
          _TopBarButton(
            icon: Icons.emoji_emotions_outlined,
            onTap: _openReactions,
          ),
          _TopBarButton(
            icon: Icons.menu_book_rounded,
            onTap: () => showUnoRulesSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentPanel(
    UnoGameState state,
    String opponentName,
    String? opponentAvatar,
  ) {
    final isTheirTurn = state.isOpponentTurn;
    return Container(
      key: _opponentKey,
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTheirTurn
              ? const Color(0xFFF9A825).withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.1),
          width: 1.3,
        ),
      ),
      child: Row(
        children: [
          _Avatar(
            name: opponentName,
            avatarUrl: opponentAvatar,
            size: 42,
            accent: const Color(0xFFF9A825),
            active: isTheirTurn,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: state.isOpponentTurn
                            ? const Color(0xFFF9A825)
                            : const Color(0xFF64748B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      state.isOpponentTurn ? 'Sedang bermain' : 'Menunggu',
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
          UnoOpponentCardFan(count: state.opponentCardCount, width: 20),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${state.opponentCardCount}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
    UnoGameProvider provider,
    UnoGameState state,
    double baseWidth,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pileWidth = math.min(baseWidth, constraints.maxHeight / 1.9);
        final discardWidth = math.min(baseWidth * 1.12, constraints.maxHeight / 1.75);

        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              KeyedSubtree(
                key: _drawKey,
                child: UnoDrawPile(
                  width: pileWidth,
                  deckCount: state.match.deckCount,
                  active: provider.canDrawOne,
                  pulse: _pulse,
                  onTap: provider.canDrawOne
                      ? () => provider.drawOne()
                      : null,
                ),
              ),
              const SizedBox(width: 26),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeyedSubtree(
                    key: _discardKey,
                    child: UnoDiscardPile(
                      card: state.topCard,
                      width: discardWidth,
                    ),
                  ),
                  const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        UnoColorPill(color: state.currentColor),
                        UnoPendingDrawBadge(count: state.match.pendingDraw),
                        if (state.match.extraTurns > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9A825)
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFF9A825)
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                            child: Text(
                              'Extra turn +${state.match.extraTurns}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFFF8E1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusArea(
    UnoGameProvider provider,
    UnoGameState state,
    String opponentName,
  ) {
    final chain = state.match.turnCards;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: state.isMyAction
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFFF9A825),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    _statusText(state, opponentName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (chain.isNotEmpty) ...[
            const SizedBox(width: 8),
            UnoChainStrip(cards: chain, width: 26),
            const SizedBox(width: 6),
            Text(
              'x${chain.length}',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusText(UnoGameState state, String opponentName) {
    if (state.isPaused) return 'Game dipause';
    if (state.isPauseRequestForMe) return 'Lawan minta pause';
    if (state.pauseRequested) return 'Menunggu persetujuan pause';
    if (state.match.phase == UnoPhase.drawResponse) {
      if (state.isDrawResponseForMe) {
        return 'Balas +${state.match.pendingDraw} atau terima';
      }
      return 'Menunggu balasan draw dari $opponentName';
    }
    if (state.isMyTurn) {
      if (state.match.turnCards.isNotEmpty) {
        return 'Tumpuk lagi atau selesaikan giliran';
      }
      return 'Giliran kamu — mainkan kartu atau ambil 1';
    }
    return 'Giliran $opponentName';
  }

  Widget _buildMyPanel(
    UnoGameProvider provider,
    UnoGameState state,
    String myName,
    String? myAvatar,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: state.isMyAction
              ? const Color(0xFF4ADE80).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          _Avatar(
            name: myName,
            avatarUrl: myAvatar,
            size: 34,
            accent: const Color(0xFF4ADE80),
            active: state.isMyAction,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '$myName  •  ${state.myCardCount} kartu'
              '${state.myCardCount > 7 ? '  •  geser' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          InkWell(
            onTap: provider.cycleHandSort,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sort_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 15,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    provider.handSortMode.label,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(
    UnoGameProvider provider,
    UnoGameState state,
    String opponentName,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: _actionContent(provider, state, opponentName),
    );
  }

  Widget _actionContent(
    UnoGameProvider provider,
    UnoGameState state,
    String opponentName,
  ) {
    if (state.isDrawResponseForMe) {
      final count = state.match.pendingDraw;
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: state.match.drawResponseStarted
                  ? () => provider.passDrawPenalty()
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.24),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                minimumSize: const Size.fromHeight(46),
              ),
              child: Text(
                state.match.drawResponseStarted
                    ? 'Oper +$count'
                    : 'Balas dengan kartu +',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: provider.busy
                  ? null
                  : () => provider.acceptDrawPenalty(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                minimumSize: const Size.fromHeight(46),
              ),
              child: Text(
                'Terima +$count',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (state.isMyTurn) {
      if (state.match.turnCards.isNotEmpty) {
        final last = state.match.turnCards.last;
        final isDrawChain = last.isDraw;
        final hasBlock = state.match.turnCards.any((c) => c.isBlock);
        return SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            onPressed: provider.busy ? null : () => provider.endTurn(),
            style: FilledButton.styleFrom(
              backgroundColor: isDrawChain
                  ? const Color(0xFFE53935)
                  : const Color(0xFF1E88E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              isDrawChain
                  ? 'Selesai & Oper +${state.match.pendingDraw}'
                  : hasBlock
                      ? 'Selesai Giliran (+1 extra turn)'
                      : 'Selesai Giliran',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      }

      if (provider.canDrawOne) {
        return SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton.icon(
            onPressed: provider.busy ? null : () => provider.drawOne(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF9A825),
              foregroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.style_rounded, size: 18),
            label: const Text(
              'Ambil Kartu',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
        );
      }

      return const SizedBox(
        height: 46,
        child: Center(
          child: Text(
            'Tap kartu yang menyala untuk dimainkan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 46,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFF9A825),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Menunggu $opponentName...',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _waitingOverlay(
    UnoGameProvider provider,
    String opponentName,
    String? opponentAvatar,
  ) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0B1220).withValues(alpha: 0.92),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.05).animate(_pulse),
                  child: UnoCardWidget(
                    card: const UnoCard(
                      id: 'waiting-card',
                      type: UnoCardType.wild,
                    ),
                    width: 86,
                    playable: true,
                  ),
                ),
                const SizedBox(height: 22),
                _Avatar(
                  name: opponentName,
                  avatarUrl: opponentAvatar,
                  size: 64,
                  accent: const Color(0xFFF9A825),
                  active: true,
                ),
                const SizedBox(height: 14),
                Text(
                  'Menunggu $opponentName',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Undangan sudah dikirim. Begitu diterima, server membagikan kartu dan permainan langsung dimulai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Berlaku 5 menit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () async {
                      await provider.leaveGame();
                      if (mounted) context.go('/uno');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Batalkan Ajakan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pausedOverlay(UnoGameProvider provider, UnoGameState state) {
    final canApprove = state.isResumeRequestForMe;
    return Positioned.fill(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          color: Colors.black.withValues(alpha: 0.58),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⏸️', style: TextStyle(fontSize: 46)),
                  const SizedBox(height: 12),
                  const Text(
                    'Game dipause',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    canApprove
                        ? 'Lawan ingin melanjutkan permainan.'
                        : state.resumeRequested
                            ? 'Menunggu persetujuan lawan untuk lanjut...'
                            : 'State kartu terakhir tersimpan. Ajukan resume kalau sudah siap.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (canApprove) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        onPressed: () => provider.pauseGame('resume_approve'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4ADE80),
                          foregroundColor: const Color(0xFF052E16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Setujui & Lanjut',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () =>
                            provider.pauseGame('resume_reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Nanti dulu',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ] else if (!state.resumeRequested) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        onPressed: () => provider.pauseGame('resume_request'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Ajukan Resume',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                  TextButton(
                    onPressed: _confirmExit,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF94A3B8),
                    ),
                    child: const Text(
                      'Keluar dari game',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _reactionFloat(String emoji) {
    return Positioned(
      top: 120,
      right: 24,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(emoji),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 30)),
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;
  final Color accent;
  final bool active;

  const _Avatar({
    required this.name,
    required this.size,
    required this.accent,
    this.avatarUrl,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: active ? accent : Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initial(),
            )
          : _initial(),
    );
  }

  Widget _initial() {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
          color: accent,
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;

  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlyingCard extends StatefulWidget {
  final Rect from;
  final Rect to;
  final UnoCard card;
  final bool faceUp;
  final VoidCallback onDone;

  const _FlyingCard({
    required this.from,
    required this.to,
    required this.card,
    required this.faceUp,
    required this.onDone,
  });

  @override
  State<_FlyingCard> createState() => _FlyingCardState();
}

class _FlyingCardState extends State<_FlyingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _controller.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
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
        final t = Curves.easeOutCubic.transform(_controller.value);
        final rect = Rect.lerp(widget.from, widget.to, t)!;
        final angle = ui.lerpDouble(-0.16, 0.05, t)!;
        return Positioned.fromRect(
          rect: rect,
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: 1 + 0.05 * (1 - t),
              child: UnoCardWidget(
                card: widget.card,
                width: rect.width,
                faceUp: widget.faceUp,
                playable: false,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UnoMomentOverlay extends StatefulWidget {
  final String badge;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onDone;

  const _UnoMomentOverlay({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onDone,
  });

  @override
  State<_UnoMomentOverlay> createState() => _UnoMomentOverlayState();
}

class _UnoMomentOverlayState extends State<_UnoMomentOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    _controller.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final scale =
                t < 0.22 ? Curves.elasticOut.transform(t / 0.22) : 1.0;
            final opacity = t < 0.12
                ? t / 0.12
                : t > 0.82
                    ? (1 - t) / 0.18
                    : 1.0;
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                color: Colors.black.withValues(alpha: 0.42),
                child: Center(
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 34),
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.35),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  widget.color,
                                  widget.color.withValues(alpha: 0.72),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.color.withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                widget.badge,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            widget.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
