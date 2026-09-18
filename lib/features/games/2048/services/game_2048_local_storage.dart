import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_2048_snapshot.dart';

class Game2048LocalStorage {
  static const String activeGameKey = 'game_2048_active_v1';
  static const String bestScoreKey = 'game_2048_best_score';

  Future<Game2048Snapshot?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(activeGameKey);
      if (raw == null || raw.isEmpty) {
        return null;
      }

      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        await prefs.remove(activeGameKey);
        return null;
      }

      return Game2048Snapshot.fromJson(json);
    } catch (e) {
      debugPrint('Error loading 2048 active game snapshot: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(activeGameKey);
      } catch (_) {}
      return null;
    }
  }

  Future<void> save(Game2048Snapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(snapshot.toJson());
    await prefs.setString(activeGameKey, raw);
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
