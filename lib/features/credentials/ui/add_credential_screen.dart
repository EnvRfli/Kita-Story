import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/credential_model.dart';
import '../providers/credential_provider.dart';

class _FieldItem {
  final TextEditingController labelController;
  final TextEditingController valueController;
  bool isObscured;

  _FieldItem({
    required this.labelController,
    required this.valueController,
    this.isObscured = false,
  });

  void dispose() {
    labelController.dispose();
    valueController.dispose();
  }
}

class AddCredentialScreen extends StatefulWidget {
  final CredentialModel? credentialToEdit;

  const AddCredentialScreen({
    super.key,
    this.credentialToEdit,
  });

  @override
  State<AddCredentialScreen> createState() => _AddCredentialScreenState();
}

class _AddCredentialScreenState extends State<AddCredentialScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _keteranganController;
  final List<_FieldItem> _fields = [];

  String _selectedCategory = 'Aplikasi';
  String? _selectedCategoryId;
  String _selectedSubcategory = '';
  String? _selectedSubcategoryId;

  bool _isSaving = false;
  bool _isShared = false;

  bool get _isEditMode => widget.credentialToEdit != null;

  @override
  void initState() {
    super.initState();
    final cred = widget.credentialToEdit;

    _titleController = TextEditingController(text: cred?.title ?? '');
    _keteranganController = TextEditingController(text: cred?.keterangan ?? '');

    if (cred != null) {
      _selectedCategory = cred.categoryName;
      _selectedCategoryId = cred.categoryId;
      _selectedSubcategory = cred.subcategoryName;
      _selectedSubcategoryId = cred.subcategoryId;
      _isShared = cred.isSharedWithPartner;

      for (final field in cred.fields) {
        final lower = field.label.toLowerCase();
        final isSecret = lower.contains('sandi') ||
            lower.contains('pass') ||
            lower.contains('pin') ||
            lower.contains('secret');
        _fields.add(
          _FieldItem(
            labelController: TextEditingController(text: field.label),
            valueController: TextEditingController(text: field.value),
            isObscured: isSecret,
          ),
        );
      }
      if (_fields.isEmpty) {
        _addField();
      }
    } else {
      // Start with 1 clean field ready to fill
      _addField();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCategories();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _keteranganController.dispose();
    for (final item in _fields) {
      item.dispose();
    }
    super.dispose();
  }

  void _addField(
      {String label = '', String value = '', bool isObscured = false}) {
    setState(() {
      _fields.add(
        _FieldItem(
          labelController: TextEditingController(text: label),
          valueController: TextEditingController(text: value),
          isObscured: isObscured,
        ),
      );
    });
  }

  void _removeField(int index) {
    if (index >= 0 && index < _fields.length) {
      setState(() {
        final removed = _fields.removeAt(index);
        removed.dispose();
      });
    }
  }

  Future<void> _initCategories() async {
    final provider = context.read<CredentialProvider>();
    if (provider.categories.isEmpty) {
      final userId = context.read<AuthProvider>().currentUserProfile?.id ?? '';
      await provider.fetchInitialData(userId);
    }
    if (!mounted) return;
    if (!_isEditMode && provider.categories.isNotEmpty) {
      final currentCat = provider.categories.firstWhere(
        (c) => c.name.toLowerCase() == _selectedCategory.toLowerCase(),
        orElse: () => provider.categories.first,
      );
      setState(() {
        _selectedCategory = currentCat.name;
        _selectedCategoryId = currentCat.id;
      });
      _updateSubcategoriesForCurrentCat();
    } else {
      _updateSubcategoriesForCurrentCat();
    }
  }

  void _updateSubcategoriesForCurrentCat() {
    final provider = context.read<CredentialProvider>();
    final cat = provider.categories.firstWhere(
      (c) => c.name.toLowerCase() == _selectedCategory.toLowerCase(),
      orElse: () => provider.categories.first,
    );

    _selectedCategoryId = cat.id;
    final subcats =
        provider.subcategories.where((s) => s.categoryId == cat.id).toList();

    if (!_isEditMode && subcats.isNotEmpty && _selectedSubcategory.isEmpty) {
      setState(() {
        _selectedSubcategory = subcats.first.name;
        _selectedSubcategoryId = subcats.first.id;
      });
    }
  }

  void _onCategorySelected(String name, String id) {
    setState(() {
      _selectedCategory = name;
      _selectedCategoryId = id;
      _selectedSubcategory = '';
      _selectedSubcategoryId = null;
    });
    _updateSubcategoriesForCurrentCat();
  }

  Future<void> _showAddCategoryDialog() async {
    final textController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Tambah Kategori Baru',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nama Kategori (misal: Investasi)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop(textController.text.trim());
              }
            },
            child: const Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty || !mounted) return;

    final userId = context.read<AuthProvider>().currentUserProfile?.id;
    if (userId == null) return;

    final provider = context.read<CredentialProvider>();
    final newCat = await provider.addCategory(name, userId);
    if (!mounted) return;
    if (newCat != null) {
      _onCategorySelected(newCat.name, newCat.id);
      AppSnackBar.success(context, 'Kategori "$name" berhasil ditambahkan!');
    }
  }

  Future<void> _showAddSubcategoryDialog() async {
    if (_selectedCategoryId == null) {
      AppSnackBar.show(
        context,
        message: 'Pilih kategori terlebih dahulu.',
        type: SnackBarType.warning,
      );
      return;
    }

    final textController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Tambah Sub Kategori ($_selectedCategory)',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nama Sub Kategori (misal: GitHub)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop(textController.text.trim());
              }
            },
            child: const Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty || !mounted) return;

    final userId = context.read<AuthProvider>().currentUserProfile?.id;
    if (userId == null) return;

    final provider = context.read<CredentialProvider>();
    final newSubcat = await provider.addSubcategory(
      _selectedCategoryId!,
      name,
      userId,
    );
    if (!mounted) return;
    if (newSubcat != null) {
      setState(() {
        _selectedSubcategory = newSubcat.name;
        _selectedSubcategoryId = newSubcat.id;
      });
      AppSnackBar.success(
          context, 'Sub Kategori "$name" berhasil ditambahkan!');
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().currentUserProfile?.id;
    if (userId == null) {
      AppSnackBar.show(
        context,
        message: 'Sesi pengguna tidak valid.',
        type: SnackBarType.error,
      );
      return;
    }

    // Collect all valid fields
    final fields = _fields
        .where((f) =>
            f.labelController.text.trim().isNotEmpty ||
            f.valueController.text.trim().isNotEmpty)
        .map((f) {
      final label = f.labelController.text.trim().isEmpty
          ? 'Informasi'
          : f.labelController.text.trim();
      final value = f.valueController.text.trim();
      return CredentialField(label: label, value: value);
    }).toList();

    if (fields.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Masukkan setidaknya satu informasi kredensial.',
        type: SnackBarType.warning,
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<CredentialProvider>();

    final auth = context.read<AuthProvider>();
    final partnerId = auth.partnerProfile?.id;

    final credential = CredentialModel(
      id: widget.credentialToEdit?.id ?? '',
      userId: userId,
      categoryId: _selectedCategoryId,
      categoryName: _selectedCategory,
      subcategoryId: _selectedSubcategoryId,
      subcategoryName: _selectedSubcategory,
      title: _titleController.text.trim(),
      fields: fields,
      keterangan: _keteranganController.text.trim().isEmpty
          ? null
          : _keteranganController.text.trim(),
      isSharedWithPartner: _isShared,
      partnerId: _isShared ? partnerId : null,
      createdAt: widget.credentialToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final bool success = _isEditMode
        ? await provider.updateCredential(credential)
        : await provider.addCredential(credential);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      final isShared = credential.isSharedWithPartner;
      AppSnackBar.success(
        context,
        _isEditMode
            ? 'Kredensial berhasil diperbarui!'
            : isShared
                ? 'Kredensial Bersama "${credential.title}" berhasil disimpan! (+10 Poin 🎉)'
                : 'Kredensial "${credential.title}" berhasil disimpan! (+5 Poin 🎉)',
      );
      context.pop();
    } else {
      AppSnackBar.show(
        context,
        message: provider.errorMessage ?? 'Gagal menyimpan kredensial.',
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CredentialProvider>();
    final categories = provider.categories;

    final currentSubcategories = provider.subcategories.where((s) {
      if (_selectedCategoryId == null) return true;
      return s.categoryId == _selectedCategoryId;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Bar
            Container(
              color: const Color(0xFFFCFCFD),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF1E293B),
                      size: 22,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      }
                    },
                  ),
                  Expanded(
                    child: Text(
                      _isEditMode ? 'Ubah Kredensial' : 'Tambah Kredensial',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 2. Scrollable Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  children: [
                    // Section 1: Kategori
                    _buildSectionHeader('Kategori'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...categories.map((cat) {
                          final isSelected = cat.name.toLowerCase() ==
                              _selectedCategory.toLowerCase();
                          return InkWell(
                            onTap: () => _onCategorySelected(cat.name, cat.id),
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
                                cat.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          );
                        }),
                        InkWell(
                          onTap: _showAddCategoryDialog,
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
                    const SizedBox(height: 20),

                    // Section 2: Sub Kategori
                    _buildSectionHeader('Sub Kategori'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...currentSubcategories.map((subcat) {
                          final isSelected = subcat.name.toLowerCase() ==
                              _selectedSubcategory.toLowerCase();
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedSubcategory = subcat.name;
                                _selectedSubcategoryId = subcat.id;
                              });
                            },
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
                                subcat.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          );
                        }),
                        InkWell(
                          onTap: _showAddSubcategoryDialog,
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
                    const SizedBox(height: 22),

                    // Section 3: Judul (Wajib)
                    _buildFormField(
                      label: 'Judul',
                      controller: _titleController,
                      hintText: 'misal: Server VPS, PIN ATM, Netflix, GitHub',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Section 4: Data Kredensial (Dinamis & Fleksibel)
                    Row(
                      children: [
                        _buildSectionHeader('Informasi Kredensial'),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_fields.length}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Masukkan informasi apa saja (misal: SSH IP, PIN, Password, Token, dsb.)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // List of Dynamic Fields
                    ..._fields.asMap().entries.map((entry) {
                      return _buildFieldCard(entry.key, entry.value);
                    }),

                    // Button: "+ Tambah Field Baru"
                    InkWell(
                      onTap: () => _addField(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFBAE6FD),
                            width: 1.2,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                              color: Color(0xFF0088FF),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tambah Field Baru',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0088FF),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 5: Keterangan (Opsional)
                    _buildFormField(
                      label: 'Keterangan (Opsional)',
                      controller: _keteranganController,
                      hintText:
                          'Tambahkan catatan atau detail lain jika ada...',
                      maxLines: 4,
                      minLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // Section 6: Kredensial Bersama Toggle Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isShared
                              ? const Color(0xFF0088FF)
                              : const Color(0xFFE2E8F0),
                          width: _isShared ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isShared
                                ? const Color(0xFF0088FF)
                                    .withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
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
                                  'Kredensial Bersama',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Sinkronkan agar dapat dilihat di aplikasi pasangan',
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
                            onChanged: (val) => setState(() => _isShared = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Section 7: Tombol Simpan (Gradient Biru)
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientBiru,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0284F6).withValues(alpha: 0.32),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSaving ? null : _handleSave,
                          borderRadius: BorderRadius.circular(14),
                          child: Center(
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : Text(
                                    _isEditMode ? 'Perbarui' : 'Simpan',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
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
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(int index, _FieldItem field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris 1: Label / Nama Field + Tombol Hapus (✕)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 8, 7),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: field.labelController,
                    onChanged: (val) {
                      final lower = val.toLowerCase();
                      if ((lower.contains('sandi') ||
                              lower.contains('pass') ||
                              lower.contains('pin') ||
                              lower.contains('secret')) &&
                          !field.isObscured) {
                        setState(() => field.isObscured = true);
                      }
                    },
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Label (misal: SSH IP, PIN, Password, Email)',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_fields.length > 1)
                  InkWell(
                    onTap: () => _removeField(index),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1),

          // Baris 2: Nilai / Value Field + Toggle Sembunyikan Mata
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 7, 8, 8),
            child: TextFormField(
              controller: field.valueController,
              obscureText: field.isObscured,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                hintText: 'Nilai / isi kredensial',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 2),
                suffixIconConstraints: const BoxConstraints(),
                suffixIcon: InkWell(
                  onTap: () {
                    setState(() => field.isObscured = !field.isObscured);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      field.isObscured
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 18,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    int minLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: minLines,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF0088FF),
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
