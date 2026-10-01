import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../providers/finance_provider.dart';

class SetSummaryDateBottomSheet extends StatefulWidget {
  final String userId;
  final int? currentStartDay;

  const SetSummaryDateBottomSheet({
    super.key,
    required this.userId,
    this.currentStartDay,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    int? currentStartDay,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SetSummaryDateBottomSheet(
        userId: userId,
        currentStartDay: currentStartDay,
      ),
    );
  }

  @override
  State<SetSummaryDateBottomSheet> createState() =>
      _SetSummaryDateBottomSheetState();
}

class _SetSummaryDateBottomSheetState extends State<SetSummaryDateBottomSheet> {
  late bool _isAllTime;
  late int _selectedDay;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isAllTime = widget.currentStartDay == null ||
        widget.currentStartDay! < 1 ||
        widget.currentStartDay! > 31;
    _selectedDay = widget.currentStartDay ?? 25; // Default 25 (common payday)
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final provider = context.read<FinanceProvider>();

    try {
      final int? dayToSave = _isAllTime ? null : _selectedDay;
      await provider.updateSummaryStartDay(
        userId: widget.userId,
        startDay: dayToSave,
      );

      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.success(
          context,
          _isAllTime
              ? 'Ringkasan diatur ke seluruh waktu'
              : 'Siklus ringkasan diatur per tanggal $_selectedDay',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.error(context, 'Gagal menyimpan pengaturan: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  color: Color(0xFFFF7A00),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Periode Ringkasan Keuangan',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pilih patokan waktu untuk kartu ringkasan',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Option 1: Keseluruhan (Semua Waktu)
          _buildOptionTile(
            title: 'Keseluruhan (Semua Transaksi)',
            subtitle: 'Menampilkan total akumulasi transaksi dari awal dicatat',
            icon: Icons.all_inclusive_rounded,
            iconColor: const Color(0xFF8B5CF6),
            iconBgColor: const Color(0xFFF3E8FF),
            isSelected: _isAllTime,
            onTap: () {
              setState(() {
                _isAllTime = true;
              });
            },
          ),
          const SizedBox(height: 10),

          // Option 2: Siklus Bulanan (Pilih Tanggal)
          _buildOptionTile(
            title: 'Siklus per Tanggal (Misal Gajian)',
            subtitle:
                'Dihitung bulanan mulai dari tanggal yang Anda tentukan',
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFFFF7A00),
            iconBgColor: const Color(0xFFFFF1E6),
            isSelected: !_isAllTime,
            onTap: () {
              setState(() {
                _isAllTime = false;
              });
            },
          ),

          // Date Grid Picker (Shown if Option 2 is selected)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: !_isAllTime
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pilih Tanggal Awal Siklus (1 - 31):',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A00).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Tanggal $_selectedDay',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF7A00),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 1-31 Days Grid
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.start,
                      children: List.generate(31, (index) {
                        final day = index + 1;
                        final isDaySelected = !_isAllTime && _selectedDay == day;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDay = day;
                              _isAllTime = false;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDaySelected
                                  ? const Color(0xFFFF7A00)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDaySelected
                                    ? const Color(0xFFFF7A00)
                                    : const Color(0xFFE2E8F0),
                                width: 1.1,
                              ),
                              boxShadow: isDaySelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFFF7A00)
                                            .withValues(alpha: 0.25),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isDaySelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isDaySelected
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '💡 Contoh: Jika Anda memilih tanggal 25, perhitungan akan berlangsung dari tgl 25 bulan ini hingga tgl 24 bulan berikutnya.',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A00),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Terapkan Pengaturan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF7A00).withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF7A00)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFFFF7A00) : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF7A00)
                        : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 13,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
