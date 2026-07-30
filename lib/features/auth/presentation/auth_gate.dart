import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/token_store.dart';
import '../../../theme/bale_theme.dart';
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
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? _buildController();
    _controller.initialize();
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _splashDone = true);
    });
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
          if (!_splashDone || _controller.status == AuthStatus.checking) {
            return const BaleSplashScreen();
          }
          return switch (_controller.status) {
            AuthStatus.checking => const BaleSplashScreen(),
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

class BaleSplashScreen extends StatelessWidget {
  const BaleSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final mascotSize = shortestSide.clamp(260.0, 360.0);

    return Scaffold(
      backgroundColor: BaleColors.warning,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
          child: Column(
            children: [
              const Spacer(flex: 5),
              SizedBox(
                width: mascotSize,
                height: mascotSize,
                child: Image.asset(
                  'assets/mascot/splash.png',
                  fit: BoxFit.contain,
                  semanticLabel: 'Maskot splash Bale Belajar',
                ),
              ),
              const Spacer(flex: 4),
              const _SplashBrand(),
              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashBrand extends StatelessWidget {
  const _SplashBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.school_rounded, color: Colors.white, size: 42),
        const SizedBox(width: 12),
        Text(
          'balebelajar',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}
