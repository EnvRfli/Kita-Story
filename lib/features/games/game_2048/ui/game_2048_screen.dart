import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_2048_move.dart';
import '../providers/game_2048_provider.dart';
import '../widgets/game_2048_board.dart';
import '../widgets/game_2048_result_overlay.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  var _isLeaving = false;

  @override
  Widget build(BuildContext context) => Consumer<Game2048Provider>(
        builder: (context, provider, _) {
          final hasActiveRun = provider.status != Game2048Status.gameOver;
          return PopScope(
            canPop: _isLeaving || !hasActiveRun,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && hasActiveRun) _showExitDialog(context, provider);
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFFCFCFD),
              body: SafeArea(
                child: Stack(
                  children: [
                    _GameContents(
                      provider: provider,
                      onExit: () => _showExitDialog(context, provider),
                    ),
                    if (provider.status == Game2048Status.celebrating2048)
                      Game2048CelebrationOverlay(
                        score: provider.score,
                        tile: provider.highestTile,
                        onContinue: provider.continueAfter2048,
                      ),
                    if (provider.status == Game2048Status.gameOver)
                      Game2048GameOverOverlay(
                        score: provider.score,
                        highestTile: provider.highestTile,
                        isNewRecord: provider.score > 0 &&
                            provider.score >= provider.bestScore,
                        onPlayAgain: () => unawaited(_playAgain(provider)),
                        onBack: () => _finishAndExit(context, provider),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Future<void> _showExitDialog(
    BuildContext screenContext,
    Game2048Provider provider,
  ) async {
    if (provider.status == Game2048Status.saving ||
        provider.status == Game2048Status.loading) {
      return;
    }
    await showDialog<void>(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari permainan?'),
        content: const Text(
          'Permainanmu bisa disimpan untuk dilanjutkan nanti.',
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Lanjut Bermain'),
          ),
          TextButton(
            onPressed: () async {
              await provider.saveAndExit();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (!screenContext.mounted) return;
              _popScreen(screenContext);
            },
            child: const Text('Simpan & Keluar'),
          ),
          TextButton(
            onPressed: () async {
              await provider.endRun();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (!screenContext.mounted) return;
              _popScreen(screenContext);
            },
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFD64646)),
            child: const Text('Akhiri Permainan'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishAndExit(
    BuildContext context,
    Game2048Provider provider,
  ) async {
    await provider.endRun();
    if (!context.mounted) return;
    _popScreen(context);
  }

  Future<void> _playAgain(Game2048Provider provider) async {
    await provider.endRun();
    await provider.newGame();
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
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight - 8),
                  child: Column(
                    children: [
                      _ScoreStrip(
                        score: provider.score,
                        bestScore: provider.bestScore,
                      ),
                      const SizedBox(height: 22),
                      Semantics(
                        label: 'Papan permainan 2048',
                        child: Game2048Board(
                          tiles: provider.tiles,
                          transitions: provider.transitions,
                          merges: provider.merges,
                          animationDuration: provider.animationDuration,
                          onSwipe: (direction) => _swipe(provider, direction),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _UndoButton(
                        undosLeft: provider.undosLeft,
                        enabled: provider.status == Game2048Status.playing &&
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

class _GameHeader extends StatelessWidget {
  const _GameHeader({required this.onExit});

  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('game-2048-back-button'),
              tooltip: 'Kembali',
              onPressed: onExit,
              icon: const Icon(Icons.arrow_back_rounded),
              color: const Color(0xFF1E293B),
            ),
            const Expanded(
              child: Text(
                '2048',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
            ),
            const SizedBox(width: 48),
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
              value: formatGame2048Number(score),
              color: const Color(0xFF0088FF),
              icon: Icons.bolt_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ScoreCard(
              label: 'Terbaik',
              value: formatGame2048Number(bestScore),
              color: const Color(0xFF5A3478),
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
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: color.withValues(alpha: .18)),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 19,
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
  Widget build(BuildContext context) => Semantics(
        label: 'Urungkan, $undosLeft kesempatan tersisa',
        button: true,
        child: OutlinedButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: const Icon(Icons.undo_rounded),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Urungkan'),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$undosLeft',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFF7A00),
            side: const BorderSide(color: Color(0xFFFFB467), width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      );
}
