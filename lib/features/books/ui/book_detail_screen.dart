import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/app_snackbar.dart';
import '../models/book_model.dart';
import '../repositories/book_repository.dart';
import '../providers/book_provider.dart';
import '../widgets/widgets.dart';

class BookDetailScreen extends StatefulWidget {
  final BookModel book;
  final bool isReadOnly;

  const BookDetailScreen({
    super.key,
    required this.book,
    this.isReadOnly = false,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final BookRepository _repository = BookRepository();
  late BookModel _currentBook;
  bool _isLoading = true;

  List<String> _genres = [];
  List<Map<String, dynamic>> _characters = [];
  List<Map<String, dynamic>> _snippets = [];

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _loadDetails();
  }

  Future<void> _loadDetails({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _repository.getBookById(_currentBook.id),
        _repository.getBookGenres(_currentBook.id),
        _repository.getBookCharacters(_currentBook.id),
        _repository.getBookSnippets(_currentBook.id),
      ]);

      if (mounted) {
        setState(() {
          _currentBook = results[0] as BookModel;
          _genres = results[1] as List<String>;
          _characters = results[2] as List<Map<String, dynamic>>;
          _snippets = results[3] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading book details: $e');
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Bottom Sheet Action Handlers ---

  void _onOpenUpdateProgress() {
    UpdateProgressBottomSheet.show(
      context: context,
      initialPage: _currentBook.currentPage,
      totalPages: _currentBook.totalPages,
      onSave: (newPage) async {
        final provider = Provider.of<BookProvider>(context, listen: false);
        final success =
            await provider.updateBookProgress(_currentBook.id, newPage);
        if (success && mounted) {
          setState(() {
            _currentBook = BookModel(
              id: _currentBook.id,
              title: _currentBook.title,
              author: _currentBook.author,
              personalRating: _currentBook.personalRating,
              personalReview: _currentBook.personalReview,
              synopsis: _currentBook.synopsis,
              coverUrl: _currentBook.coverUrl,
              totalPages: _currentBook.totalPages,
              currentPage: newPage,
              addedBy: _currentBook.addedBy,
              lastUpdatedBy: _currentBook.lastUpdatedBy,
            );
          });
        }
      },
    );
  }

  void _onOpenEditReview() {
    EditReviewBottomSheet.show(
      context: context,
      initialRating: _currentBook.personalRating,
      initialReview: _currentBook.personalReview ?? '',
      onSave: (newRating, newReview) async {
        final provider = Provider.of<BookProvider>(context, listen: false);
        final success = await provider.updateBook(_currentBook.id, {
          'personal_rating': newRating,
          'personal_review': newReview,
        });
        if (success && mounted) {
          setState(() {
            _currentBook = BookModel(
              id: _currentBook.id,
              title: _currentBook.title,
              author: _currentBook.author,
              personalRating: newRating,
              personalReview: newReview,
              synopsis: _currentBook.synopsis,
              coverUrl: _currentBook.coverUrl,
              totalPages: _currentBook.totalPages,
              currentPage: _currentBook.currentPage,
              addedBy: _currentBook.addedBy,
              lastUpdatedBy: _currentBook.lastUpdatedBy,
            );
          });
        }
      },
    );
  }

  void _onOpenCharacterDetail(Map<String, dynamic> character) {
    CharacterDetailBottomSheet.show(
      context: context,
      character: character,
      onEdit: widget.isReadOnly ? null : () => _onOpenCharacterForm(character),
      onDelete: widget.isReadOnly
          ? null
          : () async {
              final charName = (character['name'] as String?) ?? 'Karakter';
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text(
                    'Hapus Karakter',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  content: Text(
                    'Apakah Anda yakin ingin menghapus tokoh "$charName"?',
                    style:
                        const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                try {
                  await _repository.deleteCharacter(character['id'] as String);
                  await _loadDetails(showLoading: false);
                  if (mounted) {
                    AppSnackBar.success(
                      context,
                      'Karakter "$charName" berhasil dihapus!',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    AppSnackBar.error(context, 'Gagal menghapus karakter: $e');
                  }
                }
              }
            },
    );
  }

  void _onOpenCharacterForm([Map<String, dynamic>? character]) {
    if (widget.isReadOnly) return;
    CharacterFormBottomSheet.show(
      context: context,
      initialCharacter: character,
      onSave: (characterData, traits) async {
        if (character != null && character['id'] != null) {
          await _repository.updateCharacterWithDetails(
            character['id'] as String,
            characterData,
            traits,
          );
        } else {
          await _repository.addCharacterWithDetails(
            _currentBook.id,
            characterData,
            traits,
          );
        }
        await _loadDetails(showLoading: false);
      },
    );
  }

  void _onOpenSnippetDetail(Map<String, dynamic> snippet) {
    SnippetDetailBottomSheet.show(
      context: context,
      snippet: snippet,
      onEdit: widget.isReadOnly ? null : () => _onOpenSnippetForm(snippet),
      onDelete: widget.isReadOnly
          ? null
          : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text(
                    'Hapus Foto Galeri',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  content: const Text(
                    'Apakah Anda yakin ingin menghapus foto ini dari galeri?',
                    style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                try {
                  await _repository.deleteBookSnippet(snippet['id'] as String);
                  await _loadDetails(showLoading: false);
                  if (mounted) {
                    AppSnackBar.success(context, 'Foto galeri berhasil dihapus!');
                  }
                } catch (e) {
                  if (mounted) {
                    AppSnackBar.error(context, 'Gagal menghapus foto galeri: $e');
                  }
                }
              }
            },
    );
  }

  void _onOpenSnippetForm([Map<String, dynamic>? snippet]) {
    if (widget.isReadOnly) return;
    SnippetFormBottomSheet.show(
      context: context,
      initialSnippet: snippet,
      onSave: (imageUrl, caption, pageNumber) async {
        if (snippet != null && snippet['id'] != null) {
          await _repository.updateBookSnippet(
            snippet['id'] as String,
            imageUrl: imageUrl,
            caption: caption,
            pageNumber: pageNumber,
          );
        } else {
          await _repository.addBookSnippet(
            _currentBook.id,
            imageUrl: imageUrl,
            caption: caption,
            pageNumber: pageNumber,
          );
        }
        await _loadDetails(showLoading: false);
      },
    );
  }

  Future<void> _handleDeleteBook() async {
    if (widget.isReadOnly) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Buku',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus buku "${_currentBook.title}" beserta seluruh karakternya?',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _repository.deleteBook(_currentBook.id);
        if (mounted) {
          context.pop();
          Provider.of<BookProvider>(context, listen: false).fetchBooks();
          AppSnackBar.success(
            context,
            'Buku "${_currentBook.title}" berhasil dihapus!',
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.error(context, 'Gagal menghapus buku: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF5D5FEF),
                ),
              ),
            )
          : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // 1. Sliding & Sticky Morphing Hero Header
                SliverPersistentHeader(
                  pinned: true,
                  delegate: BookDetailHeaderDelegate(
                    book: _currentBook,
                    genres: _genres,
                    onBack: () => context.pop(),
                    onDeleteBook: widget.isReadOnly ? null : _handleDeleteBook,
                    onEditBook: widget.isReadOnly
                        ? null
                        : () async {
                            await context.push('/add-book', extra: _currentBook);
                            _loadDetails(showLoading: false);
                          },
                  ),
                ),

                // 2. Scrollable Body Content Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Reading Progress Card
                        BookProgressCard(
                          book: _currentBook,
                          onUpdateProgress: widget.isReadOnly
                              ? null
                              : _onOpenUpdateProgress,
                        ),
                        const SizedBox(height: 14),

                        // Synopsis Accordion Card
                        BookSynopsisCard(
                          synopsis: _currentBook.synopsis,
                        ),
                        const SizedBox(height: 14),

                        // Combined Review & Rating Card
                        BookReviewCard(
                          rating: _currentBook.personalRating,
                          review: _currentBook.personalReview,
                          onEditReview:
                              widget.isReadOnly ? null : _onOpenEditReview,
                        ),
                        const SizedBox(height: 14),

                        // 3-Column Characters Section
                        BookCharactersSection(
                          characters: _characters,
                          onCharacterTap: _onOpenCharacterDetail,
                          onAddCharacter: widget.isReadOnly
                              ? null
                              : () => _onOpenCharacterForm(null),
                        ),
                        const SizedBox(height: 14),

                        // Gallery / Book Snippets Section
                        BookSnippetsSection(
                          snippets: _snippets,
                          onAddSnippet: widget.isReadOnly
                              ? null
                              : () => _onOpenSnippetForm(null),
                          onSnippetTap: _onOpenSnippetDetail,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
