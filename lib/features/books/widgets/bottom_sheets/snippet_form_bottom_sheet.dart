import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/services/supabase_storage_service.dart';
import 'image_source_bottom_sheet.dart';

class SnippetFormBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? initialSnippet;
  final Future<void> Function(
    String imageUrl,
    String? caption,
    int? pageNumber,
  ) onSave;

  const SnippetFormBottomSheet({
    super.key,
    this.initialSnippet,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    Map<String, dynamic>? initialSnippet,
    required Future<void> Function(
      String imageUrl,
      String? caption,
      int? pageNumber,
    ) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SnippetFormBottomSheet(
        initialSnippet: initialSnippet,
        onSave: onSave,
      ),
    );
  }

  @override
  State<SnippetFormBottomSheet> createState() => _SnippetFormBottomSheetState();
}

class _SnippetFormBottomSheetState extends State<SnippetFormBottomSheet> {
  late final TextEditingController _captionController;
  late final TextEditingController _pageController;

  Uint8List? _imageBytes;
  String? _imageUrl;
  bool _isUploadingImage = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialSnippet;
    _captionController = TextEditingController(text: init?['caption'] ?? '');
    _pageController = TextEditingController(
      text: init?['page_number'] != null ? init!['page_number'].toString() : '',
    );
    _imageUrl = init?['image_url'];
  }

  @override
  void dispose() {
    _captionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handlePickImage() async {
    final source = await ImageSourceBottomSheet.show(
      context,
      title: 'Pilih Foto Galeri',
      subtitle: 'Ambil foto dari kamera atau pilih dari galeri ponsel.',
    );
    if (source == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').lastOrNull ?? 'jpg';

      final publicUrl = await SupabaseStorageService.uploadBookSnippet(
        bytes,
        fileExtension: ext,
        contentType: image.mimeType,
      );

      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _imageUrl = publicUrl;
        _isUploadingImage = false;
      });

      AppSnackBar.success(context, 'Foto berhasil diunggah!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      AppSnackBar.error(
        context,
        e.toString().replaceAll('Exception: ', ''),
        title: 'Upload Gagal',
      );
    }
  }

  Future<void> _handleSave() async {
    if ((_imageUrl == null || _imageUrl!.trim().isEmpty) &&
        _imageBytes == null) {
      AppSnackBar.warning(context, 'Silakan pilih gambar terlebih dahulu');
      return;
    }

    if (_isUploadingImage) {
      AppSnackBar.warning(
        context,
        'Harap tunggu proses upload gambar selesai.',
        title: 'Sedang Mengunggah',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final pageNumber = int.tryParse(_pageController.text.trim());
      final caption = _captionController.text.trim().isNotEmpty
          ? _captionController.text.trim()
          : null;

      await widget.onSave(
        _imageUrl ?? '',
        caption,
        pageNumber,
      );

      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.success(
          context,
          widget.initialSnippet != null
              ? 'Foto galeri berhasil diperbarui!'
              : 'Foto galeri berhasil ditambahkan!',
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
    final hasImage = _imageBytes != null ||
        (_imageUrl != null && _imageUrl!.trim().isNotEmpty);

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
              'Galeri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 18),

            // Image Picker Box (Dashed Border)
            _buildImagePicker(hasImage),
            const SizedBox(height: 20),

            // 1. Nomor Halaman
            _buildFieldLabel('Nomor Halaman'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _pageController,
              hintText: 'Halaman ke -  0',
              keyboardType: TextInputType.number,
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
                controller: _captionController,
                minLines: 4,
                maxLines: 6,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
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
            const SizedBox(height: 28),

            // 3. Simpan Button (Gradient 0088FF -> 0775D5)
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

  Widget _buildImagePicker(bool hasImage) {
    if (hasImage) {
      return Stack(
        children: [
          Container(
            width: double.infinity,
            height: 175,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _imageBytes != null
                  ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                  : (_imageUrl != null && _imageUrl!.startsWith('http')
                      ? Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_rounded),
                          ),
                        )
                      : Image.asset(
                          _imageUrl!.replaceFirst('asset:', ''),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_rounded),
                          ),
                        )),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: InkWell(
              onTap: _isUploadingImage ? null : _handlePickImage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Ubah',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: const Color(0xFFFFB300),
        strokeWidth: 1.5,
        dashPattern: const [6, 4],
        borderRadius: 16,
      ),
      child: Material(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _isUploadingImage ? null : _handlePickImage,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 160,
            alignment: Alignment.center,
            child: _isUploadingImage
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF7A00),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Mengunggah gambar...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF7A00),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.image_outlined,
                        size: 40,
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
                      SizedBox(height: 4),
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

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashPattern = const [6, 4],
    this.borderRadius = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      bool draw = true;
      int patternIndex = 0;

      while (distance < metric.length) {
        final length = dashPattern[patternIndex % dashPattern.length];
        if (draw) {
          final extractPath =
              metric.extractPath(distance, distance + length);
          canvas.drawPath(extractPath, paint);
        }
        distance += length;
        draw = !draw;
        patternIndex++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}
