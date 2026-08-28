import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/book_model.dart';
import '../providers/book_provider.dart';
import '../repositories/book_repository.dart';
import '../widgets/widgets.dart';
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

  // Rating & Progress
  int _rating = 0;
  final _currentPageController = TextEditingController();
  final _totalPagesController = TextEditingController();

  // Synopsis & Review
  final _synopsisController = TextEditingController();
  final _reviewController = TextEditingController();

  // Genres
  final _genreController = TextEditingController();
  final List<String> _genres = [];

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
      _rating = book.personalRating ?? 0;
      _currentPageController.text = book.currentPage.toString();
      _totalPagesController.text = book.totalPages.toString();
      _synopsisController.text = book.synopsis ?? '';
      _reviewController.text = book.personalReview ?? '';

      BookRepository().getBookGenres(book.id).then((genresFromDb) {
        if (mounted) {
          setState(() {
            _genres.clear();
            _genres.addAll(genresFromDb);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _currentPageController.dispose();
    _totalPagesController.dispose();
    _synopsisController.dispose();
    _reviewController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_genres.contains(genre)) {
        _genres.remove(genre);
      } else {
        _genres.add(genre);
      }
    });
  }

  void _addNewGenre(String text) {
    final val = text.trim();
    if (val.isNotEmpty && !_genres.contains(val)) {
      setState(() {
        _genres.add(val);
        _genreController.clear();
      });
    }
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

    final curPage = int.tryParse(_currentPageController.text.trim()) ?? 0;
    final totalPages = int.tryParse(_totalPagesController.text.trim()) ?? 0;

    if (curPage < 0) {
      AppSnackBar.warning(context, 'Halaman sekarang tidak boleh kurang dari 0');
      return;
    }

    if (totalPages < 0) {
      AppSnackBar.warning(context, 'Total halaman tidak boleh kurang dari 0');
      return;
    }

    if (totalPages > 0 && curPage > totalPages) {
      AppSnackBar.warning(
        context,
        'Halaman sekarang ($curPage) tidak boleh melebihi total halaman ($totalPages)',
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = Provider.of<BookProvider>(context, listen: false);
    final bookData = {
      'title': title,
      'author': _authorController.text.trim(),
      'cover_url': _coverUrl,
      'personal_rating': _rating > 0 ? _rating : null,
      'synopsis': _synopsisController.text.trim(),
      'personal_review': _reviewController.text.trim(),
      'current_page': curPage,
      'total_pages': totalPages,
    };

    bool success = false;

    if (_isEditMode) {
      success = await provider.updateBook(
        widget.bookToEdit!.id,
        bookData,
        genres: _genres,
      );
    } else {
      success = await provider.addBookWithDetails(
        bookData: bookData,
        genres: _genres,
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

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF6B4454)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditMode ? 'Edit Buku' : 'Tambah Buku Baru',
          style: const TextStyle(
            color: Color(0xFF6B4454),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookCoverPicker(
              coverUrl: _coverUrl,
              coverBytes: _coverBytes,
              isUploading: _isUploadingCover,
              onTap: _handlePickCover,
              onRemove: _handleRemoveCover,
            ),
            const SizedBox(height: 20),
            BookFormTextField(
              controller: _titleController,
              hintText: 'Judul Buku',
              icon: Icons.menu_book_rounded,
            ),
            const SizedBox(height: 12),
            BookFormTextField(
              controller: _authorController,
              hintText: 'Nama Penulis',
              icon: Icons.edit_note_rounded,
            ),
            const SizedBox(height: 20),
            BookRatingPicker(
              rating: _rating,
              onRatingChanged: (val) => setState(() => _rating = val),
            ),
            const SizedBox(height: 20),
            BookProgressInput(
              currentPageController: _currentPageController,
              totalPagesController: _totalPagesController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            BookFormTextArea(
              controller: _synopsisController,
              hintText: 'Sinopsis Buku...',
              label: 'Sinopsis Buku',
              onScanPressed: _handleScanSynopsis,
              isScanning: _isScanningSynopsis,
            ),
            const SizedBox(height: 16),
            BookFormTextArea(
              controller: _reviewController,
              hintText: 'Personal Review / Our Thoughts...',
              label: 'Personal Review',
            ),
            const SizedBox(height: 20),
            BookGenrePicker(
              controller: _genreController,
              selectedGenres: _genres,
              availableGenres: provider.availableGenres,
              onToggleGenre: _toggleGenre,
              onAddNewGenre: _addNewGenre,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF3B6B8A)),
                    ),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B6B8A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _submitAll,
                    child: Text(
                      _isEditMode ? 'Perbarui Buku' : 'Simpan Buku',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
