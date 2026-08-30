import 'package:flutter/foundation.dart';
import '../models/note_model.dart';
import '../repositories/note_repository.dart';

class NoteProvider extends ChangeNotifier {
  final NoteRepository _repository = NoteRepository();

  List<NoteModel> _notes = [];
  List<NoteModel> get notes => _notes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNotes({
    String? targetUserId,
    String? partnerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notes = await _repository.getNotes(
        targetUserId: targetUserId,
        partnerId: partnerId,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reorderNotes(int oldIndex, int newIndex, {String? targetUserId}) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _notes.removeAt(oldIndex);
    _notes.insert(newIndex, item);
    notifyListeners();

    // Persist order in background to SharedPreferences & Supabase
    await _repository.updateNotesOrder(_notes, targetUserId: targetUserId);
  }

  Future<NoteModel?> getNoteById(String noteId) async {
    try {
      return await _repository.getNoteById(noteId);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  Future<bool> createNote({
    required String title,
    required String type,
    String? content,
    String? color,
    bool isShared = false,
    String? partnerId,
    List<String>? checklistItems,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newNote = await _repository.createNote(
        title: title,
        type: type,
        content: content,
        color: color,
        isShared: isShared,
        partnerId: partnerId,
        checklistItems: checklistItems,
      );
      _notes.insert(0, newNote);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNote(
    String noteId, {
    required String title,
    required String type,
    String? content,
    String? color,
    bool? isShared,
    String? partnerId,
    List<Map<String, dynamic>>? checklistItems,
  }) async {
    try {
      await _repository.updateNote(
        noteId,
        title: title,
        type: type,
        content: content,
        color: color,
        isShared: isShared,
        partnerId: partnerId,
        checklistItems: checklistItems,
      );
      await fetchNotes(partnerId: partnerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<void> toggleChecklistItem(
    String noteId,
    String itemId,
    bool isChecked,
  ) async {
    // 1. Optimistic UI update
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex != -1) {
      final note = _notes[noteIndex];
      final updatedItems = note.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isChecked: isChecked);
        }
        return item;
      }).toList();

      _notes[noteIndex] = note.copyWith(items: updatedItems);
      notifyListeners();
    }

    // 2. Persist to Supabase
    try {
      await _repository.toggleChecklistItem(itemId, isChecked);
    } catch (e) {
      // Revert if error
      await fetchNotes();
    }
  }

  Future<bool> markNoteCompleted(String noteId, bool isCompleted) async {
    try {
      await _repository.markNoteCompleted(noteId, isCompleted);
      final noteIndex = _notes.indexWhere((n) => n.id == noteId);
      if (noteIndex != -1) {
        _notes[noteIndex] = _notes[noteIndex].copyWith(
          isCompleted: isCompleted,
          completedAt: isCompleted ? DateTime.now() : null,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> deleteNote(String noteId) async {
    try {
      await _repository.deleteNote(noteId);
      _notes.removeWhere((n) => n.id == noteId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> toggleNoteShared(
    String noteId, {
    required bool isShared,
    String? partnerId,
  }) async {
    try {
      final success = await _repository.toggleNoteShared(
        noteId,
        isShared: isShared,
        partnerId: partnerId,
      );
      if (success) {
        final noteIndex = _notes.indexWhere((n) => n.id == noteId);
        if (noteIndex != -1) {
          _notes[noteIndex] = _notes[noteIndex].copyWith(
            isShared: isShared,
            partnerId: isShared ? partnerId : null,
          );
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
