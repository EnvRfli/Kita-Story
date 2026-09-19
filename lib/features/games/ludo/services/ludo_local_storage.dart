import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ludo_game_state.dart';

class LudoLocalStorage {
  static const String _keyActiveGame = 'ludo_active_offline_game';
  static const String _keyWinCount = 'ludo_win_count';

  final SharedPreferences? _prefs;

  LudoLocalStorage({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ?? await SharedPreferences.getInstance();

  /// Save current active offline game
  Future<void> saveActiveGame(LudoGameState state) async {
    final prefs = await _instance;
    final jsonStr = jsonEncode(state.toJson());
    await prefs.setString(_keyActiveGame, jsonStr);
  }

  /// Load active offline game if available
  Future<LudoGameState?> loadActiveGame() async {
    try {
      final prefs = await _instance;
      final jsonStr = prefs.getString(_keyActiveGame);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return LudoGameState.fromJson(map);
    } catch (_) {
      await clearActiveGame();
      return null;
    }
  }

  /// Clear saved game (e.g. game over or abandoned)
  Future<void> clearActiveGame() async {
    final prefs = await _instance;
    await prefs.remove(_keyActiveGame);
  }

  /// Load win count
  Future<int> loadWinCount() async {
    final prefs = await _instance;
    return prefs.getInt(_keyWinCount) ?? 0;
  }

  /// Increment win count
  Future<int> incrementWinCount() async {
    final prefs = await _instance;
    final current = prefs.getInt(_keyWinCount) ?? 0;
    final updated = current + 1;
    await prefs.setInt(_keyWinCount, updated);
    return updated;
  }
}
