import 'package:flutter/material.dart';

import '../application/auth_controller.dart';
import 'auth_onboarding_landing_screen.dart';
import 'simple_auth_screen.dart';

class SignedOutFlow extends StatefulWidget {
  const SignedOutFlow({required this.controller, super.key});

  final AuthController controller;

  @override
  State<SignedOutFlow> createState() => _SignedOutFlowState();
}

class _SignedOutFlowState extends State<SignedOutFlow> {
  AuthMode? _formMode;

  @override
  void reassemble() {
    super.reassemble();
    if (mounted) {
      setState(() => _formMode = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
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
            child: child,
          ),
        );
      },
      child: _formMode == null
          ? AuthOnboardingLandingScreen(
              key: const ValueKey('auth-onboarding-first'),
              onGetStarted: () => setState(() => _formMode = AuthMode.register),
              onAlreadyHaveAccount: () =>
                  setState(() => _formMode = AuthMode.login),
            )
          : SimpleAuthScreen(
              key: ValueKey('auth-form-${_formMode!.name}'),
              controller: widget.controller,
              initialMode: _formMode!,
              onBackToLanding: () => setState(() => _formMode = null),
            ),
    );
  }
}
