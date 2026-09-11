import 'package:flutter/foundation.dart';
import '../models/credential_model.dart';
import '../models/credential_category_model.dart';
import '../models/credential_subcategory_model.dart';
import '../repositories/credential_repository.dart';

class CredentialProvider extends ChangeNotifier {
  final CredentialRepository _repository = CredentialRepository();

  List<CredentialModel> _credentials = [];
  List<CredentialModel> get credentials => _credentials;

  List<CredentialCategoryModel> _categories = [];
  List<CredentialCategoryModel> get categories => _categories;

  List<CredentialSubcategoryModel> _subcategories = [];
  List<CredentialSubcategoryModel> get subcategories => _subcategories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _selectedCategory = 'Semua';
  String get selectedCategory => _selectedCategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Mengambil daftar kredensial terfilter berdasarkan tab kategori & pencarian
  List<CredentialModel> get filteredCredentials {
    return _credentials.where((item) {
      // 1. Filter Kategori
      final matchesCategory = _selectedCategory == 'Semua' ||
          item.categoryName.trim().toLowerCase() ==
              _selectedCategory.trim().toLowerCase();

      if (!matchesCategory) return false;

      // 2. Filter Pencarian
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();

      final titleMatch = item.title.toLowerCase().contains(q);
      final fieldsMatch = item.fields.any((f) =>
          f.label.toLowerCase().contains(q) ||
          f.value.toLowerCase().contains(q));
      final userMatch = item.usernameId?.toLowerCase().contains(q) ?? false;
      final emailMatch = item.email?.toLowerCase().contains(q) ?? false;
      final subMatch = item.subcategoryName.toLowerCase().contains(q);
      final rekMatch = item.nomorRekening?.toLowerCase().contains(q) ?? false;
      final ketMatch = item.keterangan?.toLowerCase().contains(q) ?? false;

      return titleMatch ||
          fieldsMatch ||
          userMatch ||
          emailMatch ||
          subMatch ||
          rekMatch ||
          ketMatch;
    }).toList();
  }

  /// Memuat semua data awal (kategori, subkategori, dan kredensial)
  Future<void> fetchInitialData(String userId, {String? partnerId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchCategories(),
        _repository.fetchSubcategories(),
        _repository.fetchCredentials(userId, partnerId: partnerId),
      ]);

      _categories = results[0] as List<CredentialCategoryModel>;
      _subcategories = results[1] as List<CredentialSubcategoryModel>;
      _credentials = results[2] as List<CredentialModel>;
    } catch (e) {
      _errorMessage = 'Gagal memuat data kredensial.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memuat ulang daftar kredensial
  Future<void> fetchCredentials(String userId, {String? partnerId}) async {
    try {
      _credentials = await _repository.fetchCredentials(userId, partnerId: partnerId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memuat kredensial.';
      notifyListeners();
    }
  }

  /// Memuat ulang daftar kategori
  Future<void> fetchCategories() async {
    try {
      _categories = await _repository.fetchCategories();
      notifyListeners();
    } catch (_) {}
  }

  /// Memuat ulang daftar subkategori (opsional per categoryId)
  Future<void> fetchSubcategories({String? categoryId}) async {
    try {
      _subcategories =
          await _repository.fetchSubcategories(categoryId: categoryId);
      notifyListeners();
    } catch (_) {}
  }

  /// Menambah kredensial baru
  Future<bool> addCredential(CredentialModel credential) async {
    _isLoading = true;
    notifyListeners();

    try {
      final created = await _repository.addCredential(credential);
      _credentials.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error addCredential: $e');
      _errorMessage = 'Gagal menyimpan kredensial: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Memperbarui kredensial
  Future<bool> updateCredential(CredentialModel credential) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _repository.updateCredential(credential);
      final index = _credentials.indexWhere((c) => c.id == updated.id);
      if (index != -1) {
        _credentials[index] = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updateCredential: $e');
      _errorMessage = 'Gagal memperbarui kredensial: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Menghapus kredensial
  Future<bool> deleteCredential(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteCredential(id);
      _credentials.removeWhere((c) => c.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus kredensial.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Menambah kategori kustom
  Future<CredentialCategoryModel?> addCategory(
      String name, String userId) async {
    try {
      final created =
          await _repository.addCategory(name: name.trim(), userId: userId);
      _categories.add(created);
      notifyListeners();
      return created;
    } catch (_) {
      return null;
    }
  }

  /// Menambah subkategori kustom
  Future<CredentialSubcategoryModel?> addSubcategory(
    String categoryId,
    String name,
    String userId,
  ) async {
    try {
      final created = await _repository.addSubcategory(
        categoryId: categoryId,
        name: name.trim(),
        userId: userId,
      );
      _subcategories.add(created);
      notifyListeners();
      return created;
    } catch (_) {
      return null;
    }
  }
}
