import 'package:flutter/foundation.dart';
import '../models/book_model.dart';
import '../repositories/book_repository.dart';

class BookProvider extends ChangeNotifier {
  final BookRepository _repository = BookRepository();
  
  List<BookModel> _books = [];
  List<BookModel> get books => _books;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBooks() async {
    _setLoading(true);
    try {
      _books = await _repository.getBooks();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load books: $e';
    }
    _setLoading(false);
  }

  Future<bool> addBookWithDetails({
    required Map<String, dynamic> bookData,
    required List<String> genres,
    required List<Map<String, dynamic>> notes,
    required List<Map<String, dynamic>> characters,
  }) async {
    _setLoading(true);
    try {
      final newBook = await _repository.addBook(bookData);
      
      // Atomic-like extended data saving
      if (genres.isNotEmpty) {
        await _repository.addGenresToBook(newBook.id, genres);
      }
      if (notes.isNotEmpty) {
        await _repository.addBookNotes(newBook.id, notes);
      }
      if (characters.isNotEmpty) {
        await _repository.addCharacters(newBook.id, characters);
      }

      _books.insert(0, newBook);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add book details: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateBookProgress(String id, int currentPage) async {
    try {
      await _repository.updateBook(id, {'current_page': currentPage});
      final index = _books.indexWhere((b) => b.id == id);
      if (index != -1) {
        final oldBook = _books[index];
        _books[index] = BookModel(
          id: oldBook.id,
          title: oldBook.title,
          author: oldBook.author,
          personalRating: oldBook.personalRating,
          personalReview: oldBook.personalReview,
          synopsis: oldBook.synopsis,
          coverUrl: oldBook.coverUrl,
          totalPages: oldBook.totalPages,
          currentPage: currentPage,
          addedBy: oldBook.addedBy,
          lastUpdatedBy: oldBook.lastUpdatedBy, // ideally updated locally too
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update progress: $e';
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
