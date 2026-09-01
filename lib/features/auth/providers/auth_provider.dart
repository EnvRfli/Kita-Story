import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  UserModel? _currentUserProfile;
  UserModel? get currentUserProfile => _currentUserProfile;

  UserModel? _partnerProfile;
  UserModel? get partnerProfile => _partnerProfile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _repository.getCurrentUser() != null;
  String? get currentEmail => _repository.getCurrentUser()?.email;

  Future<void> checkAuthStatus() async {
    final user = _repository.getCurrentUser();
    if (user != null) {
      await _loadUserProfile(user.id);
    }
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final user = _repository.getCurrentUser();
    if (user != null) {
      await _loadUserProfile(user.id);
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final response =
          await _repository.signInWithEmailPassword(email, password);
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
      final response =
          await _repository.signUpWithEmailPassword(email, password, name);
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

  Future<bool> updateProfilePhoto(String photoUrl) async {
    final user = _repository.getCurrentUser();
    if (user == null) return false;

    _setLoading(true);
    try {
      await _repository.updateProfilePhoto(user.id, photoUrl);
      await _loadUserProfile(user.id);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateAccount({
    required String name,
    String? newEmail,
    String? currentPassword,
    String? newPassword,
  }) async {
    final user = _repository.getCurrentUser();
    if (user == null) return false;

    _setLoading(true);
    _errorMessage = null;
    try {
      await _repository.updateAccount(
        userId: user.id,
        name: name,
        newEmail: newEmail,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      await _loadUserProfile(user.id);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  RealtimeChannel? _profileSubscription;

  Future<void> signOut() async {
    _profileSubscription?.unsubscribe();
    _profileSubscription = null;
    await _repository.signOut();
    _currentUserProfile = null;
    _partnerProfile = null;
    notifyListeners();
  }

  Future<void> _loadUserProfile(String userId) async {
    _currentUserProfile = await _repository.getUserProfile(userId);
    if (_currentUserProfile != null && _currentUserProfile!.partnerId != null) {
      _partnerProfile =
          await _repository.getUserProfile(_currentUserProfile!.partnerId!);
    } else {
      _partnerProfile = null;
    }

    _subscribeToProfiles(userId, _currentUserProfile?.partnerId);
  }

  void _subscribeToProfiles(String userId, String? partnerId) {
    _profileSubscription?.unsubscribe();

    try {
      final client = Supabase.instance.client;
      final channel = client.channel('public:app_users_sync:$userId');

      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'app_users',
        callback: (payload) {
          final newRec = payload.newRecord;
          if (newRec.isEmpty) return;
          final recordId = newRec['id'] as String?;
          if (recordId == userId) {
            _currentUserProfile = UserModel.fromJson(newRec);
            notifyListeners();
          } else if (partnerId != null && recordId == partnerId) {
            _partnerProfile = UserModel.fromJson(newRec);
            notifyListeners();
          }
        },
      ).subscribe();

      _profileSubscription = channel;
    } catch (_) {}
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _profileSubscription?.unsubscribe();
    super.dispose();
  }
}
