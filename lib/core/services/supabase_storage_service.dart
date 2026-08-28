import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/supabase_client.dart';

class SupabaseStorageService {
  static final SupabaseClient _client = SupabaseNetwork.client;

  static const String booksCoverBucket = 'books cover';
  static const String charactersProfileBucket = 'characters profile';
  static const String bookSnippetsBucket = 'book snippets';

  /// Uploads a book cover image and returns its public URL
  static Future<String> uploadBookCover(
    Uint8List bytes, {
    String fileExtension = 'jpg',
    String? contentType,
  }) async {
    return _uploadToStorage(
      primaryBucket: booksCoverBucket,
      fallbackBuckets: const ['books_cover', 'books-cover', 'books'],
      bytes: bytes,
      fileExtension: fileExtension,
      contentType: contentType ?? 'image/jpeg',
    );
  }

  /// Uploads a character profile image and returns its public URL
  static Future<String> uploadCharacterPhoto(
    Uint8List bytes, {
    String fileExtension = 'jpg',
    String? contentType,
  }) async {
    return _uploadToStorage(
      primaryBucket: charactersProfileBucket,
      fallbackBuckets: const [
        'characters_profile',
        'characters-profile',
        'characters'
      ],
      bytes: bytes,
      fileExtension: fileExtension,
      contentType: contentType ?? 'image/jpeg',
    );
  }

  /// Uploads a book snippet image and returns its public URL
  static Future<String> uploadBookSnippet(
    Uint8List bytes, {
    String fileExtension = 'jpg',
    String? contentType,
  }) async {
    return _uploadToStorage(
      primaryBucket: bookSnippetsBucket,
      fallbackBuckets: const [
        'book_snippets',
        'book-snippets',
        'snippets'
      ],
      bytes: bytes,
      fileExtension: fileExtension,
      contentType: contentType ?? 'image/jpeg',
    );
  }

  static Future<String> _uploadToStorage({
    required String primaryBucket,
    required List<String> fallbackBuckets,
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) async {
    final user = _client.auth.currentUser;
    final userId = user?.id ?? 'anonymous';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${userId}_$timestamp.$fileExtension';
    final filePath = '$userId/$fileName';

    final bucketsToTry = [primaryBucket, ...fallbackBuckets];
    Object? lastError;

    for (final bucket in bucketsToTry) {
      try {
        debugPrint('Mencoba upload ke bucket: $bucket, path: $filePath');
        await _client.storage.from(bucket).uploadBinary(
              filePath,
              bytes,
              fileOptions: FileOptions(
                contentType: contentType,
                upsert: true,
              ),
            );

        final publicUrl = _client.storage.from(bucket).getPublicUrl(filePath);
        debugPrint('Upload berhasil! Public URL: $publicUrl');
        return publicUrl;
      } catch (e) {
        debugPrint('Upload ke bucket $bucket gagal: $e');
        lastError = e;
      }
    }

    throw Exception(
      'Gagal mengunggah gambar ke Supabase Storage: ${lastError ?? "Bucket tidak ditemukan"}',
    );
  }
}
