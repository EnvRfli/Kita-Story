import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class GameWonOverlay extends StatefulWidget {
  final int points;
  final int elapsedSeconds;
  final String difficulty;
  final bool isTestingMode;
  final VoidCallback onHome;

  const GameWonOverlay({
    super.key,
    required this.points,
    this.elapsedSeconds = 0,
    this.difficulty = 'normal',
    this.isTestingMode = false,
    required this.onHome,
  });

  @override
  State<GameWonOverlay> createState() => _GameWonOverlayState();
}

class _GameWonOverlayState extends State<GameWonOverlay>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3))..play();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = widget.elapsedSeconds ~/ 60;
    final seconds = widget.elapsedSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get _difficultyLabel {
    return widget.difficulty
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xFF172554).withValues(alpha: 0.56),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 7,
                minBlastForce: 3,
                emissionFrequency: 0.045,
                numberOfParticles: 30,
                gravity: 0.18,
                colors: const [
                  Color(0xFFFFC928),
                  Color(0xFF0088FF),
                  Color(0xFFFF7EB6),
                  Color(0xFF7C5CFC),
                  Color(0xFF5ED6A8),
                ],
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 24,
                ),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 390),
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFFBF2), Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF172554).withValues(alpha: 0.28),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -28),
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFE079),
                                  Color(0xFFFF9B42),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9B42)
                                      .withValues(alpha: 0.38),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 0),
                        const Text(
                          'Sudoku Selesai!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF273653),
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Hebat! Semua angka sudah berada di tempat yang tepat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: Color(0xFF718096),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F8FF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFDCEBFF),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Statistik Permainan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ResultStat(
                                      icon: Icons.timer_rounded,
                                      label: 'Waktu',
                                      value: _formattedTime,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 38,
                                    color: const Color(0xFFDCEBFF),
                                  ),
                                  Expanded(
                                    child: _ResultStat(
                                      icon: Icons.wb_sunny_rounded,
                                      label: 'Level',
                                      value: _difficultyLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.isTestingMode
                                  ? const [
                                      Color(0xFFFFF3E8),
                                      Color(0xFFFFE7CF),
                                    ]
                                  : const [
                                      Color(0xFFEDE9FE),
                                      Color(0xFFDCEBFF),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.isTestingMode
                                    ? Icons.science_rounded
                                    : Icons.auto_awesome_rounded,
                                color: widget.isTestingMode
                                    ? const Color(0xFFFF7A00)
                                    : const Color(0xFF7047F6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.isTestingMode
                                    ? 'Mode Testing • Tanpa Poin'
                                    : '+${widget.points} Poin',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: widget.isTestingMode
                                      ? const Color(0xFFD96300)
                                      : const Color(0xFF5B42D6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: widget.onHome,
                            icon: const Icon(Icons.home_rounded, size: 19),
                            label: const Text('Kembali ke Beranda'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0088FF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
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
    );
  }
}

class _ResultStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ResultStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0088FF)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF334155),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}
