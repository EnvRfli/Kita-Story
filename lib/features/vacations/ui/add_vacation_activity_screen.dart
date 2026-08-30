import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../models/vacation_model.dart';
import '../models/vacation_activity_model.dart';
import '../providers/vacation_provider.dart';

class AddVacationActivityScreen extends StatefulWidget {
  final String vacationId;
  final VacationActivityModel? initialActivity;
  final DateTime? defaultDate;
  final String? vacationTitle;

  const AddVacationActivityScreen({
    super.key,
    required this.vacationId,
    this.initialActivity,
    this.defaultDate,
    this.vacationTitle,
  });

  @override
  State<AddVacationActivityScreen> createState() =>
      _AddVacationActivityScreenState();
}

class _AddVacationActivityScreenState extends State<AddVacationActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late DateTime _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  bool get isEditing => widget.initialActivity != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialActivity?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialActivity?.description ?? '');

    _selectedDate = widget.initialActivity?.activityDate ??
        widget.defaultDate ??
        DateTime.now();

    if (widget.initialActivity != null) {
      final startParts = widget.initialActivity!.startTime.split(':');
      if (startParts.length >= 2) {
        _startTime = TimeOfDay(
          hour: int.tryParse(startParts[0]) ?? 9,
          minute: int.tryParse(startParts[1]) ?? 0,
        );
      }

      final endParts = widget.initialActivity!.endTime.split(':');
      if (endParts.length >= 2) {
        _endTime = TimeOfDay(
          hour: int.tryParse(endParts[0]) ?? 12,
          minute: int.tryParse(endParts[1]) ?? 0,
        );
      }
    } else {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 12, minute: 0);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vacation = _getVacation();
      if (vacation != null) {
        final firstDate = DateTime(vacation.startDate.year,
            vacation.startDate.month, vacation.startDate.day);
        final lastDate = DateTime(vacation.endDate.year, vacation.endDate.month,
            vacation.endDate.day);
        if (_selectedDate.isBefore(firstDate)) {
          setState(() => _selectedDate = firstDate);
        } else if (_selectedDate.isAfter(lastDate)) {
          setState(() => _selectedDate = lastDate);
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  VacationModel? _getVacation() {
    final provider = context.read<VacationProvider>();
    if (provider.currentVacation != null &&
        provider.currentVacation!.id == widget.vacationId) {
      return provider.currentVacation;
    }
    try {
      return provider.vacations.firstWhere((v) => v.id == widget.vacationId);
    } catch (_) {
      return null;
    }
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

  String _formatTimeOfDay(TimeOfDay? tod) {
    if (tod == null) return 'Pilih waktu';
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickDate() async {
    final vacation = _getVacation();
    final firstDate = vacation != null
        ? DateTime(vacation.startDate.year, vacation.startDate.month,
            vacation.startDate.day)
        : DateTime(2020);
    final lastDate = vacation != null
        ? DateTime(
            vacation.endDate.year, vacation.endDate.month, vacation.endDate.day)
        : DateTime(2035);

    DateTime initial = _selectedDate;
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<TimeOfDay?> _showWheelTimePicker({
    required BuildContext context,
    required String title,
    required TimeOfDay initialTime,
  }) async {
    int selectedHour = initialTime.hour;
    int selectedMinute = initialTime.minute;

    final fixedHourController =
        FixedExtentScrollController(initialItem: selectedHour);
    final fixedMinuteController =
        FixedExtentScrollController(initialItem: selectedMinute);

    return await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top drag handle
                  Container(
                    width: 40,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header actions: Batal, Title, Selesai
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(
                            ctx,
                            TimeOfDay(
                              hour: selectedHour,
                              minute: selectedMinute,
                            ),
                          );
                        },
                        child: const Text(
                          'Selesai',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6155F5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Selected Time Preview Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 20,
                          color: Color(0xFF6155F5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedHour.toString().padLeft(2, '0')} : ${selectedMinute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Column Labels centered above wheels
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          'Jam',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      SizedBox(width: 24),
                      SizedBox(
                        width: 80,
                        child: Text(
                          'Menit',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Up-Down Vertical Scroll Wheels for Hours & Minutes (Perfect Center Alignment)
                  SizedBox(
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Central selection indicator container (200px width, centered)
                        Container(
                          width: 200,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6155F5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF6155F5)
                                  .withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                        ),

                        // Wheels Row exactly in center
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Hour Wheel (00 - 23)
                            SizedBox(
                              width: 80,
                              height: 160,
                              child: ListWheelScrollView.useDelegate(
                                controller: fixedHourController,
                                itemExtent: 44,
                                perspective: 0.003,
                                diameterRatio: 1.3,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (index) {
                                  setModalState(() {
                                    selectedHour = index;
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 24,
                                  builder: (context, index) {
                                    final isCurrent = index == selectedHour;
                                    return Center(
                                      child: Text(
                                        index.toString().padLeft(2, '0'),
                                        style: TextStyle(
                                          fontSize: isCurrent ? 24 : 17,
                                          fontWeight: isCurrent
                                              ? FontWeight.w800
                                              : FontWeight.w500,
                                          color: isCurrent
                                              ? const Color(0xFF6155F5)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Separator Colon
                            SizedBox(
                              width: 24,
                              height: 48,
                              child: Center(
                                child: Text(
                                  ':',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF6155F5),
                                  ),
                                ),
                              ),
                            ),

                            // Minute Wheel (00 - 59)
                            SizedBox(
                              width: 80,
                              height: 160,
                              child: ListWheelScrollView.useDelegate(
                                controller: fixedMinuteController,
                                itemExtent: 44,
                                perspective: 0.003,
                                diameterRatio: 1.3,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (index) {
                                  setModalState(() {
                                    selectedMinute = index;
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 60,
                                  builder: (context, index) {
                                    final isCurrent = index == selectedMinute;
                                    return Center(
                                      child: Text(
                                        index.toString().padLeft(2, '0'),
                                        style: TextStyle(
                                          fontSize: isCurrent ? 24 : 17,
                                          fontWeight: isCurrent
                                              ? FontWeight.w800
                                              : FontWeight.w500,
                                          color: isCurrent
                                              ? const Color(0xFF6155F5)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickStartTime() async {
    final picked = await _showWheelTimePicker(
      context: context,
      title: 'Pilih Waktu Mulai',
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await _showWheelTimePicker(
      context: context,
      title: 'Pilih Waktu Selesai',
      initialTime: _endTime ?? const TimeOfDay(hour: 12, minute: 0),
    );

    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      AppSnackBar.error(
          context, 'Silakan tentukan waktu mulai dan waktu selesai.');
      return;
    }

    final vacation = _getVacation();
    if (vacation != null) {
      final firstDate = DateTime(vacation.startDate.year,
          vacation.startDate.month, vacation.startDate.day);
      final lastDate = DateTime(
          vacation.endDate.year, vacation.endDate.month, vacation.endDate.day);
      final sel =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

      if (sel.isBefore(firstDate)) {
        AppSnackBar.error(context,
            'Tanggal aktivitas tidak boleh lebih kecil dari tanggal awal liburan (${_formatDate(firstDate)}).');
        return;
      }
      if (sel.isAfter(lastDate)) {
        AppSnackBar.error(context,
            'Tanggal aktivitas tidak boleh lebih besar dari tanggal akhir liburan (${_formatDate(lastDate)}).');
        return;
      }
    }

    final startMin = _startTime!.hour * 60 + _startTime!.minute;
    final endMin = _endTime!.hour * 60 + _endTime!.minute;

    if (endMin <= startMin) {
      AppSnackBar.error(
          context, 'Waktu selesai harus lebih besar dari waktu mulai.');
      return;
    }

    final startStr = _formatTimeOfDay(_startTime);
    final endStr = _formatTimeOfDay(_endTime);

    // Validation: Waktu mulai tidak boleh lebih kecil dari waktu selesai kegiatan lainnya pada hari yang sama
    if (vacation != null) {
      final sel =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final activitiesOnDay = vacation.activities.where((a) {
        if (widget.initialActivity != null &&
            a.id == widget.initialActivity!.id) {
          return false;
        }
        final aDate = DateTime(
            a.activityDate.year, a.activityDate.month, a.activityDate.day);
        return aDate.isAtSameMomentAs(sel);
      }).toList();

      for (final other in activitiesOnDay) {
        final otherStartParts = other.startTime.split(':');
        final otherEndParts = other.endTime.split(':');
        final otherStartMin = (int.tryParse(otherStartParts[0]) ?? 0) * 60 +
            (int.tryParse(
                    otherStartParts.length > 1 ? otherStartParts[1] : '0') ??
                0);
        final otherEndMin = (int.tryParse(otherEndParts[0]) ?? 0) * 60 +
            (int.tryParse(otherEndParts.length > 1 ? otherEndParts[1] : '0') ??
                0);

        if (startMin < otherEndMin && endMin > otherStartMin) {
          AppSnackBar.error(
            context,
            'Waktu mulai ($startStr) tidak boleh lebih kecil dari waktu selesai kegiatan "${other.title}" (${other.endTime}).',
          );
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<VacationProvider>();
      if (isEditing) {
        await provider.updateActivity(
          widget.initialActivity!.id,
          vacationId: widget.vacationId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          activityDate: _selectedDate,
          startTime: startStr,
          endTime: endStr,
        );
        if (mounted) {
          AppSnackBar.success(context, 'Aktivitas berhasil diperbarui! ✨');
          context.pop();
        }
      } else {
        await provider.addActivity(
          vacationId: widget.vacationId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          activityDate: _selectedDate,
          startTime: startStr,
          endTime: endStr,
        );
        if (mounted) {
          AppSnackBar.success(
              context, 'Aktivitas baru berhasil ditambahkan! 🏖️ (+3 Poin)');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Gagal menyimpan aktivitas: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          isEditing ? 'Ubah Aktivitas' : 'Tambah Aktivitas',
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
                      // 1. Judul Aktivitas
                      _buildFieldLabel('Judul Aktivitas'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Masukkan judul aktivitas',
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
                              color: Color(0xFF6155F5),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Judul aktivitas tidak boleh kosong';
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
                              color: Color(0xFF6155F5),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Tanggal
                      _buildFieldLabel('Tanggal'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
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
                                  _formatDate(_selectedDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 4. Waktu Mulai & Waktu Selesai Row
                      Row(
                        children: [
                          // Waktu Mulai
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Waktu Mulai'),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _pickStartTime,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
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
                                          Icons.access_time_rounded,
                                          color: Color(0xFF64748B),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _formatTimeOfDay(_startTime),
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              color: _startTime != null
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFF94A3B8),
                                              fontWeight: _startTime != null
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Waktu Selesai
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Waktu Selesai'),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _pickEndTime,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
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
                                          Icons.access_time_rounded,
                                          color: Color(0xFF64748B),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _formatTimeOfDay(_endTime),
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              color: _endTime != null
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFF94A3B8),
                                              fontWeight: _endTime != null
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                  gradient: AppColors.gradientBiru,
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
