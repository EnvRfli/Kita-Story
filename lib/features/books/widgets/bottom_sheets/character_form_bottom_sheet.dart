import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/services/supabase_storage_service.dart';
import 'image_source_bottom_sheet.dart';

class CharacterFormBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? initialCharacter;
  final List<String> availableTraits;
  final List<String> availableRoles;
  final Future<void> Function(
    Map<String, dynamic> characterData,
    List<String> traits,
  ) onSave;
  final Future<void> Function()? onDelete;

  const CharacterFormBottomSheet({
    super.key,
    this.initialCharacter,
    this.availableTraits = const [],
    this.availableRoles = const [],
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    Map<String, dynamic>? initialCharacter,
    List<String> availableTraits = const [],
    List<String> availableRoles = const [],
    required Future<void> Function(
      Map<String, dynamic> characterData,
      List<String> traits,
    ) onSave,
    Future<void> Function()? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => CharacterFormBottomSheet(
        initialCharacter: initialCharacter,
        availableTraits: availableTraits,
        availableRoles: availableRoles,
        onSave: onSave,
        onDelete: onDelete,
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
  late final TextEditingController _roleInputController;

  String? _photoUrl;
  Uint8List? _photoBytes;
  bool _isUploadingPhoto = false;

  late String _selectedRole;
  late String _selectedGender;
  final List<String> _selectedTraits = [];
  final List<String> _customRoles = [];

  bool _isSaving = false;
  bool _isDeleting = false;
  bool _showAddRoleField = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

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
    _roleInputController = TextEditingController();

    _photoUrl = init?['photo_url'];

    // Setup initial role
    final initialRole = init?['role'] as String?;
    if (initialRole != null && initialRole.isNotEmpty) {
      _selectedRole = initialRole;
      if (!widget.availableRoles.contains(initialRole)) {
        _customRoles.add(initialRole);
      }
    } else if (widget.availableRoles.isNotEmpty) {
      _selectedRole = widget.availableRoles.first;
    } else {
      _selectedRole = 'Main';
    }

    _selectedGender = init?['gender'] ?? 'Male';

    if (init?['traits'] != null && init!['traits'] is List) {
      _selectedTraits.addAll(List<String>.from(init['traits']));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _appearanceController.dispose();
    _roleInputController.dispose();
    super.dispose();
  }

  void _addNewRole(String text) {
    final val = text.trim();
    if (val.isNotEmpty) {
      setState(() {
        if (!_customRoles.contains(val) &&
            !widget.availableRoles.contains(val)) {
          _customRoles.add(val);
        }
        _selectedRole = val;
        _roleInputController.clear();
        _showAddRoleField = false;
      });
    }
  }

  Future<void> _handlePickPhoto() async {
    final source = await ImageSourceBottomSheet.show(
      context,
      title: 'Foto Profil Karakter',
      subtitle: 'Pilih foto profil dari kamera atau galeri ponsel.',
    );
    if (source == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
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
        'Gagal mengunggah foto karakter: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  void _handleRemovePhoto() {
    setState(() {
      _photoBytes = null;
      _photoUrl = null;
    });
  }

  Future<void> _handleDelete() async {
    if (widget.onDelete == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Karakter',
          style: TextStyle(
            color: Color(0xFF6B4454),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus karakter "${_nameController.text.trim()}"?',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9534F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    await widget.onDelete!();
    if (mounted) {
      Navigator.of(context).pop();
      AppSnackBar.success(context, 'Karakter berhasil dihapus');
    }
  }

  Future<void> _handleSave() async {
    if (_isUploadingPhoto) {
      AppSnackBar.warning(
        context,
        'Harap tunggu proses upload foto karakter selesai terlebih dahulu.',
        title: 'Sedang Mengunggah',
      );
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppSnackBar.warning(context, 'Nama karakter wajib diisi');
      return;
    }

    final page = int.tryParse(_appearanceController.text.trim());
    final description = _descriptionController.text.trim();

    final characterData = {
      'name': name,
      'gender': _selectedGender,
      'role': _selectedRole,
      'description': description.isNotEmpty ? description : null,
      'first_appearance_page': page,
      'photo_url': _photoUrl,
    };

    setState(() => _isSaving = true);
    await widget.onSave(characterData, _selectedTraits);
    if (mounted) {
      Navigator.of(context).pop();
      AppSnackBar.success(
        context,
        widget.initialCharacter != null
            ? 'Karakter berhasil diperbarui'
            : 'Karakter baru berhasil ditambahkan',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialCharacter != null;

    final allRoles = <String>{
      ...widget.availableRoles,
      ..._customRoles,
      if (_selectedRole.isNotEmpty) _selectedRole,
    }.toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sticky Header: Title & Subtitle + Optional Delete Action
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Karakter' : 'Tambah Karakter Baru',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4454),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Catat tokoh penting, peran, dan deskripsi karakternya.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (isEditing && widget.onDelete != null)
                  InkWell(
                    onTap: _isDeleting ? null : _handleDelete,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9534F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isDeleting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFD9534F)),
                              ),
                            )
                          : const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFD9534F),
                              size: 20,
                            ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3E8EC)),

          // Scrollable Form Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar Tap Button (Photo Picker & Preview)
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        InkWell(
                          onTap: _isUploadingPhoto ? null : _handlePickPhoto,
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFADD8E6),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _isUploadingPhoto
                                ? const Center(
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Color(0xFF3B6B8A)),
                                      ),
                                    ),
                                  )
                                : _photoBytes != null
                                    ? ClipOval(
                                        child: Image.memory(
                                          _photoBytes!,
                                          fit: BoxFit.cover,
                                          height: 80,
                                          width: 80,
                                        ),
                                      )
                                    : (_photoUrl != null &&
                                            _photoUrl!.isNotEmpty)
                                        ? ClipOval(
                                            child: Image.network(
                                              _photoUrl!,
                                              fit: BoxFit.cover,
                                              height: 80,
                                              width: 80,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  _buildAvatarPlaceholder(),
                                            ),
                                          )
                                        : _buildAvatarPlaceholder(),
                          ),
                        ),
                        if (!_isUploadingPhoto)
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF6B4454),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if ((_photoUrl != null || _photoBytes != null) &&
                      !_isUploadingPhoto)
                    Center(
                      child: TextButton(
                        onPressed: _handleRemovePhoto,
                        child: const Text(
                          'Hapus Foto',
                          style: TextStyle(
                            color: Color(0xFFD9534F),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 18),

                  // Name Field
                  _buildSectionLabel('Nama Karakter'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B4454),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _buildInputDecoration(
                      hint: 'Masukkan nama karakter...',
                      icon: Icons.person_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gender Selection
                  _buildSectionLabel('Gender'),
                  const SizedBox(height: 6),
                  Row(
                    children: _genders.map((gender) {
                      final isSelected = _selectedGender == gender;
                      final label = gender == 'Male'
                          ? 'Laki-laki'
                          : gender == 'Female'
                              ? 'Perempuan'
                              : 'Lainnya';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6B4454),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF3B6B8A),
                          backgroundColor: const Color(0xFFFAFAFA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF3B6B8A)
                                  : const Color(0xFFEADBDF),
                            ),
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedGender = gender);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Role Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionLabel('Peran Karakter (Role Dinamis)'),
                      InkWell(
                        onTap: () => setState(() {
                          _showAddRoleField = !_showAddRoleField;
                        }),
                        child: Text(
                          _showAddRoleField ? 'Batal' : '+ Tambah Role',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B6B8A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (_showAddRoleField) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _roleInputController,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF6B4454)),
                            onSubmitted: (text) => _addNewRole(text),
                            decoration: InputDecoration(
                              hintText: 'Ketik nama role baru...',
                              hintStyle: const TextStyle(
                                  color: Colors.black38, fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFFFAFAFA),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFFEADBDF), width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFFEADBDF), width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFF3B6B8A), width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _addNewRole(_roleInputController.text),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B4454),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allRoles.map((role) {
                      final isSelected = _selectedRole == role;
                      return ChoiceChip(
                        label: Text(role),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF6B4454),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF6B4454),
                        backgroundColor: const Color(0xFFFAFAFA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF6B4454)
                                : const Color(0xFFEADBDF),
                          ),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedRole = role);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Character Description Field
                  _buildSectionLabel('Deskripsi / Latar Belakang Karakter'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF6B4454),
                      height: 1.35,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Tuliskan deskripsi tokoh, kepribadian, atau latar belakang singkatnya...',
                      hintStyle:
                          const TextStyle(color: Colors.black38, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFFEADBDF), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFFEADBDF), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFF3B6B8A), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // First Appearance Field
                  _buildSectionLabel('Kemunculan Pertama'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _appearanceController,
                    keyboardType: TextInputType.number,
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xFF6B4454)),
                    decoration: _buildInputDecoration(
                      hint: 'Muncul pertama kali di halaman ke...',
                      icon: Icons.menu_book_rounded,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Fixed Bottom Button
          Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B6B8A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isEditing ? 'Perbarui Karakter' : 'Simpan Karakter',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B4454),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    final name = _nameController.text.trim();
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B4454),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF6B4454), size: 18),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEADBDF), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEADBDF), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3B6B8A), width: 1.5),
      ),
    );
  }
}
