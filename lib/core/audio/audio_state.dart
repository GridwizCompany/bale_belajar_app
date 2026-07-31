import 'audio_types.dart';

class AudioState {
  const AudioState({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.soundVolume = 0.80,
    this.musicVolume = 0.35,
    this.currentMusic,
    this.isMusicPlaying = false,
    this.isInitialized = false,
    this.isAppInForeground = true,
    this.activeSoundPriority = 0,
  });

  final bool soundEnabled;
  final bool musicEnabled;
  final double soundVolume;
  final double musicVolume;
  final BackgroundMusicId? currentMusic;
  final bool isMusicPlaying;
  final bool isInitialized;
  final bool isAppInForeground;
  final int activeSoundPriority;

  AudioState copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    double? soundVolume,
    double? musicVolume,
    BackgroundMusicId? currentMusic,
    bool clearCurrentMusic = false,
    bool? isMusicPlaying,
    bool? isInitialized,
    bool? isAppInForeground,
    int? activeSoundPriority,
  }) {
    return AudioState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      currentMusic:
          clearCurrentMusic ? null : currentMusic ?? this.currentMusic,
      isMusicPlaying: isMusicPlaying ?? this.isMusicPlaying,
      isInitialized: isInitialized ?? this.isInitialized,
      isAppInForeground: isAppInForeground ?? this.isAppInForeground,
      activeSoundPriority: activeSoundPriority ?? this.activeSoundPriority,
    );
  }
}
