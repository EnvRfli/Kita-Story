import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/supabase_storage_service.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';

class AddRecipeScreen extends StatefulWidget {
  final RecipeModel? recipeToEdit;

  const AddRecipeScreen({
    super.key,
    this.recipeToEdit,
  });

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _IngredientRowItem {
  final TextEditingController nameController;
  final TextEditingController quantityController;

  _IngredientRowItem({
    required this.nameController,
    required this.quantityController,
  });

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
  }
}

class _StepRowItem {
  final TextEditingController textController;
  Uint8List? localImageBytes;
  String? existingImageUrl;

  _StepRowItem({
    required this.textController,
    this.existingImageUrl,
  });

  void dispose() {
    textController.dispose();
  }
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  // Main Cover Image
  Uint8List? _coverImageBytes;
  String? _existingCoverImageUrl;

  // Structured Duration
  int _durationNumber = 30;
  String _durationUnit = 'menit';

  // Structured Portion
  String _selectedPortion = '2-3 porsi';
  static const List<String> _portionPresets = [
    '1 porsi',
    '2-3 porsi',
    '4-5 porsi',
    '6+ porsi',
  ];

  // Dynamic Lists
  final List<_IngredientRowItem> _ingredients = [];
  final List<_StepRowItem> _steps = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final item = widget.recipeToEdit;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descriptionController =
        TextEditingController(text: item?.description ?? '');
    _existingCoverImageUrl = item?.imageUrl;

    if (item != null) {
      _selectedPortion = item.portionSize;
      _parseDuration(item.cookingDuration);

      // Populate ingredients
      for (final ing in item.ingredients) {
        _ingredients.add(_IngredientRowItem(
          nameController: TextEditingController(text: ing.name),
          quantityController: TextEditingController(text: ing.quantity),
        ));
      }

      // Populate steps
      for (final step in item.instructions) {
        _steps.add(_StepRowItem(
          textController: TextEditingController(text: step.text),
          existingImageUrl: step.imageUrl,
        ));
      }
    }

    // Default at least 2 empty ingredient rows if creating new
    if (_ingredients.isEmpty) {
      _addIngredientRow();
      _addIngredientRow();
    }

    // Default at least 2 empty step rows if creating new
    if (_steps.isEmpty) {
      _addStepRow();
      _addStepRow();
    }
  }

  void _parseDuration(String durationStr) {
    final lower = durationStr.toLowerCase().trim();
    if (lower.contains('jam')) {
      final numPart = double.tryParse(lower.replaceAll('jam', '').trim()) ?? 1;
      _durationNumber = numPart.toInt();
      _durationUnit = 'jam';
    } else {
      final numPart = int.tryParse(lower.replaceAll('menit', '').trim()) ?? 30;
      _durationNumber = numPart;
      _durationUnit = 'menit';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final i in _ingredients) {
      i.dispose();
    }
    for (final s in _steps) {
      s.dispose();
    }
    super.dispose();
  }

  void _addIngredientRow() {
    setState(() {
      _ingredients.add(_IngredientRowItem(
        nameController: TextEditingController(),
        quantityController: TextEditingController(),
      ));
    });
  }

  void _removeIngredientRow(int index) {
    if (_ingredients.length <= 1) return;
    setState(() {
      _ingredients[index].dispose();
      _ingredients.removeAt(index);
    });
  }

  void _addStepRow() {
    setState(() {
      _steps.add(_StepRowItem(
        textController: TextEditingController(),
      ));
    });
  }

  void _removeStepRow(int index) {
    if (_steps.length <= 1) return;
    setState(() {
      _steps[index].dispose();
      _steps.removeAt(index);
    });
  }

  Future<void> _pickCoverImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _coverImageBytes = bytes;
          _existingCoverImageUrl = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking cover image: $e');
    }
  }

  Future<void> _pickStepImage(int index, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 82,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _steps[index].localImageBytes = bytes;
          _steps[index].existingImageUrl = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking step image: $e');
    }
  }

  void _showImageSourcePicker({
    required Function(ImageSource) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Color(0xFFFF7A00),
                ),
              ),
              title: const Text(
                'Kamera',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onSelected(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0088FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFF0088FF),
                ),
              ),
              title: const Text(
                'Galeri',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onSelected(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppSnackBar.error(context, 'Judul resep tidak boleh kosong');
      return;
    }

    final provider = Provider.of<RecipeProvider>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      // 1. Upload Cover Image (if new bytes selected)
      String? finalCoverUrl = _existingCoverImageUrl;
      if (_coverImageBytes != null) {
        finalCoverUrl = await SupabaseStorageService.uploadRecipeImage(
          _coverImageBytes!,
          fileExtension: 'jpg',
          contentType: 'image/jpeg',
        );
      }

      // 2. Prepare Ingredients
      final List<RecipeIngredientModel> finalIngredients = [];
      for (final ing in _ingredients) {
        final name = ing.nameController.text.trim();
        final qty = ing.quantityController.text.trim();
        if (name.isNotEmpty) {
          finalIngredients.add(RecipeIngredientModel(
            name: name,
            quantity: qty.isNotEmpty ? qty : 'Secukupnya',
          ));
        }
      }

      // 3. Upload Step Images & Prepare Instructions
      final List<RecipeStepModel> finalSteps = [];
      for (int i = 0; i < _steps.length; i++) {
        final stepItem = _steps[i];
        final text = stepItem.textController.text.trim();
        if (text.isEmpty && stepItem.localImageBytes == null) continue;

        String? stepImageUrl = stepItem.existingImageUrl;
        if (stepItem.localImageBytes != null) {
          stepImageUrl = await SupabaseStorageService.uploadRecipeImage(
            stepItem.localImageBytes!,
            fileExtension: 'jpg',
            contentType: 'image/jpeg',
          );
        }

        finalSteps.add(RecipeStepModel(
          step: finalSteps.length + 1,
          text: text.isNotEmpty ? text : 'Langkah ${finalSteps.length + 1}',
          imageUrl: stepImageUrl,
        ));
      }

      final durationFormatted = '$_durationNumber $_durationUnit';
      final isEditing = widget.recipeToEdit != null;

      bool success = false;
      if (isEditing) {
        success = await provider.updateRecipe(
          widget.recipeToEdit!.id,
          title: title,
          description: _descriptionController.text.trim(),
          imageUrl: finalCoverUrl,
          cookingDuration: durationFormatted,
          portionSize: _selectedPortion,
          ingredients: finalIngredients,
          instructions: finalSteps,
        );
      } else {
        success = await provider.createRecipe(
          title: title,
          description: _descriptionController.text.trim(),
          imageUrl: finalCoverUrl,
          cookingDuration: durationFormatted,
          portionSize: _selectedPortion,
          ingredients: finalIngredients,
          instructions: finalSteps,
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        AppSnackBar.success(
          context,
          isEditing
              ? 'Resep "$title" berhasil diperbarui!'
              : 'Resep "$title" berhasil disimpan! (+5 Poin 🎉)',
        );
        context.pop();
      } else {
        AppSnackBar.error(
          context,
          provider.errorMessage ?? 'Gagal menyimpan resep.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.error(context, 'Terjadi kesalahan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recipeToEdit != null;

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
          isEditing ? 'Ubah Resep' : 'Tambah Resep',
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
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Cover Photo Picker Box (Dashed style)
                      _buildCoverPhotoPicker(),
                      const SizedBox(height: 20),

                      // 2. Judul Resep
                      _buildFieldLabel('Judul Resep'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _titleController,
                        hintText: 'Masukkan judul resep',
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Judul resep tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // 3. Deskripsi
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
                          minLines: 3,
                          maxLines: 4,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFF1E293B),
                            height: 1.35,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Masukkan deskripsi',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 4. Durasi Masak (Structured Input)
                      _buildFieldLabel('Durasi Masak'),
                      const SizedBox(height: 8),
                      _buildDurationSelector(),
                      const SizedBox(height: 18),

                      // 5. Jumlah Porsi (Structured Input)
                      _buildFieldLabel('Jumlah Porsi'),
                      const SizedBox(height: 8),
                      _buildPortionSelector(),
                      const SizedBox(height: 24),

                      // 6. Bahan-Bahan Section
                      _buildFieldLabel('Bahan-Bahan'),
                      const SizedBox(height: 10),
                      ..._ingredients.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              // Nama Bahan
                              Expanded(
                                flex: 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1.1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: item.nameController,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1E293B),
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Bahan (mis: Ayam)',
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      isDense: true,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Takaran
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1.1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: item.quantityController,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1E293B),
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Takaran (6 sdm)',
                                      hintStyle: TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      isDense: true,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),

                              // Red Trash Button
                              IconButton(
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFFF3B30),
                                  size: 22,
                                ),
                                onPressed: () => _removeIngredientRow(index),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 4),

                      // Button "+ Tambah Bahan"
                      OutlinedButton.icon(
                        onPressed: _addIngredientRow,
                        icon: const Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: Color(0xFFFF7A00),
                        ),
                        label: const Text(
                          'Tambah Bahan',
                          style: TextStyle(
                            color: Color(0xFFFF7A00),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFFF7A00),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),

                      // 7. Cara Membuat Section
                      _buildFieldLabel('Cara Membuat'),
                      const SizedBox(height: 10),
                      ..._steps.asMap().entries.map((entry) {
                        final index = entry.key;
                        final stepItem = entry.value;
                        final hasImage = stepItem.localImageBytes != null ||
                            (stepItem.existingImageUrl != null &&
                                stepItem.existingImageUrl!.isNotEmpty);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Step Description Field
                              Expanded(
                                child: Container(
                                  height: 68,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: stepItem.textController,
                                    minLines: 2,
                                    maxLines: 3,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: Color(0xFF1E293B),
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Langkah ${index + 1}: Masukkan deskripsi',
                                      hintStyle: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Image Picker Box ("+")
                              InkWell(
                                onTap: () => _showImageSourcePicker(
                                  onSelected: (source) =>
                                      _pickStepImage(index, source),
                                ),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 58,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: hasImage
                                      ? Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                              child: stepItem.localImageBytes !=
                                                      null
                                                  ? Image.memory(
                                                      stepItem.localImageBytes!,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Image.network(
                                                      stepItem
                                                          .existingImageUrl!,
                                                      fit: BoxFit.cover,
                                                    ),
                                            ),
                                            Positioned(
                                              top: 2,
                                              right: 2,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.edit,
                                                  size: 11,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.add_rounded,
                                            color: Color(0xFF64748B),
                                            size: 26,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 4),

                              // Red Trash Delete Button (Vertically Centered)
                              IconButton(
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFFF3B30),
                                  size: 22,
                                ),
                                onPressed: () => _removeStepRow(index),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 4),

                      // Button "+ Tambah Cara Membuat"
                      OutlinedButton.icon(
                        onPressed: _addStepRow,
                        icon: const Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: Color(0xFFFF7A00),
                        ),
                        label: const Text(
                          'Tambah Cara Membuat',
                          style: TextStyle(
                            color: Color(0xFFFF7A00),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFFF7A00),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Fixed "Simpan" Button
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
                      colors: [Color(0xFF0088FF), Color(0xFF0775D5)],
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

  Widget _buildCoverPhotoPicker() {
    final hasImage = _coverImageBytes != null ||
        (_existingCoverImageUrl != null && _existingCoverImageUrl!.isNotEmpty);

    return InkWell(
      onTap: () => _showImageSourcePicker(
        onSelected: (source) => _pickCoverImage(source),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF7A00).withValues(alpha: 0.5),
            width: 1.4,
            style: BorderStyle.solid,
          ),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _coverImageBytes != null
                        ? Image.memory(_coverImageBytes!, fit: BoxFit.cover)
                        : Image.network(_existingCoverImageUrl!,
                            fit: BoxFit.cover),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.edit, color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Ganti Foto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.image_outlined,
                    size: 42,
                    color: Color(0xFFFF7A00),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Klik untuk memilih gambar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Mendukung kamera & galeri',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Chips Row
        Wrap(
          spacing: 8,
          children: [15, 30, 45, 60, 90].map((mins) {
            final isSelected =
                _durationUnit == 'menit' && _durationNumber == mins;
            return ChoiceChip(
              label: Text('$mins mnt'),
              selected: isSelected,
              selectedColor: const Color(0xFF5856D6),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _durationNumber = mins;
                    _durationUnit = 'menit';
                  });
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Duration Stepper Container
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Color(0xFF5856D6),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$_durationNumber $_durationUnit',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded,
                    color: Color(0xFF64748B), size: 22),
                onPressed: () {
                  if (_durationNumber > 5) {
                    setState(() => _durationNumber -= 5);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded,
                    color: Color(0xFF5856D6), size: 22),
                onPressed: () {
                  setState(() => _durationNumber += 5);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortionSelector() {
    return Wrap(
      spacing: 8,
      children: _portionPresets.map((portion) {
        final isSelected = _selectedPortion == portion;
        return ChoiceChip(
          label: Text(portion),
          selected: isSelected,
          selectedColor: const Color(0xFF0088FF),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1E293B),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
          backgroundColor: const Color(0xFFF1F5F9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedPortion = portion);
            }
          },
        );
      }).toList(),
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
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
