import 'package:flutter/foundation.dart';
import '../models/book_model.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/activity_log_service.dart';

class BookRepository {
  final _client = SupabaseNetwork.client;

  Future<List<BookModel>> getBooks({String? targetUserId}) async {
    final user = _client.auth.currentUser;
    final uid = targetUserId ?? user?.id;
    if (uid == null) return [];

    final data = await _client
        .from('books')
        .select()
        .eq('added_by', uid)
        .order('created_at', ascending: false);

    return (data as List).map((json) => BookModel.fromJson(json)).toList();
  }

  Future<BookModel> getBookById(String id) async {
    final data = await _client.from('books').select().eq('id', id).single();
    return BookModel.fromJson(data);
  }

  Future<void> _recordActivityAndAddPoints({
    required String userId,
    required int points,
    required String activityType,
    required String title,
    required String description,
    String? referenceId,
  }) async {
    await ActivityLogService.recordActivityAndAddPoints(
      userId: userId,
      points: points,
      activityType: activityType,
      title: title,
      description: description,
      referenceId: referenceId,
    );
  }

  Future<BookModel> addBook(Map<String, dynamic> bookData) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      bookData['added_by'] = user.id;
      bookData['last_updated_by'] = user.id;
    }

    // Sanitize personal_rating so 0 or invalid rating is omitted
    if (bookData.containsKey('personal_rating')) {
      final rating = bookData['personal_rating'];
      if (rating == null || (rating is num && (rating < 1 || rating > 5))) {
        bookData.remove('personal_rating');
      }
    }

    final data = await _client.from('books').insert(bookData).select().single();
    final bookTitle = bookData['title'] as String? ?? 'Buku';

    // Record activity & increment points (+10 pts)
    if (user != null) {
      await _recordActivityAndAddPoints(
        userId: user.id,
        points: 10,
        activityType: 'add_book',
        title: 'Menambah Buku Baru 📖',
        description: 'Menambahkan buku "$bookTitle" ke rak',
        referenceId: data['id'] as String?,
      );
    }

    return BookModel.fromJson(data);
  }

  Future<void> updateBook(String id, Map<String, dynamic> updates) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      updates['last_updated_by'] = user.id;
    }

    // Sanitize personal_rating so 0 or invalid rating is set to null
    if (updates.containsKey('personal_rating')) {
      final rating = updates['personal_rating'];
      if (rating is num && (rating < 1 || rating > 5)) {
        updates['personal_rating'] = null;
      }
    }

    await _client.from('books').update(updates).eq('id', id);

    if (user != null) {
      try {
        final bookData = await _client
            .from('books')
            .select('title, total_pages, current_page')
            .eq('id', id)
            .single();
        final bookTitle = bookData['title'] as String? ?? 'Buku';
        final totalPages = bookData['total_pages'] as int? ?? 0;
        final currentPage = updates['current_page'] as int? ??
            (bookData['current_page'] as int? ?? 0);

        if (totalPages > 0 &&
            currentPage >= totalPages &&
            updates['current_page'] != null) {
          // Bonus finisher (+30 pts = 5 base + 25 bonus)
          await _recordActivityAndAddPoints(
            userId: user.id,
            points: 30,
            activityType: 'finish_book',
            title: 'Menamatkan Buku 🏆',
            description: 'Menyelesaikan membaca buku "$bookTitle"',
            referenceId: id,
          );
        } else if (updates['current_page'] != null) {
          await _recordActivityAndAddPoints(
            userId: user.id,
            points: 5,
            activityType: 'update_progress',
            title: 'Melanjutkan Membaca 🔖',
            description: 'Mencapai halaman $currentPage pada buku "$bookTitle"',
            referenceId: id,
          );
        } else {
          await _recordActivityAndAddPoints(
            userId: user.id,
            points: 5,
            activityType: 'edit_book',
            title: 'Memperbarui Buku ✍️',
            description: 'Memperbarui detail / review buku "$bookTitle"',
            referenceId: id,
          );
        }
      } catch (e) {
        debugPrint('Error recording update activity: $e');
        await _recordActivityAndAddPoints(
          userId: user.id,
          points: 5,
          activityType: 'edit_book',
          title: 'Memperbarui Buku ✍️',
          description: 'Memperbarui aktivitas buku',
          referenceId: id,
        );
      }
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
        final data = await _client
            .from('genres')
            .upsert({
              'name': name.toLowerCase().trim(),
              'created_by': user.id,
            }, onConflict: 'name')
            .select('id')
            .single();

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

  Future<void> updateBookGenres(String bookId, List<String> genreNames) async {
    try {
      // 1. Delete all existing genre links for this book
      await _client.from('book_genres').delete().eq('book_id', bookId);

      // 2. Insert newly selected genres
      if (genreNames.isNotEmpty) {
        await addGenresToBook(bookId, genreNames);
      }
    } catch (e) {
      debugPrint('Error updating book genres: $e');
    }
  }

  Future<void> addBookNotes(
    String bookId,
    List<Map<String, dynamic>> notes, {
    String? bookTitle,
  }) async {
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

    String resolvedTitle = bookTitle ?? '';
    if (resolvedTitle.isEmpty) {
      try {
        final bData = await _client
            .from('books')
            .select('title')
            .eq('id', bookId)
            .maybeSingle();
        resolvedTitle = bData?['title'] as String? ?? '';
      } catch (_) {}
    }

    final desc = resolvedTitle.isNotEmpty
        ? 'Menambahkan ${notes.length} catatan pada buku "$resolvedTitle"'
        : 'Menambahkan ${notes.length} catatan baru';

    // Record activity & increment points (+3 pts per note)
    await _recordActivityAndAddPoints(
      userId: user.id,
      points: 3 * notes.length,
      activityType: 'add_note',
      title: 'Menambah Catatan 📝',
      description: desc,
      referenceId: bookId,
    );
  }

  Future<void> addCharacters(
      String bookId, List<Map<String, dynamic>> characters) async {
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

  Future<List<String>> getAllGenres() async {
    try {
      final data = await _client
          .from('genres')
          .select('name')
          .order('name', ascending: true);
      return (data as List).map((e) => e['name'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching all genres: $e');
      return [];
    }
  }

  Future<List<String>> getAllTraits() async {
    try {
      final data = await _client
          .from('traits')
          .select('name')
          .order('name', ascending: true);
      return (data as List).map((e) => e['name'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching traits: $e');
      return [];
    }
  }

  Future<List<String>> getAllRoles() async {
    try {
      final data = await _client
          .from('character_roles')
          .select('name')
          .order('name', ascending: true);
      return (data as List).map((e) => e['name'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching character roles: $e');
      return ['Main', 'Side', 'Cameo', 'Antagonist', 'Supporting'];
    }
  }

  Future<void> addRole(String roleName) async {
    final user = _client.auth.currentUser;
    if (user == null || roleName.trim().isEmpty) return;

    try {
      await _client.from('character_roles').upsert({
        'name': roleName.trim(),
        'created_by': user.id,
      }, onConflict: 'name');
    } catch (e) {
      debugPrint('Error adding character role: $e');
    }
  }

  Future<void> addCharacterWithDetails(
    String bookId,
    Map<String, dynamic> characterData,
    List<String> traits, {
    String? bookTitle,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Upsert role if new
    final role = characterData['role'] as String?;
    if (role != null && role.trim().isNotEmpty) {
      await addRole(role.trim());
    }

    characterData['book_id'] = bookId;
    characterData['added_by'] = user.id;

    final charResult = await _client
        .from('characters')
        .insert(characterData)
        .select('id')
        .single();

    final characterId = charResult['id'] as String;

    // Link traits
    if (traits.isNotEmpty) {
      for (var traitName in traits) {
        try {
          final traitResult = await _client
              .from('traits')
              .upsert({
                'name': traitName.toLowerCase().trim(),
                'created_by': user.id,
              }, onConflict: 'name')
              .select('id')
              .single();

          final traitId = traitResult['id'];

          await _client.from('character_traits').upsert({
            'character_id': characterId,
            'trait_id': traitId,
          });
        } catch (e) {
          debugPrint('Error linking trait $traitName: $e');
        }
      }
    }

    final charName = characterData['name'] as String? ?? 'Karakter';

    String resolvedTitle = bookTitle ?? '';
    if (resolvedTitle.isEmpty) {
      try {
        final bData = await _client
            .from('books')
            .select('title')
            .eq('id', bookId)
            .maybeSingle();
        resolvedTitle = bData?['title'] as String? ?? '';
      } catch (_) {}
    }

    final desc = resolvedTitle.isNotEmpty
        ? 'Mendaftarkan tokoh "$charName" pada buku "$resolvedTitle"'
        : 'Mendaftarkan tokoh "$charName"';

    // Record activity & increment points (+5 pts)
    await _recordActivityAndAddPoints(
      userId: user.id,
      points: 5,
      activityType: 'add_character',
      title: 'Menambah Tokoh Karakter 🎭',
      description: desc,
      referenceId: bookId,
    );
  }

  Future<void> updateCharacterWithDetails(
    String characterId,
    Map<String, dynamic> characterData,
    List<String> traits,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Upsert role if new
    final role = characterData['role'] as String?;
    if (role != null && role.trim().isNotEmpty) {
      await addRole(role.trim());
    }

    await _client
        .from('characters')
        .update(characterData)
        .eq('id', characterId);

    // Re-link traits
    if (traits.isNotEmpty) {
      await _client
          .from('character_traits')
          .delete()
          .eq('character_id', characterId);
      for (var traitName in traits) {
        try {
          final traitResult = await _client
              .from('traits')
              .upsert({
                'name': traitName.toLowerCase().trim(),
                'created_by': user.id,
              }, onConflict: 'name')
              .select('id')
              .single();

          final traitId = traitResult['id'];

          await _client.from('character_traits').upsert({
            'character_id': characterId,
            'trait_id': traitId,
          });
        } catch (e) {
          debugPrint('Error linking trait $traitName: $e');
        }
      }
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
          .select('*, character_traits(traits(name))')
          .eq('book_id', bookId);

      return (data as List).map((item) {
        final map = Map<String, dynamic>.from(item);
        final traitList = <String>[];
        if (item['character_traits'] != null) {
          for (var ct in item['character_traits']) {
            if (ct['traits'] != null && ct['traits']['name'] != null) {
              traitList.add(ct['traits']['name'] as String);
            }
          }
        }
        map['traits'] = traitList;
        return map;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching characters: $e');
      return [];
    }
  }

  Future<void> deleteCharacter(String characterId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('characters').delete().eq('id', characterId);
    } catch (e) {
      debugPrint('Error deleting character: $e');
      rethrow;
    }
  }

  // --- Book Snippets (Quotes & Memorable Moments) ---

  Future<List<Map<String, dynamic>>> getBookSnippets(String bookId) async {
    try {
      final data = await _client
          .from('book_snippets')
          .select()
          .eq('book_id', bookId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching book snippets: $e');
      return [];
    }
  }

  Future<void> addBookSnippet(
    String bookId, {
    required String imageUrl,
    String? caption,
    int? pageNumber,
    String? bookTitle,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('book_snippets').insert({
        'book_id': bookId,
        'image_url': imageUrl,
        'caption': caption,
        'page_number': pageNumber,
        'added_by': user.id,
      });

      String resolvedTitle = bookTitle ?? '';
      if (resolvedTitle.isEmpty) {
        try {
          final bData = await _client
              .from('books')
              .select('title')
              .eq('id', bookId)
              .maybeSingle();
          resolvedTitle = bData?['title'] as String? ?? '';
        } catch (_) {}
      }

      final String desc;
      if (pageNumber != null) {
        desc = resolvedTitle.isNotEmpty
            ? 'Menyimpan cuplikan foto halaman $pageNumber pada buku "$resolvedTitle"'
            : 'Menyimpan cuplikan foto halaman $pageNumber';
      } else {
        desc = resolvedTitle.isNotEmpty
            ? 'Menyimpan cuplikan foto pada buku "$resolvedTitle"'
            : 'Menyimpan cuplikan foto baru';
      }

      // Record activity & increment points (+5 pts)
      await _recordActivityAndAddPoints(
        userId: user.id,
        points: 5,
        activityType: 'add_snippet',
        title: 'Menambah Cuplikan Foto 📸',
        description: desc,
        referenceId: bookId,
      );
    } catch (e) {
      debugPrint('Error adding book snippet: $e');
      rethrow;
    }
  }

  Future<void> updateBookSnippet(
    String snippetId, {
    required String imageUrl,
    String? caption,
    int? pageNumber,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('book_snippets').update({
        'image_url': imageUrl,
        'caption': caption,
        'page_number': pageNumber,
      }).eq('id', snippetId);
    } catch (e) {
      debugPrint('Error updating book snippet: $e');
      rethrow;
    }
  }

  Future<void> deleteBookSnippet(String snippetId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('book_snippets').delete().eq('id', snippetId);
    } catch (e) {
      debugPrint('Error deleting book snippet: $e');
      rethrow;
    }
  }

  // --- Point & Activity Logs ---

  Future<List<Map<String, dynamic>>> getActivityLogs({int limit = 20}) async {
    return ActivityLogService.getActivityLogs(limit: limit);
  }
}
