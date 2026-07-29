import '../../../core/api/api_client.dart';
import '../../../core/auth/token_store.dart';
import '../domain/auth_models.dart';

class AuthService {
  AuthService({required this.apiClient, required this.tokenStore});

  final ApiClient apiClient;
  final TokenStore tokenStore;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await apiClient.post('/auth/login', body: {
      'email': email.trim(),
      'password': password,
    });
    return _persist(AuthSession.fromJson(data as Map<String, dynamic>));
  }

  Future<AuthSession> registerStudent({
    required String name,
    required String email,
    required String password,
    required int gradeLevel,
  }) async {
    final data = await apiClient.post('/auth/register', body: {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'gradeLevel': gradeLevel,
    });
    return _persist(AuthSession.fromJson(data as Map<String, dynamic>));
  }

  Future<AuthSession> loginWithParticipantCode(String code) async {
    final data = await apiClient.post('/auth/student-login', body: {
      'participantCode': code.trim().toUpperCase(),
    });
    return _persist(AuthSession.fromJson(data as Map<String, dynamic>));
  }

  Future<AuthSession> loginWithGoogle(String idToken) async {
    final data = await apiClient.post('/auth/google', body: {
      'idToken': idToken,
    });
    return _persist(AuthSession.fromJson(data as Map<String, dynamic>));
  }

  Future<AuthUser> me() async {
    final data = await apiClient.get('/auth/me');
    return AuthUser.fromJson(data as Map<String, dynamic>);
  }

  Future<AuthUser> updateStudentProfile({
    required String fullName,
    required int gradeLevel,
    required CareerPath careerPath,
  }) async {
    await apiClient.patch('/student/account/profile', body: {
      'fullName': fullName.trim(),
      'gradeLevel': gradeLevel,
      'careerPath': careerPath.payload,
    });
    return me();
  }

  Future<void> logout() async {
    try {
      await apiClient.post('/auth/logout');
    } finally {
      await tokenStore.clear();
    }
  }

  Future<AuthSession> _persist(AuthSession session) async {
    await tokenStore.save(session.accessToken);
    return session;
  }
}
