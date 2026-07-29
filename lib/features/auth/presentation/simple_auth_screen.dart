import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../shared/widgets/bale_card.dart';
import '../../../theme/bale_theme.dart';
import '../application/auth_controller.dart';

enum AuthMode { login, register, code }

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
  AuthMode _mode = AuthMode.login;
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
    final compact = MediaQuery.sizeOf(context).width < 760;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: compact
                  ? ListView(
                      children: [
                        const _BrandPanel(compact: true),
                        const SizedBox(height: 14),
                        _AuthCard(
                            controller: widget.controller, child: _form()),
                      ],
                    )
                  : Row(
                      children: [
                        const Expanded(child: _BrandPanel()),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _AuthCard(
                            controller: widget.controller,
                            child: _form(),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(_helper),
          const SizedBox(height: 18),
          if (_mode != AuthMode.code) ...[
            _GoogleButton(
              loading: _googleBusy,
              disabled: widget.controller.isBusy,
              onPressed: _continueWithGoogle,
            ),
            const SizedBox(height: 16),
            const _DividerLabel(label: 'atau pakai email'),
            const SizedBox(height: 16),
          ],
          SegmentedButton<AuthMode>(
            segments: const [
              ButtonSegment(value: AuthMode.login, label: Text('Masuk')),
              ButtonSegment(value: AuthMode.register, label: Text('Daftar')),
              ButtonSegment(value: AuthMode.code, label: Text('Kode')),
            ],
            selected: {_mode},
            onSelectionChanged: widget.controller.isBusy || _googleBusy
                ? null
                : (value) => setState(() => _mode = value.first),
          ),
          const SizedBox(height: 16),
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
                tooltip:
                    _showPassword ? 'Sembunyikan password' : 'Lihat password',
                onPressed: () => setState(() => _showPassword = !_showPassword),
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
          FilledButton.icon(
            onPressed: widget.controller.isBusy || _googleBusy ? null : _submit,
            icon: widget.controller.isBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_buttonIcon),
            label: Text(_buttonLabel),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed:
                widget.controller.isBusy || _googleBusy ? null : _switchMode,
            child: Text(_switchLabel),
          ),
        ],
      ),
    );
  }

  String get _title => switch (_mode) {
        AuthMode.login => 'Selamat datang kembali',
        AuthMode.register => 'Buat akun belajar',
        AuthMode.code => 'Masuk dengan kode siswa',
      };

  String get _helper => switch (_mode) {
        AuthMode.login => 'Masuk untuk lanjut ke misi, progres, dan profilmu.',
        AuthMode.register =>
          'Daftar cepat. Setelah itu kamu bisa mengatur minat belajar.',
        AuthMode.code =>
          'Gunakan kode dari sekolah atau mentor untuk masuk sebagai siswa.',
      };

  String get _switchLabel => switch (_mode) {
        AuthMode.login => 'Belum punya akun? Daftar',
        AuthMode.register => 'Sudah punya akun? Masuk',
        AuthMode.code => 'Masuk pakai email',
      };

  IconData get _buttonIcon => switch (_mode) {
        AuthMode.login => Icons.login_rounded,
        AuthMode.register => Icons.person_add_alt_1_rounded,
        AuthMode.code => Icons.qr_code_2_rounded,
      };

  String get _buttonLabel => switch (_mode) {
        AuthMode.login => 'Masuk',
        AuthMode.register => 'Buat Akun',
        AuthMode.code => 'Masuk dengan Kode',
      };

  void _switchMode() {
    setState(() {
      _mode = switch (_mode) {
        AuthMode.login => AuthMode.register,
        AuthMode.register => AuthMode.login,
        AuthMode.code => AuthMode.login,
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
    } else {
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

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 28),
      decoration: BoxDecoration(
        color: BaleColors.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: BaleColors.success,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Colors.white),
          ),
          SizedBox(height: compact ? 16 : 28),
          Text(
            'BaleBelajar',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontSize: compact ? 28 : 34,
                ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Belajar lebih terarah dengan misi, mentor, dan progres yang mudah dipahami.',
            style: TextStyle(
              color: Color(0xFFDDE5F0),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 28),
            const _Benefit(
                icon: Icons.flag_rounded, label: 'Misi belajar bertahap'),
            const SizedBox(height: 12),
            const _Benefit(
                icon: Icons.groups_rounded, label: 'Bantuan mentor saat buntu'),
            const SizedBox(height: 12),
            const _Benefit(
                icon: Icons.insights_rounded, label: 'Progres siswa tersimpan'),
          ],
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: BaleColors.dayaBale),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.controller, required this.child});

  final AuthController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return BaleCard(
          padding: const EdgeInsets.all(22),
          child: child,
        );
      },
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
        minimumSize: const Size.fromHeight(54),
        side: const BorderSide(color: BaleColors.line, width: 2),
        backgroundColor: Colors.white,
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
        border: const OutlineInputBorder(),
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
