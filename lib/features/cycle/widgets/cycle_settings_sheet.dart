import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_snackbar.dart';
import '../models/cycle_settings_model.dart';
import '../providers/cycle_provider.dart';
import '../utils/cycle_date_utils.dart';

class CycleSettingsSheet extends StatefulWidget {
  final String userId;
  final CycleSettingsModel? settings;
  final bool isOnboarding;

  const CycleSettingsSheet({
    super.key,
    required this.userId,
    this.settings,
    this.isOnboarding = false,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    CycleSettingsModel? settings,
    bool isOnboarding = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CycleSettingsSheet(
        userId: userId,
        settings: settings,
        isOnboarding: isOnboarding,
      ),
    );
  }

  @override
  State<CycleSettingsSheet> createState() => _CycleSettingsSheetState();
}

class _CycleSettingsSheetState extends State<CycleSettingsSheet> {
  late int _cycleLength;
  late int _periodLength;
  late DateTime _lastPeriodStart;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cycleLength = widget.settings?.cycleLength ?? 28;
    _periodLength = widget.settings?.periodLength ?? 5;
    _lastPeriodStart = widget.settings?.lastPeriodStart ?? DateTime.now();
  }

  String _formatDate(DateTime date) => cycleLongDate(date);

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodStart,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFE11D48),
            onPrimary: Colors.white,
            onSurface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _lastPeriodStart = picked);
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final provider = context.read<CycleProvider>();
    final success = await provider.saveSettings(
      userId: widget.userId,
      cycleLength: _cycleLength,
      periodLength: _periodLength,
      lastPeriodStart: _lastPeriodStart,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      AppSnackBar.success(context, 'Pengaturan siklus tersimpan!');
      Navigator.of(context).pop();
    } else {
      AppSnackBar.error(
        context,
        provider.errorMessage ?? 'Gagal menyimpan pengaturan siklus',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isOnboarding ? 'Atur Siklusmu' : 'Pengaturan Siklus',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Data ini dipakai untuk memperkirakan fase dan tanggal haid berikutnya.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              _NumberStepper(
                label: 'Panjang siklus',
                helper:
                    'Dari hari pertama haid ke hari pertama haid berikutnya.',
                value: _cycleLength,
                min: 21,
                max: 45,
                suffix: 'hari',
                onChanged: (value) => setState(() => _cycleLength = value),
              ),
              const SizedBox(height: 16),
              _NumberStepper(
                label: 'Lama haid',
                helper: 'Rata-rata berapa hari kamu mengalami haid.',
                value: _periodLength,
                min: 2,
                max: 10,
                suffix: 'hari',
                onChanged: (value) => setState(() => _periodLength = value),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        size: 19,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hari pertama haid terakhir',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(_lastPeriodStart),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _pickStartDate,
                      child: const Text(
                        'Ubah',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSaving ? null : _save,
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Simpan Pengaturan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberStepper extends StatelessWidget {
  final String label;
  final String helper;
  final int value;
  final int min;
  final int max;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _NumberStepper({
    required this.label,
    required this.helper,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                enabled: value > min,
                onTap: () => onChanged(value - 1),
              ),
              Expanded(
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$value',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        TextSpan(
                          text: '  $suffix',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                enabled: value < max,
                onTap: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? Colors.white : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(
            icon,
            size: 19,
            color: enabled ? const Color(0xFFE11D48) : const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }
}
