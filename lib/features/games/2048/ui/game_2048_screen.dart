import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_2048_move.dart';
import '../providers/game_2048_provider.dart';
import '../utils/game_2048_formatters.dart';
import '../widgets/game_2048_board.dart';
import '../widgets/game_2048_result_overlay.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  var _isLeaving = false;
  var _isExitActionPending = false;

  @override
  Widget build(BuildContext context) => Consumer<Game2048Provider>(
        builder: (context, provider, _) {
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
                    ),
                    if (provider.status == Game2048Status.celebrating2048)
                      Game2048CelebrationOverlay(
                        score: provider.score,
                        tile: provider.highestTile,
                        elapsedSeconds: provider.elapsedSeconds,
                        movesCount: provider.moveCount,
                        onContinue: provider.continueAfter2048,
                        onHome: () => _finishAndExit(context, provider),
                      ),
                    if (provider.status == Game2048Status.gameOver)
                      Game2048GameOverOverlay(
                        score: provider.score,
                        highestTile: provider.highestTile,
                        isNewRecord: provider.score > 0 &&
                            provider.score >= provider.bestScore,
                        onPlayAgain: _isExitActionPending
                            ? () {}
                            : () => unawaited(_playAgain(provider)),
                        onBack: _isExitActionPending
                            ? () {}
                            : () => _finishAndExit(context, provider),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  void _handleBackRequest(
    BuildContext context,
    Game2048Provider provider,
  ) {
    if (_exitIsBlocked(provider)) return;
    if (provider.status == Game2048Status.gameOver) {
      unawaited(_finishAndExit(context, provider));
      return;
    }
    unawaited(_showExitDialog(context, provider));
  }

  bool _exitIsBlocked(Game2048Provider provider) =>
      _isExitActionPending ||
      provider.isInputLocked ||
      provider.status == Game2048Status.saving ||
      provider.status == Game2048Status.loading;

  Future<void> _showExitDialog(
    BuildContext screenContext,
    Game2048Provider provider,
  ) async {
    if (_exitIsBlocked(provider)) return;
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
                colors: [Color(0xFFFFF0E6), Color(0xFFFFDFCC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🎮',
                style: TextStyle(fontSize: 32),
              ),
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
                      : () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF0088FF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF93C5FD),
                    disabledForegroundColor: Colors.white70,
                    elevation: dialogPending ? 0 : 2,
                    shadowColor:
                        const Color(0xFF0088FF).withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(vertical: 13.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          size: 22, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Lanjut Bermain',
                        style: TextStyle(
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
                          if (provider.status == Game2048Status.error) {
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
                    backgroundColor: const Color(0xFFFFF7ED),
                    foregroundColor: const Color(0xFFEA580C),
                    disabledBackgroundColor: const Color(0xFFF1F5F9),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                          color: Color(0xFFFFEDD5), width: 1.2),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_add_rounded,
                          size: 20, color: Color(0xFFEA580C)),
                      SizedBox(width: 6),
                      Text(
                        'Simpan & Keluar',
                        style: TextStyle(
                          color: Color(0xFFEA580C),
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
                          if (provider.status == Game2048Status.error) {
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
    Game2048Provider provider,
  ) async {
    if (_exitIsBlocked(provider)) return;
    _setExitActionPending(true);
    await provider.endRun();
    if (!mounted) return;
    if (provider.status == Game2048Status.error) {
      _setExitActionPending(false);
      return;
    }
    if (!context.mounted) return;
    _popScreen(context);
  }

  Future<void> _playAgain(Game2048Provider provider) async {
    if (_exitIsBlocked(provider)) return;
    _setExitActionPending(true);
    await provider.endRun();
    if (!mounted) return;
    if (provider.status == Game2048Status.error) {
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
  });

  final Game2048Provider provider;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _GameHeader(onExit: onExit),
          Expanded(
            child: _GameSwipeArea(
              onSwipe: (direction) => _swipe(provider, direction),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  // Centered Score Pill Badge (matches mockup)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF5FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD8EBFF)),
                    ),
                    child: Text(
                      '${format2048Score(provider.score)} poin',
                      style: const TextStyle(
                        color: Color(0xFF0088FF),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 8),
                          child: Column(
                            children: [
                              _ScoreStrip(
                                score: provider.score,
                                bestScore: provider.bestScore,
                              ),
                              const SizedBox(height: 18),
                              Semantics(
                                label: 'Papan permainan 2048',
                                child: Game2048Board(
                                  tiles: provider.tiles,
                                  transitions: provider.transitions,
                                  merges: provider.merges,
                                  animationDuration: provider.animationDuration,
                                  onSwipe: (direction) =>
                                      _swipe(provider, direction),
                                ),
                              ),
                              const SizedBox(height: 22),
                              _UndoButton(
                                undosLeft: provider.undosLeft,
                                enabled:
                                    provider.status == Game2048Status.playing &&
                                        !provider.isInputLocked &&
                                        provider.undosLeft > 0 &&
                                        provider.undoSnapshots.isNotEmpty,
                                onPressed: () => unawaited(provider.undo()),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  void _swipe(Game2048Provider provider, Game2048Direction direction) {
    provider.swipe(direction);
    if (!provider.isInputLocked) return;
    unawaited(
      Future<void>.delayed(
          provider.animationDuration, provider.completeAnimation),
    );
  }
}

class _GameSwipeArea extends StatefulWidget {
  const _GameSwipeArea({
    required this.onSwipe,
    required this.child,
  });

  final ValueChanged<Game2048Direction> onSwipe;
  final Widget child;

  @override
  State<_GameSwipeArea> createState() => _GameSwipeAreaState();
}

class _GameSwipeAreaState extends State<_GameSwipeArea> {
  static const double _swipeThreshold = 24.0;
  Offset _panStart = Offset.zero;
  Offset _panOffset = Offset.zero;
  bool _didDispatchSwipe = false;

  void _dispatchSwipeIfNeeded() {
    if (_didDispatchSwipe || _panOffset.distance < _swipeThreshold) return;

    _didDispatchSwipe = true;
    if (_panOffset.dx.abs() >= _panOffset.dy.abs()) {
      widget.onSwipe(
        _panOffset.dx.isNegative
            ? Game2048Direction.left
            : Game2048Direction.right,
      );
      return;
    }
    widget.onSwipe(
      _panOffset.dy.isNegative ? Game2048Direction.up : Game2048Direction.down,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        _panStart = details.localPosition;
        _panOffset = Offset.zero;
        _didDispatchSwipe = false;
      },
      onPanUpdate: (details) {
        _panOffset = details.localPosition - _panStart;
        _dispatchSwipeIfNeeded();
      },
      onPanEnd: (_) => _dispatchSwipeIfNeeded(),
      child: widget.child,
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({required this.onExit});

  final VoidCallback onExit;

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
                key: const ValueKey('game-2048-back-button'),
                tooltip: 'Kembali',
                onPressed: onExit,
                icon: const Icon(Icons.arrow_back_rounded),
                color: const Color(0xFF1E293B),
                iconSize: 20,
              ),
            ),
            const Expanded(
              child: Text(
                '2048',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 42),
          ],
        ),
      );
}

class _ScoreStrip extends StatelessWidget {
  const _ScoreStrip({required this.score, required this.bestScore});

  final int score;
  final int bestScore;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _ScoreCard(
              label: 'Skor',
              value: format2048Score(score),
              color: const Color(0xFF0088FF),
              icon: Icons.bolt_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ScoreCard(
              label: 'Terbaik',
              value: format2048Score(bestScore),
              color: const Color(0xFF6155F5),
              icon: Icons.emoji_events_rounded,
            ),
          ),
        ],
      );
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _UndoButton extends StatelessWidget {
  const _UndoButton({
    required this.undosLeft,
    required this.enabled,
    required this.onPressed,
  });

  final int undosLeft;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ulangi, $undosLeft kesempatan tersisa',
      button: true,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFFF7A00) : const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(15),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF7A00).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: enabled ? onPressed : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.replay_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Urungkan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$undosLeft',
                      style: TextStyle(
                        color: enabled
                            ? const Color(0xFFFF7A00)
                            : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
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
