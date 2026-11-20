import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tetris_provider.dart';
import '../repositories/tetris_repository.dart';
import '../utils/tetris_formatters.dart';
import '../widgets/tetris_achievement_banner.dart';
import '../widgets/tetris_artwork.dart';
import '../widgets/tetris_board.dart';
import '../widgets/tetris_controls.dart';
import '../widgets/tetris_next_preview.dart';
import '../widgets/tetris_result_overlay.dart';

class TetrisGameScreen extends StatefulWidget {
  const TetrisGameScreen({super.key});

  @override
  State<TetrisGameScreen> createState() => _TetrisGameScreenState();
}

class _TetrisGameScreenState extends State<TetrisGameScreen>
    with WidgetsBindingObserver {
  var _isLeaving = false;
  var _isExitActionPending = false;
  TetrisProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<TetrisProvider>();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _provider?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer<TetrisProvider>(
        builder: (context, provider, _) {
          final showGameOver = provider.isGameOver &&
              (provider.status == TetrisStatus.gameOver ||
                  provider.status == TetrisStatus.error ||
                  provider.status == TetrisStatus.saving);

          return PopScope(
            canPop: _isLeaving,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _handleBackRequest(context, provider);
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFF8F9FE),
              body: SafeArea(
                child: Stack(
                  children: [
                    _GameContents(
                      provider: provider,
                      onExit: () => _handleBackRequest(context, provider),
                      onPause: provider.togglePause,
                    ),
                    if (provider.status == TetrisStatus.paused)
                      _PauseOverlay(
                        provider: provider,
                        onResume: provider.resume,
                        onExit: () => _handleBackRequest(context, provider),
                      ),
                    if (showGameOver)
                      TetrisGameOverOverlay(
                        score: provider.score,
                        lines: provider.lines,
                        level: provider.level,
                        isNewRecord: provider.isNewRecord,
                        pointsEarned: provider.sessionPointsEarned,
                        onPlayAgain: _isExitActionPending
                            ? () {}
                            : () => unawaited(_playAgain(provider)),
                        onBack: _isExitActionPending
                            ? () {}
                            : () => _finishAndExit(context, provider),
                      ),
                    if (provider.newlyUnlockedMilestone != null &&
                        provider.status != TetrisStatus.gameOver &&
                        provider.status != TetrisStatus.clearing &&
                        provider.status != TetrisStatus.paused)
                      Positioned(
                        top: 12,
                        left: 16,
                        right: 16,
                        child: TetrisAchievementBanner(
                          key: ValueKey(provider.newlyUnlockedMilestone),
                          milestone: provider.newlyUnlockedMilestone!,
                          points: TetrisRepository.rewardPointsFor(
                                provider.newlyUnlockedMilestone!,
                              ) ??
                              0,
                          onDismiss: provider.clearNewlyUnlockedMilestone,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  void _handleBackRequest(BuildContext context, TetrisProvider provider) {
    if (_exitIsBlocked(provider)) return;
    if (provider.status == TetrisStatus.gameOver) {
      unawaited(_finishAndExit(context, provider));
      return;
    }
    unawaited(_showExitDialog(context, provider));
  }

  bool _exitIsBlocked(TetrisProvider provider) =>
      _isExitActionPending || provider.isInputLocked;

  Future<void> _showExitDialog(
    BuildContext screenContext,
    TetrisProvider provider,
  ) async {
    if (_exitIsBlocked(provider)) return;
    final wasPlaying = provider.status == TetrisStatus.playing;
    if (wasPlaying) provider.pause();
    var dialogPending = false;

    await showDialog<void>(
      context: screenContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Colors.white,
          iconPadding: const EdgeInsets.only(top: 24, bottom: 0),
          titlePadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          icon: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF3E8FF), Color(0xFFE0F2FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: TetrisArtwork(size: 38),
            ),
          ),
          title: const Text(
            'Keluar dari permainan?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 19.5,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          content: const Text(
            'Permainanmu bisa disimpan untuk dilanjutkan nanti, atau akhiri jika ingin mulai baru.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  onPressed: dialogPending
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                          if (wasPlaying) provider.resume();
                        },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFC4B5FD),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 13.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        wasPlaying
                            ? Icons.play_arrow_rounded
                            : Icons.arrow_back_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        wasPlaying ? 'Lanjut Bermain' : 'Kembali',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: dialogPending
                      ? null
                      : () async {
                          setDialogState(() => dialogPending = true);
                          _setExitActionPending(true);
                          await provider.saveAndExit();
                          if (!mounted) return;
                          if (provider.status == TetrisStatus.error) {
                            _setExitActionPending(false);
                            if (dialogContext.mounted) {
                              setDialogState(() => dialogPending = false);
                            }
                            return;
                          }
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          if (screenContext.mounted) _popScreen(screenContext);
                        },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F3FF),
                    foregroundColor: const Color(0xFF7C3AED),
                    disabledBackgroundColor: const Color(0xFFF1F5F9),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                          color: Color(0xFFDDD6FE), width: 1.2),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_add_rounded,
                          size: 20, color: Color(0xFF7C3AED)),
                      SizedBox(width: 6),
                      Text(
                        'Simpan & Keluar',
                        style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: dialogPending
                      ? null
                      : () async {
                          setDialogState(() => dialogPending = true);
                          _setExitActionPending(true);
                          await provider.endRun();
                          if (!mounted) return;
                          if (provider.hasPendingWrite ||
                              provider.status == TetrisStatus.error) {
                            _setExitActionPending(false);
                            if (dialogContext.mounted) {
                              setDialogState(() => dialogPending = false);
                            }
                            return;
                          }
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          if (screenContext.mounted) _popScreen(screenContext);
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close_rounded,
                          size: 16, color: Color(0xFFEF4444)),
                      SizedBox(width: 4),
                      Text(
                        'Akhiri Permainan',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finishAndExit(
    BuildContext context,
    TetrisProvider provider,
  ) async {
    if (_exitIsBlocked(provider)) return;
    _setExitActionPending(true);
    await provider.endRun();
    if (!mounted) return;
    if (provider.hasPendingWrite || provider.status == TetrisStatus.error) {
      _setExitActionPending(false);
      return;
    }
    if (!context.mounted) return;
    _popScreen(context);
  }

  Future<void> _playAgain(TetrisProvider provider) async {
    if (_exitIsBlocked(provider)) return;
    _setExitActionPending(true);
    await provider.endRun();
    if (!mounted) return;
    if (provider.hasPendingWrite || provider.status == TetrisStatus.error) {
      _setExitActionPending(false);
      return;
    }
    await provider.newGame();
    if (mounted) _setExitActionPending(false);
  }

  void _setExitActionPending(bool value) {
    if (mounted && _isExitActionPending != value) {
      setState(() => _isExitActionPending = value);
    }
  }

  void _popScreen(BuildContext context) {
    if (!mounted || !context.mounted) return;
    setState(() => _isLeaving = true);
    Navigator.of(context).pop();
  }
}

class _GameContents extends StatelessWidget {
  const _GameContents({
    required this.provider,
    required this.onExit,
    required this.onPause,
  });

  final TetrisProvider provider;
  final VoidCallback onExit;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GameHeader(
          onExit: onExit,
          onPause: onPause,
          pauseEnabled: provider.status == TetrisStatus.playing &&
              !provider.isInputLocked,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _ScoreCard(
                  score: provider.score,
                  level: provider.level,
                ),
              ),
              const SizedBox(width: 10),
              TetrisNextPreview(queue: provider.nextQueue),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.grid_on_rounded,
                  label: 'Garis',
                  value: '${provider.lines}',
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  icon: Icons.speed_rounded,
                  label: 'Level',
                  value: '${provider.level}',
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  icon: Icons.emoji_events_rounded,
                  label: 'Rekor',
                  value: formatTetrisNumber(provider.bestScore),
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: _BoardGestureArea(
                onTap: provider.rotate,
                onLeft: provider.moveLeft,
                onRight: provider.moveRight,
                onSoftDrop: provider.softDrop,
                child: TetrisBoard(
                  board: provider.board,
                  activePiece: provider.activePiece,
                  ghostRow: provider.ghostRow,
                  clearingRows: provider.clearingRows,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TetrisControls(
            enabled: provider.status == TetrisStatus.playing &&
                !provider.isInputLocked,
            onLeft: provider.moveLeft,
            onRight: provider.moveRight,
            onRotate: provider.rotate,
            onSoftDrop: provider.softDrop,
            onHardDrop: provider.hardDrop,
            onPause: onPause,
          ),
        ),
      ],
    );
  }
}

enum _DragAxis { horizontal, vertical }

class _BoardGestureArea extends StatefulWidget {
  const _BoardGestureArea({
    required this.onTap,
    required this.onLeft,
    required this.onRight,
    required this.onSoftDrop,
    required this.child,
  });

  final VoidCallback onTap;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onSoftDrop;
  final Widget child;

  @override
  State<_BoardGestureArea> createState() => _BoardGestureAreaState();
}

class _BoardGestureAreaState extends State<_BoardGestureArea> {
  static const double _step = 26;

  Offset _accumulated = Offset.zero;
  _DragAxis? _axis;

  void _reset() {
    _accumulated = Offset.zero;
    _axis = null;
  }

  void _onUpdate(DragUpdateDetails details) {
    if (_axis == null) {
      if (details.delta.distance < 0.5) return;
      _axis = details.delta.dx.abs() >= details.delta.dy.abs()
          ? _DragAxis.horizontal
          : _DragAxis.vertical;
    }

    if (_axis == _DragAxis.horizontal) {
      _accumulated = Offset(_accumulated.dx + details.delta.dx, 0);
      while (_accumulated.dx <= -_step) {
        widget.onLeft();
        _accumulated = Offset(_accumulated.dx + _step, 0);
      }
      while (_accumulated.dx >= _step) {
        widget.onRight();
        _accumulated = Offset(_accumulated.dx - _step, 0);
      }
      return;
    }

    _accumulated = Offset(0, _accumulated.dy + details.delta.dy);
    while (_accumulated.dy >= _step) {
      widget.onSoftDrop();
      _accumulated = Offset(0, _accumulated.dy - _step);
    }
    if (_accumulated.dy < 0) _accumulated = Offset.zero;
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onPanStart: (_) => _reset(),
        onPanUpdate: _onUpdate,
        onPanEnd: (_) => _reset(),
        onPanCancel: _reset,
        child: widget.child,
      );
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.onExit,
    required this.onPause,
    required this.pauseEnabled,
  });

  final VoidCallback onExit;
  final VoidCallback onPause;
  final bool pauseEnabled;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                key: const ValueKey('tetris-back-button'),
                tooltip: 'Kembali',
                onPressed: onExit,
                icon: const Icon(Icons.arrow_back_rounded),
                color: const Color(0xFF1E293B),
                iconSize: 20,
              ),
            ),
            const Expanded(
              child: Text(
                'Tetris',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                key: const ValueKey('tetris-pause-button'),
                tooltip: 'Jeda',
                onPressed: pauseEnabled ? onPause : null,
                icon: const Icon(Icons.pause_rounded),
                color: const Color(0xFF1E293B),
                iconSize: 20,
              ),
            ),
          ],
        ),
      );
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.level});

  final int score;
  final int level;

  @override
  Widget build(BuildContext context) => Container(
        height: 86,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'SKOR',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'LV $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatTetrisNumber(score),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 29,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                height: 1,
              ),
            ),
          ],
        ),
      );
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.provider,
    required this.onResume,
    required this.onExit,
  });

  final TetrisProvider provider;
  final VoidCallback onResume;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xFF172554).withValues(alpha: 0.55),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF172554).withValues(alpha: 0.26),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFF3E8FF), Color(0xFFE0F2FE)],
                    ),
                  ),
                  child: const Center(child: TetrisArtwork(size: 48)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Jeda Sebentar',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Balok-balok menunggu kamu kembali.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _PauseStat(
                        label: 'Skor',
                        value: formatTetrisNumber(provider.score),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PauseStat(
                        label: 'Garis',
                        value: '${provider.lines}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PauseStat(
                        label: 'Level',
                        value: '${provider.level}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text(
                      'Lanjutkan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton(
                    onPressed: onExit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Keluar',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
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
}

class _PauseStat extends StatelessWidget {
  const _PauseStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      );
}
