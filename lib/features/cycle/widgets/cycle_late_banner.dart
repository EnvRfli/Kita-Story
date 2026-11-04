import 'package:flutter/material.dart';

import '../models/cycle_summary.dart';
import '../utils/cycle_date_utils.dart';

class CycleLateBanner extends StatelessWidget {
  final CycleSummary summary;
  final bool isPartner;
  final String? partnerName;
  final VoidCallback? onConfirm;

  const CycleLateBanner({
    super.key,
    required this.summary,
    this.isPartner = false,
    this.partnerName,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final title = isPartner
        ? '${partnerName ?? 'Pasangan'} terlambat ${summary.lateDays} hari'
        : 'Haid terlambat ${summary.lateDays} hari';
    final body = isPartner
        ? 'Beri dukungan ekstra hari ini. Tanyakan kabar dengan lembut, tanpa menekan.'
        : 'Diperkirakan mulai ${cycleLongDate(summary.nextPeriodStart)}. '
            'Catat hari pertama haid agar prediksi kembali akurat.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFE11D48)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            body,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.94),
            ),
          ),
          if (onConfirm != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFBE123C),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text(
                  'Sudah mulai haid',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
