import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reuses the existing Ludo SFX so UNO v1 has audio without new binary assets.
enum UnoSfx {
  play('step.wav', 0.45),
  draw('turn.wav', 0.4),
  shuffle('dice_roll.wav', 0.5),
  skip('turn.wav', 0.5),
  penalty('capture.wav', 0.6),
  win('win.wav', 0.8),
  cardLand('dice_land.wav', 0.55),
  unoCall('home.wav', 0.75);

  final String file;
  final double volume;

  const UnoSfx(this.file, this.volume);

  String get assetPath => 'audio/ludo/$file';
}

class UnoSoundService {
  static final UnoSoundService instance = UnoSoundService._();

  UnoSoundService._();

  UnoSoundService.forTesting()
      : _enabled = false,
        _initialized = true;

  static const String _prefKey = 'uno_sound_enabled';

  final Map<UnoSfx, AudioPlayer> _players = {};
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

    for (final sfx in UnoSfx.values) {
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

  Future<void> play(UnoSfx sfx, {double? volume}) async {
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
      debugPrint('UNO sound ${sfx.name} failed: $e');
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
