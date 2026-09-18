import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../utils/game_2048_formatters.dart';

class Game2048CelebrationOverlay extends StatefulWidget {
  const Game2048CelebrationOverlay({
    super.key,
    required this.score,
    required this.tile,
    required this.onContinue,
    this.elapsedSeconds = 0,
    this.movesCount = 0,
    this.pointsEarned = 20,
    this.onHome,
  });

  final int score;
  final int tile;
  final int elapsedSeconds;
  final int movesCount;
  final int pointsEarned;
  final VoidCallback onContinue;
  final VoidCallback? onHome;

  @override
  State<Game2048CelebrationOverlay> createState() =>
      _Game2048CelebrationOverlayState();
}

class _Game2048CelebrationOverlayState extends State<Game2048CelebrationOverlay>
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

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xFF172554).withValues(alpha: 0.56),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Top Confetti blast (consistent with Sudoku)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: math.pi / 2,
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
            const Positioned.fill(child: _CelebrationParticles()),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 24,
                ),
                child: ScaleTransition(
                  scale: disableAnimations
                      ? const AlwaysStoppedAnimation(1.0)
                      : _scaleAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 360),
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
                        // Floating golden trophy badge at top
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
                        const Text(
                          '2048 Tercapai!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF273653),
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Hebat! Kamu berhasil menggabungkan ubin hingga mencapai ${widget.tile} legendaris.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: Color(0xFF718096),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Statistik Permainan container
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
                                      icon: Icons.emoji_events_rounded,
                                      label: 'Skor',
                                      value: format2048Score(widget.score),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 38,
                                    color: const Color(0xFFDCEBFF),
                                  ),
                                  Expanded(
                                    child: _ResultStat(
                                      icon: Icons.grid_view_rounded,
                                      label: 'Ubin',
                                      value: '${widget.tile}',
                                    ),
                                  ),
                                  if (widget.elapsedSeconds > 0) ...[
                                    Container(
                                      width: 1,
                                      height: 38,
                                      color: const Color(0xFFDCEBFF),
                                    ),
                                    Expanded(
                                      child: _ResultStat(
                                        icon: Icons.timer_rounded,
                                        label: 'Waktu',
                                        value: format2048Timer(
                                            widget.elapsedSeconds),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Points reward badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFEDE9FE),
                                Color(0xFFDCEBFF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                color: Color(0xFF7047F6),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+${widget.pointsEarned} Poin',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF5B42D6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Lanjutkan Bermain Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: widget.onContinue,
                            icon:
                                const Icon(Icons.play_arrow_rounded, size: 20),
                            label: const Text('Lanjutkan Bermain'),
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
                        if (widget.onHome != null) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton(
                              onPressed: widget.onHome,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF64748B),
                                side:
                                    const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Kembali ke Beranda',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
                        ],
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

class Game2048GameOverOverlay extends StatelessWidget {
  const Game2048GameOverOverlay({
    super.key,
    required this.score,
    required this.highestTile,
    this.isNewRecord = false,
    this.pointsEarned = 0,
    required this.onPlayAgain,
    required this.onBack,
  });

  final int score;
  final int highestTile;
  final bool isNewRecord;
  final int pointsEarned;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xFF172554).withValues(alpha: 0.56),
        child: SafeArea(
          minimum: const EdgeInsets.all(20),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0xFFFFF9FD)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x520E0714),
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFEDD5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFFFF7A00),
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Game Selesai',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (isNewRecord) ...[
                      const SizedBox(height: 6),
                      const Text(
                        '⭐ Rekor baru untukmu!',
                        style: TextStyle(
                          color: Color(0xFFFF7A00),
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _ResultMetric(
                            label: 'Skor Akhir',
                            value: format2048Score(score),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ResultMetric(
                            label: 'Tile Tertinggi',
                            value: '$highestTile',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: pointsEarned > 0
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: pointsEarned > 0
                              ? const Color(0xFFBBF7D0)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            pointsEarned > 0
                                ? Icons.stars_rounded
                                : Icons.military_tech_rounded,
                            color: pointsEarned > 0
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF94A3B8),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pointsEarned > 0
                                      ? '+$pointsEarned Poin'
                                      : '0 Poin',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: pointsEarned > 0
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                                Text(
                                  pointsEarned > 0
                                      ? 'Berhasil ditambahkan ke saldo akun'
                                      : 'Raih ubin 128 ke atas untuk mendapatkan poin',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: onPlayAgain,
                        icon: const Icon(Icons.replay_rounded, size: 19),
                        label: const Text('Main Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0088FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        onPressed: onBack,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Kembali',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _CelebrationParticles extends StatefulWidget {
  const _CelebrationParticles();

  @override
  State<_CelebrationParticles> createState() => _CelebrationParticlesState();
}

class _CelebrationParticlesState extends State<_CelebrationParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  bool? _disableAnimations;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (_disableAnimations == disableAnimations) return;
    _disableAnimations = disableAnimations;
    if (disableAnimations) {
      _controller
        ..stop()
        ..value = .35;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Semantics(
          label: 'Konfeti perayaan',
          child: RepaintBoundary(
            key: const ValueKey('game-2048-confetti'),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _ParticlePainter(_controller.value),
              ),
            ),
          ),
        ),
      );
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.progress);

  final double progress;

  static const _colors = [
    Color(0xFFFF7A00),
    Color(0xFF0088FF),
    Color(0xFFB064D7),
    Color(0xFFFFCF5A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < 20; index++) {
      final baseX = ((index * 53) % 100) / 100;
      final offset = (progress + index * .13) % 1;
      final x = size.width * baseX;
      final y = size.height * offset;
      final paint = Paint()..color = _colors[index % _colors.length];
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((progress + index) * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -6, 6, 12),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

String formatGame2048Number(int value) => format2048Score(value);
