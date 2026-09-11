import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// Service for two-way AES-256 encryption and decryption of sensitive user credentials.
/// 
/// Data is stored as ciphertext in Supabase (`base64(iv):base64(ciphertext)`)
/// and only decrypted locally on the authenticated user's device.
class EncryptionService {
  static const String _appSalt = 'KitaStory_Vault_AES256_Salt_2026_Secure#88';

  /// Derives a 256-bit (32-byte) AES key uniquely per user using SHA-256.
  static enc.Key _deriveKey(String userId) {
    final keyBytes = sha256.convert(utf8.encode('$userId:$_appSalt')).bytes;
    return enc.Key(Uint8List.fromList(keyBytes));
  }

  /// Encrypts a plain-text string into `base64(iv):base64(ciphertext)`.
  static String encrypt(String plainText, String userId) {
    if (plainText.isEmpty) return '';
    try {
      final key = _deriveKey(userId);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return '${iv.base64}:${encrypted.base64}';
    } catch (_) {
      return plainText;
    }
  }

  /// Decrypts ciphertext formatted as `base64(iv):base64(ciphertext)`.
  static String decrypt(String encryptedData, String userId) {
    if (encryptedData.isEmpty) return '';
    try {
      final parts = encryptedData.split(':');
      if (parts.length != 2) return encryptedData; // fallback if already plain
      final iv = enc.IV.fromBase64(parts[0]);
      final key = _deriveKey(userId);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (_) {
      // In case of decryption failure, return empty or raw
      return '';
    }
  }

  /// Encrypts a JSON-encodable object (e.g. List of fields) into ciphertext.
  static String encryptJson(dynamic jsonObject, String userId) {
    try {
      final jsonString = jsonEncode(jsonObject);
      return encrypt(jsonString, userId);
    } catch (_) {
      return '';
    }
  }

  /// Decrypts ciphertext and parses it back into dynamic JSON object.
  static dynamic decryptJson(String encryptedData, String userId) {
    if (encryptedData.isEmpty) return null;
    try {
      final decryptedString = decrypt(encryptedData, userId);
      if (decryptedString.isEmpty) return null;
      return jsonDecode(decryptedString);
    } catch (_) {
      return null;
    }
  }
}
