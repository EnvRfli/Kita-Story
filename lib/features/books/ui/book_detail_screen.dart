import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/book_model.dart';
import '../repositories/book_repository.dart';
import '../providers/book_provider.dart';
import '../widgets/widgets.dart';

class BookDetailScreen extends StatefulWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final BookRepository _repository = BookRepository();
  late BookModel _currentBook;
  bool _isLoading = true;

  List<String> _genres = [];
  List<Map<String, dynamic>> _characters = [];
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _snippets = [];

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _repository.getBookById(_currentBook.id),
        _repository.getBookGenres(_currentBook.id),
        _repository.getBookCharacters(_currentBook.id),
        _repository.getBookNotes(_currentBook.id),
        _repository.getBookSnippets(_currentBook.id),
      ]);

      if (mounted) {
        setState(() {
          _currentBook = results[0] as BookModel;
          _genres = results[1] as List<String>;
          _characters = results[2] as List<Map<String, dynamic>>;
          _notes = results[3] as List<Map<String, dynamic>>;
          _snippets = results[4] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading book details: $e');
      if (mounted) {
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
      initialReview: _currentBook.personalReview ?? '',
      onSave: (newReview) async {
        final provider = Provider.of<BookProvider>(context, listen: false);
        final success = await provider
            .updateBook(_currentBook.id, {'personal_review': newReview});
        if (success && mounted) {
          setState(() {
            _currentBook = BookModel(
              id: _currentBook.id,
              title: _currentBook.title,
              author: _currentBook.author,
              personalRating: _currentBook.personalRating,
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

  void _onOpenCharacterForm([Map<String, dynamic>? character]) async {
    final results = await Future.wait([
      _repository.getAllTraits(),
      _repository.getAllRoles(),
    ]);

    if (!mounted) return;

    final availableTraits = results[0];
    final availableRoles = results[1];

    CharacterFormBottomSheet.show(
      context: context,
      initialCharacter: character,
      availableTraits: availableTraits,
      availableRoles: availableRoles,
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
        await _loadDetails();
      },
      onDelete: (character != null && character['id'] != null)
          ? () async {
              await _repository.deleteCharacter(character['id'] as String);
              await _loadDetails();
            }
          : null,
    );
  }

  void _onOpenNoteForm() {
    NoteFormBottomSheet.show(
      context: context,
      onSave: (pageNumber, noteText) async {
        await _repository.addBookNotes(_currentBook.id, [
          {'page': pageNumber, 'text': noteText}
        ]);
        await _loadDetails();
      },
    );
  }

  void _onOpenSnippetForm() {
    SnippetFormBottomSheet.show(
      context: context,
      onSave: (imageUrl, caption, pageNumber) async {
        await _repository.addBookSnippet(
          _currentBook.id,
          imageUrl: imageUrl,
          caption: caption,
          pageNumber: pageNumber,
        );
        await _loadDetails();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF6B4454)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Detail Buku',
          style: TextStyle(
            color: Color(0xFF6B4454),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B6B8A)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BookDetailHeader(
                    book: _currentBook,
                    genres: _genres,
                    onEditBook: () async {
                      await context.push('/add-book', extra: _currentBook);
                      _loadDetails();
                    },
                  ),
                  const SizedBox(height: 24),
                  BookProgressCard(
                    book: _currentBook,
                    onUpdateProgress: _onOpenUpdateProgress,
                  ),
                  const SizedBox(height: 16),
                  BookSynopsisCard(
                    synopsis: _currentBook.synopsis,
                  ),
                  const SizedBox(height: 16),
                  BookReviewCard(
                    review: _currentBook.personalReview,
                    onEditReview: _onOpenEditReview,
                  ),
                  const SizedBox(height: 24),
                  BookSnippetsSection(
                    snippets: _snippets,
                    onAddSnippet: _onOpenSnippetForm,
                    onDeleteSnippet: (snippetId) async {
                      await _repository.deleteBookSnippet(snippetId);
                      await _loadDetails();
                    },
                  ),
                  const SizedBox(height: 24),
                  BookCharactersSection(
                    characters: _characters,
                    onCharacterTap: _onOpenCharacterForm,
                    onAddCharacter: () => _onOpenCharacterForm(null),
                  ),
                  const SizedBox(height: 24),
                  BookNotesSection(
                    notes: _notes,
                    onAddNote: _onOpenNoteForm,
                  ),
                ],
              ),
            ),
    );
  }
}
