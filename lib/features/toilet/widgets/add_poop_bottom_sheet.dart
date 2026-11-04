import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/poop_log_model.dart';
import '../providers/toilet_provider.dart';
import 'map_picker_bottom_sheet.dart';

class AddPoopBottomSheet extends StatefulWidget {
  final PoopLogModel? logToEdit;

  const AddPoopBottomSheet({
    super.key,
    this.logToEdit,
  });

  static Future<void> show(
    BuildContext context, {
    PoopLogModel? logToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddPoopBottomSheet(logToEdit: logToEdit),
    );
  }

  @override
  State<AddPoopBottomSheet> createState() => _AddPoopBottomSheetState();
}

class _AddPoopBottomSheetState extends State<AddPoopBottomSheet> {
  late final TextEditingController _noteController;

  late DateTime _selectedDateTime;
  late String _selectedStoolType; // 'normal', 'hard', 'soft', 'liquid'

  String _locationName = '';
  String _locationAddress = '';
  double? _latitude;
  double? _longitude;

  bool _isFetchingGps = false;
  String? _gpsError;
  bool _isSaving = false;

  bool get isEditing => widget.logToEdit != null;

  static const List<String> _monthNames = [
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
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.logToEdit;
    _noteController = TextEditingController(text: item?.note ?? '');
    _selectedDateTime = item?.poopedAt ?? DateTime.now();
    _selectedStoolType = item?.stoolType ?? 'normal';

    _locationName = item?.locationName ?? '';
    _locationAddress = item?.locationAddress ?? '';
    _latitude = item?.latitude;
    _longitude = item?.longitude;

    if (!isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _detectGpsLocation();
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _detectGpsLocation() async {
    if (!mounted) return;
    setState(() {
      _isFetchingGps = true;
      _gpsError = null;
    });

    final res = await LocationService.getCurrentLocation();
    if (!mounted) return;

    if (res.success && res.latitude != null && res.longitude != null) {
      setState(() {
        _isFetchingGps = false;
        _latitude = res.latitude;
        _longitude = res.longitude;
        _locationName =
            res.placeName.isNotEmpty ? res.placeName : 'Lokasi Saat Ini';
        _locationAddress = res.address;
        _gpsError = null;
      });
    } else {
      setState(() {
        _isFetchingGps = false;
        _gpsError =
            res.errorMessage ?? 'Nyalakan GPS untuk mendeteksi lokasi otomatis.';
      });
    }
  }

  Future<void> _openMapPicker() async {
    final picked = await MapPickerBottomSheet.show(
      context,
      initialLatitude: _latitude,
      initialLongitude: _longitude,
      initialLocationName: _locationName,
    );

    if (picked != null && mounted) {
      setState(() {
        _locationName = picked.locationName;
        _locationAddress = picked.address;
        _latitude = picked.latitude;
        _longitude = picked.longitude;
        _gpsError = null;
      });
    }
  }

  Future<void> _pickDateAndTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime.isAfter(now) ? now : _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Pilih Tanggal',
      cancelText: 'Batal',
      confirmText: 'Lanjut',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFF7A00),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      helpText: 'Pilih Jam',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFF7A00),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );

    if (!mounted) return;
    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _selectedDateTime.hour,
        pickedTime?.minute ?? _selectedDateTime.minute,
      );
    });
  }

  String _formatDisplayDateTime(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;

    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final dateStr = '${dt.day} ${_monthNames[dt.month - 1]} ${dt.year}';

    if (isToday) {
      return 'Hari ini, $timeStr';
    } else if (isYesterday) {
      return 'Kemarin, $timeStr';
    }
    return '$dateStr, $timeStr';
  }

  Future<void> _handleSave() async {
    if (_locationName.trim().isEmpty || _latitude == null || _longitude == null) {
      AppSnackBar.error(
        context,
        'Pilih lokasi di peta atau aktifkan GPS terlebih dahulu',
      );
      return;
    }

    setState(() => _isSaving = true);

    final toiletProvider = context.read<ToiletProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUserProfile;
    final partner = authProvider.partnerProfile;

    bool success = false;
    if (isEditing) {
      success = await toiletProvider.updatePoopLog(
        widget.logToEdit!.id,
        poopedAt: _selectedDateTime,
        isBackdated: false,
        locationName: _locationName.trim(),
        locationAddress: _locationAddress.trim(),
        latitude: _latitude,
        longitude: _longitude,
        isManualLocation: false,
        stoolType: _selectedStoolType,
        feeling: 'relieved',
        durationMinutes: 5,
        note: _noteController.text.trim(),
        isShared: true,
        partnerId: partner?.id,
      );
    } else {
      success = await toiletProvider.createPoopLog(
        poopedAt: _selectedDateTime,
        isBackdated: false,
        locationName: _locationName.trim(),
        locationAddress: _locationAddress.trim(),
        latitude: _latitude,
        longitude: _longitude,
        isManualLocation: false,
        stoolType: _selectedStoolType,
        feeling: 'relieved',
        durationMinutes: 5,
        note: _noteController.text.trim(),
        isShared: true,
        partnerId: partner?.id,
        currentUserName: currentUser?.name,
        currentUserPhotoUrl: currentUser?.photoUrl,
        currentUserGender: currentUser?.gender,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      await authProvider.refreshProfile();
      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnackBar.success(
        context,
        isEditing
            ? 'Catatan berhasil diperbarui! ✨'
            : 'Berhasil dicatat! 🚽✨ (+5 Poin)',
      );
    } else {
      AppSnackBar.error(
        context,
        toiletProvider.errorMessage ?? 'Gagal menyimpan catatan',
      );
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
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottomInset),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Handle Bar
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Title
                Text(
                  isEditing ? 'Ubah Catatan Toilet' : 'Catat Toilet 🚽',
                  style: const TextStyle(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Lokasi (Tap to pick pin on Map)
                const Text(
                  'Lokasi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                _buildLocationPickerBox(),
                const SizedBox(height: 14),

                // 4. Waktu (Tap to change date & time)
                const Text(
                  'Waktu',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDateAndTime,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 19,
                          color: Color(0xFFFF7A00),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _formatDisplayDateTime(_selectedDateTime),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const Text(
                          'Ubah',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0088FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 5. Kondisi (4 Simple Chips)
                const Text(
                  'Kondisi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildConditionChip('normal', 'Lancar ✨'),
                    const SizedBox(width: 8),
                    _buildConditionChip('hard', 'Keras 🪨'),
                    const SizedBox(width: 8),
                    _buildConditionChip('soft', 'Lembek 🍦'),
                    const SizedBox(width: 8),
                    _buildConditionChip('liquid', 'Cair 🌊'),
                  ],
                ),
                const SizedBox(height: 14),

                // 6. Catatan Singkat (Opsional)
                const Text(
                  'Catatan (Opsional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tulis catatan singkat...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF0088FF),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 7. Simpan Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A00),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEditing ? 'Simpan Perubahan' : 'Simpan',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPickerBox() {
    if (_isFetchingGps) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Color(0xFF0088FF),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mencari lokasi GPS saat ini...',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final hasLocation = _locationName.trim().isNotEmpty;

    return InkWell(
      onTap: _openMapPicker,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _gpsError != null && !hasLocation
                ? const Color(0xFFFDA4AF)
                : const Color(0xFFE2E8F0),
            width: 1.1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A00).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Color(0xFFFF7A00),
                size: 19,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: hasLocation
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (_locationAddress.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _locationAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    )
                  : Text(
                      _gpsError ?? 'Ketuk untuk memilih titik lokasi di peta',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _gpsError != null
                            ? const Color(0xFFE11D48)
                            : const Color(0xFF64748B),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map_rounded,
                    size: 14,
                    color: Color(0xFF0088FF),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Peta',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0088FF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionChip(String value, String label) {
    final isSelected = _selectedStoolType == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedStoolType = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0088FF)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0088FF)
                  : const Color(0xFFE2E8F0),
              width: 1.1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
