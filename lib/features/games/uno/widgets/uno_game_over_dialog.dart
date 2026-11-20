import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class UnoGameOverDialog extends StatefulWidget {
  final String winnerName;
  final bool isWinnerLocal;
  final int totalMoves;
  final bool rematchWaiting;
  final VoidCallback onRematch;
  final VoidCallback onExit;

  const UnoGameOverDialog({
    super.key,
    required this.winnerName,
    required this.isWinnerLocal,
    required this.totalMoves,
    this.rematchWaiting = false,
    required this.onRematch,
    required this.onExit,
  });

  @override
  State<UnoGameOverDialog> createState() => _UnoGameOverDialogState();
}

class _UnoGameOverDialogState extends State<UnoGameOverDialog>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _trophy;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _trophy = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    if (widget.isWinnerLocal) _confetti.play();
    _trophy.forward();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _trophy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.06,
          numberOfParticles: 18,
          maxBlastForce: 22,
          minBlastForce: 8,
          gravity: 0.25,
          colors: const [
            Color(0xFFE53935),
            Color(0xFFF9A825),
            Color(0xFF2E9E4F),
            Color(0xFF1E88E5),
            Colors.white,
          ],
        ),
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
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _trophy,
                    curve: Curves.elasticOut,
                  ),
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isWinnerLocal
                            ? const [Color(0xFFFFF8E1), Color(0xFFFFE082)]
                            : const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                      ),
                      border: Border.all(
                        color: widget.isWinnerLocal
                            ? const Color(0xFFF9A825)
                            : const Color(0xFFCBD5E1),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.isWinnerLocal ? '🏆' : '🃏',
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isWinnerLocal ? 'Kamu menang!' : '${widget.winnerName} menang',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isWinnerLocal
                      ? 'Kartu habis lebih dulu. Main lagi yuk?'
                      : 'Kartu lawan habis lebih dulu. Balas dendam di rematch?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app_rounded,
                          size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.totalMoves} aksi dimainkan',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: widget.rematchWaiting ? null : widget.onRematch,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: widget.rematchWaiting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF94A3B8),
                            ),
                          )
                        : const Icon(Icons.replay_rounded, size: 19),
                    label: Text(
                      widget.rematchWaiting
                          ? 'Menunggu persetujuan lawan...'
                          : 'Rematch',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: TextButton(
                    onPressed: widget.onExit,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Keluar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
  }
}
