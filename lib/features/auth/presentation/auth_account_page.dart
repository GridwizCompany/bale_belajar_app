import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../theme/bale_theme.dart';
import '../application/auth_controller.dart';

enum AuthAccountMode { login, register, code }

class AuthAccountPage extends StatefulWidget {
  const AuthAccountPage({
    required this.controller,
    required this.initialMode,
    required this.onBack,
    this.onAuthenticated,
    this.onAuthFlowLockChanged,
    this.keepFlowAfterAuth = false,
    this.initialName = '',
    this.initialGrade = 10,
    super.key,
  });

  final AuthController controller;
  final AuthAccountMode initialMode;
  final VoidCallback onBack;
  final Future<void> Function()? onAuthenticated;
  final ValueChanged<bool>? onAuthFlowLockChanged;
  final bool keepFlowAfterAuth;
  final String initialName;
  final int initialGrade;

  @override
  State<AuthAccountPage> createState() => _AuthAccountPageState();
}

class _AuthAccountPageState extends State<AuthAccountPage> {
  final _formKey = GlobalKey<FormState>();
  late AuthAccountMode _mode;
  late final TextEditingController _name;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  late int _grade;
  bool _showPassword = false;
  bool _googleBusy = false;
  bool _appleBusy = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode == AuthAccountMode.code
        ? AuthAccountMode.login
        : widget.initialMode;
    _name = TextEditingController(text: widget.initialName);
    _grade = _normalizedGrade(widget.initialGrade);
  }

  @override
  void didUpdateWidget(covariant AuthAccountPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode) {
      _mode = widget.initialMode == AuthAccountMode.code
          ? AuthAccountMode.login
          : widget.initialMode;
    }
    if (oldWidget.initialGrade != widget.initialGrade) {
      _grade = _normalizedGrade(widget.initialGrade);
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final compact = screenHeight < 740;
    final isLogin = _mode == AuthAccountMode.login;
    final mascotSize =
        isLogin ? (compact ? 128.0 : 158.0) : (compact ? 92.0 : 118.0);
    final subtitle = _subtitle;
    final showApple = defaultTargetPlatform != TargetPlatform.android;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                22,
                isLogin ? (compact ? 6 : 10) : (compact ? 12 : 20),
                22,
                18,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isLogin) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Kembali',
                          onPressed: _busy ? null : widget.onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const _MiniBrand(),
                      SizedBox(height: compact ? 6 : 10),
                    ],
                    Text(
                      _title,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: isLogin
                                    ? (compact ? 25 : 29)
                                    : (compact ? 22 : 26),
                                color: BaleColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    SizedBox(
                        height:
                            isLogin ? (compact ? 8 : 12) : (compact ? 4 : 8)),
                    _LoginMascot(size: mascotSize),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF7A8796),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    SizedBox(height: compact ? 12 : 16),
                    if (_mode != AuthAccountMode.code) ...[
                      _GoogleLoginButton(
                        loading: _googleBusy,
                        disabled: _busy || _appleBusy,
                        onPressed: _continueWithGoogle,
                      ),
                      if (showApple) ...[
                        const SizedBox(height: 10),
                        _AppleLoginButton(
                          loading: _appleBusy,
                          disabled: _busy || _googleBusy,
                          onPressed: _continueWithApple,
                        ),
                      ],
                      const SizedBox(height: 14),
                      const _DividerLabel(label: 'atau'),
                      const SizedBox(height: 14),
                    ],
                    if (_mode == AuthAccountMode.register) ...[
                      _AccountField(
                        controller: _name,
                        label: 'Nama lengkap',
                        icon: Icons.person_rounded,
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_mode == AuthAccountMode.code)
                      _AccountField(
                        controller: _code,
                        label: 'Kode peserta',
                        icon: Icons.badge_rounded,
                        textCapitalization: TextCapitalization.characters,
                        validator: _required,
                      )
                    else ...[
                      _AccountField(
                        controller: _email,
                        label: 'Email',
                        icon: Icons.mail_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: _emailValidator,
                      ),
                      const SizedBox(height: 12),
                      _AccountField(
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
                    if (_mode == AuthAccountMode.register) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _grade,
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
                    FilledButton.icon(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: BaleColors.warning,
                        foregroundColor: BaleColors.ink,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      icon: widget.controller.isBusy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_primaryIcon),
                      label: Text(_primaryLabel),
                    ),
                    const SizedBox(height: 12),
                    _ModeSwitch(
                      prefix: _switchPrefix,
                      action: _switchAction,
                      onPressed: _busy ? null : _switchMode,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _busy => widget.controller.isBusy || _googleBusy || _appleBusy;

  String get _title => switch (_mode) {
        AuthAccountMode.login => 'Selamat datang kembali!',
        AuthAccountMode.register => 'Buat akun BaleBelajar',
        AuthAccountMode.code => 'Masuk dengan kode siswa',
      };

  String get _subtitle => switch (_mode) {
        AuthAccountMode.login => '',
        AuthAccountMode.register =>
          'Simpan hasil cek awal dan mulai dari level yang pas.',
        AuthAccountMode.code => 'Masukkan kode dari sekolah atau mentor.',
      };

  IconData get _primaryIcon => switch (_mode) {
        AuthAccountMode.login => Icons.login_rounded,
        AuthAccountMode.register => Icons.person_add_alt_1_rounded,
        AuthAccountMode.code => Icons.qr_code_2_rounded,
      };

  String get _primaryLabel => switch (_mode) {
        AuthAccountMode.login => 'MASUK',
        AuthAccountMode.register => 'DAFTAR',
        AuthAccountMode.code => 'MASUK DENGAN KODE',
      };

  String get _switchPrefix => switch (_mode) {
        AuthAccountMode.login => 'Belum punya akun? ',
        AuthAccountMode.register => 'Sudah punya akun? ',
        AuthAccountMode.code => 'Belum punya akun? ',
      };

  String get _switchAction => switch (_mode) {
        AuthAccountMode.login => 'DAFTAR',
        AuthAccountMode.register => 'MASUK',
        AuthAccountMode.code => 'DAFTAR',
      };

  void _switchMode() {
    setState(() {
      _mode = _mode == AuthAccountMode.register
          ? AuthAccountMode.login
          : AuthAccountMode.register;
    });
  }

  Future<void> _continueWithGoogle() async {
    if (!FirebaseBootstrap.isConfigured) {
      widget.controller.setError(
        'Login Google belum aktif. Lengkapi konfigurasi Firebase dulu.',
      );
      return;
    }
    _lockFlowIfNeeded();
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
      await _finishAuthIfSuccessful();
    } on FirebaseAuthException catch (error) {
      widget.controller.setError(_googleError(error));
    } catch (_) {
      widget.controller.setError('Login Google gagal. Coba lagi.');
    } finally {
      _unlockFlowOnError();
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Future<void> _continueWithApple() async {
    setState(() => _appleBusy = true);
    widget.controller.setError(
      'Login Apple belum aktif. Aktifkan Apple di Firebase dan backend dulu.',
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (mounted) setState(() => _appleBusy = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _lockFlowIfNeeded();
    final isRegistering = _mode == AuthAccountMode.register;
    if (_mode == AuthAccountMode.login) {
      await widget.controller.loginWithEmail(_email.text, _password.text);
    } else if (_mode == AuthAccountMode.register) {
      await widget.controller.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        gradeLevel: _registerGradeLevel,
      );
    } else {
      await widget.controller.loginWithCode(_code.text);
    }
    if (isRegistering &&
        widget.controller.errorMessage == null &&
        widget.controller.user != null &&
        mounted) {
      await _showRegisterSuccessDialog();
    }
    await _finishAuthIfSuccessful();
    _unlockFlowOnError();
  }

  Future<void> _showRegisterSuccessDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 112,
                height: 136,
                child: Image.asset(
                  'assets/mascot/splash.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Akun berhasil dibuat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: BaleColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Progres belajarmu sudah tersimpan. Sekarang lanjut ke cek awal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF7A8796),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: BaleColors.warning,
                  foregroundColor: BaleColors.ink,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
                child: const Text('LANJUT'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _lockFlowIfNeeded() {
    if (widget.keepFlowAfterAuth) {
      widget.onAuthFlowLockChanged?.call(true);
    }
  }

  void _unlockFlowOnError() {
    if (widget.keepFlowAfterAuth && widget.controller.errorMessage != null) {
      widget.onAuthFlowLockChanged?.call(false);
    }
  }

  Future<void> _finishAuthIfSuccessful() async {
    if (widget.controller.errorMessage != null ||
        widget.controller.user == null) {
      return;
    }
    await widget.onAuthenticated?.call();
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

  int _normalizedGrade(int grade) {
    return grade >= 7 && grade <= 12 ? grade : 10;
  }

  int? get _registerGradeLevel {
    return _grade >= 10 && _grade <= 12 ? _grade : null;
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

class _MiniBrand extends StatelessWidget {
  const _MiniBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: BaleColors.warning,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 22,
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

class _LoginMascot extends StatelessWidget {
  const _LoginMascot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size * 1.22,
        child: Image.asset(
          'assets/mascot/login.png',
          fit: BoxFit.contain,
          semanticLabel: 'Maskot login Bale Belajar',
        ),
      ),
    );
  }
}

class _GoogleLoginButton extends StatelessWidget {
  const _GoogleLoginButton({
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
        minimumSize: const Size.fromHeight(50),
        backgroundColor: Colors.white,
        foregroundColor: BaleColors.ink,
        side: const BorderSide(color: BaleColors.line, width: 2),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
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
            const Text(
              'G',
              style: TextStyle(
                color: BaleColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          const SizedBox(width: 12),
          const Text('LANJUTKAN DENGAN GOOGLE'),
        ],
      ),
    );
  }
}

class _AppleLoginButton extends StatelessWidget {
  const _AppleLoginButton({
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
        minimumSize: const Size.fromHeight(50),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        side: const BorderSide(color: BaleColors.line, width: 2),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
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
            const Icon(Icons.apple_rounded, size: 22),
          const SizedBox(width: 12),
          const Text('LANJUTKAN DENGAN APPLE'),
        ],
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

class _AccountField extends StatelessWidget {
  const _AccountField({
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
          borderSide: const BorderSide(color: BaleColors.warning, width: 2),
        ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.prefix,
    required this.action,
    required this.onPressed,
  });

  final String prefix;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prefix,
          style: const TextStyle(
            color: Color(0xFF7A8796),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 34),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          onPressed: onPressed,
          child: Text(action),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: BaleColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BaleColors.danger.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: BaleColors.danger,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
