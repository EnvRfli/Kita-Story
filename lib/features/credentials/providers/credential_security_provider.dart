import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/credential_security_repository.dart';

class CredentialSecurityProvider extends ChangeNotifier {
  final CredentialSecurityRepository _repository =
      CredentialSecurityRepository();

  bool _hasPin = false;
  bool get hasPin => _hasPin;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Memeriksa apakah pengguna sudah memiliki PIN tersimpan
  Future<bool> checkPinStatus(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _hasPin = await _repository.checkHasPin(userId);
      _isLoading = false;
      notifyListeners();
      return _hasPin;
    } catch (e) {
      _errorMessage = 'Gagal memeriksa status PIN';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Memverifikasi PIN input pengguna
  Future<bool> verifyPin(String userId, String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isValid = await _repository.verifyPin(userId, pin);
      _isLoading = false;
      if (!isValid) {
        _errorMessage = 'PIN yang kamu masukkan salah';
      }
      notifyListeners();
      return isValid;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat memverifikasi PIN';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mendaftarkan PIN pertama kali dengan verifikasi password akun
  Future<bool> setupPin({
    required String userId,
    required String email,
    required String password,
    required String pin,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.setupPin(
        userId: userId,
        email: email,
        password: password,
        pin: pin,
      );
      if (success) {
        _hasPin = true;
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal membuat PIN. Silakan coba lagi.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mereset PIN dengan verifikasi password akun
  Future<bool> resetPin({
    required String userId,
    required String email,
    required String password,
    required String newPin,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.resetPin(
        userId: userId,
        email: email,
        password: password,
        newPin: newPin,
      );
      if (success) {
        _hasPin = true;
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal mereset PIN. Silakan coba lagi.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
