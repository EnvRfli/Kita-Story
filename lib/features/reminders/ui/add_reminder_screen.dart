import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/reminder_model.dart';
import '../providers/reminder_provider.dart';

class AddReminderScreen extends StatefulWidget {
  final ReminderModel? reminderToEdit;

  const AddReminderScreen({
    super.key,
    this.reminderToEdit,
  });

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  DateTime? _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 0, minute: 0);
  bool _hasCustomTime = false;

  bool _isShared = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final item = widget.reminderToEdit;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descriptionController =
        TextEditingController(text: item?.description ?? '');

    if (item != null) {
      _selectedDate = item.targetDate;
      _selectedTime = TimeOfDay(
        hour: item.targetDate.hour,
        minute: item.targetDate.minute,
      );
      _hasCustomTime = item.hasCustomTime;
      _isShared = item.isShared;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 50),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFF7A00),
            onPrimary: Colors.white,
            onSurface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final initial = _hasCustomTime ? _selectedTime : TimeOfDay.now();

    final picked = await _showWheelTimePicker(
      context: context,
      title: 'Atur Waktu Agenda',
      initialTime: initial,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _hasCustomTime = true;
      });
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
                            color: Color(0xFFFF7A00),
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
                          color: Color(0xFFFF7A00),
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

                  // Up-Down Vertical Scroll Wheels for Hours & Minutes
                  SizedBox(
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Central selection indicator container
                        Container(
                          width: 200,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF7A00).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFFF7A00)
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
                                              ? const Color(0xFFFF7A00)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Separator Colon
                            const SizedBox(
                              width: 24,
                              height: 48,
                              child: Center(
                                child: Text(
                                  ':',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFFF7A00),
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
                                              ? const Color(0xFFFF7A00)
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

  String _formatDisplayDate(DateTime? date) {
    if (date == null) return '';
    const months = [
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDisplayTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      AppSnackBar.error(context, 'Pilih tanggal agenda terlebih dahulu');
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppSnackBar.error(context, 'Judul agenda tidak boleh kosong');
      return;
    }

    setState(() => _isLoading = true);

    final finalDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _hasCustomTime ? _selectedTime.hour : 0,
      _hasCustomTime ? _selectedTime.minute : 0,
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final partnerId = authProvider.partnerProfile?.id;
    final provider = Provider.of<ReminderProvider>(context, listen: false);

    bool success = false;
    final isEditing = widget.reminderToEdit != null;

    if (isEditing) {
      success = await provider.updateReminder(
        widget.reminderToEdit!.id,
        title: title,
        description: _descriptionController.text.trim(),
        targetDate: finalDateTime,
        hasCustomTime: _hasCustomTime,
        isShared: _isShared,
        partnerId: _isShared ? partnerId : null,
      );
    } else {
      success = await provider.createReminder(
        title: title,
        description: _descriptionController.text.trim(),
        targetDate: finalDateTime,
        hasCustomTime: _hasCustomTime,
        isShared: _isShared,
        partnerId: _isShared ? partnerId : null,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      AppSnackBar.success(
        context,
        isEditing
            ? 'Pengingat "$title" berhasil diperbarui!'
            : 'Pengingat "$title" berhasil disimpan! (+5 Poin 🎉)',
      );
      context.pop();
    } else {
      AppSnackBar.error(
        context,
        provider.errorMessage ?? 'Gagal menyimpan pengingat',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reminderToEdit != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF1E293B),
            size: 22,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditing ? 'Ubah Pengingat' : 'Tambah Pengingat',
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Judul Agenda
                      _buildFieldLabel('Judul Agenda'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _titleController,
                        hintText: 'Masukkan judul agenda',
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Judul agenda tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // 2. Tanggal Agenda
                      _buildFieldLabel('Tanggal Agenda'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              Expanded(
                                child: Text(
                                  _selectedDate != null
                                      ? _formatDisplayDate(_selectedDate)
                                      : 'Masukkan tanggal agenda',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: _selectedDate != null
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFF94A3B8),
                                    fontWeight: _selectedDate != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: Color(0xFF1E293B),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 3. Waktu Agenda (Jam & Menit - Opsional)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFieldLabel('Waktu Agenda (Opsional)'),
                          if (_hasCustomTime)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _hasCustomTime = false;
                                  _selectedTime =
                                      const TimeOfDay(hour: 0, minute: 0);
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Reset (00:00)',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFFFF3B30),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              Expanded(
                                child: Text(
                                  _hasCustomTime
                                      ? _formatDisplayTime(_selectedTime)
                                      : 'Pukul 00:00 (Ketuk untuk atur jam)',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: _hasCustomTime
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFF94A3B8),
                                    fontWeight: _hasCustomTime
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF1E293B),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 4. Deskripsi
                      _buildFieldLabel('Deskripsi'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: TextFormField(
                          controller: _descriptionController,
                          minLines: 4,
                          maxLines: 6,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFF1E293B),
                            height: 1.4,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Masukkan deskripsi',
                            hintStyle: TextStyle(
                              fontSize: 14.5,
                              color: Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const SizedBox(height: 22),

                      // 5. Toggle "Pengingat Bersama" (Shared Reminder)
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
                                ? const Color(0xFF0088FF).withValues(alpha: 0.5)
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
                                children: const [
                                  Text(
                                    'Pengingat Bersama',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Sinkronkan agenda & bunyikan alarm di HP pasangan',
                                    style: TextStyle(
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

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Fixed Simpan Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF0088FF),
                        Color(0xFF0775D5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0088FF).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _handleSave,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: _isLoading
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
                                'Simpan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                ),
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
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: const TextStyle(
          fontSize: 14.5,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14.5,
            color: Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
