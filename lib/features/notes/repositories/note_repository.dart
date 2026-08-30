import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/activity_log_service.dart';
import '../models/note_model.dart';
import '../models/checklist_item_model.dart';

class NoteRepository {
  final SupabaseClient _client = SupabaseNetwork.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Fetch notes for the logged in user + any shared notes from partner
  Future<List<NoteModel>> getNotes({
    String? targetUserId,
    String? partnerId,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    // Fetch partner ID if not provided and in personal view
    String? pId = partnerId;
    if (pId == null && targetUserId == null) {
      try {
        final userRec = await _client
            .from('app_users')
            .select('partner_id')
            .eq('id', userId)
            .maybeSingle();
        pId = userRec?['partner_id'] as String?;
      } catch (_) {}
    }

    var query = _client.from('notes').select('*, note_checklist_items(*)');

    if (targetUserId != null) {
      query = query.eq('added_by', targetUserId);
    } else if (pId != null && pId.isNotEmpty) {
      query = query.or(
          'added_by.eq.$userId,and(is_shared.eq.true,added_by.eq.$pId),and(is_shared.eq.true,partner_id.eq.$userId)');
    } else {
      query = query.or(
          'added_by.eq.$userId,and(is_shared.eq.true,partner_id.eq.$userId)');
    }

    final response = await query;

    final List<dynamic> data = response as List<dynamic>;

    final notes = data.map((noteJson) {
      final itemsData =
          noteJson['note_checklist_items'] as List<dynamic>? ?? [];
      final items = itemsData
          .map((itemJson) =>
              ChecklistItemModel.fromJson(itemJson as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      return NoteModel.fromJson(noteJson as Map<String, dynamic>, items: items);
    }).toList();

    // Deterministic Multi-Device Ordering:
    // Sort strictly by `sort_order` ASC, then `updated_at` / `created_at` DESC
    notes.sort((a, b) {
      if (a.sortOrder != b.sortOrder) {
        return a.sortOrder.compareTo(b.sortOrder);
      }
      final aTime = a.updatedAt ?? a.createdAt ?? DateTime(2000);
      final bTime = b.updatedAt ?? b.createdAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    return notes;
  }

  /// Persist custom reordered notes in Supabase with clean sequential unique ranks (0, 1, 2...)
  Future<void> updateNotesOrder(
    List<NoteModel> reorderedNotes, {
    String? targetUserId,
  }) async {
    final userId = targetUserId ?? currentUserId;
    if (userId == null || reorderedNotes.isEmpty) return;

    for (int i = 0; i < reorderedNotes.length; i++) {
      try {
        await _client.from('notes').update({
          'sort_order': i,
          'last_updated_by': userId,
        }).eq('id', reorderedNotes[i].id);
      } catch (e) {
        // Silently skip if update fails for a single row
      }
    }
  }

  /// Get single note by ID with checklist items
  Future<NoteModel?> getNoteById(String noteId) async {
    final response = await _client
        .from('notes')
        .select('*, note_checklist_items(*)')
        .eq('id', noteId)
        .maybeSingle();

    if (response == null) return null;

    final itemsData = response['note_checklist_items'] as List<dynamic>? ?? [];
    final items = itemsData
        .map((itemJson) =>
            ChecklistItemModel.fromJson(itemJson as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return NoteModel.fromJson(response, items: items);
  }

  /// Create a new note and its checklist items (awards +5 Points)
  Future<NoteModel> createNote({
    required String title,
    required String type,
    String? content,
    String? color,
    bool isShared = false,
    String? partnerId,
    List<String>? checklistItems,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User tidak terautentikasi.');
    }

    // 1. Resolve partner ID if shared and partnerId is null
    String? pId = partnerId;
    if (isShared && (pId == null || pId.isEmpty)) {
      try {
        final userRec = await _client
            .from('app_users')
            .select('partner_id')
            .eq('id', userId)
            .maybeSingle();
        pId = userRec?['partner_id'] as String?;
      } catch (_) {}
    }

    // 2. Insert parent note
    final noteResponse = await _client
        .from('notes')
        .insert({
          'title': title.trim(),
          'type': type,
          'content': content?.trim(),
          'color': color ?? 'pink',
          'is_completed': false,
          'is_shared': isShared,
          'partner_id': isShared ? pId : null,
          'added_by': userId,
          'last_updated_by': userId,
        })
        .select()
        .single();

    final noteId = noteResponse['id'] as String;
    List<ChecklistItemModel> createdItems = [];

    // 3. Insert checklist items if checklist type
    if (type == 'checklist' &&
        checklistItems != null &&
        checklistItems.isNotEmpty) {
      final itemsToInsert = checklistItems.asMap().entries.map((entry) {
        return {
          'note_id': noteId,
          'item_text': entry.value.trim(),
          'is_checked': false,
          'sort_order': entry.key,
        };
      }).toList();

      final itemsResponse = await _client
          .from('note_checklist_items')
          .insert(itemsToInsert)
          .select();

      final List<dynamic> itemsData = itemsResponse as List<dynamic>;
      createdItems = itemsData
          .map((itemJson) =>
              ChecklistItemModel.fromJson(itemJson as Map<String, dynamic>))
          .toList();
    }

    // 4. Award Points and record activity log (Shared: +10 pts, Personal: +5 pts)
    final points = isShared ? 10 : 5;
    await ActivityLogService.recordActivityAndAddPoints(
      userId: userId,
      points: points,
      activityType: isShared ? 'add_shared_note' : 'add_note',
      title:
          isShared ? 'Membuat Catatan Bersama 👥' : 'Membuat Catatan Baru 📝',
      description: isShared
          ? 'Berbagi catatan "${title.trim()}" dengan pasangan'
          : 'Membuat catatan "${title.trim()}"',
      referenceId: noteId,
    );

    return NoteModel.fromJson(noteResponse, items: createdItems);
  }

  /// Update existing note and replace / update its checklist items
  Future<void> updateNote(
    String noteId, {
    required String title,
    required String type,
    String? content,
    String? color,
    bool? isShared,
    String? partnerId,
    List<Map<String, dynamic>>? checklistItems,
  }) async {
    final userId = currentUserId;

    String? pId = partnerId;
    if (isShared == true && (pId == null || pId.isEmpty) && userId != null) {
      try {
        final userRec = await _client
            .from('app_users')
            .select('partner_id')
            .eq('id', userId)
            .maybeSingle();
        pId = userRec?['partner_id'] as String?;
      } catch (_) {}
    }

    final updateData = <String, dynamic>{
      'title': title.trim(),
      'type': type,
      'content': content?.trim(),
      'color': color ?? 'pink',
      'last_updated_by': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (isShared != null) {
      updateData['is_shared'] = isShared;
      updateData['partner_id'] = isShared ? pId : null;
    }

    // 1. Update parent note
    await _client.from('notes').update(updateData).eq('id', noteId);

    // 2. If checklist type, recreate or sync checklist items
    if (type == 'checklist' && checklistItems != null) {
      // Delete old items and insert updated ones for clean ordering
      await _client.from('note_checklist_items').delete().eq('note_id', noteId);

      if (checklistItems.isNotEmpty) {
        final itemsToInsert = checklistItems.asMap().entries.map((entry) {
          final item = entry.value;
          return {
            'note_id': noteId,
            'item_text': (item['item_text'] as String?)?.trim() ?? '',
            'is_checked': (item['is_checked'] as bool?) ?? false,
            'sort_order': entry.key,
            if (item['checked_by'] != null) 'checked_by': item['checked_by'],
          };
        }).toList();

        await _client.from('note_checklist_items').insert(itemsToInsert);
      }
    }
  }

  /// Toggle single checklist item is_checked status (Awards +1 Point when checked)
  Future<void> toggleChecklistItem(String itemId, bool isChecked) async {
    final userId = currentUserId;
    await _client.from('note_checklist_items').update({
      'is_checked': isChecked,
      'checked_by': isChecked ? userId : null,
      'checked_at': isChecked ? DateTime.now().toIso8601String() : null,
    }).eq('id', itemId);

    if (isChecked && userId != null) {
      String itemText = '';
      String noteTitle = '';
      try {
        final itemRecord = await _client
            .from('note_checklist_items')
            .select('item_text, note_id, notes(title)')
            .eq('id', itemId)
            .maybeSingle();
        if (itemRecord != null) {
          itemText = itemRecord['item_text'] as String? ?? '';
          if (itemRecord['notes'] is Map) {
            noteTitle = itemRecord['notes']['title'] as String? ?? '';
          }
        }
      } catch (_) {}

      String desc = 'Mencentang item checklist';
      if (itemText.isNotEmpty && noteTitle.isNotEmpty) {
        desc = 'Mencentang "$itemText" pada catatan "$noteTitle"';
      } else if (itemText.isNotEmpty) {
        desc = 'Mencentang "$itemText"';
      } else if (noteTitle.isNotEmpty) {
        desc = 'Mencentang checklist pada catatan "$noteTitle"';
      }

      await ActivityLogService.recordActivityAndAddPoints(
        userId: userId,
        points: 1,
        activityType: 'check_note_item',
        title: 'Checklist Selesai ☑️',
        description: desc,
        referenceId: itemId,
      );
    }
  }

  /// Mark full note as completed / uncompleted (awards +10 Points when completed!)
  Future<void> markNoteCompleted(String noteId, bool isCompleted) async {
    final userId = currentUserId;
    await _client.from('notes').update({
      'is_completed': isCompleted,
      'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
      'last_updated_by': userId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', noteId);

    // If marked completed, award +10 points to the user and log
    if (isCompleted && userId != null) {
      String noteTitle = '';
      try {
        final noteRecord = await _client
            .from('notes')
            .select('title')
            .eq('id', noteId)
            .maybeSingle();
        noteTitle = noteRecord?['title'] as String? ?? '';
      } catch (_) {}

      final desc = noteTitle.isNotEmpty
          ? 'Menyelesaikan seluruh isi catatan "$noteTitle"'
          : 'Menyelesaikan seluruh isi catatan';

      await ActivityLogService.recordActivityAndAddPoints(
        userId: userId,
        points: 10,
        activityType: 'complete_note',
        title: 'Menyelesaikan Catatan 🎉',
        description: desc,
        referenceId: noteId,
      );
    }
  }

  /// Toggle share status of an existing note
  Future<bool> toggleNoteShared(
    String noteId, {
    required bool isShared,
    String? partnerId,
  }) async {
    final userId = currentUserId;
    try {
      await _client.from('notes').update({
        'is_shared': isShared,
        'partner_id': isShared ? partnerId : null,
        'last_updated_by': userId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', noteId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Delete note and cascade delete items
  Future<void> deleteNote(String noteId) async {
    await _client.from('notes').delete().eq('id', noteId);

    // Remove from local SharedPreferences order
    try {
      final userId = currentUserId;
      if (userId != null) {
        final prefs = await SharedPreferences.getInstance();
        final savedOrder = prefs.getStringList('notes_order_$userId');
        if (savedOrder != null) {
          savedOrder.remove(noteId);
          await prefs.setStringList('notes_order_$userId', savedOrder);
        }
      }
    } catch (_) {}
  }
}
