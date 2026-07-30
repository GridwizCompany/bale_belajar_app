import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../shared/widgets/belo_mascot.dart';
import '../../../theme/bale_theme.dart';
import '../application/auth_controller.dart';

class AuthLoginScreen extends StatefulWidget {
  const AuthLoginScreen({
    required this.controller,
    required this.onBack,
    required this.onRegister,
    super.key,
  });

  final AuthController controller;
  final VoidCallback onBack;
  final VoidCallback onRegister;

  @override
  State<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends State<AuthLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _googleBusy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              children: [
                const SizedBox(height: 16),
                const _MiniBrand(),
                const SizedBox(height: 24),
                const Center(
                  child: BeloMascot(
                    pose: BeloPose.kedip,
                    size: 136,
                    animate: true,
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
                _GoogleLoginButton(
                  loading: _googleBusy,
                  disabled: widget.controller.isBusy,
                  onPressed: _continueWithGoogle,
                ),
                const SizedBox(height: 20),
                const _DividerLabel(label: 'atau'),
                const SizedBox(height: 20),
                _LoginField(
                  controller: _email,
                  label: 'Email',
                  icon: Icons.mail_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _LoginField(
                  controller: _password,
                  label: 'Password',
                  icon: Icons.lock_rounded,
                  obscureText: !_showPassword,
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
                if (widget.controller.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(message: widget.controller.errorMessage!),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed:
                      widget.controller.isBusy || _googleBusy ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    backgroundColor: BaleColors.warning,
                    foregroundColor: BaleColors.ink,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                    elevation: 4,
                    shadowColor: const Color(0x55F4B400),
                  ),
                  child: widget.controller.isBusy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('MASUK'),
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
                      onPressed: widget.controller.isBusy || _googleBusy
                          ? null
                          : widget.onRegister,
                      child: const Text('DAFTAR'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || !email.contains('@') || password.length < 8) {
      widget.controller.setError('Isi email dan password dengan benar.');
      return;
    }
    FocusScope.of(context).unfocus();
    await widget.controller.loginWithEmail(email, password);
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
        minimumSize: const Size.fromHeight(56),
        backgroundColor: Colors.white,
        foregroundColor: BaleColors.ink,
        side: const BorderSide(color: BaleColors.line, width: 2),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
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

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: BaleColors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7A8796),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Expanded(child: Divider(color: BaleColors.line)),
      ],
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
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
