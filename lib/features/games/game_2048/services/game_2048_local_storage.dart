import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_2048_snapshot.dart';

class Game2048LocalStorage {
  static const String activeSnapshotKey = 'game_2048_active_v1';
  static const String bestScoreKey = 'game_2048_best_score';

  Future<Game2048Snapshot?> load() async {
    final preferences = await SharedPreferences.getInstance();
    try {
      final encoded = preferences.getString(activeSnapshotKey);
      if (encoded == null) return null;

      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        throw const FormatException('Snapshot must be a JSON object.');
      }
      return Game2048Snapshot.fromJson(Map<String, dynamic>.from(decoded));
    } on Object {
      await preferences.remove(activeSnapshotKey);
      return null;
    }
  }

  Future<void> save(Game2048Snapshot snapshot) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
        activeSnapshotKey, jsonEncode(snapshot.toJson()));
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(activeSnapshotKey);
  }

  Future<int> loadBestScore() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(bestScoreKey) ?? 0;
  }

  Future<void> saveBestScore(int score) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(bestScoreKey, score);
  }
}
