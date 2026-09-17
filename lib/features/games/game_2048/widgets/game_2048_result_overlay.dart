import 'dart:math' as math;

import 'package:flutter/material.dart';

class Game2048CelebrationOverlay extends StatelessWidget {
  const Game2048CelebrationOverlay({
    super.key,
    required this.score,
    required this.tile,
    required this.onContinue,
  });

  final int score;
  final int tile;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => _ResultScrim(
        child: _ResultCard(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(child: _CelebrationParticles()),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.celebration_rounded,
                    color: Color(0xFFFF8A00),
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hebat!',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kamu berhasil membuat tile $tile',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EAFB),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$tile',
                          style: const TextStyle(
                            color: Color(0xFF5A3478),
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Skor ${formatGame2048Number(score)}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Semantics(
                    button: true,
                    label: 'Lanjutkan Bermain',
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onContinue,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Lanjutkan Bermain'),
                        style: _primaryButtonStyle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class Game2048GameOverOverlay extends StatelessWidget {
  const Game2048GameOverOverlay({
    super.key,
    required this.score,
    required this.highestTile,
    required this.isNewRecord,
    required this.onPlayAgain,
    required this.onBack,
  });

  final int score;
  final int highestTile;
  final bool isNewRecord;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => _ResultScrim(
        child: _ResultCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFFF7A00),
                size: 42,
              ),
              const SizedBox(height: 8),
              const Text(
                'Game Selesai',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (isNewRecord) ...[
                const SizedBox(height: 6),
                const Text(
                  'Rekor baru untukmu!',
                  style: TextStyle(
                    color: Color(0xFFFF7A00),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _ResultMetric(
                      label: 'Skor Akhir',
                      value: formatGame2048Number(score),
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
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onPlayAgain,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Main Lagi'),
                  style: _primaryButtonStyle,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5A3478),
                    side: const BorderSide(color: Color(0xFFB99BD0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Kembali'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ResultScrim extends StatelessWidget {
  const _ResultScrim({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: ColoredBox(
          color: const Color(0x9E251233),
          child: SafeArea(
            minimum: const EdgeInsets.all(20),
            child: Center(
              child: SingleChildScrollView(child: child),
            ),
          ),
        ),
      );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0.88, end: 1),
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: child,
        ),
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
          child: child,
        ),
      );
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EAFB),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF35134F),
                fontSize: 21,
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
  )..repeat();

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

final _primaryButtonStyle = FilledButton.styleFrom(
  backgroundColor: const Color(0xFF0088FF),
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 14),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
);

String formatGame2048Number(int value) {
  final digits = value.toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = math.max(0, end - 3);
    groups.add(digits.substring(start, end));
  }
  return groups.reversed.join('.');
}
