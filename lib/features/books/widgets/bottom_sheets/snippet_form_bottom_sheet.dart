import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/services/supabase_storage_service.dart';
import 'image_source_bottom_sheet.dart';

class SnippetFormBottomSheet extends StatefulWidget {
  final Future<void> Function(
    String imageUrl,
    String? caption,
    int? pageNumber,
  ) onSave;

  const SnippetFormBottomSheet({
    super.key,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required Future<void> Function(
      String imageUrl,
      String? caption,
      int? pageNumber,
    ) onSave,
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
      builder: (context) => SnippetFormBottomSheet(onSave: onSave),
    );
  }

  @override
  State<SnippetFormBottomSheet> createState() => _SnippetFormBottomSheetState();
}

class _SnippetFormBottomSheetState extends State<SnippetFormBottomSheet> {
  final _captionController = TextEditingController();
  final _pageController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageExtension;
  String? _imageMimeType;

  bool _isSaving = false;

  @override
  void dispose() {
    _captionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handlePickImage() async {
    final source = await ImageSourceBottomSheet.show(
      context,
      title: 'Foto Cuplikan / Quotes',
      subtitle: 'Foto halaman buku langsung atau pilih dari galeri.',
    );
    if (source == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();
    final ext = image.name.split('.').lastOrNull ?? 'jpg';

    if (!mounted) return;

    setState(() {
      _imageBytes = bytes;
      _imageExtension = ext;
      _imageMimeType = image.mimeType;
    });
  }

  void _handleRemoveImage() {
    setState(() {
      _imageBytes = null;
      _imageExtension = null;
      _imageMimeType = null;
    });
  }

  Future<void> _handleSave() async {
    if (_imageBytes == null) {
      AppSnackBar.warning(
        context,
        'Harap pilih atau ambil foto cuplikan buku terlebih dahulu.',
        title: 'Foto Wajib Diisi',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Upload photo to Supabase Storage bucket 'book snippets'
      final publicUrl = await SupabaseStorageService.uploadBookSnippet(
        _imageBytes!,
        fileExtension: _imageExtension ?? 'jpg',
        contentType: _imageMimeType,
      );

      final caption = _captionController.text.trim();
      final pageNumber = int.tryParse(_pageController.text.trim());

      // 2. Save snippet entity to database
      await widget.onSave(
        publicUrl,
        caption.isNotEmpty ? caption : null,
        pageNumber,
      );

      if (!mounted) return;

      Navigator.of(context).pop();
      AppSnackBar.success(context, 'Cuplikan foto berhasil ditambahkan!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackBar.error(
        context,
        'Gagal menyimpan cuplikan: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tambah Cuplikan Buku (Snippet)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B4454),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Simpan foto kutipan quotes, dialog lucu, atau ilustrasi.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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
                  // Image Picker Container
                  _buildImagePickerBox(),
                  const SizedBox(height: 16),

                  // Page Number (Optional)
                  _buildSectionLabel('Nomor Halaman (Opsional)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _pageController,
                    keyboardType: TextInputType.number,
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xFF6B4454)),
                    decoration: _buildInputDecoration(
                      hint: 'Contoh: 142',
                      icon: Icons.bookmark_border_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Caption / Notes
                  _buildSectionLabel('Deskripsi / Kutipan Kata (Opsional)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _captionController,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B4454),
                      height: 1.35,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Tuliskan kutipan menarik atau catatan mengapa foto ini berkesan...',
                      hintStyle:
                          const TextStyle(color: Colors.black38, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFEADBDF),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFEADBDF),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF3B6B8A),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  : const Text(
                      'Simpan Cuplikan Foto',
                      style: TextStyle(
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

  Widget _buildImagePickerBox() {
    if (_imageBytes != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEADBDF), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Image.memory(
                _imageBytes!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: _handlePickImage,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _handleRemoveImage,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9534F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: _handlePickImage,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD6B9C3),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_rounded,
                size: 40,
                color: Color(0xFF3B6B8A),
              ),
              SizedBox(height: 8),
              Text(
                'Ketuk untuk memilih / foto cuplikan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4454),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Mendukung kamera & galeri foto',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
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
