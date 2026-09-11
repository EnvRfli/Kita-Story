import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../models/security_pin_model.dart';

class CredentialSecurityRepository {
  final _client = SupabaseNetwork.client;

  String _generateSalt([int length = 16]) {
    final random = math.Random.secure();
    final values = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(values);
  }

  String _hashPin(String userId, String salt, String pin) {
    final rawString = '$userId:$salt:$pin';
    return sha256.convert(utf8.encode(rawString)).toString();
  }

  /// Memeriksa apakah pengguna sudah pernah membuat PIN keamanan
  Future<bool> checkHasPin(String userId) async {
    try {
      final data = await _client
          .from('user_security_pins')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }

  /// Memvalidasi PIN 6 digit yang dimasukkan pengguna
  Future<bool> verifyPin(String userId, String pin) async {
    try {
      final data = await _client
          .from('user_security_pins')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return false;

      final pinModel = SecurityPinModel.fromJson(data);
      final computedHash = _hashPin(userId, pinModel.salt, pin);
      return computedHash == pinModel.pinHash;
    } catch (_) {
      return false;
    }
  }

  /// Memvalidasi kata sandi akun Supabase Auth pengguna saat ini
  Future<bool> verifyAccountPassword(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user != null;
    } on AuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Menyiapkan PIN pertama kali untuk akun pengguna
  Future<bool> setupPin({
    required String userId,
    required String email,
    required String password,
    required String pin,
  }) async {
    final isPasswordValid = await verifyAccountPassword(email, password);
    if (!isPasswordValid) {
      throw const AuthException('Kata sandi akun salah. Silakan coba lagi.');
    }

    final salt = _generateSalt();
    final pinHash = _hashPin(userId, salt, pin);
    final now = DateTime.now().toIso8601String();

    await _client.from('user_security_pins').upsert({
      'user_id': userId,
      'pin_hash': pinHash,
      'salt': salt,
      'created_at': now,
      'updated_at': now,
    });

    return true;
  }

  /// Mereset PIN yang ada dengan verifikasi password akun
  Future<bool> resetPin({
    required String userId,
    required String email,
    required String password,
    required String newPin,
  }) async {
    final isPasswordValid = await verifyAccountPassword(email, password);
    if (!isPasswordValid) {
      throw const AuthException('Kata sandi akun salah. Silakan coba lagi.');
    }

    final salt = _generateSalt();
    final pinHash = _hashPin(userId, salt, newPin);
    final now = DateTime.now().toIso8601String();

    await _client.from('user_security_pins').upsert({
      'user_id': userId,
      'pin_hash': pinHash,
      'salt': salt,
      'updated_at': now,
    });

    return true;
  }
}
