import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/vacation_model.dart';
import '../providers/vacation_provider.dart';

class AddVacationScreen extends StatefulWidget {
  final VacationModel? initialVacation;

  const AddVacationScreen({
    super.key,
    this.initialVacation,
  });

  @override
  State<AddVacationScreen> createState() => _AddVacationScreenState();
}

class _AddVacationScreenState extends State<AddVacationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isShared = true;
  bool _isLoading = false;

  bool get isEditing => widget.initialVacation != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialVacation?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialVacation?.description ?? '');

    if (widget.initialVacation != null) {
      _startDate = widget.initialVacation!.startDate;
      _endDate = widget.initialVacation!.endDate;
      _isShared = widget.initialVacation!.isShared;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  String get _dateRangeDisplay {
    if (_startDate == null) return 'Pilih tanggal';
    if (_endDate == null || _startDate == _endDate) {
      return _formatDate(_startDate!);
    }
    return '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime initialStart = _startDate ?? today;
    if (initialStart.isBefore(today)) {
      initialStart = today;
    }
    DateTime initialEnd = _endDate ?? initialStart.add(const Duration(days: 2));
    if (initialEnd.isBefore(initialStart)) {
      initialEnd = initialStart;
    }

    final initialDateRange =
        DateTimeRange(start: initialStart, end: initialEnd);

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: today, // Cannot pick before today
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6155F5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      AppSnackBar.error(context, 'Silakan pilih tanggal liburan.');
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay =
        DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    if (startDay.isBefore(today)) {
      AppSnackBar.error(context,
          'Tanggal liburan tidak boleh lebih kecil dari tanggal sekarang.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<VacationProvider>();
      if (isEditing) {
        await provider.updateVacation(
          widget.initialVacation!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          isShared: _isShared,
        );
        if (mounted) {
          AppSnackBar.success(context, 'Jadwal liburan berhasil diperbarui! ✨');
          context.pop();
        }
      } else {
        await provider.createVacation(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          isShared: _isShared,
        );
        if (mounted) {
          AppSnackBar.success(
              context, 'Jadwal liburan baru berhasil disimpan! ✈️🎉');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Gagal menyimpan jadwal liburan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final partner = authProvider.partnerProfile;
    final hasPartner = partner != null;
    final partnerName = partner?.name;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
            size: 18,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditing ? 'Ubah Jadwal' : 'Tambah Jadwal',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Judul Kegiatan
                      _buildFieldLabel('Judul Kegiatan'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Masukkan judul kegiatan',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF0D8BF0),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Judul kegiatan tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // 2. Deskripsi
                      _buildFieldLabel('Deskripsi'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        minLines: 4,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Masukkan deskripsi',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF0D8BF0),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Tanggal (Date Picker)
                      _buildFieldLabel('Tanggal'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF64748B),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _dateRangeDisplay,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _startDate != null
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFF94A3B8),
                                    fontWeight: _startDate != null
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 4. Shared with Partner Toggle Card (Same as Notes)
                      if (hasPartner) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isShared
                                  ? const Color(0xFF0088FF)
                                      .withValues(alpha: 0.5)
                                  : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _isShared
                                      ? const Color(0xFF0088FF)
                                          .withValues(alpha: 0.12)
                                      : const Color(0xFFE2E8F0),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.favorite_rounded,
                                  color: _isShared
                                      ? const Color(0xFF0088FF)
                                      : const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Liburan Bersama',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      partnerName != null &&
                                              partnerName.isNotEmpty
                                          ? 'Bagikan ke $partnerName, keduanya dapat mengedit & menambah kegiatan'
                                          : 'Bagikan ke pasangan, keduanya dapat mengedit & menambah kegiatan',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _isShared,
                                activeTrackColor: const Color(0xFF0088FF),
                                onChanged: (val) =>
                                    setState(() => _isShared = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Save Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPartnerBlue,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6155F5).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _handleSubmit,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Simpan',
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
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
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
      ),
    );
  }
}
