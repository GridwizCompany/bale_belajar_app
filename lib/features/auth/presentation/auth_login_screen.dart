import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final mascotSize = screenHeight < 700 ? 136.0 : 166.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
              child: Column(
                children: [
                  SizedBox(height: screenHeight < 700 ? 18 : 42),
                  const _MiniBrand(),
                  const SizedBox(height: 10),
                  _LoginMascot(size: mascotSize),
                  const SizedBox(height: 8),
                  Text(
                    'Selamat datang kembali!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 22,
                          color: BaleColors.ink,
                        ),
                  ),
                  const SizedBox(height: 14),
                  _GoogleLoginButton(
                    loading: _googleBusy,
                    disabled: widget.controller.isBusy,
                    onPressed: _continueWithGoogle,
                  ),
                  const SizedBox(height: 10),
                  const _DividerLabel(label: 'atau'),
                  const SizedBox(height: 10),
                  _LoginField(
                    controller: _email,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
                  _LoginField(
                    controller: _password,
                    label: 'Password',
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
                    const SizedBox(height: 8),
                    _ErrorBanner(message: widget.controller.errorMessage!),
                  ],
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: widget.controller.isBusy || _googleBusy
                        ? null
                        : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: BaleColors.warning,
                      foregroundColor: BaleColors.ink,
                      textStyle: const TextStyle(
                        fontSize: 15,
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
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(
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
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: BaleColors.warning,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.menu_book_rounded,
              color: Colors.white, size: 18),
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
    return SizedBox(
      width: size,
      height: size * 1.22,
      child: Image.asset(
        'assets/mascot/login.png',
        fit: BoxFit.contain,
        semanticLabel: 'Maskot login Bale Belajar',
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

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: BaleColors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7A8796),
              fontSize: 13,
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
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
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
