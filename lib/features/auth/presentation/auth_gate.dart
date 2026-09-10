import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/token_store.dart';
import '../../../theme/bale_theme.dart';
import '../../baleverse/presentation/baleverse_demo_screen.dart';
import '../../vocab/application/vocab_sync_service.dart';
import '../../vocab/presentation/vocab_permission_gate_screen.dart';
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

  // Status gate izin notifikasi/widget kosakata. Dievaluasi ulang SETIAP kali
  // status berubah jadi signedIn (login baru maupun sesi lama yang sudah
  // tersimpan) - bukan cuma sekali seumur install - supaya user yang belum
  // kasih izin terus "ditagih" tiap sesi baru sampai dia benar-benar
  // mengizinkan atau memilih lewati (lihat VocabPermissionGateScreen).
  bool _vocabGateResolved = false;
  bool _vocabGateNeedsNotification = false;
  bool _vocabGateNeedsWidget = false;
  bool _vocabGateDismissedThisSession = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? _buildController();
    _controller.addListener(_handleAuthStatusChange);
    _controller.initialize();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_handleAuthStatusChange);
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

  void _handleAuthStatusChange() {
    if (_controller.status != AuthStatus.signedIn) {
      // Reset supaya kalau user logout lalu login lagi (akun sama atau
      // beda), gate dievaluasi ulang dari nol untuk sesi baru itu.
      _vocabGateResolved = false;
      _vocabGateDismissedThisSession = false;
      return;
    }
    if (_vocabGateResolved) return;
    unawaited(_evaluateVocabGate());
  }

  // Dipanggil setiap sesi signedIn baru (login baru ATAU akun/sesi yang
  // sudah ada) - sync kosakata dulu (untuk tahu notificationEnabled/
  // widgetEnabled terbaru dari akun ini), lalu cek status izin OS yang
  // sesungguhnya, baru putuskan perlu tampilkan gate atau tidak.
  Future<void> _evaluateVocabGate() async {
    final daily = await _vocabSyncService.syncToday(force: true);
    final notifStatus = await _vocabSyncService.notificationPermissionStatus();
    final widgetPinned = await _vocabSyncService.isWidgetPinned();
    if (!mounted) return;
    setState(() {
      _vocabGateNeedsNotification =
          (daily?.setting.notificationEnabled ?? true) && !notifStatus.isGranted;
      _vocabGateNeedsWidget =
          (daily?.setting.widgetEnabled ?? true) && !widgetPinned;
      _vocabGateResolved = true;
    });
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
            AuthStatus.signedIn => _buildSignedInFlow(),
          };
        },
      ),
    );
  }

  Widget _buildSignedInFlow() {
    if (!_vocabGateResolved) {
      // Sedang evaluasi izin notifikasi/widget - tahan sebentar di splash
      // daripada kelap-kelip nampilin dashboard lalu langsung ketutup gate.
      return const BaleSplashScreen();
    }
    final needsGate =
        (_vocabGateNeedsNotification || _vocabGateNeedsWidget) &&
            !_vocabGateDismissedThisSession;
    if (needsGate) {
      return VocabPermissionGateScreen(
        needsNotification: _vocabGateNeedsNotification,
        needsWidget: _vocabGateNeedsWidget,
        onContinue: () => setState(() => _vocabGateDismissedThisSession = true),
      );
    }
    return BaleVerseDemoScreen(
      skipDemoLogin: true,
      authController: _controller,
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
