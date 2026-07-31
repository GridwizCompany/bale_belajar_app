import 'package:shared_preferences/shared_preferences.dart';

import 'audio_state.dart';

class AudioPreferences {
  static const _key = 'bale_belajar_audio_settings_v1';

  Future<AudioState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null || raw.length != 4) return const AudioState();

    return AudioState(
      soundEnabled: raw[0] == 'true',
      musicEnabled: raw[1] == 'true',
      soundVolume: _parseVolume(raw[2], 0.80),
      musicVolume: _parseVolume(raw[3], 0.35),
    );
  }

  Future<void> save(AudioState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, [
      state.soundEnabled.toString(),
      state.musicEnabled.toString(),
      state.soundVolume.clamp(0.0, 1.0).toStringAsFixed(3),
      state.musicVolume.clamp(0.0, 1.0).toStringAsFixed(3),
    ]);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  double _parseVolume(String value, double fallback) {
    return (double.tryParse(value) ?? fallback).clamp(0.0, 1.0);
  }
}
