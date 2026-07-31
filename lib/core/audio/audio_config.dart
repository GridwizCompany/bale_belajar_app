import 'audio_asset.dart';
import 'audio_types.dart';

class AudioConfig {
  const AudioConfig._();

  static const preloadedSounds = <SoundEffectId>{
    SoundEffectId.buttonTap,
    SoundEffectId.incorrectAnswer,
    SoundEffectId.encouragement,
    SoundEffectId.xpReward,
    SoundEffectId.mascotWave,
  };

  static const sounds = <SoundEffectId, SoundEffectConfig>{
    SoundEffectId.buttonTap: SoundEffectConfig(
      assetPath: '${AudioAsset.sfxRoot}/button_tap_soft_wood_kalimba_0_25s.ogg',
      baseVolume: 0.20,
      priority: 1,
      cooldown: Duration(milliseconds: 100),
      allowOverlap: false,
      expectedDuration: Duration(milliseconds: 250),
      category: AudioCategory.ui,
    ),
    SoundEffectId.pageTransition: SoundEffectConfig(
      assetPath:
          '${AudioAsset.sfxRoot}/page_transition_soft_airy_upward_0_4s.ogg',
      baseVolume: 0.25,
      priority: 2,
      cooldown: Duration(milliseconds: 500),
      allowOverlap: false,
      expectedDuration: Duration(milliseconds: 400),
      category: AudioCategory.ui,
    ),
    SoundEffectId.incorrectAnswer: SoundEffectConfig(
      assetPath:
          '${AudioAsset.sfxRoot}/incorrect_answer_soft_retry_v3_0_55s.ogg',
      baseVolume: 0.45,
      priority: 4,
      cooldown: Duration(milliseconds: 700),
      allowOverlap: false,
      musicDucking: 0.20,
      expectedDuration: Duration(milliseconds: 550),
      category: AudioCategory.feedback,
    ),
    SoundEffectId.incorrectAnswerAlternative: SoundEffectConfig(
      assetPath:
          '${AudioAsset.sfxRoot}/incorrect_answer_gentle_marimba_retry_0_55s.ogg',
      baseVolume: 0.42,
      priority: 4,
      cooldown: Duration(milliseconds: 700),
      allowOverlap: false,
      musicDucking: 0.20,
      expectedDuration: Duration(milliseconds: 550),
      category: AudioCategory.feedback,
    ),
    SoundEffectId.encouragement: SoundEffectConfig(
      assetPath: '${AudioAsset.sfxRoot}/encouragement_getting_closer_0_65s.ogg',
      baseVolume: 0.40,
      priority: 3,
      cooldown: Duration(milliseconds: 600),
      allowOverlap: false,
      expectedDuration: Duration(milliseconds: 650),
      category: AudioCategory.feedback,
    ),
    SoundEffectId.xpReward: SoundEffectConfig(
      assetPath: '${AudioAsset.sfxRoot}/xp_reward_polished_star_0_65s.ogg',
      baseVolume: 0.45,
      priority: 3,
      cooldown: Duration(milliseconds: 300),
      allowOverlap: false,
      expectedDuration: Duration(milliseconds: 650),
      category: AudioCategory.reward,
    ),
    SoundEffectId.dailyStreak: SoundEffectConfig(
      assetPath: '${AudioAsset.sfxRoot}/daily_streak_cozy_kalimba_v2_0_9s.ogg',
      baseVolume: 0.50,
      priority: 4,
      cooldown: Duration(milliseconds: 1000),
      allowOverlap: false,
      musicDucking: 0.20,
      expectedDuration: Duration(milliseconds: 900),
      category: AudioCategory.reward,
    ),
    SoundEffectId.badgeUnlock: SoundEffectConfig(
      assetPath: '${AudioAsset.sfxRoot}/badge_unlock_magical_warm_1_2s.ogg',
      baseVolume: 0.65,
      priority: 5,
      cooldown: Duration(milliseconds: 1500),
      allowOverlap: false,
      interruptLowerPriority: true,
      musicDucking: 0.40,
      expectedDuration: Duration(milliseconds: 1200),
      category: AudioCategory.reward,
    ),
    SoundEffectId.levelUp: SoundEffectConfig(
      assetPath: '${AudioAsset.sfxRoot}/level_up_polished_gentle_v2_1_5s.ogg',
      baseVolume: 0.70,
      priority: 5,
      cooldown: Duration(milliseconds: 2000),
      allowOverlap: false,
      interruptLowerPriority: true,
      musicDucking: 0.50,
      expectedDuration: Duration(milliseconds: 1500),
      category: AudioCategory.reward,
    ),
    SoundEffectId.mascotAppearance: SoundEffectConfig(
      assetPath:
          '${AudioAsset.sfxRoot}/mascot_appearance_warm_bubbly_v2_0_6s.ogg',
      baseVolume: 0.42,
      priority: 2,
      cooldown: Duration(milliseconds: 1500),
      allowOverlap: false,
      expectedDuration: Duration(milliseconds: 600),
      category: AudioCategory.mascot,
    ),
    SoundEffectId.mascotWave: SoundEffectConfig(
      assetPath:
          '${AudioAsset.sfxRoot}/mascot_wave_soft_swish_pop_v2_0_45s.ogg',
      baseVolume: 0.35,
      priority: 2,
      cooldown: Duration(milliseconds: 800),
      allowOverlap: false,
      expectedDuration: Duration(milliseconds: 450),
      category: AudioCategory.mascot,
    ),
    SoundEffectId.audioLogo: SoundEffectConfig(
      assetPath: '${AudioAsset.sfxRoot}/bale_belajar_audio_logo_1s.ogg',
      baseVolume: 0.50,
      priority: 4,
      cooldown: Duration(milliseconds: 3000),
      allowOverlap: false,
      expectedDuration: Duration(milliseconds: 1000),
      category: AudioCategory.brand,
    ),
  };

  static const music = <BackgroundMusicId, BackgroundMusicConfig>{
    BackgroundMusicId.home: BackgroundMusicConfig(
      assetPath:
          '${AudioAsset.musicRoot}/home_screen_learning_adventure_loop_40s.ogg',
      baseVolume: 0.15,
    ),
    BackgroundMusicId.learning: BackgroundMusicConfig(
      assetPath: '${AudioAsset.musicRoot}/focused_learning_loop_45s.ogg',
      baseVolume: 0.12,
    ),
  };
}
