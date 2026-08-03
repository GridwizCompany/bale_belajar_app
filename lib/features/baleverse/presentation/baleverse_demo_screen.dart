import 'package:flutter/material.dart';

import '../../../core/audio/audio_scope.dart';
import '../../../core/audio/audio_types.dart';
import '../../auth/application/auth_controller.dart';
import '../application/baleverse_progress_service.dart';
import '../application/mission_engine.dart';
import '../data/baleverse_dummy_data.dart';
import '../data/worlds_repository.dart';
import '../domain/baleverse_models.dart';
import '../state/mission_state_machine.dart' as machine;
import 'screens/bale_profile_page.dart';
import 'screens/dashboard_screen.dart';
import 'screens/learning_circle_screen.dart';
import 'screens/login_demo_screen.dart';
import 'screens/mentor_handoff_screen.dart';
import 'screens/mission_hub_screen.dart';
import 'screens/mission_screen.dart';
import 'screens/reward_screen.dart';
import 'screens/worlds_screen.dart';

enum BaleTab { home, worlds, mission, profile }

class BaleVerseDemoScreen extends StatefulWidget {
  const BaleVerseDemoScreen({
    this.skipDemoLogin = true,
    this.authController,
    this.prototypeStudentProfileId,
    super.key,
  });

  final bool skipDemoLogin;
  final AuthController? authController;
  final String? prototypeStudentProfileId;

  @override
  State<BaleVerseDemoScreen> createState() => _BaleVerseDemoScreenState();
}

class _BaleVerseDemoScreenState extends State<BaleVerseDemoScreen> {
  final BaleVerseProgressService _progressService = BaleVerseProgressService();
  final MissionEngine _missionEngine = const MissionEngine();
  final WorldsRepository _worldsRepository = WorldsRepository();
  late machine.BaleVerseState _state;
  BaleTab _tab = BaleTab.home;
  String? _selectedOptionId;
  String? _feedback;
  bool _mistakeMarked = false;
  String _teachBackText = '';
  final Set<String> _mentorShare = {
    ...humanHelpRecommendation.shareableContext,
  };
  BackgroundMusicId? _lastRequestedMusic;
  Map<String, dynamic>? _backendData;

  BaleVerseProgress get _progress => _progressService.snapshot;

  @override
  void initState() {
    super.initState();
    _state = widget.skipDemoLogin
        ? const machine.BaleVerseState(step: MissionStep.dashboard)
        : const machine.BaleVerseState();
    _progressService.addListener(_onProgressChanged);
    _loadBackendData();
  }

  @override
  void dispose() {
    _progressService.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadBackendData() async {
    final studentProfileId = widget.prototypeStudentProfileId;
    final authController = widget.authController;
    if (studentProfileId == null || authController == null) return;
    try {
      final data = await authController.authService.getPrototypeBaleVerse(
        studentProfileId: studentProfileId,
      );
      final merged = Map<String, dynamic>.from(data);
      await _mergeRealWorlds(merged);
      if (!mounted) return;
      setState(() => _backendData = merged);
    } catch (_) {}
  }

  /// Tambahkan Dunia sungguhan (mis. Scientia) dari `GET /student/worlds`
  /// ke daftar dunia yang sudah ada di blob prototype - dunia yang sudah
  /// ada di blob prototype (Numeria/KodeX/Detectivia) TIDAK ditimpa, supaya
  /// tampilan kartu dunia lama yang lebih kaya (exampleMission, dst) tetap
  /// utuh. Kegagalan di sini tidak boleh menggagalkan _loadBackendData.
  Future<void> _mergeRealWorlds(Map<String, dynamic> merged) async {
    try {
      final realWorlds = await _worldsRepository.fetchWorlds();
      final existingWorlds =
          (merged['worlds'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final existingKeys = existingWorlds.map((w) => w['key']).toSet();
      final newWorlds =
          realWorlds.where((w) => !existingKeys.contains(w['key']));
      merged['worlds'] = [...existingWorlds, ...newWorlds];
    } catch (_) {}
  }

  BaleWorld get _selectedWorld {
    return baleWorlds.firstWhere((world) => world.key == _state.selectedWorld);
  }

  void _update(machine.BaleVerseState next) {
    setState(() => _state = next);
    _syncMusic();
  }

  void _goToTab(BaleTab tab) {
    if (_tab == tab) return;
    AudioScope.maybeOf(context)?.playSound(SoundEffectId.buttonTap);
    setState(() => _tab = tab);
    _syncMusic();
  }

  void _startMission() {
    final audio = AudioScope.maybeOf(context);
    audio?.playSound(SoundEffectId.pageTransition);
    setState(() {
      _tab = BaleTab.mission;
      _state = machine.startMission(_state);
    });
    _syncMusic();
  }

  void _checkAnswer() {
    final previousWrongAttempts = _state.wrongAttempts;
    final evaluation = _missionEngine.evaluate(
      state: _state,
      selectedOptionId: _selectedOptionId,
      mistakeMarked: _mistakeMarked,
      teachBackText: _teachBackText,
    );
    final audio = AudioScope.maybeOf(context);
    setState(() {
      _feedback = evaluation.feedback;
      _state = evaluation.state;
      if (evaluation.shouldApplyReward) {
        _progressService.applyMissionReward(numeriaMission);
      }
      if (_state.activityType != MissionActivityType.multipleChoice) {
        _selectedOptionId = null;
      }
    });
    if (evaluation.shouldApplyReward) {
      audio?.playSound(SoundEffectId.xpReward);
    } else if (evaluation.state.wrongAttempts > previousWrongAttempts) {
      audio?.handleIncorrectAnswer(
        attemptId: 'mission-${evaluation.state.wrongAttempts}',
        wrongAttemptCount: evaluation.state.wrongAttempts,
      );
    }
    _syncMusic();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMusic();
  }

  void _syncMusic() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final audio = AudioScope.maybeOf(context);
      if (audio == null) return;
      final target = _targetMusic;
      if (target == null) {
        _lastRequestedMusic = null;
        audio.stopMusic();
        return;
      }
      if (_lastRequestedMusic == target) return;
      _lastRequestedMusic = target;
      audio.playMusic(target);
    });
  }

  BackgroundMusicId? get _targetMusic {
    if (_state.step == MissionStep.login) return null;
    if (_tab == BaleTab.profile) return null;
    if (_tab == BaleTab.mission) return BackgroundMusicId.learning;
    return BackgroundMusicId.home;
  }

  @override
  Widget build(BuildContext context) {
    if (_state.step == MissionStep.login) {
      return LoginDemoScreen(
        onLogin: () => _update(machine.login(_state)),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: _buildBody(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: _tab.index,
        onDestinationSelected: (index) => _goToTab(BaleTab.values[index]),
        indicatorColor: const Color(0xFFFFF3C6),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_rounded),
            label: 'Dunia',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_rounded),
            label: 'Misi',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (widget.prototypeStudentProfileId != null &&
        _backendData == null &&
        _state.step == MissionStep.dashboard) {
      return const ColoredBox(
        key: ValueKey('baleverse-backend-loading'),
        color: Color(0xFFFFF3C6),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFF4B400)),
        ),
      );
    }

    if (_tab == BaleTab.home) {
      return DashboardScreen(
        key: const ValueKey('dashboard'),
        progress: _progress,
        selectedWorld: _selectedWorld,
        backendData: _backendData,
        onStartMission: _startMission,
      );
    }

    if (_tab == BaleTab.worlds) {
      return WorldsScreen(
        key: const ValueKey('worlds'),
        selectedWorld: _selectedWorld,
        backendData: _backendData,
        onSelectWorld: (world) {
          _update(machine.selectWorld(_state, world));
        },
      );
    }

    if (_tab == BaleTab.profile) {
      return BaleProfilePage(
        key: const ValueKey('profile'),
        progress: _progress,
        backendData: _backendData,
        onSignOut: widget.authController?.signOut,
      );
    }

    if (_tab == BaleTab.mission && _state.step == MissionStep.dashboard) {
      return MissionHubScreen(
        key: const ValueKey('missionHub'),
        progress: _progress,
        backendData: _backendData,
        onStartMission: _startMission,
      );
    }

    return switch (_state.step) {
      MissionStep.missionIntro => MissionIntroScreen(
          key: const ValueKey('missionIntro'),
          onStart: () {
            AudioScope.maybeOf(context)
                ?.playSound(SoundEffectId.pageTransition);
            _update(machine.beginQuestion(_state));
          },
        ),
      MissionStep.humanHelp => MentorHandoffScreen(
          key: const ValueKey('handoff'),
          selectedItems: _mentorShare,
          onToggle: (item) {
            setState(() {
              if (_mentorShare.contains(item)) {
                _mentorShare.remove(item);
              } else {
                _mentorShare.add(item);
              }
            });
          },
          onApprove: () {
            setState(() {
              _state = machine.requestMentor(_state);
              _tab = BaleTab.mission;
            });
          },
        ),
      MissionStep.waitingMentor ||
      MissionStep.mentorResponded =>
        LearningCircleScreen(
          key: const ValueKey('missionCircle'),
          progress: _progress,
          onParentSupport: () {
            setState(_progressService.markParentSupportSent);
          },
          onMentorReply: () {
            setState(() {
              _progressService.markMentorFeedbackReceived();
              _state = machine.receiveMentorFeedback(_state);
            });
          },
          onTryAgain: _progress.mentorFeedbackReceived
              ? () {
                  AudioScope.maybeOf(context)
                      ?.playSound(SoundEffectId.encouragement);
                  setState(() {
                    _feedback = null;
                    _selectedOptionId = null;
                    _mistakeMarked = false;
                    _teachBackText = '';
                    _state = _state.copyWith(
                      step: MissionStep.question,
                      wrongAttempts: 1,
                    );
                  });
                }
              : null,
        ),
      MissionStep.reward => RewardScreen(
          key: const ValueKey('reward'),
          progress: _progress,
          onBackToDashboard: () {
            AudioScope.maybeOf(context)
                ?.playSound(SoundEffectId.pageTransition);
            setState(() {
              _feedback = null;
              _selectedOptionId = null;
              _mistakeMarked = false;
              _teachBackText = '';
              _tab = BaleTab.home;
              _state = _state.copyWith(
                step: MissionStep.dashboard,
                wrongAttempts: 0,
              );
            });
            _syncMusic();
          },
        ),
      _ => MissionQuestionScreen(
          key: const ValueKey('question'),
          step: _state.step,
          activityType: _state.activityType,
          wrongAttempts: _state.wrongAttempts,
          selectedOptionId: _selectedOptionId,
          mistakeMarked: _mistakeMarked,
          teachBackText: _teachBackText,
          feedback: _feedback,
          onSelectOption: (id) => setState(() => _selectedOptionId = id),
          onMarkMistake: () => setState(() => _mistakeMarked = true),
          onTeachBackChanged: (value) => setState(() => _teachBackText = value),
          onCheck: _canCheckMission ? _checkAnswer : null,
        ),
    };
  }

  bool get _canCheckMission {
    return _missionEngine.canEvaluate(
      state: _state,
      selectedOptionId: _selectedOptionId,
      mistakeMarked: _mistakeMarked,
      teachBackText: _teachBackText,
    );
  }
}
