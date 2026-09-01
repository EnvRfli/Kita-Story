import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../providers/finance_provider.dart';

class FinanceCategoryDonutChart extends StatelessWidget {
  final List<CategoryBreakdownItem> breakdown;

  const FinanceCategoryDonutChart({
    super.key,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = breakdown.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Text(
            'Kategori Pengeluaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),

          if (!hasData)
            _buildEmptyState()
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Slim Donut Chart Painter
                SizedBox(
                  width: 106,
                  height: 106,
                  child: CustomPaint(
                    painter: _DonutChartPainter(breakdown: breakdown),
                  ),
                ),
                const SizedBox(width: 18),

                // 2. Legend List with Colored Dots & Percentages
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: breakdown.take(5).map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.5),
                        child: Row(
                          children: [
                            // Color Dot
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: item.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Category Name
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Percentage
                            Text(
                              '${item.percentage.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pie_chart_outline_rounded,
              color: Color(0xFF94A3B8),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Belum ada pengeluaran di periode ini',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Catatan pengeluaran Anda akan muncul dalam grafik di sini',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<CategoryBreakdownItem> breakdown;

  _DonutChartPainter({required this.breakdown});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Slim radius & stroke width (11.0px) for elegant thin donut ring
    const strokeWidth = 11.0;
    final radius = (math.min(size.width, size.height) / 2) - (strokeWidth / 2) - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2; // Start from top 12 o'clock
    const totalCircumference = 2 * math.pi;
    final hasMultiple = breakdown.length > 1;
    final gapAngle = hasMultiple ? 0.04 : 0.0; // No gap if only 1 item

    for (final item in breakdown) {
      final sweepAngle = (item.percentage / 100.0) * totalCircumference;
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      final effectiveSweep = hasMultiple ? math.max(0.01, sweepAngle - gapAngle) : sweepAngle;
      final effectiveStart = hasMultiple ? startAngle + (gapAngle / 2) : startAngle;

      canvas.drawArc(rect, effectiveStart, effectiveSweep, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.breakdown != breakdown;
  }
}
