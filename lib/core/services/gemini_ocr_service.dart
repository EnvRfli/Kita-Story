import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiOcrService {
  static const String _synopsisPrompt = '''
Kamu adalah asisten pembaca buku pintar. Analisis gambar sampul belakang buku ini dan ekstrak HANYA teks sinopsis / deskripsi cerita buku.

Aturan Penting:
1. Abaikan kode barcode, nomor ISBN, kutipan testimoni/pujian (seperti "Buku terlaris...", "Must-read novel!"), nama penerbit, harga, dan biografi singkat penulis.
2. Format hasilnya dalam susunan paragraf yang rapi sesuai bahasa aslinya (jangan diterjemahkan).
3. Sambungkan kata-kata yang terputus tanda hubung di ujung baris (hyphenation).
4. Keluarkan HANYA teks sinopsisnya saja secara langsung tanpa tambahan kalimat pengantar seperti "Berikut adalah sinopsisnya:" atau kata penutup.
''';

  /// Candidate model names to try in order (resilient across Google AI Studio versions)
  static const List<String> _candidateModels = [
    'gemini-3.6-flash',
    'gemini-3.7-flash',
    'gemini-3.0-flash',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  /// Extracts clean book synopsis from image bytes using Gemini
  static Future<String> extractSynopsis(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    final rawKey = dotenv.env['GEMINI_API_KEY'];
    if (rawKey == null || rawKey.trim().isEmpty) {
      throw Exception(
        'GEMINI_API_KEY belum dikonfigurasi di file .env. Silakan tambahkan API key Gemini Anda terlebih dahulu.',
      );
    }

    // Clean up key if it contains quotes or accidental spaces
    final apiKey = rawKey.trim().replaceAll('"', '').replaceAll("'", '');

    // Allow custom model override from .env if specified
    final envModel = dotenv.env['GEMINI_MODEL']?.trim();
    final modelsToTry = [
      if (envModel != null && envModel.isNotEmpty) envModel,
      ..._candidateModels,
    ];

    Object? lastError;

    for (final modelName in modelsToTry) {
      try {
        debugPrint('Mencoba Gemini model: $modelName');
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
        );

        final content = [
          Content.multi([
            TextPart(_synopsisPrompt),
            DataPart(mimeType, imageBytes),
          ])
        ];

        final response = await model.generateContent(content);
        final text = response.text?.trim();

        if (text != null && text.isNotEmpty) {
          debugPrint('Berhasil mengekstrak sinopsis dengan model: $modelName');
          return text;
        }
      } catch (e) {
        debugPrint('Model $modelName gagal: $e');
        lastError = e;
      }
    }

    throw Exception(
      'Gagal mengekstrak sinopsis: ${lastError ?? "Model Gemini tidak merespon"}',
    );
  }
}
