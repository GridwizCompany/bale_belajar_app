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
  bool _googleBusy = false;
  bool _appleBusy = false;

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
                    disabled: widget.controller.isBusy || _appleBusy,
                    onPressed: _continueWithGoogle,
                  ),
                  const SizedBox(height: 10),
                  _AppleLoginButton(
                    loading: _appleBusy,
                    disabled: widget.controller.isBusy || _googleBusy,
                    onPressed: _continueWithApple,
                  ),
                  if (widget.controller.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: widget.controller.errorMessage!),
                  ],
                  const SizedBox(height: 18),
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
                        onPressed: widget.controller.isBusy ||
                                _googleBusy ||
                                _appleBusy
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

  Future<void> _continueWithApple() async {
    setState(() => _appleBusy = true);
    widget.controller.setError(
      'Login Apple belum aktif. Aktifkan Apple di Firebase dan backend dulu.',
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (mounted) setState(() => _appleBusy = false);
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
