import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/book_model.dart';
import '../providers/book_provider.dart';
import '../repositories/book_repository.dart';
import '../widgets/bottom_sheets/image_source_bottom_sheet.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/services/gemini_ocr_service.dart';
import '../../../core/services/supabase_storage_service.dart';

class AddBookScreen extends StatefulWidget {
  final BookModel? bookToEdit;

  const AddBookScreen({super.key, this.bookToEdit});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  // Cover
  String? _coverUrl;
  Uint8List? _coverBytes;
  bool _isUploadingCover = false;

  // Basic info
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _totalPagesController = TextEditingController();
  final _synopsisController = TextEditingController();

  // Genres
  final List<String> _selectedGenres = [];

  bool _isLoading = false;
  bool _isScanningSynopsis = false;
  bool get _isEditMode => widget.bookToEdit != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookProvider>(context, listen: false).fetchAvailableGenres();
    });

    if (_isEditMode) {
      final book = widget.bookToEdit!;
      _coverUrl = book.coverUrl;
      _titleController.text = book.title;
      _authorController.text = book.author ?? '';
      _totalPagesController.text =
          book.totalPages > 0 ? book.totalPages.toString() : '';
      _synopsisController.text = book.synopsis ?? '';

      BookRepository().getBookGenres(book.id).then((genresFromDb) {
        if (mounted) {
          setState(() {
            _selectedGenres.clear();
            _selectedGenres.addAll(genresFromDb);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _totalPagesController.dispose();
    _synopsisController.dispose();
    super.dispose();
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  void _showAddGenreDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Tambah Genre',
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
            hintText: 'Nama genre (misal: Mystery)',
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
              if (val.isNotEmpty && !_selectedGenres.contains(val)) {
                setState(() {
                  _selectedGenres.add(val);
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

  Future<void> _handlePickCover() async {
    final source = await ImageSourceBottomSheet.show(
      context,
      title: 'Pilih Cover Buku',
      subtitle: 'Ambil foto cover buku atau pilih dari galeri ponsel.',
    );
    if (source == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploadingCover = true);

    try {
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').lastOrNull ?? 'jpg';

      final publicUrl = await SupabaseStorageService.uploadBookCover(
        bytes,
        fileExtension: ext,
        contentType: image.mimeType,
      );

      if (!mounted) return;

      setState(() {
        _coverBytes = bytes;
        _coverUrl = publicUrl;
        _isUploadingCover = false;
      });

      AppSnackBar.success(context, 'Cover buku berhasil diunggah!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingCover = false);
      AppSnackBar.error(
        context,
        e.toString().replaceAll('Exception: ', ''),
        title: 'Upload Gagal',
      );
    }
  }

  void _handleRemoveCover() {
    setState(() {
      _coverBytes = null;
      _coverUrl = null;
    });
  }

  Future<void> _handleScanSynopsis() async {
    final source = await ImageSourceBottomSheet.show(
      context,
      title: 'Scan Sinopsis Buku (AI)',
      subtitle: 'Foto sampul belakang buku untuk mengekstrak sinopsis.',
    );
    if (source == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isScanningSynopsis = true);

    try {
      final bytes = await image.readAsBytes();
      final mimeType = image.mimeType ?? 'image/jpeg';

      final extractedSynopsis = await GeminiOcrService.extractSynopsis(
        bytes,
        mimeType: mimeType,
      );

      if (!mounted) return;

      setState(() {
        _synopsisController.text = extractedSynopsis;
        _isScanningSynopsis = false;
      });

      AppSnackBar.success(
        context,
        'Sinopsis berhasil dipindai dan diekstrak oleh AI!',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanningSynopsis = false);
      AppSnackBar.error(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> _submitAll() async {
    if (_isUploadingCover) {
      AppSnackBar.warning(
        context,
        'Harap tunggu proses upload cover buku selesai terlebih dahulu.',
        title: 'Sedang Mengunggah',
      );
      return;
    }

    if (_isScanningSynopsis) {
      AppSnackBar.warning(
        context,
        'Harap tunggu proses scan sinopsis AI selesai terlebih dahulu.',
        title: 'Sedang Memindai',
      );
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppSnackBar.warning(context, 'Judul buku wajib diisi');
      return;
    }

    final totalPages = int.tryParse(_totalPagesController.text.trim()) ?? 0;
    if (totalPages <= 0) {
      AppSnackBar.warning(context, 'Total halaman harus lebih dari 0');
      return;
    }

    // Validation for Edit: totalPages cannot be less than current reading progress
    if (_isEditMode && widget.bookToEdit != null) {
      final currentProgress = widget.bookToEdit!.currentPage;
      if (totalPages < currentProgress) {
        AppSnackBar.warning(
          context,
          'Total halaman ($totalPages) tidak boleh kurang dari progress saat ini ($currentProgress lembar)',
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final provider = Provider.of<BookProvider>(context, listen: false);
    final bookData = {
      'title': title,
      'author': _authorController.text.trim(),
      'cover_url': _coverUrl,
      'personal_rating': _isEditMode ? (widget.bookToEdit!.personalRating ?? 0) : 0,
      'synopsis': _synopsisController.text.trim(),
      'personal_review': _isEditMode ? widget.bookToEdit!.personalReview : null,
      'current_page': _isEditMode ? widget.bookToEdit!.currentPage : 0,
      'total_pages': totalPages,
    };

    bool success = false;

    if (_isEditMode) {
      success = await provider.updateBook(
        widget.bookToEdit!.id,
        bookData,
        genres: _selectedGenres,
      );
    } else {
      success = await provider.addBookWithDetails(
        bookData: bookData,
        genres: _selectedGenres,
        notes: [],
        characters: [],
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      context.pop();
    } else {
      AppSnackBar.error(
        context,
        provider.errorMessage ?? 'Gagal menyimpan data buku',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider>(context);

    // Merge database genres with any genres selected on this book
    final Set<String> allGenreSet = {
      ...provider.availableGenres,
      ..._selectedGenres,
    };
    final allGenres = allGenreSet.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditMode ? 'Edit Buku' : 'Tambah Buku',
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Cover Picker Box with Visible Dashed Amber Border
            _buildCoverPicker(),
            const SizedBox(height: 22),

            // 2. Judul Buku
            _buildFieldLabel('Judul Buku'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleController,
              hintText: 'Masukkan judul buku',
            ),
            const SizedBox(height: 18),

            // 3. Nama Penulis
            _buildFieldLabel('Nama Penulis'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _authorController,
              hintText: 'Masukkan nama penulis',
            ),
            const SizedBox(height: 18),

            // 4. Genre Section (Database Only + Selected)
            _buildFieldLabel('Genre'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...allGenres.map((genre) {
                  final isSelected = _selectedGenres.contains(genre);
                  return InkWell(
                    onTap: () => _toggleGenre(genre),
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
                        genre,
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
                // Add Genre (+) Button
                InkWell(
                  onTap: _showAddGenreDialog,
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

            // 5. Total Halaman
            _buildFieldLabel('Total Halaman'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _totalPagesController,
              hintText: 'Masukkan total halaman',
              keyboardType: TextInputType.number,
              suffix: const Text(
                'lembar',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 6. Sinopsis with "Scan via AI"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFieldLabel('Sinopsis'),
                InkWell(
                  onTap: _isScanningSynopsis ? null : _handleScanSynopsis,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFF7A00),
                        width: 1.2,
                      ),
                    ),
                    child: _isScanningSynopsis
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF7A00),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.document_scanner_outlined,
                                size: 15,
                                color: Color(0xFFFF7A00),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Scan via AI',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF7A00),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: TextField(
                controller: _synopsisController,
                minLines: 4,
                maxLines: 7,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
                decoration: const InputDecoration(
                  hintText: 'Masukkan sinopsis',
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
            const SizedBox(height: 32),

            // 7. Simpan Button (Gradient 0088FF -> 0775D5)
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
                  onTap: _isLoading ? null : _submitAll,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: _isLoading
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
            const SizedBox(height: 30),
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
    Widget? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
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
          ),
          if (suffix != null) suffix,
        ],
      ),
    );
  }

  Widget _buildCoverPicker() {
    final hasCover = _coverBytes != null ||
        (_coverUrl != null && _coverUrl!.trim().isNotEmpty);

    if (hasCover) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _coverBytes != null
                  ? Image.memory(
                      _coverBytes!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      _coverUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            if (_isUploadingCover)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            else
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  children: [
                    InkWell(
                      onTap: _handlePickCover,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Ubah',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: _handleRemoveCover,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: const Color(0xFFFFB300),
        strokeWidth: 1.5,
        radius: 16,
        dash: 6,
        gap: 5,
      ),
      child: Material(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _isUploadingCover ? null : _handlePickCover,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 155,
            width: double.infinity,
            child: _isUploadingCover
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFF7A00)),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.image_outlined,
                        size: 38,
                        color: Color(0xFFFF7A00),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Klik untuk memilih cover buku',
                        style: TextStyle(
                          fontSize: 13.5,
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
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.dash,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len =
            (distance + dash < metric.length) ? dash : metric.length - distance;
        dashPath.addPath(
          metric.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gap != gap ||
      oldDelegate.dash != dash ||
      oldDelegate.radius != radius;
}
