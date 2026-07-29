import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../shared/widgets/bale_card.dart';
import '../../../theme/bale_theme.dart';
import '../application/auth_controller.dart';

const _authBlue = Color(0xFF38BDF8);
const _authBlueDark = Color(0xFF0284C7);
const _authBlueSoft = Color(0xFFE0F7FF);

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

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
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
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _mode == AuthMode.welcome
                    ? _OnboardingView(
                        key: const ValueKey('onboarding'),
                        onRegister: () => _goTo(AuthMode.register),
                        onLogin: () => _goTo(AuthMode.login),
                        onCode: () => _goTo(AuthMode.code),
                      )
                    : _AuthStep(
                        key: ValueKey(_mode),
                        controller: widget.controller,
                        progress: _progress,
                        title: _title,
                        helper: _helper,
                        onBack: () => _goTo(AuthMode.welcome),
                        child: _form(),
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
            ],
          ),
        );
      },
    );
  }

  double get _progress => switch (_mode) {
        AuthMode.welcome => 0.18,
        AuthMode.register => 0.58,
        AuthMode.login => 0.58,
        AuthMode.code => 0.58,
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
    setState(() => _mode = mode);
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

class _OnboardingView extends StatelessWidget {
  const _OnboardingView({
    required this.onRegister,
    required this.onLogin,
    required this.onCode,
    super.key,
  });

  final VoidCallback onRegister;
  final VoidCallback onLogin;
  final VoidCallback onCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        const _BaleBookMascot(size: 148),
        const SizedBox(height: 18),
        Text(
          'BaleBelajar',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: _authBlueDark,
                fontSize: 34,
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
        const Spacer(flex: 3),
        _PrimaryAction(
          icon: Icons.play_arrow_rounded,
          label: 'GET STARTED',
          onPressed: onRegister,
        ),
        const SizedBox(height: 12),
        _OutlineAction(
          icon: Icons.login_rounded,
          label: 'I ALREADY HAVE AN ACCOUNT',
          onPressed: onLogin,
        ),
        const SizedBox(height: 10),
        _SecondaryAction(label: 'Masuk dengan kode siswa', onPressed: onCode),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _AuthStep extends StatelessWidget {
  const _AuthStep({
    required this.controller,
    required this.progress,
    required this.title,
    required this.helper,
    required this.onBack,
    required this.child,
    super.key,
  });

  final AuthController controller;
  final double progress;
  final String title;
  final String helper;
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
            Expanded(child: _ProgressTrack(value: progress)),
          ],
        ),
        const SizedBox(height: 14),
        const _BaleBookMascot(size: 104),
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

class _BaleBookMascot extends StatefulWidget {
  const _BaleBookMascot({required this.size});

  final double size;

  @override
  State<_BaleBookMascot> createState() => _BaleBookMascotState();
}

class _BaleBookMascotState extends State<_BaleBookMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mascot buku BaleBelajar',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final wave = math.sin(_controller.value * math.pi * 2);
          return Transform.translate(
            offset: Offset(0, wave * 5),
            child: Transform.rotate(
              angle: wave * 0.035,
              child: child,
            ),
          );
        },
        child: SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(painter: _BaleBookMascotPainter()),
        ),
      ),
    );
  }
}

class _BaleBookMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final w = size.width;
    final h = size.height;

    paint.color = const Color(0x22000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.86),
        width: w * 0.56,
        height: h * 0.08,
      ),
      paint,
    );

    final armPaint = Paint()
      ..isAntiAlias = true
      ..color = _authBlueDark
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(w * 0.2, h * 0.47), Offset(w * 0.08, h * 0.38), armPaint);
    canvas.drawLine(
        Offset(w * 0.8, h * 0.47), Offset(w * 0.92, h * 0.38), armPaint);

    final leftPage = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.34, h * 0.5),
      Radius.circular(w * 0.08),
    );
    final rightPage = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.48, h * 0.18, w * 0.34, h * 0.5),
      Radius.circular(w * 0.08),
    );

    paint.color = _authBlueDark;
    canvas.drawRRect(leftPage, paint);
    paint.color = _authBlue;
    canvas.drawRRect(rightPage, paint);

    paint.color = const Color(0xFF0369A1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.475, h * 0.18, w * 0.05, h * 0.52),
        Radius.circular(w * 0.04),
      ),
      paint,
    );

    paint.color = _authBlueSoft;
    canvas.drawCircle(Offset(w * 0.38, h * 0.39), w * 0.095, paint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.39), w * 0.095, paint);

    paint.color = BaleColors.ink;
    canvas.drawCircle(Offset(w * 0.39, h * 0.39), w * 0.032, paint);
    canvas.drawCircle(Offset(w * 0.61, h * 0.39), w * 0.032, paint);

    paint.color = Colors.white;
    canvas.drawCircle(Offset(w * 0.402, h * 0.376), w * 0.012, paint);
    canvas.drawCircle(Offset(w * 0.622, h * 0.376), w * 0.012, paint);

    final smile = Path()
      ..moveTo(w * 0.42, h * 0.52)
      ..quadraticBezierTo(w * 0.5, h * 0.59, w * 0.58, h * 0.52);
    canvas.drawPath(
      smile,
      Paint()
        ..isAntiAlias = true
        ..color = BaleColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.025
        ..strokeCap = StrokeCap.round,
    );

    paint.color = BaleColors.dayaBale;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.48),
        width: w * 0.09,
        height: h * 0.055,
      ),
      paint,
    );

    final footPaint = Paint()
      ..isAntiAlias = true
      ..color = BaleColors.warning
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(w * 0.38, h * 0.7), Offset(w * 0.3, h * 0.76), footPaint);
    canvas.drawLine(
        Offset(w * 0.62, h * 0.7), Offset(w * 0.7, h * 0.76), footPaint);

    paint.color = Colors.white.withValues(alpha: 0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.25, h * 0.25, w * 0.16, h * 0.035),
        Radius.circular(w * 0.02),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.59, h * 0.25, w * 0.14, h * 0.035),
        Radius.circular(w * 0.02),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 12,
        backgroundColor: BaleColors.line,
        color: _authBlue,
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
          color: BaleColors.info,
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
    required this.icon,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool loading;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: loading || disabled ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        backgroundColor: _authBlue,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        elevation: 4,
        shadowColor: const Color(0x5538BDF8),
      ),
      icon: loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        backgroundColor: Colors.white,
        foregroundColor: _authBlueDark,
        side: const BorderSide(color: BaleColors.line, width: 2),
      ),
      icon: Icon(icon),
      label: Text(label),
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
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BaleColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _authBlue, width: 2),
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
