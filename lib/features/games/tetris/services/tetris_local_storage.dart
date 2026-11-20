import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tetris_snapshot.dart';

class TetrisLocalStorage {
  static const String activeGameKey = 'game_tetris_active_v1';
  static const String bestScoreKey = 'game_tetris_best_score';

  Future<TetrisSnapshot?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(activeGameKey);
      if (raw == null || raw.isEmpty) return null;

      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        await prefs.remove(activeGameKey);
        return null;
      }
      return TetrisSnapshot.fromJson(json);
    } catch (error) {
      debugPrint('Error loading Tetris active game snapshot: $error');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(activeGameKey);
      } catch (_) {}
      return null;
    }
  }

  Future<void> save(TetrisSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(activeGameKey, jsonEncode(snapshot.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(activeGameKey);
  }

  Future<int> loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(bestScoreKey) ?? 0;
  }

  Future<void> saveBestScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(bestScoreKey) ?? 0;
    if (score > current) {
      await prefs.setInt(bestScoreKey, score);
    }
  }
}
