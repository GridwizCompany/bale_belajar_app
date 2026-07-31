import 'audio_types.dart';

class SoundEffectConfig {
  const SoundEffectConfig({
    required this.assetPath,
    required this.baseVolume,
    required this.priority,
    required this.cooldown,
    required this.allowOverlap,
    required this.category,
    this.interruptLowerPriority = false,
    this.musicDucking = 0,
    this.expectedDuration,
  });

  final String assetPath;
  final double baseVolume;
  final int priority;
  final Duration cooldown;
  final bool allowOverlap;
  final bool interruptLowerPriority;
  final double musicDucking;
  final Duration? expectedDuration;
  final AudioCategory category;
}

class BackgroundMusicConfig {
  const BackgroundMusicConfig({
    required this.assetPath,
    required this.baseVolume,
    this.loop = true,
  });

  final String assetPath;
  final double baseVolume;
  final bool loop;
}

class AudioAsset {
  const AudioAsset._();

  static const sfxRoot = 'audio/sfx';
  static const musicRoot = 'audio/music';
}
