import 'package:flutter/foundation.dart';
import '../models/book_model.dart';
import '../repositories/book_repository.dart';

class BookProvider extends ChangeNotifier {
  final BookRepository _repository = BookRepository();

  List<BookModel> _books = [];
  List<BookModel> get books => _books;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<String> _availableGenres = [];
  List<String> get availableGenres => _availableGenres;

  List<String> _availableTraits = [];
  List<String> get availableTraits => _availableTraits;

  List<String> _availableRoles = [];
  List<String> get availableRoles => _availableRoles;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAvailableGenres() async {
    try {
      _availableGenres = await _repository.getAllGenres();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading available genres: $e');
    }
  }

  Future<void> fetchAvailableTraits() async {
    try {
      _availableTraits = await _repository.getAllTraits();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading available traits: $e');
    }
  }

  Future<void> fetchAvailableRoles() async {
    try {
      _availableRoles = await _repository.getAllRoles();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading available roles: $e');
    }
  }

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

  Future<bool> updateBook(String id, Map<String, dynamic> updates,
      {List<String>? genres}) async {
    try {
      await _repository.updateBook(id, updates);
      if (genres != null) {
        await _repository.updateBookGenres(id, genres);
      }
      final index = _books.indexWhere((b) => b.id == id);
      if (index != -1) {
        final old = _books[index];
        _books[index] = BookModel(
          id: old.id,
          title: (updates['title'] as String?) ?? old.title,
          author: (updates['author'] as String?) ?? old.author,
          personalRating: updates.containsKey('personal_rating')
              ? updates['personal_rating'] as int?
              : old.personalRating,
          personalReview: updates.containsKey('personal_review')
              ? updates['personal_review'] as String?
              : old.personalReview,
          synopsis: updates.containsKey('synopsis')
              ? updates['synopsis'] as String?
              : old.synopsis,
          coverUrl: updates.containsKey('cover_url')
              ? updates['cover_url'] as String?
              : old.coverUrl,
          totalPages: (updates['total_pages'] as int?) ?? old.totalPages,
          currentPage: (updates['current_page'] as int?) ?? old.currentPage,
          addedBy: old.addedBy,
          lastUpdatedBy: old.lastUpdatedBy,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update book: $e';
      notifyListeners();
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

  Future<bool> deleteBook(String id) async {
    try {
      await _repository.deleteBook(id);
      _books.removeWhere((b) => b.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete book: $e';
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
