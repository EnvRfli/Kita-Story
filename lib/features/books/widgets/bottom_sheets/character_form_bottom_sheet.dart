import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/services/supabase_storage_service.dart';
import '../../repositories/book_repository.dart';
import 'character_avatar_picker_bottom_sheet.dart';

class CharacterFormBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? initialCharacter;
  final List<String> availableRoles;
  final Future<void> Function(
    Map<String, dynamic> characterData,
    List<String> traits,
  ) onSave;

  const CharacterFormBottomSheet({
    super.key,
    this.initialCharacter,
    this.availableRoles = const [],
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    Map<String, dynamic>? initialCharacter,
    List<String> availableRoles = const [],
    required Future<void> Function(
      Map<String, dynamic> characterData,
      List<String> traits,
    ) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => CharacterFormBottomSheet(
        initialCharacter: initialCharacter,
        availableRoles: availableRoles,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CharacterFormBottomSheet> createState() =>
      _CharacterFormBottomSheetState();
}

class _CharacterFormBottomSheetState extends State<CharacterFormBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _appearanceController;

  String? _photoUrl;
  Uint8List? _photoBytes;
  bool _isUploadingPhoto = false;

  String _selectedRole = 'Main';
  final List<String> _customRoles = [];

  bool _isSaving = false;

  final List<String> _defaultRoles = [
    'Main',
    'Side',
    'Detektif Kepolisian',
    'Antagonis',
    'Korban',
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialCharacter;
    _nameController = TextEditingController(text: init?['name'] ?? '');
    _descriptionController =
        TextEditingController(text: init?['description'] ?? '');
    _appearanceController = TextEditingController(
      text: init?['first_appearance_page'] != null
          ? init!['first_appearance_page'].toString()
          : '',
    );

    _photoUrl = init?['photo_url'];

    // Setup initial role
    final initialRole = init?['role'] as String?;
    if (initialRole != null && initialRole.trim().isNotEmpty) {
      _selectedRole = initialRole.trim();
      if (!_defaultRoles.contains(_selectedRole) &&
          !widget.availableRoles.contains(_selectedRole)) {
        _customRoles.add(_selectedRole);
      }
    } else {
      _selectedRole = 'Main';
    }

    _loadAvailableRoles();
  }

  Future<void> _loadAvailableRoles() async {
    try {
      final roles = await BookRepository().getAllRoles();
      if (mounted) {
        setState(() {
          for (final r in roles) {
            if (!_defaultRoles.contains(r) && !_customRoles.contains(r)) {
              _customRoles.add(r);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading roles: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _appearanceController.dispose();
    super.dispose();
  }

  void _showAddRoleDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Tambah Peran',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: 'Nama peran (misal: Saksi)',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0088FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  if (!_customRoles.contains(val)) {
                    _customRoles.add(val);
                  }
                  _selectedRole = val;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePickPhoto() async {
    final result = await CharacterAvatarPickerBottomSheet.show(
      context,
      currentPhotoUrl: _photoUrl,
    );
    if (result == null) return;

    // 1. System preset selected -> No storage upload!
    if (result.assetPath != null) {
      setState(() {
        _photoBytes = null;
        _photoUrl = result.assetPath;
      });
      if (mounted) {
        AppSnackBar.success(context, 'Avatar karakter dipilih!');
      }
      return;
    }

    // 2. Custom photo via Camera or Gallery -> Upload to bucket
    if (result.imageSource != null) {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: result.imageSource!,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingPhoto = true);

      try {
        final bytes = await image.readAsBytes();
        final ext = image.name.split('.').lastOrNull ?? 'jpg';

        final publicUrl = await SupabaseStorageService.uploadCharacterPhoto(
          bytes,
          fileExtension: ext,
          contentType: image.mimeType,
        );

        if (!mounted) return;

        setState(() {
          _photoBytes = bytes;
          _photoUrl = publicUrl;
          _isUploadingPhoto = false;
        });

        AppSnackBar.success(context, 'Foto karakter berhasil diunggah!');
      } catch (e) {
        if (!mounted) return;
        setState(() => _isUploadingPhoto = false);
        AppSnackBar.error(
          context,
          e.toString().replaceAll('Exception: ', ''),
          title: 'Upload Gagal',
        );
      }
    }
  }

  Widget _buildAvatarImage() {
    if (_photoBytes != null) {
      return ClipOval(
        child: Image.memory(
          _photoBytes!,
          fit: BoxFit.cover,
        ),
      );
    }

    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      final isNetwork = _photoUrl!.startsWith('http');
      return ClipOval(
        child: isNetwork
            ? Image.network(
                _photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 46,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              )
            : Image.asset(
                _photoUrl!.replaceFirst('asset:', ''),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 46,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
      );
    }

    return const Center(
      child: Icon(
        Icons.person_rounded,
        size: 46,
        color: Color(0xFF7C3AED),
      ),
    );
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppSnackBar.warning(context, 'Nama karakter wajib diisi');
      return;
    }

    if (_isUploadingPhoto) {
      AppSnackBar.warning(
        context,
        'Harap tunggu proses upload foto selesai.',
        title: 'Sedang Mengunggah',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final pageNum = int.tryParse(_appearanceController.text.trim());

      final characterData = {
        'name': name,
        'role': _selectedRole,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'photo_url': _photoUrl,
        'first_appearance_page': pageNum,
      };

      await widget.onSave(characterData, []);

      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.success(
          context,
          widget.initialCharacter != null
              ? 'Karakter "$name" berhasil diperbarui!'
              : 'Karakter "$name" berhasil ditambahkan!',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.error(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Set<String> allRolesSet = {
      ..._defaultRoles,
      ...widget.availableRoles,
      ..._customRoles,
    };
    final allRoles = allRolesSet.toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
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

            // Title Header
            const Text(
              'Karakter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 20),

            // Avatar Upload Container with Amber Edit Badge
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  InkWell(
                    onTap: _isUploadingPhoto ? null : _handlePickPhoto,
                    borderRadius: BorderRadius.circular(45),
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isUploadingPhoto
                          ? const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF7C3AED),
                                ),
                              ),
                            )
                          : _buildAvatarImage(),
                    ),
                  ),
                  // Amber Edit Badge Icon (Bottom Right)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: InkWell(
                      onTap: _isUploadingPhoto ? null : _handlePickPhoto,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFB800)
                                  .withValues(alpha: 0.35),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 1. Nama Karakter
            _buildFieldLabel('Nama Karakter'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hintText: 'Masukkan nama karakter',
            ),
            const SizedBox(height: 18),

            // 2. Deskripsi
            _buildFieldLabel('Deskripsi'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: TextField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                style:
                    const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
                decoration: const InputDecoration(
                  hintText: 'Masukkan deskripsi',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 3. Peran (Role Pills)
            _buildFieldLabel('Peran'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...allRoles.map((role) {
                  final isSelected = _selectedRole.toLowerCase().trim() ==
                      role.toLowerCase().trim();

                  return InkWell(
                    onTap: () => setState(() => _selectedRole = role),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF7A00)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  );
                }),
                // Add Role (+) Button
                InkWell(
                  onTap: _showAddRoleDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 4. Kemunculan Pertama
            _buildFieldLabel('Kemunculan Pertama'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _appearanceController,
              hintText: 'Halaman ke - 0',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 28),

            // 5. Simpan Button (Gradient 0088FF -> 0775D5)
            Container(
              width: double.infinity,
              height: 48,
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
                    color: const Color(0xFF0088FF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSaving ? null : _handleSave,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Simpan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
