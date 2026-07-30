import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/token_store.dart';
import '../../baleverse/presentation/baleverse_demo_screen.dart';
import '../application/auth_controller.dart';
import '../data/auth_service.dart';
import 'onboarding_screen.dart';
import 'signed_out_flow.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({this.controller, super.key});

  final AuthController? controller;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? _buildController();
    _controller.initialize();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return switch (_controller.status) {
            AuthStatus.checking => const _LoadingScreen(),
            AuthStatus.signedOut => SignedOutFlow(
                key: const ValueKey('signed-out-onboarding'),
                controller: _controller,
              ),
            AuthStatus.onboarding => OnboardingScreen(controller: _controller),
            AuthStatus.signedIn => BaleVerseDemoScreen(
                skipDemoLogin: true,
                authController: _controller,
              ),
          };
        },
      ),
    );
  }

  AuthController _buildController() {
    late final ApiClient apiClient;
    const tokenStore = SecureTokenStore();
    apiClient = ApiClient(tokenProvider: tokenStore.read);
    return AuthController(
      authService: AuthService(apiClient: apiClient, tokenStore: tokenStore),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
