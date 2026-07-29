import 'package:flutter/material.dart';

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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                const _AuthHeader(),
                const SizedBox(height: 18),
                SegmentedButton<AuthMode>(
                  segments: const [
                    ButtonSegment(value: AuthMode.login, label: Text('Masuk')),
                    ButtonSegment(
                        value: AuthMode.register, label: Text('Daftar')),
                    ButtonSegment(value: AuthMode.code, label: Text('Kode')),
                  ],
                  selected: {_mode},
                  onSelectionChanged: widget.controller.isBusy
                      ? null
                      : (value) => setState(() => _mode = value.first),
                ),
                const SizedBox(height: 14),
                BaleCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(_helper),
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
                              tooltip: _showPassword
                                  ? 'Sembunyikan password'
                                  : 'Lihat password',
                              onPressed: () {
                                setState(() => _showPassword = !_showPassword);
                              },
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
                              DropdownMenuItem(
                                  value: 10, child: Text('Kelas 10')),
                              DropdownMenuItem(
                                  value: 11, child: Text('Kelas 11')),
                              DropdownMenuItem(
                                  value: 12, child: Text('Kelas 12')),
                            ],
                            onChanged: (value) {
                              if (value != null) setState(() => _grade = value);
                            },
                          ),
                        ],
                        if (widget.controller.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          _ErrorBanner(
                              message: widget.controller.errorMessage!),
                        ],
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: widget.controller.isBusy ? null : _submit,
                          icon: widget.controller.isBusy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(_buttonIcon),
                          label: Text(_buttonLabel),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed:
                              widget.controller.isBusy ? null : _switchMode,
                          child: Text(_switchLabel),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _title => switch (_mode) {
        AuthMode.login => 'Masuk ke akun',
        AuthMode.register => 'Buat akun siswa',
        AuthMode.code => 'Masuk pakai kode',
      };

  String get _helper => switch (_mode) {
        AuthMode.login => 'Pakai email dan password yang sudah terdaftar.',
        AuthMode.register =>
          'Isi data dasar dulu. Profil belajar bisa dilengkapi setelah ini.',
        AuthMode.code => 'Masukkan kode peserta dari sekolah atau mentor.',
      };

  String get _switchLabel => switch (_mode) {
        AuthMode.login => 'Belum punya akun? Daftar',
        AuthMode.register => 'Sudah punya akun? Masuk',
        AuthMode.code => 'Masuk pakai email',
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
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: BaleColors.success,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.menu_book_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BaleBelajar',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              Text(
                'Masuk, daftar, atau pakai kode siswa.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
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
