import 'package:flutter/widgets.dart';

import '../../../core/api/api_client.dart';
import '../data/auth_service.dart';
import '../domain/auth_models.dart';

enum AuthStatus { checking, signedOut, onboarding, signedIn }

class AuthController extends ChangeNotifier {
  AuthController({required this.authService});

  final AuthService authService;

  AuthStatus status = AuthStatus.checking;
  AuthUser? user;
  String? errorMessage;
  bool isBusy = false;

  Future<void> initialize() async {
    status = AuthStatus.checking;
    notifyListeners();
    try {
      user = await authService.me();
      status = _statusFor(user);
    } on BaleApiException {
      status = AuthStatus.signedOut;
    } catch (_) {
      status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  Future<void> loginWithEmail(String email, String password) {
    return _run(() async {
      final session = await authService.login(email: email, password: password);
      user = session.user;
      user = await authService.me();
      status = _statusFor(user);
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required int gradeLevel,
  }) {
    return _run(() async {
      final session = await authService.registerStudent(
        name: name,
        email: email,
        password: password,
        gradeLevel: gradeLevel,
      );
      user = session.user;
      user = await authService.me();
      status = AuthStatus.onboarding;
    });
  }

  Future<void> loginWithCode(String code) {
    return _run(() async {
      final session = await authService.loginWithParticipantCode(code);
      user = session.user;
      user = await authService.me();
      status = _statusFor(user);
    });
  }

  Future<void> completeOnboarding({
    required String fullName,
    required int gradeLevel,
    required CareerPath careerPath,
  }) {
    return _run(() async {
      user = await authService.updateStudentProfile(
        fullName: fullName,
        gradeLevel: gradeLevel,
        careerPath: careerPath,
      );
      status = AuthStatus.signedIn;
    });
  }

  Future<void> signOut() {
    return _run(() async {
      await authService.logout();
      user = null;
      status = AuthStatus.signedOut;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on BaleApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Tidak bisa terhubung ke server.';
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  AuthStatus _statusFor(AuthUser? nextUser) {
    if (nextUser == null) return AuthStatus.signedOut;
    if (nextUser.hasStudentProfile && !nextUser.hasCompletedOnboarding) {
      return AuthStatus.onboarding;
    }
    return AuthStatus.signedIn;
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    required AuthController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found');
    return scope!.notifier!;
  }
}
