import 'package:flutter/foundation.dart';
import '../models/book_model.dart';
import '../../../core/network/supabase_client.dart';

class BookRepository {
  final _client = SupabaseNetwork.client;

  Future<List<BookModel>> getBooks() async {
    final data = await _client
        .from('books')
        .select()
        .order('created_at', ascending: false);
    
    return (data as List).map((json) => BookModel.fromJson(json)).toList();
  }

  Future<BookModel> addBook(Map<String, dynamic> bookData) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      bookData['added_by'] = user.id;
      bookData['last_updated_by'] = user.id;
    }

    final data = await _client.from('books').insert(bookData).select().single();
    
    // Increment points for gamification
    if (user != null) {
      await _client.rpc('increment_points', params: {'user_id': user.id, 'point_amount': 10});
    }

    return BookModel.fromJson(data);
  }

  Future<void> updateBook(String id, Map<String, dynamic> updates) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      updates['last_updated_by'] = user.id;
    }

    await _client.from('books').update(updates).eq('id', id);
    
    if (user != null) {
      await _client.rpc('increment_points', params: {'user_id': user.id, 'point_amount': 5});
    }
  }

  Future<void> deleteBook(String id) async {
    await _client.from('books').delete().eq('id', id);
  }

  Future<void> addGenresToBook(String bookId, List<String> genreNames) async {
    final user = _client.auth.currentUser;
    if (user == null || genreNames.isEmpty) return;
    
    for (String name in genreNames) {
      try {
        // Upsert genre
        final data = await _client.from('genres').upsert({
          'name': name.toLowerCase().trim(),
          'created_by': user.id,
        }, onConflict: 'name').select('id').single();
        
        final genreId = data['id'];
        
        // Link to book
        await _client.from('book_genres').upsert({
          'book_id': bookId,
          'genre_id': genreId,
        });
      } catch (e) {
        debugPrint('Error inserting genre $name: $e');
      }
    }
  }

  Future<void> addBookNotes(String bookId, List<Map<String, dynamic>> notes) async {
    final user = _client.auth.currentUser;
    if (user == null || notes.isEmpty) return;

    for (var note in notes) {
      await _client.from('book_notes').insert({
        'book_id': bookId,
        'page_number': note['page'],
        'note_text': note['text'],
        'added_by': user.id,
      });
    }
  }

  Future<void> addCharacters(String bookId, List<Map<String, dynamic>> characters) async {
    final user = _client.auth.currentUser;
    if (user == null || characters.isEmpty) return;

    for (var char in characters) {
      await _client.from('characters').insert({
        'book_id': bookId,
        'name': char['name'],
        'role': char['role'],
        'added_by': user.id,
      });
    }
  }

  Future<List<String>> getBookGenres(String bookId) async {
    try {
      final data = await _client
          .from('book_genres')
          .select('genres(name)')
          .eq('book_id', bookId);
      return (data as List).map((e) => e['genres']['name'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching genres: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBookNotes(String bookId) async {
    try {
      final data = await _client
          .from('book_notes')
          .select()
          .eq('book_id', bookId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching notes: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBookCharacters(String bookId) async {
    try {
      final data = await _client
          .from('characters')
          .select()
          .eq('book_id', bookId);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching characters: $e');
      return [];
    }
  }
}
