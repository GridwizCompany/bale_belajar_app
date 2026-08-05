import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/audio/audio_scope.dart';
import '../../../core/audio/audio_types.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../shared/widgets/bale_card.dart';
import '../../../shared/widgets/belo_mascot.dart';
import '../../../theme/bale_theme.dart';
import '../../baleverse/presentation/baleverse_demo_screen.dart';
import '../../test_templates/domain/test_template_models.dart';
import '../../test_templates/presentation/templates/test_templates.dart';
import '../application/auth_controller.dart';
import 'analisis_hasil_page.dart';
import 'auth_account_page.dart';
import 'onboarding_questions/daily_duration_question.dart';
import 'onboarding_questions/grade_question.dart';
import 'onboarding_questions/learning_format_question.dart';
import 'onboarding_questions/learning_goal_question.dart';
import 'onboarding_questions/learning_world_question.dart';
import 'onboarding_questions/onboarding_question_models.dart';
import 'onboarding_questions/self_reported_level_question.dart';
import 'onboarding_questions/study_time_question.dart';

const _authPrimary = Color(0xFFF4B400);
const _authDark = Color(0xFF0E3A5F);

bool _compactPhoneLayout(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.shortestSide < 600 && size.height < 980;
}

enum AuthMode {
  welcome,
  register,
  world,
  grade,
  level,
  format,
  duration,
  studyTime,
  recommendation,
  placement,
  analysis,
  account,
  login,
  code,
}

class SimpleAuthScreen extends StatefulWidget {
  const SimpleAuthScreen({
    required this.controller,
    this.initialMode = AuthMode.welcome,
    this.onBackToLanding,
    this.onLoginRequested,
    this.onAuthenticatedFlowLockChanged,
    super.key,
  });

  final AuthController controller;
  final AuthMode initialMode;
  final VoidCallback? onBackToLanding;
  final VoidCallback? onLoginRequested;
  final ValueChanged<bool>? onAuthenticatedFlowLockChanged;

  @override
  State<SimpleAuthScreen> createState() => _SimpleAuthScreenState();
}

class _SimpleAuthScreenState extends State<SimpleAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  AuthMode _mode = AuthMode.welcome;
  int _grade = 10;
  bool _showPassword = false;
  bool _googleBusy = false;
  int _flowStep = 1;
  LearningGoal? _learningGoal;
  LearningWorld? _learningWorld;
  GradeChoice? _gradeChoice;
  SelfReportedLevel? _selfReportedLevel;
  final Set<LearningFormat> _learningFormats = {};
  DailyDuration? _dailyDuration;
  StudyTime? _studyTime;
  int _placementQuestionIndex = 0;
  String? _prototypeStudentProfileId;
  String? _prototypePlacementAttemptId;
  List<TemplateQuestion>? _backendPlacementQuestions;
  // Kalau backend gagal, tampilkan error/retry - JANGAN diam-diam pakai
  // soal dummy (lihat _PlacementTestFlow.build()).
  bool _placementLoadFailed = false;
  bool _continuePlacementAfterAuth = false;

  bool get _prototypeFallbackAllowed =>
      !kReleaseMode && widget.controller.user == null;

  @override
  void initState() {
    super.initState();
    _resetToInitialMode();
  }

  @override
  void didUpdateWidget(covariant SimpleAuthScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.initialMode != widget.initialMode) {
      _resetToInitialMode();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (mounted) {
      setState(_resetToInitialMode);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  void _resetToInitialMode() {
    _mode = widget.initialMode == AuthMode.login
        ? AuthMode.welcome
        : widget.initialMode;
    _flowStep = widget.initialMode == AuthMode.world
        ? 2
        : widget.initialMode == AuthMode.grade
            ? 3
            : widget.initialMode == AuthMode.level
                ? 4
                : widget.initialMode == AuthMode.format
                    ? 5
                    : widget.initialMode == AuthMode.duration
                        ? 6
                        : 1;
    _googleBusy = false;
    _showPassword = false;
    _prototypePlacementAttemptId = null;
    if (widget.initialMode == AuthMode.register &&
        widget.controller.user == null) {
      unawaited(_ensurePrototypeSession());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == AuthMode.analysis) {
      return AnalisisHasilPage(
        onBack: () {
          setState(() {
            _mode = AuthMode.placement;
            _placementQuestionIndex =
                ((_backendPlacementQuestions?.length ?? 13) - 1).clamp(0, 999);
          });
          _syncAuthAudio(AuthMode.placement);
        },
        onContinue: _goToBaleVerseHome,
      );
    }

    if (_mode == AuthMode.account ||
        _mode == AuthMode.login ||
        _mode == AuthMode.code) {
      return AuthAccountPage(
        key: ValueKey('auth-account-${_mode.name}'),
        controller: widget.controller,
        initialMode: switch (_mode) {
          AuthMode.account => AuthAccountMode.register,
          AuthMode.code => AuthAccountMode.code,
          _ => AuthAccountMode.login,
        },
        initialName: _name.text,
        initialGrade: _normalizedGrade,
        keepFlowAfterAuth: _continuePlacementAfterAuth,
        onAuthFlowLockChanged: widget.onAuthenticatedFlowLockChanged,
        onBack: () {
          if (_continuePlacementAfterAuth) {
            setState(() {
              _continuePlacementAfterAuth = false;
              _mode = AuthMode.studyTime;
              _flowStep = 7;
            });
            _syncAuthAudio(AuthMode.studyTime);
            return;
          }
          final onBackToLanding = widget.onBackToLanding;
          if (onBackToLanding != null) {
            onBackToLanding();
            return;
          }
          setState(() => _mode = AuthMode.welcome);
        },
        onAuthenticated: () async {
          if (_continuePlacementAfterAuth) {
            await _continueAuthenticatedPlacementFlow();
            return;
          }
          await _saveRealOnboardingAnswers();
          await widget.controller.initialize();
        },
      );
    }

    final compact = _compactPhoneLayout(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3C6),
      body: SafeArea(
        child: ColoredBox(
          color: const Color(0xFFFFF3C6),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 14 : 22,
                  compact ? 10 : 18,
                  compact ? 14 : 22,
                  compact ? 8 : 18,
                ),
                child: SizedBox.expand(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                        reverseCurve: Curves.easeInCubic,
                      );
                      return FadeTransition(
                        opacity: curved,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(curved),
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.98, end: 1)
                                .animate(curved),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _mode == AuthMode.welcome
                        ? _OnboardingView(
                            key: const ValueKey('onboarding'),
                            flowStep: _flowStep,
                            onRegister: () => _goTo(AuthMode.register),
                            onLogin: () => _goTo(AuthMode.login),
                          )
                        : _mode == AuthMode.login
                            ? _LoginWelcomeStep(
                                key: const ValueKey('login-welcome-step'),
                                controller: widget.controller,
                                googleBusy: _googleBusy,
                                showPassword: _showPassword,
                                emailController: _email,
                                passwordController: _password,
                                errorMessage: widget.controller.errorMessage,
                                onBack: widget.onBackToLanding ??
                                    () => _goTo(AuthMode.welcome),
                                onTogglePassword: () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                                onGoogle: _continueWithGoogle,
                                onSubmit: _submit,
                                onRegister: () => _goTo(AuthMode.register),
                              )
                            : _mode == AuthMode.register
                                ? _LearningGoalStep(
                                    key: const ValueKey('learning-goal-step'),
                                    selectedGoal: _learningGoal,
                                    onBack: widget.onBackToLanding ??
                                        () => _goTo(AuthMode.welcome),
                                    onSelected: (goal) {
                                      setState(() => _learningGoal = goal);
                                    },
                                    onContinue: _learningGoal == null
                                        ? null
                                        : () => _goTo(AuthMode.world),
                                    onSkip: () => _goTo(AuthMode.world),
                                  )
                                : _mode == AuthMode.world
                                    ? _LearningWorldStep(
                                        key: const ValueKey(
                                          'learning-world-step',
                                        ),
                                        selectedWorld: _learningWorld,
                                        onBack: () => _goTo(AuthMode.register),
                                        onSelected: (world) {
                                          setState(
                                              () => _learningWorld = world);
                                        },
                                        onContinue: _learningWorld == null
                                            ? null
                                            : () => _goTo(AuthMode.grade),
                                        onSkip: () => _goTo(AuthMode.grade),
                                      )
                                    : _mode == AuthMode.grade
                                        ? _GradeStep(
                                            key: const ValueKey('grade-step'),
                                            selectedGrade: _gradeChoice,
                                            onBack: () => _goTo(AuthMode.world),
                                            onSelected: (grade) {
                                              setState(() {
                                                _gradeChoice = grade;
                                                if (grade.gradeLevel != null) {
                                                  _grade = grade.gradeLevel!;
                                                }
                                              });
                                            },
                                            onContinue: _gradeChoice == null
                                                ? null
                                                : () => _goTo(AuthMode.level),
                                            onSkip: () => _goTo(AuthMode.level),
                                          )
                                        : _mode == AuthMode.level
                                            ? _SelfReportedLevelStep(
                                                key: const ValueKey(
                                                  'self-reported-level-step',
                                                ),
                                                selectedLevel:
                                                    _selfReportedLevel,
                                                onBack: () =>
                                                    _goTo(AuthMode.grade),
                                                onSelected: (level) {
                                                  setState(() =>
                                                      _selfReportedLevel =
                                                          level);
                                                },
                                                onContinue:
                                                    _selfReportedLevel == null
                                                        ? null
                                                        : () => _goTo(
                                                              AuthMode.format,
                                                            ),
                                                onSkip: () =>
                                                    _goTo(AuthMode.format),
                                              )
                                            : _mode == AuthMode.format
                                                ? _LearningFormatStep(
                                                    key: const ValueKey(
                                                      'learning-format-step',
                                                    ),
                                                    selectedFormats:
                                                        _learningFormats,
                                                    onBack: () =>
                                                        _goTo(AuthMode.level),
                                                    onToggle: _toggleFormat,
                                                    onContinue: _learningFormats
                                                            .isEmpty
                                                        ? null
                                                        : () => _goTo(
                                                              AuthMode.duration,
                                                            ),
                                                    onSkip: () => _goTo(
                                                        AuthMode.duration),
                                                  )
                                                : _mode == AuthMode.duration
                                                    ? _DailyDurationStep(
                                                        key: const ValueKey(
                                                          'daily-duration-step',
                                                        ),
                                                        selectedDuration:
                                                            _dailyDuration,
                                                        onBack: () => _goTo(
                                                          AuthMode.format,
                                                        ),
                                                        onSelected: (duration) {
                                                          setState(() {
                                                            _dailyDuration =
                                                                duration;
                                                          });
                                                        },
                                                        onContinue:
                                                            _dailyDuration ==
                                                                    null
                                                                ? null
                                                                : () => _goTo(
                                                                      AuthMode
                                                                          .studyTime,
                                                                    ),
                                                        onSkip: () => _goTo(
                                                          AuthMode.studyTime,
                                                        ),
                                                      )
                                                    : _mode ==
                                                            AuthMode.studyTime
                                                        ? _StudyTimeStep(
                                                            key: const ValueKey(
                                                              'study-time-step',
                                                            ),
                                                            selectedTime:
                                                                _studyTime,
                                                            onBack: () => _goTo(
                                                              AuthMode.duration,
                                                            ),
                                                            onSelected: (time) {
                                                              setState(() {
                                                                _studyTime =
                                                                    time;
                                                              });
                                                            },
                                                            onContinue:
                                                                _studyTime ==
                                                                        null
                                                                    ? null
                                                                    : _showRecommendation,
                                                            onSkip:
                                                                _showRecommendation,
                                                          )
                                                        : _mode ==
                                                                AuthMode
                                                                    .recommendation
                                                            ? _RecommendationSplash(
                                                                key:
                                                                    const ValueKey(
                                                                  'recommendation-splash',
                                                                ),
                                                                world:
                                                                    _learningWorld,
                                                                onPreviewAnalysis:
                                                                    _showAnalysis,
                                                              )
                                                            : _mode ==
                                                                    AuthMode
                                                                        .placement
                                                                ? _PlacementTestFlow(
                                                                    key:
                                                                        const ValueKey(
                                                                      'placement-test-flow',
                                                                    ),
                                                                    world:
                                                                        _learningWorld,
                                                                    questions:
                                                                        _backendPlacementQuestions,
                                                                    currentIndex:
                                                                        _placementQuestionIndex,
                                                                    onBack:
                                                                        _previousPlacementQuestion,
                                                                    onNext:
                                                                        _nextPlacementQuestion,
                                                                    onShowAnalysis:
                                                                        _showAnalysis,
                                                                    onQuestionCompleted:
                                                                        _completePrototypePlacementQuestion,
                                                                    loadFailed:
                                                                        _placementLoadFailed,
                                                                    onRetry: () =>
                                                                        unawaited(
                                                                            _ensurePrototypePlacementAttempt()),
                                                                  )
                                                                : _mode ==
                                                                        AuthMode
                                                                            .analysis
                                                                    ? AnalisisHasilPage(
                                                                        key:
                                                                            const ValueKey(
                                                                          'analysis-page',
                                                                        ),
                                                                        onBack:
                                                                            _previousPlacementQuestion,
                                                                        onContinue:
                                                                            _goToBaleVerseHome,
                                                                      )
                                                                    : _AuthStep(
                                                                        key:
                                                                            ValueKey(
                                                                          _mode,
                                                                        ),
                                                                        controller:
                                                                            widget.controller,
                                                                        flowStep:
                                                                            _flowStep,
                                                                        title:
                                                                            _title,
                                                                        helper:
                                                                            _helper,
                                                                        mascotPose:
                                                                            _mascotPose,
                                                                        onBack: widget
                                                                                .onBackToLanding ??
                                                                            () =>
                                                                                _goTo(
                                                                                  AuthMode.welcome,
                                                                                ),
                                                                        child:
                                                                            _form(),
                                                                      ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_mode != AuthMode.code) ...[
                _GoogleButton(
                  loading: _googleBusy,
                  disabled: widget.controller.isBusy,
                  onPressed: _continueWithGoogle,
                ),
                const SizedBox(height: 16),
                const _DividerLabel(label: 'atau'),
                const SizedBox(height: 16),
              ],
              if (_mode == AuthMode.account) ...[
                _Field(
                  controller: _name,
                  label: 'Nama lengkap',
                  icon: Icons.person_rounded,
                  validator: _required,
                ),
                const SizedBox(height: 12),
              ],
              if (_mode != AuthMode.code) ...[
                _Field(
                  controller: _email,
                  label: 'Email',
                  icon: Icons.mail_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _password,
                  label: 'Password',
                  icon: Icons.lock_rounded,
                  obscureText: !_showPassword,
                  validator: _passwordValidator,
                  suffixIcon: IconButton(
                    tooltip: _showPassword
                        ? 'Sembunyikan password'
                        : 'Lihat password',
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                  ),
                ),
              ],
              if (_mode == AuthMode.code)
                _Field(
                  controller: _code,
                  label: 'Kode peserta',
                  icon: Icons.badge_rounded,
                  textCapitalization: TextCapitalization.characters,
                  validator: _required,
                ),
              if (_mode == AuthMode.account) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _normalizedGrade,
                  decoration: const InputDecoration(
                    labelText: 'Kelas',
                    prefixIcon: Icon(Icons.school_rounded),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('Kelas 7')),
                    DropdownMenuItem(value: 8, child: Text('Kelas 8')),
                    DropdownMenuItem(value: 9, child: Text('Kelas 9')),
                    DropdownMenuItem(value: 10, child: Text('Kelas 10')),
                    DropdownMenuItem(value: 11, child: Text('Kelas 11')),
                    DropdownMenuItem(value: 12, child: Text('Kelas 12')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _grade = value);
                  },
                ),
              ],
              if (widget.controller.errorMessage != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: widget.controller.errorMessage!),
              ],
              const SizedBox(height: 18),
              _PrimaryAction(
                loading: widget.controller.isBusy,
                disabled: _googleBusy,
                icon: _buttonIcon,
                label: _buttonLabel,
                onPressed: _submit,
              ),
              const SizedBox(height: 10),
              _SecondaryAction(
                label: _switchLabel,
                onPressed: widget.controller.isBusy || _googleBusy
                    ? null
                    : () => _goTo(_switchTarget),
              ),
              if (_mode == AuthMode.login) ...[
                const SizedBox(height: 2),
                _SecondaryAction(
                  label: 'Masuk dengan kode siswa',
                  onPressed: widget.controller.isBusy || _googleBusy
                      ? null
                      : () => _goTo(AuthMode.code),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  BeloPose get _mascotPose => switch (_mode) {
        AuthMode.register => BeloPose.lompatKegirangan,
        AuthMode.world => BeloPose.lompatKegirangan,
        AuthMode.grade => BeloPose.lompatKegirangan,
        AuthMode.level => BeloPose.lompatKegirangan,
        AuthMode.format => BeloPose.lompatKegirangan,
        AuthMode.duration => BeloPose.lompatKegirangan,
        AuthMode.studyTime => BeloPose.lompatKegirangan,
        AuthMode.recommendation => BeloPose.lompatKegirangan,
        AuthMode.placement => BeloPose.lompatKegirangan,
        AuthMode.analysis => BeloPose.lompatKegirangan,
        AuthMode.account => BeloPose.lompatKegirangan,
        AuthMode.login => BeloPose.kedip,
        AuthMode.code => BeloPose.jempolOke,
        AuthMode.welcome => BeloPose.jatuhCinta,
      };

  int get _normalizedGrade {
    if (_grade >= 7 && _grade <= 12) return _grade;
    final selectedGrade = _gradeChoice?.gradeLevel;
    if (selectedGrade != null && selectedGrade >= 7 && selectedGrade <= 12) {
      return selectedGrade;
    }
    return 10;
  }

  String get _title => switch (_mode) {
        AuthMode.welcome => 'BaleBelajar',
        AuthMode.register => learningGoalQuestion.title,
        AuthMode.world => learningWorldQuestion.title,
        AuthMode.grade => gradeQuestion.title,
        AuthMode.level => selfReportedLevelQuestion.title,
        AuthMode.format => learningFormatQuestion.title,
        AuthMode.duration => dailyDurationQuestion.title,
        AuthMode.studyTime => studyTimeQuestion.title,
        AuthMode.recommendation => 'Menyiapkan rekomendasi',
        AuthMode.placement => 'Cek Awal',
        AuthMode.analysis => 'Analisis',
        AuthMode.account => 'Simpan progresmu',
        AuthMode.login => 'Masuk lagi',
        AuthMode.code => 'Pakai kode siswa',
      };

  String get _helper => switch (_mode) {
        AuthMode.welcome => '',
        AuthMode.register => 'Pilih tujuan yang paling cocok.',
        AuthMode.world => 'Pilih satu dunia untuk mulai.',
        AuthMode.grade => 'Ini hanya untuk memilih materi awal.',
        AuthMode.level => 'Ini bukan ujian, hanya titik awal.',
        AuthMode.format => 'Pilih sampai tiga cara belajar.',
        AuthMode.duration => 'Pilih target yang realistis.',
        AuthMode.studyTime => 'Pilih waktu yang cocok.',
        AuthMode.recommendation => 'Sebentar, Bale sedang menyiapkan jalurmu.',
        AuthMode.placement => 'Mulai dari tes singkat sesuai dunia pilihanmu.',
        AuthMode.analysis => 'Kami sedang menganalisis jawabanmu.',
        AuthMode.account =>
          'Masuk dulu supaya hasil cek awal tersimpan ke akunmu.',
        AuthMode.login => 'Lanjutkan progres belajar yang sudah tersimpan.',
        AuthMode.code => 'Masukkan kode dari sekolah atau mentor.',
      };

  String get _switchLabel => switch (_mode) {
        AuthMode.register => 'Sudah punya akun? Masuk',
        AuthMode.world => 'Sudah punya akun? Masuk',
        AuthMode.grade => 'Sudah punya akun? Masuk',
        AuthMode.level => 'Sudah punya akun? Masuk',
        AuthMode.format => 'Sudah punya akun? Masuk',
        AuthMode.duration => 'Sudah punya akun? Masuk',
        AuthMode.studyTime => 'Sudah punya akun? Masuk',
        AuthMode.recommendation => '',
        AuthMode.placement => 'Sudah punya akun? Masuk',
        AuthMode.analysis => '',
        AuthMode.account => 'Sudah punya akun? Masuk',
        AuthMode.login => 'Belum punya akun? Mulai belajar',
        AuthMode.code => 'Masuk pakai email',
        AuthMode.welcome => '',
      };

  AuthMode get _switchTarget => switch (_mode) {
        AuthMode.register => AuthMode.login,
        AuthMode.world => AuthMode.login,
        AuthMode.grade => AuthMode.login,
        AuthMode.level => AuthMode.login,
        AuthMode.format => AuthMode.login,
        AuthMode.duration => AuthMode.login,
        AuthMode.studyTime => AuthMode.login,
        AuthMode.recommendation => AuthMode.login,
        AuthMode.placement => AuthMode.login,
        AuthMode.analysis => AuthMode.login,
        AuthMode.account => AuthMode.login,
        AuthMode.login => AuthMode.register,
        AuthMode.code => AuthMode.login,
        AuthMode.welcome => AuthMode.register,
      };

  IconData get _buttonIcon => switch (_mode) {
        AuthMode.register => Icons.arrow_forward_rounded,
        AuthMode.world => Icons.arrow_forward_rounded,
        AuthMode.grade => Icons.arrow_forward_rounded,
        AuthMode.level => Icons.arrow_forward_rounded,
        AuthMode.format => Icons.arrow_forward_rounded,
        AuthMode.duration => Icons.arrow_forward_rounded,
        AuthMode.studyTime => Icons.arrow_forward_rounded,
        AuthMode.recommendation => Icons.auto_awesome_rounded,
        AuthMode.placement => Icons.quiz_rounded,
        AuthMode.analysis => Icons.auto_graph_rounded,
        AuthMode.account => Icons.person_add_alt_1_rounded,
        AuthMode.login => Icons.login_rounded,
        AuthMode.code => Icons.qr_code_2_rounded,
        AuthMode.welcome => Icons.play_arrow_rounded,
      };

  String get _buttonLabel => switch (_mode) {
        AuthMode.register => 'Lanjutkan',
        AuthMode.world => 'Lanjutkan',
        AuthMode.grade => 'Lanjutkan',
        AuthMode.level => 'Lanjutkan',
        AuthMode.format => 'Lanjutkan',
        AuthMode.duration => 'Lanjutkan',
        AuthMode.studyTime => 'Lihat rekomendasiku',
        AuthMode.recommendation => 'Menyiapkan',
        AuthMode.placement => 'Mulai Cek Awal',
        AuthMode.analysis => 'Menganalisis',
        AuthMode.account => 'Buat Akun dan Lanjut Tes',
        AuthMode.login => 'Masuk',
        AuthMode.code => 'Masuk dengan Kode',
        AuthMode.welcome => 'Mulai',
      };

  void _goTo(AuthMode mode) {
    if (mode == AuthMode.login &&
        widget.onLoginRequested != null &&
        _mode == AuthMode.welcome) {
      widget.onLoginRequested!();
      return;
    }
    if (mode == AuthMode.register) {
      if (widget.controller.user == null) {
        unawaited(_ensurePrototypeSession());
      }
    }
    if (mode == AuthMode.placement && widget.controller.user == null) {
      _continuePlacementAfterAuth = true;
      mode = AuthMode.account;
    }
    setState(() {
      _mode = mode;
      _flowStep = switch (mode) {
        AuthMode.welcome => 1,
        AuthMode.register => 1,
        AuthMode.world => 2,
        AuthMode.grade => 3,
        AuthMode.level => 4,
        AuthMode.format => 5,
        AuthMode.duration => 6,
        AuthMode.studyTime ||
        AuthMode.recommendation ||
        AuthMode.placement ||
        AuthMode.analysis =>
          7,
        AuthMode.account || AuthMode.login || AuthMode.code => 7,
      };
      if (mode == AuthMode.placement) {
        _placementQuestionIndex = 0;
        _prototypePlacementAttemptId = null;
        _backendPlacementQuestions = null;
        _placementLoadFailed = false;
      }
    });
    _syncAuthAudio(mode);
  }

  void _showRecommendation() {
    unawaited(_completePrototypeOnboarding());
    setState(() {
      _mode = AuthMode.recommendation;
      _flowStep = 7;
    });
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted && _mode == AuthMode.recommendation) {
        if (widget.controller.user == null) {
          _continuePlacementAfterAuth = true;
          setState(() {
            _mode = AuthMode.account;
            _flowStep = 7;
          });
          _syncAuthAudio(AuthMode.account);
          return;
        }
        _startPlacement();
      }
    });
  }

  void _startPlacement() {
    setState(() {
      _mode = AuthMode.placement;
      _flowStep = 7;
      _placementQuestionIndex = 0;
      _prototypePlacementAttemptId = null;
      _backendPlacementQuestions = null;
      _placementLoadFailed = false;
    });
    unawaited(_ensurePrototypePlacementAttempt());
    _syncAuthAudio(AuthMode.placement);
  }

  void _nextPlacementQuestion() {
    final audio = AudioScope.maybeOf(context);
    final lastIndex = (_backendPlacementQuestions?.length ?? 13) - 1;
    if (_placementQuestionIndex >= lastIndex) {
      audio?.playSound(SoundEffectId.pageTransition);
      _showAnalysis();
      return;
    }
    audio?.playSound(SoundEffectId.pageTransition);
    setState(() => _placementQuestionIndex += 1);
  }

  void _showAnalysis() {
    unawaited(_submitPlacementAttempt());
    setState(() {
      _mode = AuthMode.analysis;
      _flowStep = 7;
    });
    _syncAuthAudio(AuthMode.analysis);
  }

  Future<void> _ensurePrototypeSession() async {
    if (!_prototypeFallbackAllowed) return;
    if (_prototypeStudentProfileId != null) return;
    try {
      _prototypeStudentProfileId =
          await widget.controller.authService.startPrototypeSession();
    } catch (_) {
      // Prototype UI tetap bisa dipakai ketika backend belum aktif.
    }
  }

  Future<void> _completePrototypeOnboarding() async {
    if (widget.controller.user != null) {
      await _saveRealOnboardingAnswers();
      return;
    }
    if (!_prototypeFallbackAllowed) return;
    await _ensurePrototypeSession();
    final studentProfileId = _prototypeStudentProfileId;
    if (studentProfileId == null) return;
    try {
      await widget.controller.authService.savePrototypeOnboarding(
        studentProfileId: studentProfileId,
        complete: true,
        answers: _onboardingPayload(),
      );
    } catch (_) {}
  }

  Future<void> _ensurePrototypePlacementAttempt() async {
    if (_prototypePlacementAttemptId != null) return;
    if (mounted) setState(() => _placementLoadFailed = false);
    if (widget.controller.user != null) {
      try {
        _prototypePlacementAttemptId =
            await widget.controller.authService.startPlacement(
          worldKey: _learningWorldPayload(_learningWorld),
        );
        final questionJson =
            await widget.controller.authService.getPlacementQuestions();
        if (!mounted) return;
        setState(() {
          _backendPlacementQuestions = questionJson
              .map(_templateQuestionFromJson)
              .toList(growable: false);
        });
      } catch (_) {
        if (mounted) setState(() => _placementLoadFailed = true);
      }
      return;
    }
    if (!_prototypeFallbackAllowed) {
      if (mounted) setState(() => _placementLoadFailed = true);
      return;
    }
    await _ensurePrototypeSession();
    final studentProfileId = _prototypeStudentProfileId;
    if (studentProfileId == null) {
      if (mounted) setState(() => _placementLoadFailed = true);
      return;
    }
    try {
      _prototypePlacementAttemptId =
          await widget.controller.authService.startPrototypePlacement(
        studentProfileId: studentProfileId,
        worldKey: _learningWorldPayload(_learningWorld),
      );
      final questionJson =
          await widget.controller.authService.getPrototypePlacementQuestions(
        studentProfileId: studentProfileId,
      );
      if (!mounted) return;
      setState(() {
        _backendPlacementQuestions =
            questionJson.map(_templateQuestionFromJson).toList(growable: false);
      });
    } catch (_) {
      if (mounted) setState(() => _placementLoadFailed = true);
    }
  }

  Future<void> _savePrototypePlacementAnswer(
    TemplateQuestion question,
    Object? answer, {
    required bool skipped,
  }) async {
    await _ensurePrototypePlacementAttempt();
    final attemptId = _prototypePlacementAttemptId;
    if (attemptId == null) return;
    try {
      if (skipped) {
        if (widget.controller.user != null) {
          await widget.controller.authService.skipPlacementAnswer(
            attemptId: attemptId,
            questionId: question.id,
            questionType: question.questionType.payload,
          );
          return;
        }
        if (!_prototypeFallbackAllowed) return;
        await widget.controller.authService.skipPrototypePlacementAnswer(
          attemptId: attemptId,
          questionId: question.id,
          questionType: question.questionType.payload,
        );
        return;
      }
      if (widget.controller.user != null) {
        await widget.controller.authService.savePlacementAnswer(
          attemptId: attemptId,
          questionId: question.id,
          questionType: question.questionType.payload,
          answer: {'value': answer?.toString()},
        );
        return;
      }
      if (!_prototypeFallbackAllowed) return;
      await widget.controller.authService.savePrototypePlacementAnswer(
        attemptId: attemptId,
        questionId: question.id,
        questionType: question.questionType.payload,
        answer: {'value': answer?.toString()},
      );
    } catch (_) {}
  }

  void _completePrototypePlacementQuestion(
    TemplateQuestion question,
    Object? answer, {
    required bool skipped,
  }) {
    unawaited(
        _savePrototypePlacementAnswer(question, answer, skipped: skipped));
  }

  Future<void> _submitPlacementAttempt() async {
    await _ensurePrototypePlacementAttempt();
    final attemptId = _prototypePlacementAttemptId;
    if (attemptId == null) return;
    try {
      if (widget.controller.user != null) {
        await widget.controller.authService.submitPlacement(attemptId);
        return;
      }
      if (!_prototypeFallbackAllowed) return;
      await widget.controller.authService.submitPrototypePlacement(attemptId);
    } catch (_) {}
  }

  Future<void> _saveRealOnboardingAnswers() async {
    final answers = _onboardingPayload();
    try {
      await widget.controller.authService.saveOnboardingAnswers(answers);
      await widget.controller.authService.finishOnboarding(answers);
    } catch (_) {
      // Best-effort - lihat komentar di titik pemanggilan (_submit()).
    }
  }

  Map<String, dynamic> _onboardingPayload() {
    return {
      'learningGoal': _learningGoal?.name,
      'learningWorld': _learningWorldPayload(_learningWorld),
      'gradeChoice': _gradeChoice?.name,
      'selfReportedLevel': _selfReportedLevel?.name,
      'learningFormats': _learningFormats.map((format) => format.name).toList(),
      'dailyDuration': _dailyDuration?.name,
      'studyTime': _studyTime?.name,
      'rawAnswers': {
        'learningGoal': _learningGoal?.name,
        'learningWorld': _learningWorld?.name,
        'gradeChoice': _gradeChoice?.name,
        'selfReportedLevel': _selfReportedLevel?.name,
        'learningFormats':
            _learningFormats.map((format) => format.name).toList(),
        'dailyDuration': _dailyDuration?.name,
        'studyTime': _studyTime?.name,
      },
    };
  }

  void _goToBaleVerseHome() {
    AudioScope.maybeOf(context)?.playSound(SoundEffectId.audioLogo);
    widget.onAuthenticatedFlowLockChanged?.call(false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BaleVerseDemoScreen(
          skipDemoLogin: true,
          authController: widget.controller,
          prototypeStudentProfileId: _prototypeStudentProfileId,
        ),
      ),
    );
  }

  void _previousPlacementQuestion() {
    if (_placementQuestionIndex == 0) {
      _goTo(AuthMode.studyTime);
      return;
    }
    AudioScope.maybeOf(context)?.playSound(SoundEffectId.pageTransition);
    setState(() => _placementQuestionIndex -= 1);
  }

  void _syncAuthAudio(AuthMode mode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final audio = AudioScope.maybeOf(context);
      if (audio == null) return;
      if (mode == AuthMode.placement || mode == AuthMode.analysis) {
        audio.playMusic(BackgroundMusicId.learning);
      } else {
        audio.stopMusic();
      }
    });
  }

  void _toggleFormat(LearningFormat format) {
    setState(() {
      if (_learningFormats.contains(format)) {
        _learningFormats.remove(format);
      } else if (_learningFormats.length < 3) {
        _learningFormats.add(format);
      }
    });
  }

  Future<void> _continueWithGoogle() async {
    if (!FirebaseBootstrap.isConfigured) {
      widget.controller.setError(
        'Login Google belum aktif. Lengkapi konfigurasi Firebase dulu.',
      );
      return;
    }

    final shouldContinuePlacement = _shouldContinuePlacementAfterAuth;
    if (shouldContinuePlacement) {
      widget.onAuthenticatedFlowLockChanged?.call(true);
    }
    setState(() => _googleBusy = true);
    try {
      final provider = GoogleAuthProvider();
      final credential = kIsWeb
          ? await FirebaseAuth.instance.signInWithPopup(provider)
          : await FirebaseAuth.instance.signInWithProvider(provider);
      final idToken = await credential.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        widget.controller.setError('Token Google tidak diterima. Coba lagi.');
        return;
      }
      await widget.controller.loginWithGoogleToken(idToken);
      if (_shouldContinuePlacementAfterAuth) {
        await _continueAuthenticatedPlacementFlow();
      }
    } on FirebaseAuthException catch (error) {
      widget.controller.setError(_googleError(error));
    } catch (_) {
      widget.controller.setError('Login Google gagal. Coba lagi.');
    } finally {
      if (shouldContinuePlacement && widget.controller.errorMessage != null) {
        widget.onAuthenticatedFlowLockChanged?.call(false);
      }
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Future<void> _submit() async {
    if (_mode == AuthMode.login) {
      if (_emailValidator(_email.text) != null ||
          _passwordValidator(_password.text) != null) {
        widget.controller.setError('Isi email dan password dengan benar.');
        return;
      }
    } else if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    final shouldContinuePlacement = _shouldContinuePlacementAfterAuth;
    if (shouldContinuePlacement) {
      widget.onAuthenticatedFlowLockChanged?.call(true);
    }
    if (_mode == AuthMode.login) {
      await widget.controller.loginWithEmail(_email.text, _password.text);
    } else if (_mode == AuthMode.account) {
      await widget.controller.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        gradeLevel: _normalizedGrade,
      );
      // Akun berhasil dibuat (baru punya JWT sekarang) - kirim jawaban
      // 7 pertanyaan onboarding yang sudah terkumpul selama flow ini ke
      // backend REAL yang authenticated, bukan cuma modul prototype.
      // Best-effort: kegagalan di sini tidak boleh memblokir alur signup,
      // OnboardingScreen (real, lewat AuthGate) tetap akan muncul.
      if (widget.controller.errorMessage == null && !shouldContinuePlacement) {
        await _saveRealOnboardingAnswers();
        await widget.controller.initialize();
      }
    } else if (_mode == AuthMode.code) {
      await widget.controller.loginWithCode(_code.text);
    }
    if (shouldContinuePlacement) {
      await _continueAuthenticatedPlacementFlow();
    }
  }

  bool get _shouldContinuePlacementAfterAuth =>
      _continuePlacementAfterAuth &&
      (_mode == AuthMode.account ||
          _mode == AuthMode.login ||
          _mode == AuthMode.code);

  Future<void> _continueAuthenticatedPlacementFlow() async {
    if (widget.controller.errorMessage != null ||
        widget.controller.user == null ||
        !mounted) {
      widget.onAuthenticatedFlowLockChanged?.call(false);
      return;
    }
    await _saveRealOnboardingAnswers();
    await widget.controller.initialize();
    if (!mounted) return;
    _continuePlacementAfterAuth = false;
    _startPlacement();
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Wajib diisi.' : null;
  }

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email wajib diisi.';
    if (!text.contains('@')) return 'Format email belum benar.';
    return null;
  }

  String? _passwordValidator(String? value) {
    final text = value ?? '';
    if (text.length < 8) return 'Minimal 8 karakter.';
    return null;
  }

  String _googleError(FirebaseAuthException error) {
    return switch (error.code) {
      'popup-closed-by-user' => 'Jendela Google ditutup sebelum selesai.',
      'popup-blocked' => 'Browser memblokir pop-up Google.',
      'unauthorized-domain' => 'Domain ini belum diizinkan di Firebase.',
      'network-request-failed' => 'Koneksi internet bermasalah.',
      'invalid-api-key' => 'Konfigurasi Firebase belum benar.',
      _ => 'Login Google gagal (${error.code}). Coba lagi.',
    };
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView({
    required this.flowStep,
    required this.onRegister,
    required this.onLogin,
    super.key,
  });

  final int flowStep;
  final VoidCallback onRegister;
  final VoidCallback onLogin;

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _brandOffset;
  late final Animation<Offset> _buttonsOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _brandOffset = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _buttonsOffset = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const Spacer(flex: 3),
            FadeTransition(
              opacity: _fade,
              child: const _WelcomeMascot(size: 230),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _brandOffset,
                child: Column(
                  children: [
                    Text(
                      'BaleBelajar',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: _authDark,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Belajar lebih ringan, seru, dan terarah.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF7A8796),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 4),
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _buttonsOffset,
                child: Column(
                  children: [
                    _PrimaryAction(
                      label: 'GET STARTED',
                      onPressed: widget.onRegister,
                    ),
                    const SizedBox(height: 12),
                    _OutlineAction(
                      label: 'I ALREADY HAVE AN ACCOUNT',
                      onPressed: widget.onLogin,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ],
    );
  }
}

String? _learningWorldPayload(LearningWorld? world) => switch (world) {
      LearningWorld.numeria => 'NUMERIA',
      LearningWorld.kodex => 'KODEX',
      LearningWorld.detectivia => 'DETECTIVIA',
      LearningWorld.bahasa => 'BAHASA',
      LearningWorld.sains => 'SAINS',
      LearningWorld.tryAll => 'TRY_ALL',
      null => null,
    };

TemplateQuestion _templateQuestionFromJson(Map<String, dynamic> json) {
  final questionType = QuestionType.values.firstWhere(
    (type) => type.payload == json['questionType'],
    orElse: () => QuestionType.singleChoice,
  );
  return TemplateQuestion(
    id: json['id'] as String,
    questionType: questionType,
    prompt: json['prompt'] as String,
    instruction: json['instruction'] as String?,
    options: _jsonList(json['options']).map((item) {
      return TemplateOption(
        id: item['id'] as String,
        label: item['label'] as String,
        imageUrl: item['imageUrl'] as String?,
        description: item['description'] as String?,
      );
    }).toList(growable: false),
    media: json['media'] is Map<String, dynamic>
        ? _templateMediaFromJson(json['media'] as Map<String, dynamic>)
        : null,
    responseConfig: json['responseConfig'] is Map<String, dynamic>
        ? _responseConfigFromJson(
            json['responseConfig'] as Map<String, dynamic>)
        : null,
    matchingPairs: _jsonList(json['matchingPairs']).map((item) {
      return MatchingPair(
        leftId: item['leftId'] as String,
        leftLabel: item['leftLabel'] as String,
        rightId: item['rightId'] as String,
        rightLabel: item['rightLabel'] as String,
      );
    }).toList(growable: false),
    orderingItems: _jsonList(json['orderingItems']).map((item) {
      return OrderingItem(
        id: item['id'] as String,
        label: item['label'] as String,
      );
    }).toList(growable: false),
    hotspotAreas: _jsonList(json['hotspotAreas']).map((item) {
      return HotspotArea(
        id: item['id'] as String,
        label: item['label'] as String,
        x: (item['x'] as num).toDouble(),
        y: (item['y'] as num).toDouble(),
        radius: ((item['radius'] as num?) ?? 0.08).toDouble(),
      );
    }).toList(growable: false),
    timelineItems: _jsonList(json['timelineItems']).map((item) {
      return TimelineItem(
        id: item['id'] as String,
        label: item['label'] as String,
        timeLabel: item['timeLabel'] as String?,
        description: item['description'] as String?,
      );
    }).toList(growable: false),
    evidenceItems: _jsonList(json['evidenceItems']).map((item) {
      return EvidenceItem(
        id: item['id'] as String,
        label: item['label'] as String,
        description: item['description'] as String?,
        category: item['category'] as String?,
      );
    }).toList(growable: false),
    codeConfig: json['codeConfig'] is Map<String, dynamic>
        ? _codeConfigFromJson(json['codeConfig'] as Map<String, dynamic>)
        : null,
  );
}

TemplateMedia _templateMediaFromJson(Map<String, dynamic> json) {
  return TemplateMedia(
    type: json['type'] as String,
    url: json['url'] as String,
    durationSeconds: json['durationSeconds'] as int?,
    maxReplay: json['maxReplay'] as int?,
    transcriptAvailable: json['transcriptAvailable'] as bool? ?? false,
    transcript: json['transcript'] as String?,
  );
}

ResponseConfig _responseConfigFromJson(Map<String, dynamic> json) {
  final mode = TextInputMode.values.firstWhere(
    (mode) => mode.name == json['inputMode'],
    orElse: () => TextInputMode.text,
  );
  return ResponseConfig(
    inputMode: mode,
    maxLength: json['maxLength'] as int? ?? 200,
    caseSensitive: json['caseSensitive'] as bool? ?? false,
    allowEmpty: json['allowEmpty'] as bool? ?? false,
    allowUnit: json['allowUnit'] as bool? ?? false,
  );
}

CodeConfig _codeConfigFromJson(Map<String, dynamic> json) {
  return CodeConfig(
    language: json['language'] as String,
    initialCode: json['initialCode'] as String? ?? '',
    readOnlyPrefix: json['readOnlyPrefix'] as String?,
    expectedOutput: json['expectedOutput'] as String?,
    backendExecutionEnabled: json['backendExecutionEnabled'] as bool? ?? false,
  );
}

List<Map<String, dynamic>> _jsonList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}

class _MascotStage extends StatelessWidget {
  const _MascotStage({
    required this.pose,
    required this.size,
    this.compact = false,
  });

  final BeloPose pose;
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + (compact ? 28 : 62),
      height: size * 1.36,
      child: Center(child: BeloMascot(pose: pose, size: size, animate: false)),
    );
  }
}

class _LearningGoalStep extends StatelessWidget {
  const _LearningGoalStep({
    required this.selectedGoal,
    required this.onBack,
    required this.onSelected,
    required this.onContinue,
    required this.onSkip,
    super.key,
  });

  final LearningGoal? selectedGoal;
  final VoidCallback onBack;
  final ValueChanged<LearningGoal> onSelected;
  final VoidCallback? onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final compact = _compactPhoneLayout(context);
    final options = learningGoalQuestion.options;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            _CircleBackButton(onPressed: onBack),
            const Spacer(),
            const Text(
              'Langkah 1 dari 7',
              style: TextStyle(
                color: _authDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 10 : 18),
        const _SevenStepProgress(currentStep: 1),
        SizedBox(height: compact ? 12 : 20),
        _IntroMascotBubble(compact: compact),
        SizedBox(height: compact ? 8 : 22),
        Text(
          'Tujuan belajarmu?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF3B2318),
                fontSize: compact ? 23 : 30,
                fontWeight: FontWeight.w900,
              ),
        ),
        SizedBox(height: compact ? 4 : 8),
        Text(
          'Pilih satu. Bisa diubah nanti.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF747985),
            fontSize: compact ? 13 : 16,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final cardWidth = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final option in options)
                  SizedBox(
                    width: cardWidth,
                    child: _LearningGoalCard(
                      option: option,
                      selected: selectedGoal == option.value,
                      compact: compact,
                      onTap: () => onSelected(option.value),
                    ),
                  ),
              ],
            );
          },
        ),
        SizedBox(height: compact ? 8 : 12),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(compact ? 46 : 54),
            backgroundColor: _authPrimary,
            foregroundColor: const Color(0xFF3B2318),
            textStyle: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w900,
            ),
            elevation: 6,
            shadowColor: const Color(0x66F4B400),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Lanjutkan'),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: compact ? 23 : 25),
            ],
          ),
        ),
        SizedBox(height: compact ? 0 : 4),
        TextButton(
          onPressed: onSkip,
          child: const Text(
            'Lewati dulu',
            style: TextStyle(
              color: Color(0xFF8B8179),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _LearningWorldStep extends StatelessWidget {
  const _LearningWorldStep({
    required this.selectedWorld,
    required this.onBack,
    required this.onSelected,
    required this.onContinue,
    required this.onSkip,
    super.key,
  });

  final LearningWorld? selectedWorld;
  final VoidCallback onBack;
  final ValueChanged<LearningWorld> onSelected;
  final VoidCallback? onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final compact = _compactPhoneLayout(context);
    final options = learningWorldQuestion.options;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            _CircleBackButton(onPressed: onBack),
            const Spacer(),
            const Text(
              'Langkah 2 dari 7',
              style: TextStyle(
                color: _authDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 10 : 18),
        const _SevenStepProgress(currentStep: 2),
        SizedBox(height: compact ? 12 : 20),
        _IntroMascotBubble(
          compact: compact,
          text:
              'Sekarang pilih dunia belajar yang paling menarik. Nanti aku siapkan misi pertamamu.',
        ),
        SizedBox(height: compact ? 8 : 22),
        Text(
          'Pilih dunia belajar',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF3B2318),
                fontSize: compact ? 23 : 30,
                fontWeight: FontWeight.w900,
              ),
        ),
        SizedBox(height: compact ? 4 : 8),
        Text(
          'Pilih satu dulu. Yang lain bisa dibuka nanti.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF747985),
            fontSize: compact ? 13 : 16,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final cardWidth = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final option in options)
                  SizedBox(
                    width: cardWidth,
                    child: _LearningWorldCard(
                      option: option,
                      selected: selectedWorld == option.value,
                      compact: compact,
                      onTap: () => onSelected(option.value),
                    ),
                  ),
              ],
            );
          },
        ),
        SizedBox(height: compact ? 8 : 12),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(compact ? 46 : 54),
            backgroundColor: _authPrimary,
            foregroundColor: const Color(0xFF3B2318),
            textStyle: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w900,
            ),
            elevation: 6,
            shadowColor: const Color(0x66F4B400),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Lanjutkan'),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: compact ? 23 : 25),
            ],
          ),
        ),
        SizedBox(height: compact ? 0 : 4),
        TextButton(
          onPressed: onSkip,
          child: const Text(
            'Lewati dulu',
            style: TextStyle(
              color: Color(0xFF8B8179),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _GradeStep extends StatelessWidget {
  const _GradeStep({
    required this.selectedGrade,
    required this.onBack,
    required this.onSelected,
    required this.onContinue,
    required this.onSkip,
    super.key,
  });

  final GradeChoice? selectedGrade;
  final VoidCallback onBack;
  final ValueChanged<GradeChoice> onSelected;
  final VoidCallback? onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final compact = _compactPhoneLayout(context);
    const options = [
      GradeChoice.junior7,
      GradeChoice.senior10,
      GradeChoice.senior11,
      GradeChoice.senior12,
      GradeChoice.graduated,
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            _CircleBackButton(onPressed: onBack),
            const Spacer(),
            const Text(
              'Langkah 3 dari 7',
              style: TextStyle(
                color: _authDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 10 : 18),
        const _SevenStepProgress(currentStep: 3),
        SizedBox(height: compact ? 12 : 20),
        _IntroMascotBubble(
          compact: compact,
          text:
              'Sekarang pilih kelasmu dulu, ya. Ini bantu aku menyiapkan materi yang pas.',
        ),
        SizedBox(height: compact ? 8 : 22),
        Text(
          'Kamu kelas berapa?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF3B2318),
                fontSize: compact ? 23 : 30,
                fontWeight: FontWeight.w900,
              ),
        ),
        SizedBox(height: compact ? 4 : 8),
        Text(
          'Pilih yang sesuai sekarang. Level bisa berubah nanti.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF747985),
            fontSize: compact ? 13 : 16,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        for (final option in options) ...[
          _GradeCard(
            grade: option,
            selected: selectedGrade == option,
            compact: compact,
            onTap: () => onSelected(option),
          ),
          SizedBox(height: compact ? 10 : 11),
        ],
        SizedBox(height: compact ? 4 : 8),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(compact ? 46 : 54),
            backgroundColor: _authPrimary,
            foregroundColor: const Color(0xFF3B2318),
            textStyle: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w900,
            ),
            elevation: 6,
            shadowColor: const Color(0x66F4B400),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Lanjutkan'),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: compact ? 23 : 25),
            ],
          ),
        ),
        SizedBox(height: compact ? 0 : 4),
        TextButton(
          onPressed: onSkip,
          child: const Text(
            'Lewati dulu',
            style: TextStyle(
              color: Color(0xFF8B8179),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelfReportedLevelStep extends StatelessWidget {
  const _SelfReportedLevelStep({
    required this.selectedLevel,
    required this.onBack,
    required this.onSelected,
    required this.onContinue,
    required this.onSkip,
    super.key,
  });

  final SelfReportedLevel? selectedLevel;
  final VoidCallback onBack;
  final ValueChanged<SelfReportedLevel> onSelected;
  final VoidCallback? onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final compact = _compactPhoneLayout(context);
    final options = selfReportedLevelQuestion.options;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            _CircleBackButton(onPressed: onBack),
            const Spacer(),
            const Text(
              'Langkah 4 dari 7',
              style: TextStyle(
                color: _authDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 10 : 18),
        const _SevenStepProgress(currentStep: 4),
        SizedBox(height: compact ? 12 : 20),
        _IntroMascotBubble(
          compact: compact,
          text:
              'Sekarang aku mau tahu kamu sudah sejauh apa. Tenang, ini bukan ujian.',
        ),
        SizedBox(height: compact ? 8 : 22),
        Text(
          'Sudah sejauh apa?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF3B2318),
                fontSize: compact ? 23 : 30,
                fontWeight: FontWeight.w900,
              ),
        ),
        SizedBox(height: compact ? 4 : 8),
        Text(
          'Pilih yang paling dekat dengan kondisimu.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF747985),
            fontSize: compact ? 13 : 16,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        for (final option in options) ...[
          _SelfReportedLevelCard(
            option: option,
            selected: selectedLevel == option.value,
            compact: compact,
            onTap: () => onSelected(option.value),
          ),
          SizedBox(height: compact ? 10 : 11),
        ],
        SizedBox(height: compact ? 4 : 8),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(compact ? 46 : 54),
            backgroundColor: _authPrimary,
            foregroundColor: const Color(0xFF3B2318),
            textStyle: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w900,
            ),
            elevation: 6,
            shadowColor: const Color(0x66F4B400),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Lanjutkan'),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: compact ? 23 : 25),
            ],
          ),
        ),
        SizedBox(height: compact ? 0 : 4),
        TextButton(
          onPressed: onSkip,
          child: const Text(
            'Lewati dulu',
            style: TextStyle(
              color: Color(0xFF8B8179),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _LearningFormatStep extends StatelessWidget {
  const _LearningFormatStep({
    required this.selectedFormats,
    required this.onBack,
    required this.onToggle,
    required this.onContinue,
    required this.onSkip,
    super.key,
  });

  final Set<LearningFormat> selectedFormats;
  final VoidCallback onBack;
  final ValueChanged<LearningFormat> onToggle;
  final VoidCallback? onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final compact = _compactPhoneLayout(context);
    final options = learningFormatQuestion.options;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            _CircleBackButton(onPressed: onBack),
            const Spacer(),
            const Text(
              'Langkah 5 dari 7',
              style: TextStyle(
                color: _authDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 10 : 18),
        const _SevenStepProgress(currentStep: 5),
        SizedBox(height: compact ? 12 : 20),
        _IntroMascotBubble(
          compact: compact,
          text:
              'Sekarang pilih cara belajar yang kamu suka. Aku akan buat misinya terasa lebih pas.',
        ),
        SizedBox(height: compact ? 8 : 22),
        Text(
          'Suka belajar gimana?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF3B2318),
                fontSize: compact ? 23 : 30,
                fontWeight: FontWeight.w900,
              ),
        ),
        SizedBox(height: compact ? 4 : 8),
        Text(
          'Pilih sampai 3 cara yang kamu suka.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF747985),
            fontSize: compact ? 13 : 16,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        for (final option in options) ...[
          _LearningFormatCard(
            option: option,
            selected: selectedFormats.contains(option.value),
            compact: compact,
            onTap: () => onToggle(option.value),
          ),
          SizedBox(height: compact ? 10 : 11),
        ],
        SizedBox(height: compact ? 4 : 8),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(compact ? 46 : 54),
            backgroundColor: _authPrimary,
            foregroundColor: const Color(0xFF3B2318),
            textStyle: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w900,
            ),
            elevation: 6,
            shadowColor: const Color(0x66F4B400),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                selectedFormats.isEmpty
                    ? 'Lanjutkan'
                    : 'Lanjutkan (${selectedFormats.length}/3)',
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: compact ? 23 : 25),
            ],
          ),
        ),
        SizedBox(height: compact ? 0 : 4),
        TextButton(
          onPressed: onSkip,
          child: const Text(
            'Lewati dulu',
            style: TextStyle(
              color: Color(0xFF8B8179),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyDurationStep extends StatelessWidget {
  const _DailyDurationStep({
    required this.selectedDuration,
    required this.onBack,
    required this.onSelected,
    required this.onContinue,
    required this.onSkip,
    super.key,
  });

  final DailyDuration? selectedDuration;
  final VoidCallback onBack;
  final ValueChanged<DailyDuration> onSelected;
  final VoidCallback? onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final compact = _compactPhoneLayout(context);
    final options = dailyDurationQuestion.options;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            _CircleBackButton(onPressed: onBack),
            const Spacer(),
            const Text(
              'Langkah 6 dari 7',
              style: TextStyle(
                color: _authDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 10 : 18),
        const _SevenStepProgress(currentStep: 6),
        SizedBox(height: compact ? 12 : 20),
        _IntroMascotBubble(
          compact: compact,
          text:
              'Sekarang kita atur target belajarmu. Pilih durasi yang terasa nyaman dulu.',
        ),
        SizedBox(height: compact ? 8 : 22),
        Text(
          'Belajar berapa menit?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF3B2318),
                fontSize: compact ? 23 : 30,
                fontWeight: FontWeight.w900,
              ),
        ),
        SizedBox(height: compact ? 4 : 8),
        Text(
          'Pilih durasi yang realistis buat harianmu.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF747985),
            fontSize: compact ? 13 : 16,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        for (final option in options) ...[
          _DailyDurationCard(
            option: option,
            selected: selectedDuration == option.value,
            compact: compact,
            onTap: () => onSelected(option.value),
          ),
          SizedBox(height: compact ? 10 : 11),
        ],
        SizedBox(height: compact ? 4 : 8),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(compact ? 46 : 54),
            backgroundColor: _authPrimary,
            foregroundColor: const Color(0xFF3B2318),
            textStyle: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w900,
            ),
            elevation: 6,
            shadowColor: const Color(0x66F4B400),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Lanjutkan'),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: compact ? 23 : 25),
            ],
          ),
        ),
        SizedBox(height: compact ? 0 : 4),
        TextButton(
          onPressed: onSkip,
          child: const Text(
            'Lewati dulu',
            style: TextStyle(
              color: Color(0xFF8B8179),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _StudyTimeStep extends StatelessWidget {
  const _StudyTimeStep({
    required this.selectedTime,
    required this.onBack,
    required this.onSelected,
    required this.onContinue,
    required this.onSkip,
    super.key,
  });

  final StudyTime? selectedTime;
  final VoidCallback onBack;
  final ValueChanged<StudyTime> onSelected;
  final VoidCallback? onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final compact = _compactPhoneLayout(context);
    final options = studyTimeQuestion.options;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            _CircleBackButton(onPressed: onBack),
            const Spacer(),
            const Text(
              'Langkah 7 dari 7',
              style: TextStyle(
                color: _authDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 10 : 18),
        const _SevenStepProgress(currentStep: 7),
        SizedBox(height: compact ? 12 : 20),
        _IntroMascotBubble(
          compact: compact,
          text:
              'Sip, tinggal satu langkah lagi! Pilih waktu belajar yang paling nyaman buatmu.',
        ),
        SizedBox(height: compact ? 14 : 22),
        Text(
          'Waktu belajar terbaik?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF3B2318),
                fontSize: compact ? 23 : 30,
                fontWeight: FontWeight.w900,
              ),
        ),
        SizedBox(height: compact ? 4 : 8),
        Text(
          'Pilih waktu yang cocok dengan rutinitasmu.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF747985),
            fontSize: compact ? 13 : 16,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        for (final option in options) ...[
          _StudyTimeCard(
            option: option,
            selected: selectedTime == option.value,
            compact: compact,
            onTap: () => onSelected(option.value),
          ),
          SizedBox(height: compact ? 10 : 11),
        ],
        SizedBox(height: compact ? 4 : 8),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(compact ? 50 : 54),
            backgroundColor: _authPrimary,
            foregroundColor: const Color(0xFF3B2318),
            textStyle: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w900,
            ),
            elevation: 6,
            shadowColor: const Color(0x66F4B400),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Lihat rekomendasiku'),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: compact ? 23 : 25),
            ],
          ),
        ),
        SizedBox(height: compact ? 0 : 4),
        TextButton(
          onPressed: onSkip,
          child: const Text(
            'Lewati dulu',
            style: TextStyle(
              color: Color(0xFF8B8179),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendationSplash extends StatelessWidget {
  const _RecommendationSplash({
    required this.world,
    required this.onPreviewAnalysis,
    super.key,
  });

  final LearningWorld? world;
  final VoidCallback onPreviewAnalysis;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/mascot/kenalan.png',
          height: 210,
          fit: BoxFit.contain,
          semanticLabel: 'Bale menyiapkan rekomendasi',
        ),
        const SizedBox(height: 20),
        Text(
          'Menyiapkan Cek Awal',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF3B2318),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bale memilih tes singkat untuk ${_worldName(world)}.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF747985),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 22),
        const SizedBox.square(
          dimension: 30,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: onPreviewAnalysis,
          child: const Text('Cek UI Analisis'),
        ),
      ],
    );
  }
}

class _PlacementTestFlow extends StatelessWidget {
  const _PlacementTestFlow({
    required this.world,
    required this.questions,
    required this.currentIndex,
    required this.onBack,
    required this.onNext,
    required this.onShowAnalysis,
    required this.onQuestionCompleted,
    required this.loadFailed,
    required this.onRetry,
    super.key,
  });

  final LearningWorld? world;
  final List<TemplateQuestion>? questions;
  final int currentIndex;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onShowAnalysis;
  final void Function(
    TemplateQuestion question,
    Object? answer, {
    required bool skipped,
  }) onQuestionCompleted;
  // Backend gagal memuat soal - tampilkan error/retry, JANGAN diam-diam
  // pakai soal dummy (dulu ada fallback `_placementQuestionsFor`, sudah
  // dihapus).
  final bool loadFailed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final questions = this.questions;
    if (questions == null) {
      if (loadFailed) {
        return _PlacementLoadError(onBack: onBack, onRetry: onRetry);
      }
      return const ColoredBox(
        color: Color(0xFFFFF3C6),
        child: Center(
          child: CircularProgressIndicator(color: _authPrimary),
        ),
      );
    }
    if (currentIndex >= questions.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onShowAnalysis());
      return const ColoredBox(
        color: Color(0xFFFFF3C6),
        child: Center(
          child: CircularProgressIndicator(color: _authPrimary),
        ),
      );
    }
    final index = currentIndex.clamp(0, questions.length - 1);
    final question = questions[index];
    final totalQuestions = questions.length;
    final currentQuestion = index + 1;
    final isLastQuestion = index >= totalQuestions - 1;

    void skipCurrent() {
      onQuestionCompleted(question, null, skipped: true);
      onNext();
    }

    void answerCurrent(Object? answer) {
      onQuestionCompleted(question, answer, skipped: false);
      if (isLastQuestion) {
        onShowAnalysis();
      } else {
        onNext();
      }
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      // Dispatch berdasarkan question.questionType (bukan posisi index) -
      // dulu ada bug di sini: switch(index) 0-12 cocok kebetulan dengan
      // urutan data dummy, tapi bisa salah render tipe kalau backend
      // mengembalikan soal dengan tipe/urutan berbeda. evidenceBoard juga
      // baru ditambahkan di sini - sebelumnya tidak pernah bisa dirender
      // sama sekali karena switch(index) cuma sampai 12.
      child: switch (question.questionType) {
        QuestionType.singleChoice => SingleChoiceTemplate(
            key: ValueKey(question.id),
            question: question,
            currentQuestion: currentQuestion,
            totalQuestions: totalQuestions,
            onBack: onBack,
            onSkip: skipCurrent,
            onCheckAnswer: answerCurrent,
          ),
        QuestionType.multipleSelect => MultipleSelectTemplate(
            key: ValueKey(question.id),
            question: question,
            currentQuestion: currentQuestion,
            totalQuestions: totalQuestions,
            onBack: onBack,
            onSkip: skipCurrent,
            onCheckAnswer: answerCurrent,
          ),
        QuestionType.binaryChoice => BinaryChoiceTemplate(
            key: ValueKey(question.id),
            question: question,
            currentQuestion: currentQuestion,
            totalQuestions: totalQuestions,
            onBack: onBack,
            onSkip: skipCurrent,
            onCheckAnswer: answerCurrent,
          ),
        QuestionType.shortText => ShortTextTemplate(
            key: ValueKey(question.id),
            question: question,
            currentQuestion: currentQuestion,
            totalQuestions: totalQuestions,
            onBack: onBack,
            onSkip: skipCurrent,
            onCheckAnswer: answerCurrent,
          ),
        QuestionType.matching => MatchingTemplate(
            key: ValueKey(question.id),
            question: question,
            currentQuestion: currentQuestion,
            totalQuestions: totalQuestions,
            onBack: onBack,
            onSkip: skipCurrent,
            onCheckAnswer: answerCurrent,
          ),
        QuestionType.ordering => OrderingTemplate(
            key: ValueKey(question.id),
            question: question,
            currentQuestion: currentQuestion,
            totalQuestions: totalQuestions,
            onBack: onBack,
            onSkip: skipCurrent,
            onCheckAnswer: answerCurrent,
          ),
        QuestionType.imageChoice => ImageChoiceTemplate(
            key: ValueKey(question.id),
            question: question,
            currentQuestion: currentQuestion,
            totalQuestions: totalQuestions,
            onBack: onBack,
            onSkip: skipCurrent,
            onCheckAnswer: answerCurrent,
          ),
        QuestionType.audioChoice => AudioChoiceTemplate(
            key: ValueKey(question.id),
            question: question,
            currentQuestion: currentQuestion,
            totalQuestions: totalQuestions,
            onPlay: () {},
            onPause: () {},
            onBack: onBack,
            onSkip: skipCurrent,
            onCheckAnswer: answerCurrent,
          ),
        QuestionType.longText => LongTextTemplate(
            key: ValueKey(question.id),
            question: question,
            currentQuestion: currentQuestion,
            totalQuestions: totalQuestions,
            onBack: onBack,
            onSkip: skipCurrent,
            onSubmitAnswer: answerCurrent,
          ),
        QuestionType.codeInput => CodeInputTemplate(
            key: ValueKey(question.id),
            question: question,
            currentQuestion: currentQuestion,
            totalQuestions: totalQuestions,
            onBack: onBack,
            onSkip: skipCurrent,
            onBookmark: () {},
            onCheckAnswer: answerCurrent,
          ),
        QuestionType.imageHotspot => ImageHotspotTemplate(
            key: ValueKey(question.id),
            question: question,
            currentQuestion: currentQuestion,
            totalQuestions: totalQuestions,
            onBack: onBack,
            onSkip: skipCurrent,
            onCheckAnswer: answerCurrent,
          ),
        QuestionType.voiceResponse => VoiceResponseTemplate(
            key: ValueKey(question.id),
            question: question,
            currentQuestion: currentQuestion,
            totalQuestions: totalQuestions,
            onStartRecording: () {},
            onStopRecording: () {},
            onBack: onBack,
            onSkip: skipCurrent,
            onSubmitAnswer: answerCurrent,
          ),
        QuestionType.timelineBuilder => TimelineBuilderTemplate(
            key: ValueKey(question.id),
            question: question,
            currentQuestion: currentQuestion,
            totalQuestions: totalQuestions,
            skipLabel: isLastQuestion ? 'Lanjut ke Analisis Hasil' : 'Lewati',
            onBack: onBack,
            onSkip: isLastQuestion
                ? () {
                    onQuestionCompleted(question, null, skipped: true);
                    onShowAnalysis();
                  }
                : skipCurrent,
            onCheckAnswer: answerCurrent,
          ),
        QuestionType.evidenceBoard => EvidenceBoardTemplate(
            key: ValueKey(question.id),
            question: question,
            currentQuestion: currentQuestion,
            totalQuestions: totalQuestions,
            onBack: onBack,
            onSkip: skipCurrent,
            onCheckAnswer: answerCurrent,
          ),
      },
    );
  }
}

class _PlacementLoadError extends StatelessWidget {
  const _PlacementLoadError({required this.onBack, required this.onRetry});

  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFF3C6),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: _authPrimary, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat soal tes penempatan. Periksa koneksimu lalu coba lagi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
              TextButton(onPressed: onBack, child: const Text('Kembali')),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: const Color(0x22000000),
      child: IconButton(
        tooltip: 'Kembali',
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF3B2318)),
      ),
    );
  }
}

class _SevenStepProgress extends StatelessWidget {
  const _SevenStepProgress({required this.currentStep});

  final int currentStep;
  static const int _totalSteps = 7;

  @override
  Widget build(BuildContext context) {
    final step = currentStep.clamp(1, _totalSteps);
    return SizedBox(
      height: 26,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dotGap = constraints.maxWidth / (_totalSteps - 1);
          final progress =
              _totalSteps == 1 ? 0.0 : (step - 1) / (_totalSteps - 1);
          final markerLeft = ((constraints.maxWidth - 30) * progress)
              .clamp(0.0, constraints.maxWidth - 30);
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 13,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: BaleColors.line, width: 2),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * progress,
                height: 13,
                decoration: BoxDecoration(
                  color: _authPrimary,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              for (var index = 1; index <= _totalSteps; index++)
                Positioned(
                  left: (dotGap * (index - 1) - 6)
                      .clamp(0, constraints.maxWidth - 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: index <= step ? _authPrimary : BaleColors.line,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: index < step
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 8,
                          )
                        : null,
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutBack,
                left: markerLeft,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _authPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33F4B400),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IntroMascotBubble extends StatelessWidget {
  const _IntroMascotBubble({
    required this.compact,
    this.text =
        'Hai, saya Bale!\nAku mau tahu tujuanmu dulu, biar misi belajarnya pas.',
  });

  final bool compact;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 9,
          child: Image.asset(
            'assets/mascot/kenalan.png',
            height: compact ? 112 : 174,
            fit: BoxFit.contain,
            semanticLabel: 'Maskot Bale memperkenalkan diri',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 11,
          child: _SpeechBubble(
            compact: compact,
            text: text,
          ),
        ),
      ],
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: BoxConstraints(minHeight: compact ? 76 : 112),
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            compact ? 12 : 16,
            compact ? 12 : 16,
            compact ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(compact ? 20 : 26),
            border: Border.all(color: const Color(0xFFEEDFBF), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x15000000),
                blurRadius: 18,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: _TypingText(text: text, compact: compact),
        ),
        Positioned(
          left: -10,
          bottom: 20,
          child: Transform.rotate(
            angle: -0.45,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFEEDFBF), width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypingText extends StatefulWidget {
  const _TypingText({required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  State<_TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<_TypingText> {
  Timer? _timer;
  int _visibleCharacters = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 24), (timer) {
      if (_visibleCharacters >= widget.text.length) {
        timer.cancel();
        return;
      }
      if (mounted) {
        setState(() => _visibleCharacters += 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = widget.text.substring(0, _visibleCharacters);
    return Text(
      visibleText,
      style: TextStyle(
        color: const Color(0xFF3B2318),
        fontSize: widget.compact ? 13 : 16,
        height: 1.16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _LearningGoalCard extends StatelessWidget {
  const _LearningGoalCard({
    required this.option,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final OnboardingOption<LearningGoal> option;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(compact ? 16 : 18),
      elevation: selected ? 5 : 2,
      shadowColor: const Color(0x16000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 52 : 66),
          padding: EdgeInsets.fromLTRB(
            compact ? 11 : 13,
            compact ? 10 : 11,
            compact ? 11 : 13,
            compact ? 10 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
            border: Border.all(
              color: selected ? _authPrimary : const Color(0xFFF2E4C5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 42 : 48,
                height: compact ? 42 : 48,
                decoration: BoxDecoration(
                  color: _goalColor(option.value).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(compact ? 12 : 14),
                ),
                child: Icon(
                  option.icon ?? Icons.auto_awesome_rounded,
                  color: _goalColor(option.value),
                  size: compact ? 23 : 26,
                ),
              ),
              SizedBox(width: compact ? 11 : 13),
              Expanded(
                child: Text(
                  _shortGoalLabel(option.value),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF3B2318),
                    fontSize: compact ? 14 : 16,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected ? _authPrimary : const Color(0xFF30333A),
                size: compact ? 23 : 27,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _goalColor(LearningGoal goal) => switch (goal) {
        LearningGoal.understandSubject => const Color(0xFF2D8CFF),
        LearningGoal.examPreparation => const Color(0xFF4CAF50),
        LearningGoal.improveGrade => const Color(0xFFFF6B6B),
        LearningGoal.learnNewSkill => const Color(0xFFF4B400),
        LearningGoal.buildThinkingSkill => const Color(0xFF7C5CFF),
        LearningGoal.exploreCareer => const Color(0xFF0E3A5F),
        LearningGoal.needRecommendation => const Color(0xFFFFA629),
      };

  String _shortGoalLabel(LearningGoal goal) => switch (goal) {
        LearningGoal.understandSubject => 'Paham pelajaran',
        LearningGoal.examPreparation => 'Siap ujian',
        LearningGoal.improveGrade => 'Nilai naik',
        LearningGoal.learnNewSkill => 'Skill baru',
        LearningGoal.buildThinkingSkill => 'Latih logika',
        LearningGoal.exploreCareer => 'Cari cita-cita',
        LearningGoal.needRecommendation => 'Bantu pilih',
      };
}

class _LearningWorldCard extends StatelessWidget {
  const _LearningWorldCard({
    required this.option,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final OnboardingOption<LearningWorld> option;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(compact ? 16 : 18),
      elevation: selected ? 5 : 2,
      shadowColor: const Color(0x16000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 62 : 70),
          padding: EdgeInsets.fromLTRB(
            compact ? 11 : 13,
            compact ? 10 : 11,
            compact ? 11 : 13,
            compact ? 10 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
            border: Border.all(
              color: selected ? _authPrimary : const Color(0xFFF2E4C5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 38 : 48,
                height: compact ? 38 : 48,
                decoration: BoxDecoration(
                  color: _worldColor(option.value).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(compact ? 12 : 14),
                ),
                child: Icon(
                  option.icon ?? Icons.explore_rounded,
                  color: _worldColor(option.value),
                  size: compact ? 22 : 27,
                ),
              ),
              SizedBox(width: compact ? 11 : 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _shortWorldLabel(option.value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF3B2318),
                        fontSize: compact ? 13 : 16,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        _worldSubject(option.value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF747985),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected ? _authPrimary : const Color(0xFF30333A),
                size: compact ? 23 : 27,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _worldColor(LearningWorld world) => switch (world) {
        LearningWorld.numeria => const Color(0xFF2D8CFF),
        LearningWorld.kodex => const Color(0xFF4CAF50),
        LearningWorld.detectivia => const Color(0xFF7C5CFF),
        LearningWorld.bahasa => const Color(0xFFFF6B6B),
        LearningWorld.sains => const Color(0xFF0E3A5F),
        LearningWorld.tryAll => const Color(0xFFF4B400),
      };

  String _shortWorldLabel(LearningWorld world) => switch (world) {
        LearningWorld.numeria => 'Numeria',
        LearningWorld.kodex => 'KodeX',
        LearningWorld.detectivia => 'Detectivia',
        LearningWorld.bahasa => 'Bahasa',
        LearningWorld.sains => 'Sains',
        LearningWorld.tryAll => 'Coba semua',
      };

  String _worldSubject(LearningWorld world) => switch (world) {
        LearningWorld.numeria => 'Matematika',
        LearningWorld.kodex => 'Informatika',
        LearningWorld.detectivia => 'Logika',
        LearningWorld.bahasa => 'Bahasa',
        LearningWorld.sains => 'Sains',
        LearningWorld.tryAll => 'Semua dunia',
      };
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({
    required this.grade,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final GradeChoice grade;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(compact ? 16 : 18),
      elevation: selected ? 5 : 2,
      shadowColor: const Color(0x16000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 52 : 68),
          padding: EdgeInsets.fromLTRB(
            compact ? 11 : 13,
            compact ? 10 : 11,
            compact ? 10 : 12,
            compact ? 10 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
            border: Border.all(
              color: selected ? _authPrimary : const Color(0xFFF2E4C5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 38 : 48,
                height: compact ? 38 : 48,
                decoration: BoxDecoration(
                  color: _gradeColor(grade).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(compact ? 12 : 14),
                ),
                child: Icon(
                  _gradeIcon(grade),
                  color: _gradeColor(grade),
                  size: compact ? 22 : 27,
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _gradeTitle(grade),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF3B2318),
                        fontSize: compact ? 14 : 18,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        _gradeSubtitle(grade),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF747985),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected ? _authPrimary : const Color(0xFF30333A),
                size: compact ? 23 : 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _gradeTitle(GradeChoice grade) => switch (grade) {
        GradeChoice.junior7 ||
        GradeChoice.junior8 ||
        GradeChoice.junior9 =>
          'SMP kelas 7-9',
        GradeChoice.senior10 => 'SMA/SMK kelas 10',
        GradeChoice.senior11 => 'SMA/SMK kelas 11',
        GradeChoice.senior12 => 'SMA/SMK kelas 12',
        GradeChoice.graduated => 'Sudah lulus / umum',
        GradeChoice.customLevel => 'Pilih level sendiri',
      };

  String _gradeSubtitle(GradeChoice grade) => switch (grade) {
        GradeChoice.junior7 ||
        GradeChoice.junior8 ||
        GradeChoice.junior9 =>
          'Belajar tingkat SMP',
        GradeChoice.senior10 => 'Mulai tingkat menengah atas',
        GradeChoice.senior11 => 'Lanjut tingkat menengah atas',
        GradeChoice.senior12 => 'Fokus persiapan akhir',
        GradeChoice.graduated => 'Belajar fleksibel sesuai tujuan',
        GradeChoice.customLevel => 'Atur tingkat belajar manual',
      };

  IconData _gradeIcon(GradeChoice grade) => switch (grade) {
        GradeChoice.junior7 ||
        GradeChoice.junior8 ||
        GradeChoice.junior9 =>
          Icons.backpack_rounded,
        GradeChoice.senior10 => Icons.school_rounded,
        GradeChoice.senior11 => Icons.menu_book_rounded,
        GradeChoice.senior12 => Icons.ads_click_rounded,
        GradeChoice.graduated => Icons.public_rounded,
        GradeChoice.customLevel => Icons.tune_rounded,
      };

  Color _gradeColor(GradeChoice grade) => switch (grade) {
        GradeChoice.junior7 ||
        GradeChoice.junior8 ||
        GradeChoice.junior9 =>
          const Color(0xFF4CAF50),
        GradeChoice.senior10 => const Color(0xFF2D8CFF),
        GradeChoice.senior11 => const Color(0xFF7C5CFF),
        GradeChoice.senior12 => const Color(0xFFFF6B6B),
        GradeChoice.graduated => const Color(0xFF0E3A5F),
        GradeChoice.customLevel => const Color(0xFFF4B400),
      };
}

class _SelfReportedLevelCard extends StatelessWidget {
  const _SelfReportedLevelCard({
    required this.option,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final OnboardingOption<SelfReportedLevel> option;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(compact ? 16 : 18),
      elevation: selected ? 5 : 2,
      shadowColor: const Color(0x16000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 52 : 66),
          padding: EdgeInsets.fromLTRB(
            compact ? 11 : 13,
            compact ? 10 : 11,
            compact ? 10 : 12,
            compact ? 10 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
            border: Border.all(
              color: selected ? _authPrimary : const Color(0xFFF2E4C5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 38 : 48,
                height: compact ? 38 : 48,
                decoration: BoxDecoration(
                  color: _levelColor(option.value).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(compact ? 12 : 14),
                ),
                child: Icon(
                  option.icon ?? Icons.auto_awesome_rounded,
                  color: _levelColor(option.value),
                  size: compact ? 22 : 27,
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _levelTitle(option.value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF3B2318),
                        fontSize: compact ? 14 : 18,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        _levelSubtitle(option.value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF747985),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected ? _authPrimary : const Color(0xFF30333A),
                size: compact ? 23 : 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _levelTitle(SelfReportedLevel level) => switch (level) {
        SelfReportedLevel.beginner => 'Baru mulai',
        SelfReportedLevel.basic => 'Tahu sedikit',
        SelfReportedLevel.foundationReady => 'Paham dasar',
        SelfReportedLevel.intermediate => 'Soal menengah',
        SelfReportedLevel.advanced => 'Siap tantangan',
        SelfReportedLevel.unsure => 'Belum yakin',
      };

  String _levelSubtitle(SelfReportedLevel level) => switch (level) {
        SelfReportedLevel.beginner => 'Aku masih sangat baru',
        SelfReportedLevel.basic => 'Sudah pernah lihat dasarnya',
        SelfReportedLevel.foundationReady => 'Aku mengerti dasar-dasarnya',
        SelfReportedLevel.intermediate => 'Cukup nyaman belajar mandiri',
        SelfReportedLevel.advanced => 'Aku ingin materi menantang',
        SelfReportedLevel.unsure => 'Bantu aku menentukannya',
      };

  Color _levelColor(SelfReportedLevel level) => switch (level) {
        SelfReportedLevel.beginner => const Color(0xFF4CAF50),
        SelfReportedLevel.basic => const Color(0xFFF4B400),
        SelfReportedLevel.foundationReady => const Color(0xFF2D8CFF),
        SelfReportedLevel.intermediate => const Color(0xFF7C5CFF),
        SelfReportedLevel.advanced => const Color(0xFFFFA629),
        SelfReportedLevel.unsure => const Color(0xFFFF6B6B),
      };
}

class _LearningFormatCard extends StatelessWidget {
  const _LearningFormatCard({
    required this.option,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final OnboardingOption<LearningFormat> option;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(compact ? 16 : 18),
      elevation: selected ? 5 : 2,
      shadowColor: const Color(0x16000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 52 : 66),
          padding: EdgeInsets.fromLTRB(
            compact ? 11 : 13,
            compact ? 10 : 11,
            compact ? 10 : 12,
            compact ? 10 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
            border: Border.all(
              color: selected ? _authPrimary : const Color(0xFFF2E4C5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 38 : 48,
                height: compact ? 38 : 48,
                decoration: BoxDecoration(
                  color: _formatColor(option.value).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(compact ? 12 : 14),
                ),
                child: Icon(
                  option.icon ?? Icons.auto_awesome_rounded,
                  color: _formatColor(option.value),
                  size: compact ? 22 : 27,
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTitle(option.value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF3B2318),
                        fontSize: compact ? 14 : 18,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatSubtitle(option.value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF747985),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected ? _authPrimary : const Color(0xFF30333A),
                size: compact ? 23 : 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTitle(LearningFormat format) => switch (format) {
        LearningFormat.visual => 'Gambar & contoh',
        LearningFormat.practiceFirst => 'Langsung mencoba',
        LearningFormat.audio => 'Mendengar',
        LearningFormat.story => 'Lewat cerita',
        LearningFormat.challenge => 'Tantangan',
        LearningFormat.teachBack => 'Jelaskan sendiri',
        LearningFormat.social => 'Bareng mentor/teman',
      };

  String _formatSubtitle(LearningFormat format) => switch (format) {
        LearningFormat.visual => 'Lebih cepat paham lewat visual',
        LearningFormat.practiceFirst => 'Suka belajar sambil praktik',
        LearningFormat.audio => 'Nyaman dengan penjelasan',
        LearningFormat.story => 'Suka penjelasan yang hidup',
        LearningFormat.challenge => 'Suka target yang seru',
        LearningFormat.teachBack => 'Biar benar-benar paham',
        LearningFormat.social => 'Suka diskusi atau pendamping',
      };

  Color _formatColor(LearningFormat format) => switch (format) {
        LearningFormat.visual => const Color(0xFF2D8CFF),
        LearningFormat.practiceFirst => const Color(0xFF4CAF50),
        LearningFormat.audio => const Color(0xFF0E3A5F),
        LearningFormat.story => const Color(0xFF7C5CFF),
        LearningFormat.challenge => const Color(0xFFFF6B6B),
        LearningFormat.teachBack => const Color(0xFFF4B400),
        LearningFormat.social => const Color(0xFFFFA629),
      };
}

class _DailyDurationCard extends StatelessWidget {
  const _DailyDurationCard({
    required this.option,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final OnboardingOption<DailyDuration> option;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(compact ? 16 : 18),
      elevation: selected ? 5 : 2,
      shadowColor: const Color(0x16000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 52 : 66),
          padding: EdgeInsets.fromLTRB(
            compact ? 11 : 13,
            compact ? 10 : 11,
            compact ? 10 : 12,
            compact ? 10 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
            border: Border.all(
              color: selected ? _authPrimary : const Color(0xFFF2E4C5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 38 : 48,
                height: compact ? 38 : 48,
                decoration: BoxDecoration(
                  color: _durationColor(option.value).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(compact ? 12 : 14),
                ),
                child: Icon(
                  option.icon ?? Icons.timer_rounded,
                  color: _durationColor(option.value),
                  size: compact ? 22 : 27,
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _durationTitle(option.value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF3B2318),
                        fontSize: compact ? 14 : 18,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        _durationSubtitle(option.value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF747985),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected ? _authPrimary : const Color(0xFF30333A),
                size: compact ? 23 : 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _durationTitle(DailyDuration duration) => switch (duration) {
        DailyDuration.five => '5 menit',
        DailyDuration.ten => '10 menit',
        DailyDuration.fifteen => '15 menit',
        DailyDuration.twenty => '20 menit',
        DailyDuration.thirty => '30 menit',
        DailyDuration.adaptive => 'Otomatis',
      };

  String _durationSubtitle(DailyDuration duration) => switch (duration) {
        DailyDuration.five => 'Santai, cocok buat mulai',
        DailyDuration.ten => 'Ringan untuk setiap hari',
        DailyDuration.fifteen => 'Pas untuk misi harian',
        DailyDuration.twenty => 'Lebih fokus dan menantang',
        DailyDuration.thirty => 'Untuk belajar lebih serius',
        DailyDuration.adaptive => 'Bale menyesuaikan progresmu',
      };

  Color _durationColor(DailyDuration duration) => switch (duration) {
        DailyDuration.five => const Color(0xFF2D8CFF),
        DailyDuration.ten => const Color(0xFFF4B400),
        DailyDuration.fifteen => const Color(0xFFFF6B6B),
        DailyDuration.twenty => const Color(0xFF7C5CFF),
        DailyDuration.thirty => const Color(0xFFFFA629),
        DailyDuration.adaptive => const Color(0xFF4CAF50),
      };
}

class _StudyTimeCard extends StatelessWidget {
  const _StudyTimeCard({
    required this.option,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final OnboardingOption<StudyTime> option;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(compact ? 16 : 18),
      elevation: selected ? 5 : 2,
      shadowColor: const Color(0x16000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 52 : 66),
          padding: EdgeInsets.fromLTRB(
            compact ? 11 : 13,
            compact ? 10 : 11,
            compact ? 10 : 12,
            compact ? 10 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
            border: Border.all(
              color: selected ? _authPrimary : const Color(0xFFF2E4C5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 38 : 48,
                height: compact ? 38 : 48,
                decoration: BoxDecoration(
                  color: _timeColor(option.value).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(compact ? 12 : 14),
                ),
                child: Icon(
                  option.icon ?? Icons.schedule_rounded,
                  color: _timeColor(option.value),
                  size: compact ? 22 : 27,
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _timeTitle(option.value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF3B2318),
                        fontSize: compact ? 14 : 18,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        _timeSubtitle(option.value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF747985),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected ? _authPrimary : const Color(0xFF30333A),
                size: compact ? 23 : 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeTitle(StudyTime time) => switch (time) {
        StudyTime.beforeSchool => 'Sebelum sekolah',
        StudyTime.afternoon => 'Siang',
        StudyTime.evening => 'Sore',
        StudyTime.night => 'Malam',
        StudyTime.differentDaily => 'Jadwal berbeda',
        StudyTime.skipForNow => 'Nanti saja',
      };

  String _timeSubtitle(StudyTime time) => switch (time) {
        StudyTime.beforeSchool => 'Mulai lebih pagi',
        StudyTime.afternoon => 'Saat istirahat atau setelah pagi',
        StudyTime.evening => 'Santai setelah sekolah',
        StudyTime.night => 'Fokus di malam hari',
        StudyTime.differentDaily => 'Bale akan menyesuaikan',
        StudyTime.skipForNow => 'Bisa diatur nanti',
      };

  Color _timeColor(StudyTime time) => switch (time) {
        StudyTime.beforeSchool => const Color(0xFFF4B400),
        StudyTime.afternoon => const Color(0xFFFFA629),
        StudyTime.evening => const Color(0xFFFF6B6B),
        StudyTime.night => const Color(0xFF0E3A5F),
        StudyTime.differentDaily => const Color(0xFF4CAF50),
        StudyTime.skipForNow => const Color(0xFF7C5CFF),
      };
}

String _worldName(LearningWorld? world) => switch (world) {
      LearningWorld.numeria => 'Numeria',
      LearningWorld.kodex => 'KodeX',
      LearningWorld.detectivia => 'Detectivia',
      LearningWorld.bahasa => 'Bahasa',
      LearningWorld.sains => 'Sains',
      LearningWorld.tryAll || null => 'BaleBelajar',
    };

class _LoginWelcomeStep extends StatelessWidget {
  const _LoginWelcomeStep({
    required this.controller,
    required this.googleBusy,
    required this.showPassword,
    required this.emailController,
    required this.passwordController,
    required this.onBack,
    required this.onTogglePassword,
    required this.onGoogle,
    required this.onSubmit,
    required this.onRegister,
    this.errorMessage,
    super.key,
  });

  final AuthController controller;
  final bool googleBusy;
  final bool showPassword;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onBack;
  final VoidCallback onTogglePassword;
  final VoidCallback onGoogle;
  final VoidCallback onSubmit;
  final VoidCallback onRegister;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Kembali',
                  onPressed: controller.isBusy ? null : onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Expanded(child: _FiveStepProgress(currentStep: 2)),
              ],
            ),
            const SizedBox(height: 22),
            const _MiniBrand(),
            const SizedBox(height: 24),
            const Center(
              child: _MascotStage(
                pose: BeloPose.kedip,
                size: 136,
                compact: true,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Selamat datang kembali!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                    color: BaleColors.ink,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lanjutkan petualangan belajarmu',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7A8796),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 28),
            _GoogleButton(
              loading: googleBusy,
              disabled: controller.isBusy,
              onPressed: onGoogle,
            ),
            const SizedBox(height: 20),
            const _DividerLabel(label: 'atau'),
            const SizedBox(height: 20),
            _Field(
              controller: emailController,
              label: 'Email',
              icon: Icons.mail_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (_) => null,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: passwordController,
              label: 'Password',
              icon: Icons.lock_rounded,
              obscureText: !showPassword,
              validator: (_) => null,
              suffixIcon: IconButton(
                tooltip:
                    showPassword ? 'Sembunyikan password' : 'Lihat password',
                onPressed: onTogglePassword,
                icon: Icon(
                  showPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: errorMessage!),
            ],
            const SizedBox(height: 18),
            _PrimaryAction(
              loading: controller.isBusy,
              disabled: googleBusy,
              label: 'MASUK',
              onPressed: onSubmit,
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Belum punya akun? ',
                  style: TextStyle(
                    color: Color(0xFF7A8796),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextButton(
                  onPressed:
                      controller.isBusy || googleBusy ? null : onRegister,
                  child: const Text('DAFTAR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBrand extends StatelessWidget {
  const _MiniBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: BaleColors.warning,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.menu_book_rounded, color: Colors.white),
        ),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: BaleColors.ink,
            ),
            children: [
              TextSpan(text: 'Bale'),
              TextSpan(
                text: 'Belajar',
                style: TextStyle(color: BaleColors.warning),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WelcomeMascot extends StatelessWidget {
  const _WelcomeMascot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.28,
      child: Image.asset(
        'assets/mascot/welcome.png',
        fit: BoxFit.contain,
        alignment: Alignment.center,
        semanticLabel: 'Maskot Bale Belajar menyambut',
      ),
    );
  }
}

class _AuthStep extends StatelessWidget {
  const _AuthStep({
    required this.controller,
    required this.flowStep,
    required this.title,
    required this.helper,
    required this.mascotPose,
    required this.onBack,
    required this.child,
    super.key,
  });

  final AuthController controller;
  final int flowStep;
  final String title;
  final String helper;
  final BeloPose mascotPose;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Kembali',
              onPressed: controller.isBusy ? null : onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(child: _FiveStepProgress(currentStep: flowStep)),
          ],
        ),
        const SizedBox(height: 14),
        _MascotStage(pose: mascotPose, size: 116, compact: true),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          helper,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        BaleCard(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ],
    );
  }
}

class _FiveStepProgress extends StatelessWidget {
  const _FiveStepProgress({required this.currentStep});

  final int currentStep;

  static const int _totalSteps = 5;

  @override
  Widget build(BuildContext context) {
    final step = currentStep.clamp(1, _totalSteps);
    final progress = _totalSteps == 1 ? 0.0 : (step - 1) / (_totalSteps - 1);

    return SizedBox(
      height: 42,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mascotX = (constraints.maxWidth - 30) * progress - 15;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Row(
                children: [
                  for (var index = 1; index <= _totalSteps; index++) ...[
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutCubic,
                        height: 10,
                        decoration: BoxDecoration(
                          color: index <= step ? _authPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color:
                                index <= step ? _authPrimary : BaleColors.line,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    if (index != _totalSteps) const SizedBox(width: 10),
                  ],
                ],
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutBack,
                left: mascotX.clamp(0, constraints.maxWidth - 30),
                top: -4,
                child: const BeloMascot(
                  pose: BeloPose.lariSemangat,
                  size: 24,
                  animate: false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.loading,
    required this.disabled,
    required this.onPressed,
  });

  final bool loading;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: loading || disabled ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        side: const BorderSide(color: BaleColors.line, width: 2),
        backgroundColor: Colors.white,
        foregroundColor: BaleColors.ink,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const _GoogleGlyph(),
          const SizedBox(width: 10),
          const Text('Lanjutkan dengan Google'),
        ],
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: BaleColors.line),
        shape: BoxShape.circle,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: _authDark,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: BaleColors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const Expanded(child: Divider(color: BaleColors.line)),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.disabled = false,
  });

  final IconData? icon;
  final String label;
  final VoidCallback onPressed;
  final bool loading;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(58),
      backgroundColor: _authPrimary,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      elevation: 4,
      shadowColor: const Color(0x55F4B400),
    );
    if (loading || icon != null) {
      return FilledButton.icon(
        onPressed: loading || disabled ? null : onPressed,
        style: style,
        icon: loading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(label),
      );
    }
    return FilledButton(
      onPressed: disabled ? null : onPressed,
      style: style,
      child: Text(label),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(58),
      backgroundColor: Colors.white,
      foregroundColor: _authDark,
      side: const BorderSide(color: BaleColors.line, width: 2),
    );
    return OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: Text(label),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: BaleColors.soft.withValues(alpha: 0.62),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BaleColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _authPrimary, width: 2),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BaleColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BaleColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: BaleColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: BaleColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
