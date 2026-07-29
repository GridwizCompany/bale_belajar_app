import 'package:flutter/material.dart';

import '../../../theme/bale_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/profile_screen.dart';
import '../application/baleverse_progress_service.dart';
import '../application/mission_engine.dart';
import '../data/baleverse_dummy_data.dart';
import '../domain/baleverse_models.dart';
import '../state/mission_state_machine.dart' as machine;
import 'screens/dashboard_screen.dart';
import 'screens/learning_circle_screen.dart';
import 'screens/login_demo_screen.dart';
import 'screens/mentor_handoff_screen.dart';
import 'screens/mission_screen.dart';
import 'screens/reward_screen.dart';
import 'screens/worlds_screen.dart';

enum BaleTab { home, worlds, mission, circle, profile }

class BaleVerseDemoScreen extends StatefulWidget {
  const BaleVerseDemoScreen({
    this.skipDemoLogin = false,
    this.authController,
    super.key,
  });

  final bool skipDemoLogin;
  final AuthController? authController;

  @override
  State<BaleVerseDemoScreen> createState() => _BaleVerseDemoScreenState();
}

class _BaleVerseDemoScreenState extends State<BaleVerseDemoScreen> {
  final BaleVerseProgressService _progressService = BaleVerseProgressService();
  final MissionEngine _missionEngine = const MissionEngine();
  late machine.BaleVerseState _state;
  BaleTab _tab = BaleTab.home;
  String? _selectedOptionId;
  String? _feedback;
  bool _mistakeMarked = false;
  String _teachBackText = '';
  final Set<String> _mentorShare = {
    ...humanHelpRecommendation.shareableContext,
  };

  BaleVerseProgress get _progress => _progressService.snapshot;

  @override
  void initState() {
    super.initState();
    _state = widget.skipDemoLogin
        ? const machine.BaleVerseState(step: MissionStep.dashboard)
        : const machine.BaleVerseState();
    _progressService.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    _progressService.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  BaleWorld get _selectedWorld {
    return baleWorlds.firstWhere((world) => world.key == _state.selectedWorld);
  }

  void _update(machine.BaleVerseState next) {
    setState(() => _state = next);
  }

  void _goToTab(BaleTab tab) {
    setState(() => _tab = tab);
  }

  void _startMission() {
    setState(() {
      _tab = BaleTab.mission;
      _state = machine.startMission(_state);
    });
  }

  void _checkAnswer() {
    final evaluation = _missionEngine.evaluate(
      state: _state,
      selectedOptionId: _selectedOptionId,
      mistakeMarked: _mistakeMarked,
      teachBackText: _teachBackText,
    );
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
        selectedIndex: _tab.index,
        onDestinationSelected: (index) => _goToTab(BaleTab.values[index]),
        indicatorColor: BaleColors.success.withValues(alpha: 0.16),
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
            icon: Icon(Icons.groups_rounded),
            label: 'Lingkar',
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
    if (_tab == BaleTab.home) {
      return DashboardScreen(
        key: const ValueKey('dashboard'),
        progress: _progress,
        selectedWorld: _selectedWorld,
        onStartMission: _startMission,
      );
    }

    if (_tab == BaleTab.worlds) {
      return WorldsScreen(
        key: const ValueKey('worlds'),
        selectedWorld: _selectedWorld,
        onSelectWorld: (world) {
          _update(machine.selectWorld(_state, world));
        },
      );
    }

    if (_tab == BaleTab.circle) {
      return LearningCircleScreen(
        key: const ValueKey('circle'),
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
      );
    }

    if (_tab == BaleTab.profile && widget.authController != null) {
      return ProfileScreen(
        key: const ValueKey('profile'),
        controller: widget.authController!,
      );
    }

    return switch (_state.step) {
      MissionStep.missionIntro => MissionIntroScreen(
          key: const ValueKey('missionIntro'),
          onStart: () => _update(machine.beginQuestion(_state)),
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
              _tab = BaleTab.circle;
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
