import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../models/ludo_player.dart';

class LudoGameOverDialog extends StatefulWidget {
  final LudoPlayer winner;
  final bool isWinnerLocal;
  final bool isOnline;
  final int totalMoves;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const LudoGameOverDialog({
    super.key,
    required this.winner,
    this.isWinnerLocal = true,
    this.isOnline = false,
    required this.totalMoves,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  State<LudoGameOverDialog> createState() => _LudoGameOverDialogState();
}

class _LudoGameOverDialogState extends State<LudoGameOverDialog>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _trophyController;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _trophyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    if (widget.isWinnerLocal) {
      _confetti.play();
    }
    _trophyController.forward();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _trophyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
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
                _buildTrophy(),
                const SizedBox(height: 14),
                Text(
                  widget.isWinnerLocal
                      ? 'Kamu Menang!'
                      : '${widget.winner.name} Menang!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isWinnerLocal
                      ? 'Semua pionmu sampai rumah lebih dulu. Keren!'
                      : '${widget.winner.name} sampai rumah lebih dulu. Coba lagi!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Total Langkah', '${widget.totalMoves}'),
                      Container(
                        width: 1,
                        height: 28,
                        color: const Color(0xFFE2E8F0),
                      ),
                      _buildStat(
                        'Poin Diperoleh',
                        widget.isWinnerLocal ? '+15 Poin' : '+5 Poin',
                        valueColor: const Color(0xFFFF7A00),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: widget.onPlayAgain,
                    icon: Icon(
                      widget.isOnline
                          ? Icons.favorite_rounded
                          : Icons.refresh_rounded,
                      size: 18,
                    ),
                    label: Text(
                      widget.isOnline ? 'Ajak Rematch' : 'Main Lagi',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0088FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: widget.onExit,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Kembali ke Menu',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 26,
              emissionFrequency: 0.05,
              gravity: 0.22,
              colors: const [
                Color(0xFFFF9DD3),
                Color(0xFF0088FF),
                Color(0xFF22C55E),
                Color(0xFFEAB308),
                Color(0xFFEF4444),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrophy() {
    return AnimatedBuilder(
      animation: _trophyController,
      builder: (context, child) {
        final t = Curves.elasticOut.transform(_trophyController.value);
        final wobble = math.sin(_trophyController.value * math.pi * 4) *
            0.08 *
            (1 - _trophyController.value);
        return Transform.rotate(
          angle: wobble,
          child: Transform.scale(scale: 0.6 + t * 0.4, child: child),
        );
      },
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Text('🏆', style: TextStyle(fontSize: 38)),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: valueColor ?? const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
