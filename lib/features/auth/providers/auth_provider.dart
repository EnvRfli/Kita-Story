import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  
  UserModel? _currentUserProfile;
  UserModel? get currentUserProfile => _currentUserProfile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _repository.getCurrentUser() != null;

  Future<void> checkAuthStatus() async {
    final user = _repository.getCurrentUser();
    if (user != null) {
      await _loadUserProfile(user.id);
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _repository.signInWithEmailPassword(email, password);
      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
        _setLoading(false);
        return true;
      }
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
    }
    _setLoading(false);
    return false;
  }

  Future<bool> signUp(String email, String password, String name) async {
    _setLoading(true);
    try {
      final response = await _repository.signUpWithEmailPassword(email, password, name);
      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
        _setLoading(false);
        return true;
      }
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
    }
    _setLoading(false);
    return false;
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _currentUserProfile = null;
    notifyListeners();
  }

  Future<void> _loadUserProfile(String userId) async {
    _currentUserProfile = await _repository.getUserProfile(userId);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
