import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/cycle_day_log_model.dart';
import '../providers/cycle_provider.dart';
import '../utils/cycle_date_utils.dart';

class CycleLogSheet extends StatefulWidget {
  final String userId;
  final CycleDayLogModel? logToEdit;
  final DateTime? initialDate;
  final String? initialFlow;

  const CycleLogSheet({
    super.key,
    required this.userId,
    this.logToEdit,
    this.initialDate,
    this.initialFlow,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    CycleDayLogModel? logToEdit,
    DateTime? initialDate,
    String? initialFlow,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CycleLogSheet(
        userId: userId,
        logToEdit: logToEdit,
        initialDate: initialDate,
        initialFlow: initialFlow,
      ),
    );
  }

  @override
  State<CycleLogSheet> createState() => _CycleLogSheetState();
}

class _CycleLogSheetState extends State<CycleLogSheet> {
  late final TextEditingController _notesController;
  late DateTime _date;
  late String _flow;
  String? _mood;
  late Set<String> _symptoms;

  bool _isSaving = false;
  bool _isDeleting = false;

  bool get isEditing => widget.logToEdit != null;

  @override
  void initState() {
    super.initState();
    final log = widget.logToEdit;
    _date = log?.logDate ?? widget.initialDate ?? DateTime.now();
    _flow = log?.flow ?? widget.initialFlow ?? 'none';
    _mood = log?.mood;
    _symptoms = {...?log?.symptoms};
    _notesController = TextEditingController(text: log?.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) => cycleLongDate(date);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
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

    final existing =
        context.read<CycleProvider>().dataFor(widget.userId)?.logForDate(picked);

    setState(() {
      _date = picked;
      _flow = existing?.flow ?? 'none';
      _mood = existing?.mood;
      _symptoms = {...?existing?.symptoms};
      _notesController.text = existing?.notes ?? '';
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final provider = context.read<CycleProvider>();
    final auth = context.read<AuthProvider>();
    final result = await provider.saveDayLog(
      userId: widget.userId,
      date: _date,
      flow: _flow,
      mood: _mood,
      symptoms: _symptoms.toList(),
      notes: _notesController.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      if (result.pointsAwarded > 0) {
        AppSnackBar.success(
          context,
          'Catatan siklus tersimpan! (+${result.pointsAwarded} Poin)',
        );
      } else {
        AppSnackBar.success(context, 'Catatan siklus diperbarui.');
      }
      await auth.refreshProfile();
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      AppSnackBar.error(
        context,
        provider.errorMessage ?? 'Gagal menyimpan catatan siklus',
      );
    }
  }

  Future<void> _delete() async {
    final log = widget.logToEdit;
    if (log == null || _isDeleting) return;

    setState(() => _isDeleting = true);
    final provider = context.read<CycleProvider>();
    final success = await provider.deleteDayLog(
      userId: widget.userId,
      logId: log.id,
    );

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (success) {
      AppSnackBar.success(context, 'Catatan siklus dihapus.');
      Navigator.of(context).pop();
    } else {
      AppSnackBar.error(
        context,
        provider.errorMessage ?? 'Gagal menghapus catatan siklus',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Catatan Siklus' : 'Catat Siklus',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(_date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(
                        Icons.calendar_today_rounded,
                        size: 15,
                        color: Color(0xFFE11D48),
                      ),
                      label: const Text(
                        'Ganti tanggal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _SectionLabel('Aliran haid'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CycleDayLogModel.flowKeys.map((flow) {
                    final sample = CycleDayLogModel(
                      id: '',
                      userId: '',
                      logDate: _date,
                      flow: flow,
                    );
                    return _SelectChip(
                      label: sample.flowLabel,
                      selected: _flow == flow,
                      color: sample.flowColor,
                      onTap: () => setState(() => _flow = flow),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const _SectionLabel('Mood'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CycleDayLogModel.moodKeys.map((mood) {
                    return _SelectChip(
                      label:
                          '${CycleDayLogModel.moodEmojiFor(mood)} ${CycleDayLogModel.moodLabelFor(mood)}',
                      selected: _mood == mood,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => setState(
                        () => _mood = _mood == mood ? null : mood,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const _SectionLabel('Gejala'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CycleDayLogModel.symptomKeys.map((symptom) {
                    final selected = _symptoms.contains(symptom);
                    return _SelectChip(
                      label: CycleDayLogModel.symptomLabelFor(symptom),
                      selected: selected,
                      color: const Color(0xFF0EA5E9),
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _symptoms.remove(symptom);
                          } else {
                            _symptoms.add(symptom);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const _SectionLabel('Catatan'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _notesController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Ceritakan kondisimu hari ini...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                          color:
                              const Color(0xFFE11D48).withValues(alpha: 0.3),
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
                                  'Simpan Catatan',
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
                if (isEditing) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _isDeleting ? null : _delete,
                      child: _isDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFDC2626),
                                ),
                              ),
                            )
                          : const Text(
                              'Hapus catatan ini',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFDC2626),
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
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Color(0xFF334155),
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SelectChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : const Color(0xFFE2E8F0),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? color : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
