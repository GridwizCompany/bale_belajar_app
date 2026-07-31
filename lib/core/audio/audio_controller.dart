import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'audio_asset.dart';
import 'audio_config.dart';
import 'audio_preferences.dart';
import 'audio_state.dart';
import 'audio_types.dart';

class AudioController extends ChangeNotifier {
  AudioController({AudioPreferences? preferences})
      : _preferences = preferences ?? AudioPreferences();

  final AudioPreferences _preferences;
  final Map<SoundEffectId, AudioPlayer> _soundPlayers = {};
  final Map<SoundEffectId, DateTime> _lastPlayedAt = {};
  final Set<SoundEffectId> _missingOrFailedAssets = {};
  final List<_QueuedMajorSound> _majorQueue = [];
  final Map<Object, double> _activeDucks = {};
  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'bale_music');

  AudioState _state = const AudioState();
  bool _disposed = false;
  bool _initializing = false;
  bool _processingMajorQueue = false;
  bool _wasMusicPlayingBeforePause = false;
  Timer? _activeSoundPriorityTimer;
  Timer? _duckRestoreTimer;

  AudioState get state => _state;

  Future<void> initialize() async {
    if (_state.isInitialized || _initializing || _disposed) return;
    _initializing = true;
    try {
      final saved = await _preferences.load();
      _state = saved.copyWith(isInitialized: true);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setPlayerMode(PlayerMode.mediaPlayer);

      for (final id in AudioConfig.preloadedSounds) {
        _soundPlayers[id] = await _createSfxPlayer(id);
      }
    } catch (error, stackTrace) {
      _debugLog('Audio init failed: $error', stackTrace);
      _state = _state.copyWith(isInitialized: true);
    } finally {
      _initializing = false;
      _safeNotify();
    }
  }

  Future<void> playSound(SoundEffectId id, {bool force = false}) async {
    if (_disposed) return;
    if (!_state.isInitialized) await initialize();
    if (!_state.soundEnabled && !force) return;

    final config = AudioConfig.sounds[id];
    if (config == null) return;
    if (!_canPlay(id, config, force: force)) return;

    if (_isMajorReward(id)) {
      _majorQueue.add(_QueuedMajorSound(id, force));
      await _processMajorQueue();
      return;
    }

    await _playConfiguredSound(id, config, force: force);
  }

  Future<void> stopSound(SoundEffectId id) async {
    await _soundPlayers[id]?.stop();
  }

  Future<void> stopAllSoundEffects() async {
    for (final player in _soundPlayers.values) {
      await player.stop();
    }
    _activeSoundPriorityTimer?.cancel();
    _state = _state.copyWith(activeSoundPriority: 0);
    _safeNotify();
  }

  Future<void> playMusic(
    BackgroundMusicId id, {
    bool loop = true,
    Duration fadeIn = const Duration(milliseconds: 800),
  }) async {
    if (_disposed) return;
    if (!_state.isInitialized) await initialize();
    if (!_state.musicEnabled || !_state.isAppInForeground) return;

    final config = AudioConfig.music[id];
    if (config == null) return;

    if (_state.currentMusic == id && _state.isMusicPlaying) {
      await _applyMusicVolume();
      return;
    }

    if (_state.isMusicPlaying) {
      await stopMusic(fadeOut: const Duration(milliseconds: 350));
    }

    try {
      await _musicPlayer
          .setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await _musicPlayer.setVolume(0);
      await _musicPlayer.play(AssetSource(config.assetPath));
      _state = _state.copyWith(currentMusic: id, isMusicPlaying: true);
      _safeNotify();
      await _fadeMusic(to: _effectiveMusicVolumeFor(id), duration: fadeIn);
    } catch (error, stackTrace) {
      _debugLog('Music failed: ${config.assetPath}: $error', stackTrace);
    }
  }

  Future<void> pauseMusic() async {
    if (_disposed) return;
    _wasMusicPlayingBeforePause = _state.isMusicPlaying;
    try {
      await _musicPlayer.pause();
    } catch (error, stackTrace) {
      _debugLog('Pause music failed: $error', stackTrace);
    }
    _state = _state.copyWith(isMusicPlaying: false);
    _safeNotify();
  }

  Future<void> resumeMusic() async {
    if (_disposed || !_state.musicEnabled || !_state.isAppInForeground) return;
    if (!_wasMusicPlayingBeforePause && _state.currentMusic == null) return;
    try {
      await _musicPlayer.resume();
      _state = _state.copyWith(isMusicPlaying: true);
      _safeNotify();
      await _fadeMusic(
        to: _effectiveMusicVolumeFor(_state.currentMusic),
        duration: const Duration(milliseconds: 800),
      );
    } catch (error, stackTrace) {
      _debugLog('Resume music failed: $error', stackTrace);
    }
  }

  Future<void> stopMusic({
    Duration fadeOut = const Duration(milliseconds: 600),
  }) async {
    if (_disposed) return;
    try {
      await _fadeMusic(to: 0, duration: fadeOut);
      await _musicPlayer.stop();
    } catch (error, stackTrace) {
      _debugLog('Stop music failed: $error', stackTrace);
    }
    _state = _state.copyWith(isMusicPlaying: false);
    _safeNotify();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _state = _state.copyWith(soundEnabled: enabled);
    _safeNotify();
    await _preferences.save(_state);
    if (!enabled) await stopAllSoundEffects();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _state = _state.copyWith(musicEnabled: enabled);
    _safeNotify();
    await _preferences.save(_state);
    if (enabled) {
      final current = _state.currentMusic;
      if (current != null) await playMusic(current);
    } else {
      await stopMusic();
    }
  }

  Future<void> setSoundVolume(double value) async {
    _state = _state.copyWith(soundVolume: value.clamp(0.0, 1.0));
    _safeNotify();
    await _preferences.save(_state);
  }

  Future<void> setMusicVolume(double value) async {
    _state = _state.copyWith(musicVolume: value.clamp(0.0, 1.0));
    _safeNotify();
    await _preferences.save(_state);
    await _applyMusicVolume();
  }

  Future<void> resetSettings() async {
    await _preferences.reset();
    _state = const AudioState(isInitialized: true);
    _safeNotify();
    await _applyMusicVolume();
  }

  Future<void> previewSound() {
    return playSound(SoundEffectId.mascotWave, force: true);
  }

  Future<void> setAppInForeground(bool foreground) async {
    if (_disposed) return;
    if (_state.isAppInForeground == foreground) return;
    _state = _state.copyWith(isAppInForeground: foreground);
    _safeNotify();

    if (foreground) {
      if (_wasMusicPlayingBeforePause) await resumeMusic();
    } else {
      await pauseMusic();
      await stopAllSoundEffects();
    }
  }

  Future<void> handleMascotWave() {
    return playSound(SoundEffectId.mascotWave);
  }

  Future<void> handleIncorrectAnswer({
    required String attemptId,
    int wrongAttemptCount = 1,
  }) {
    final id = wrongAttemptCount >= 2
        ? SoundEffectId.incorrectAnswerAlternative
        : SoundEffectId.incorrectAnswer;
    return playSound(id);
  }

  Future<void> handleRetry() {
    return playSound(SoundEffectId.encouragement);
  }

  Future<void> handleLevelUp({required String levelUpEventId}) {
    return playSound(SoundEffectId.levelUp, force: true);
  }

  Future<void> playBadgeUnlock({bool force = true}) {
    return playSound(SoundEffectId.badgeUnlock, force: force);
  }

  bool _canPlay(
    SoundEffectId id,
    SoundEffectConfig config, {
    required bool force,
  }) {
    if (_missingOrFailedAssets.contains(id)) return false;
    if (!force && _state.activeSoundPriority > config.priority) return false;
    final last = _lastPlayedAt[id];
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < config.cooldown) {
      return false;
    }
    if (!config.allowOverlap && _isMajorReward(id) && _processingMajorQueue) {
      return false;
    }
    return true;
  }

  Future<void> _processMajorQueue() async {
    if (_processingMajorQueue || _disposed) return;
    _processingMajorQueue = true;

    while (_majorQueue.isNotEmpty) {
      final next = _majorQueue.removeAt(0);
      final config = AudioConfig.sounds[next.id];
      if (config == null || !_canPlay(next.id, config, force: next.force)) {
        continue;
      }
      await _playConfiguredSound(next.id, config, force: next.force);
      if (_majorQueue.isNotEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }

    _processingMajorQueue = false;
  }

  Future<void> _playConfiguredSound(
    SoundEffectId id,
    SoundEffectConfig config, {
    required bool force,
  }) async {
    final player = await _playerFor(id);
    if (player == null) return;

    try {
      if (!config.allowOverlap) await player.stop();
      if (config.musicDucking > 0) {
        _duckMusic(id, config.musicDucking, config.expectedDuration);
      }
      _lastPlayedAt[id] = DateTime.now();
      _setActivePriority(config.priority, config.expectedDuration);
      await player
          .setVolume((_state.soundVolume * config.baseVolume).clamp(0.0, 1.0));
      await player.play(AssetSource(config.assetPath));
    } catch (error, stackTrace) {
      _missingOrFailedAssets.add(id);
      _debugLog('Sound failed: ${config.assetPath}: $error', stackTrace);
    }
  }

  Future<AudioPlayer?> _playerFor(SoundEffectId id) async {
    if (_soundPlayers[id] != null) return _soundPlayers[id];
    try {
      final player = await _createSfxPlayer(id);
      _soundPlayers[id] = player;
      return player;
    } catch (error, stackTrace) {
      _missingOrFailedAssets.add(id);
      _debugLog('Create sound player failed for $id: $error', stackTrace);
      return null;
    }
  }

  Future<AudioPlayer> _createSfxPlayer(SoundEffectId id) async {
    final player = AudioPlayer(playerId: 'bale_sfx_${id.name}');
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setPlayerMode(PlayerMode.lowLatency);
    return player;
  }

  void _setActivePriority(int priority, Duration? duration) {
    _activeSoundPriorityTimer?.cancel();
    _state = _state.copyWith(activeSoundPriority: priority);
    _safeNotify();
    _activeSoundPriorityTimer =
        Timer(duration ?? const Duration(milliseconds: 700), () {
      if (_disposed) return;
      _state = _state.copyWith(activeSoundPriority: 0);
      _safeNotify();
    });
  }

  void _duckMusic(SoundEffectId id, double amount, Duration? duration) {
    _activeDucks[id] = amount.clamp(0.0, 1.0);
    _applyMusicVolume();
    _duckRestoreTimer?.cancel();
    _duckRestoreTimer =
        Timer(duration ?? const Duration(milliseconds: 900), () {
      _activeDucks.remove(id);
      _applyMusicVolume();
    });
  }

  Future<void> _applyMusicVolume() async {
    if (_disposed) return;
    try {
      await _musicPlayer
          .setVolume(_effectiveMusicVolumeFor(_state.currentMusic));
    } catch (error, stackTrace) {
      _debugLog('Apply music volume failed: $error', stackTrace);
    }
  }

  double _effectiveMusicVolumeFor(BackgroundMusicId? id) {
    if (id == null || !_state.musicEnabled) return 0;
    final config = AudioConfig.music[id];
    if (config == null) return 0;
    final strongestDuck = _activeDucks.values
        .fold<double>(0, (max, value) => value > max ? value : max);
    return (_state.musicVolume * config.baseVolume * (1 - strongestDuck))
        .clamp(0.0, 1.0);
  }

  Future<void> _fadeMusic({
    required double to,
    required Duration duration,
  }) async {
    final steps = duration.inMilliseconds <= 0 ? 1 : 10;
    final from = _effectiveMusicVolumeFor(_state.currentMusic);
    for (var i = 1; i <= steps; i++) {
      if (_disposed) return;
      final value = from + ((to - from) * (i / steps));
      await _musicPlayer.setVolume(value.clamp(0.0, 1.0));
      await Future<void>.delayed(duration ~/ steps);
    }
  }

  bool _isMajorReward(SoundEffectId id) {
    return id == SoundEffectId.levelUp || id == SoundEffectId.badgeUnlock;
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  void _debugLog(String message, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    debugPrint('[BaleAudio] $message');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }

  @override
  void dispose() {
    _disposed = true;
    _activeSoundPriorityTimer?.cancel();
    _duckRestoreTimer?.cancel();
    for (final player in _soundPlayers.values) {
      unawaited(player.dispose());
    }
    unawaited(_musicPlayer.dispose());
    super.dispose();
  }
}

class _QueuedMajorSound {
  const _QueuedMajorSound(this.id, this.force);

  final SoundEffectId id;
  final bool force;
}
