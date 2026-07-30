import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/bale_theme.dart';

class AuthOnboardingLandingScreen extends StatefulWidget {
  const AuthOnboardingLandingScreen({
    required this.onGetStarted,
    required this.onAlreadyHaveAccount,
    super.key,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onAlreadyHaveAccount;

  @override
  State<AuthOnboardingLandingScreen> createState() =>
      _AuthOnboardingLandingScreenState();
}

class _AuthOnboardingLandingScreenState
    extends State<AuthOnboardingLandingScreen>
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Column(
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
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: BaleColors.ink,
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
                          _LandingPrimaryButton(
                            label: 'GET STARTED',
                            onPressed: widget.onGetStarted,
                          ),
                          const SizedBox(height: 12),
                          _LandingOutlineButton(
                            label: 'I ALREADY HAVE AN ACCOUNT',
                            onPressed: widget.onAlreadyHaveAccount,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
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

class _LandingPrimaryButton extends StatelessWidget {
  const _LandingPrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        backgroundColor: BaleColors.warning,
        foregroundColor: BaleColors.ink,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        elevation: 4,
        shadowColor: const Color(0x55F4B400),
      ),
      child: Text(label),
    );
  }
}

class _LandingOutlineButton extends StatelessWidget {
  const _LandingOutlineButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        backgroundColor: Colors.white,
        foregroundColor: BaleColors.ink,
        side: const BorderSide(color: BaleColors.line, width: 2),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
      child: Text(label),
    );
  }
}
