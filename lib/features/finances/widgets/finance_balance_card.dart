import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../providers/finance_provider.dart';

class FinanceBalanceCard extends StatelessWidget {
  final double totalBalance;
  final double netSavings;
  final bool isBalanceVisible;
  final VoidCallback onToggleVisibility;

  const FinanceBalanceCard({
    super.key,
    required this.totalBalance,
    required this.netSavings,
    required this.isBalanceVisible,
    required this.onToggleVisibility,
  });

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = _months[now.month - 1];
    final year = now.year;

    final formattedBalance = FinanceProvider.formatRupiah(totalBalance);
    final isNetPositive = netSavings >= 0;
    final netPrefix = isNetPositive ? '+' : '';
    final formattedNetSavings =
        '$netPrefix${FinanceProvider.formatRupiah(netSavings)}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF6947D0),
            Color(0xFF231C6A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF231C6A).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 1. Triangular geometric facet overlay (left -20 deg, right +20 deg, gradient 5% to 0% white)
            Positioned.fill(
              child: CustomPaint(
                painter: _CardGeometricFacetPainter(),
              ),
            ),

            // 2. Wave Graph Image (Group 13.png) positioned on the bottom right
            Positioned(
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Image.asset(
                  'lib/assets/background/Group 13.png',
                  width: 145,
                  height: 72,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // 3. Card Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A. Top Header Row: Label & Month Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saldo Keseluruhan',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.88),
                          letterSpacing: -0.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF00E5C9).withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                const Color(0xFF00E5C9).withValues(alpha: 0.45),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: Color(0xFF00FFD5),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$monthName $year',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF00FFD5),
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // B. Main Balance Nominal + Eye Toggle side-by-side
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        isBalanceVisible ? formattedBalance : '••••••••••',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onToggleVisibility,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            isBalanceVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: Colors.white.withValues(alpha: 0.85),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // C. Bottom Row: Sisa Bersih Tabungan Bulan Ini
                  Row(
                    children: [
                      Icon(
                        isNetPositive
                            ? Icons.savings_outlined
                            : Icons.warning_amber_rounded,
                        size: 15,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isBalanceVisible
                            ? 'Sisa bulan ini: $formattedNetSavings'
                            : 'Sisa bulan ini: ••••••••',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.82),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Geometric Facet Painter: 2 Equilateral Triangles (+20 deg & -20 deg) with 5% to 0% white gradient
class _CardGeometricFacetPainter extends CustomPainter {
  Path _createEquilateralTriangle(double sideLength) {
    final h = sideLength *
        math.sqrt(3) /
        2; // Tinggi segitiga sama sisi (h = L * sqrt(3)/2)
    final path = Path()
      ..moveTo(0, -2 * h / 3) // Titik puncak atas (apex)
      ..lineTo(-sideLength / 2, h / 3) // Titik sudut kiri bawah
      ..lineTo(sideLength / 2, h / 3) // Titik sudut kanan bawah
      ..close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Panjang sisi segitiga sama sisi
    final sideLength = size.width * 0.95;
    final trianglePath = _createEquilateralTriangle(sideLength);
    final triangleBounds = trianglePath.getBounds();

    // Gradasi linear opacity dari puncak atas (5%) ke dasar bawah (0%)
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: 0.05), // 5% opacity di atas
        Colors.white.withValues(alpha: 0.0), // 0% opacity di bawah
      ],
    );
    final paint = Paint()
      ..shader = gradient.createShader(triangleBounds)
      ..style = PaintingStyle.fill;

    // 1. Segitiga Sama Sisi Kiri: Rotasi -20 derajat
    canvas.save();
    canvas.translate(size.width * 0.35, size.height * 0.85);
    canvas.rotate(-20 * math.pi / 180);
    canvas.drawPath(trianglePath, paint);
    canvas.restore();

    // 2. Segitiga Sama Sisi Kanan: Rotasi +20 derajat
    canvas.save();
    canvas.translate(size.width * 1.0, size.height * 0.35);
    canvas.rotate(20 * math.pi / 180);
    canvas.drawPath(trianglePath, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
