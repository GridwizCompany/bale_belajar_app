import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../shared/widgets/bale_card.dart';
import '../../../shared/widgets/belo_mascot.dart';
import '../../../theme/bale_theme.dart';
import '../application/auth_controller.dart';

const _authPrimary = Color(0xFFF4B400);
const _authDark = Color(0xFF0E3A5F);

enum AuthMode { welcome, register, login, code }

class SimpleAuthScreen extends StatefulWidget {
  const SimpleAuthScreen({required this.controller, super.key});

  final AuthController controller;

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

  @override
  void initState() {
    super.initState();
    _resetToWelcome();
  }

  @override
  void didUpdateWidget(covariant SimpleAuthScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _resetToWelcome();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (mounted) {
      setState(_resetToWelcome);
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

  void _resetToWelcome() {
    _mode = AuthMode.welcome;
    _flowStep = 1;
    _googleBusy = false;
    _showPassword = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
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
                      : _AuthStep(
                          key: ValueKey(_mode),
                          controller: widget.controller,
                          flowStep: _flowStep,
                          title: _title,
                          helper: _helper,
                          mascotPose: _mascotPose,
                          onBack: () => _goTo(AuthMode.welcome),
                          child: _form(),
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
              if (_mode == AuthMode.register) ...[
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
              if (_mode == AuthMode.register) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _grade,
                  decoration: const InputDecoration(
                    labelText: 'Kelas',
                    prefixIcon: Icon(Icons.school_rounded),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
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
        AuthMode.login => BeloPose.kedip,
        AuthMode.code => BeloPose.jempolOke,
        AuthMode.welcome => BeloPose.jatuhCinta,
      };

  String get _title => switch (_mode) {
        AuthMode.welcome => 'BaleBelajar',
        AuthMode.register => 'Buat akunmu',
        AuthMode.login => 'Masuk lagi',
        AuthMode.code => 'Pakai kode siswa',
      };

  String get _helper => switch (_mode) {
        AuthMode.welcome => '',
        AuthMode.register => 'Satu langkah lagi sebelum misi pertamamu.',
        AuthMode.login => 'Lanjutkan progres belajar yang sudah tersimpan.',
        AuthMode.code => 'Masukkan kode dari sekolah atau mentor.',
      };

  String get _switchLabel => switch (_mode) {
        AuthMode.register => 'Sudah punya akun? Masuk',
        AuthMode.login => 'Belum punya akun? Mulai belajar',
        AuthMode.code => 'Masuk pakai email',
        AuthMode.welcome => '',
      };

  AuthMode get _switchTarget => switch (_mode) {
        AuthMode.register => AuthMode.login,
        AuthMode.login => AuthMode.register,
        AuthMode.code => AuthMode.login,
        AuthMode.welcome => AuthMode.register,
      };

  IconData get _buttonIcon => switch (_mode) {
        AuthMode.register => Icons.arrow_forward_rounded,
        AuthMode.login => Icons.login_rounded,
        AuthMode.code => Icons.qr_code_2_rounded,
        AuthMode.welcome => Icons.play_arrow_rounded,
      };

  String get _buttonLabel => switch (_mode) {
        AuthMode.register => 'Buat Akun',
        AuthMode.login => 'Masuk',
        AuthMode.code => 'Masuk dengan Kode',
        AuthMode.welcome => 'Mulai',
      };

  void _goTo(AuthMode mode) {
    setState(() {
      _mode = mode;
      _flowStep = switch (mode) {
        AuthMode.welcome => 1,
        AuthMode.register || AuthMode.login || AuthMode.code => 2,
      };
    });
  }

  Future<void> _continueWithGoogle() async {
    if (!FirebaseBootstrap.isConfigured) {
      widget.controller.setError(
        'Login Google belum aktif. Lengkapi konfigurasi Firebase dulu.',
      );
      return;
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
    } on FirebaseAuthException catch (error) {
      widget.controller.setError(_googleError(error));
    } catch (_) {
      widget.controller.setError('Login Google gagal. Coba lagi.');
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (_mode == AuthMode.login) {
      await widget.controller.loginWithEmail(_email.text, _password.text);
    } else if (_mode == AuthMode.register) {
      await widget.controller.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        gradeLevel: _grade,
      );
    } else if (_mode == AuthMode.code) {
      await widget.controller.loginWithCode(_code.text);
    }
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
      child: Center(child: BeloMascot(pose: pose, size: size, animate: true)),
    );
  }
}

class _WelcomeMascot extends StatefulWidget {
  const _WelcomeMascot({required this.size});

  final double size;

  @override
  State<_WelcomeMascot> createState() => _WelcomeMascotState();
}

class _WelcomeMascotState extends State<_WelcomeMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final wave = math.sin(_controller.value * math.pi * 2);
        return Transform.translate(
          offset: Offset(0, wave * 5),
          child: Transform.rotate(angle: wave * 0.018, child: child),
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.28,
        child: Image.asset(
          'assets/mascot/welcome.png',
          fit: BoxFit.contain,
          alignment: Alignment.center,
          semanticLabel: 'Maskot Bale Belajar menyambut',
        ),
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
                  animate: true,
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
