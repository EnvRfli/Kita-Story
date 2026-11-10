import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LudoSfx {
  diceRoll('dice_roll.wav', 0.55),
  diceLand('dice_land.wav', 0.65),
  step('step.wav', 0.35),
  capture('capture.wav', 0.7),
  home('home.wav', 0.7),
  win('win.wav', 0.8),
  turn('turn.wav', 0.45);

  final String file;
  final double volume;

  const LudoSfx(this.file, this.volume);

  String get assetPath => 'audio/ludo/$file';
}

class LudoSoundService {
  static final LudoSoundService instance = LudoSoundService._();

  LudoSoundService._();

  /// Silent instance for unit/widget tests.
  LudoSoundService.forTesting()
      : _enabled = false,
        _initialized = true;

  static const String _prefKey = 'ludo_sound_enabled';

  final Map<LudoSfx, AudioPlayer> _players = {};
  bool _enabled = true;
  bool _initialized = false;

  bool get enabled => _enabled;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefKey) ?? true;
    } catch (_) {
      _enabled = true;
    }

    for (final sfx in LudoSfx.values) {
      final player = AudioPlayer();
      try {
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setPlayerMode(PlayerMode.lowLatency);
      } catch (_) {}
      _players[sfx] = player;
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {}
  }

  Future<void> play(LudoSfx sfx, {double? volume}) async {
    if (!_enabled) return;
    await initialize();

    final player = _players[sfx];
    if (player == null) return;

    try {
      await player.stop();
      await player.play(
        AssetSource(sfx.assetPath),
        volume: volume ?? sfx.volume,
      );
    } catch (e) {
      debugPrint('Ludo sound ${sfx.name} failed: $e');
    }
  }

  Future<void> stopAll() async {
    for (final player in _players.values) {
      try {
        await player.stop();
      } catch (_) {}
    }
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}
