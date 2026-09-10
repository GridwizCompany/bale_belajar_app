import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/token_store.dart';
import '../../../theme/bale_theme.dart';
import '../../baleverse/presentation/baleverse_demo_screen.dart';
import '../../vocab/application/vocab_sync_service.dart';
import '../application/auth_controller.dart';
import '../data/auth_service.dart';
import 'signed_out_flow.dart';
import 'simple_auth_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({this.controller, super.key});

  final AuthController? controller;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  late final AuthController _controller;
  final _vocabSyncService = VocabSyncService();
  bool _splashDone = false;
  bool _keepSignedOutFlow = false;
  bool _vocabSynced = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? _buildController();
    _controller.addListener(_maybeSyncVocab);
    _controller.initialize();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_maybeSyncVocab);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kalau app dibuka lagi di hari baru, ini yang membuat notifikasi/widget
    // ikut refresh (syncToday() sendiri no-op kalau hari ini sudah pernah
    // sync - lihat catatan di VocabSyncService soal keterbatasan ini).
    if (state == AppLifecycleState.resumed &&
        _controller.status == AuthStatus.signedIn) {
      unawaited(_vocabSyncService.syncToday());
    }
  }

  // Kosakata harian tidak punya proses background sendiri (lihat catatan di
  // VocabSyncService) - jadi disinkronkan sekali per sesi app di sini, begitu
  // siswa berhasil login/terautentikasi.
  void _maybeSyncVocab() {
    if (_vocabSynced || _controller.status != AuthStatus.signedIn) return;
    _vocabSynced = true;
    unawaited(_vocabSyncService.syncToday());
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
          if (_keepSignedOutFlow &&
              (_controller.status == AuthStatus.onboarding ||
                  _controller.status == AuthStatus.signedIn)) {
            return SignedOutFlow(
              key: const ValueKey('signed-out-onboarding'),
              controller: _controller,
              onAuthenticatedFlowLockChanged: (locked) {
                if (mounted) setState(() => _keepSignedOutFlow = locked);
              },
            );
          }
          return switch (_controller.status) {
            AuthStatus.checking => const BaleSplashScreen(),
            AuthStatus.signedOut => SignedOutFlow(
                key: const ValueKey('signed-out-onboarding'),
                controller: _controller,
                onAuthenticatedFlowLockChanged: (locked) {
                  if (mounted) setState(() => _keepSignedOutFlow = locked);
                },
              ),
            AuthStatus.onboarding => SimpleAuthScreen(
                key: const ValueKey('real-seven-question-onboarding'),
                controller: _controller,
                initialMode: AuthMode.register,
              ),
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
