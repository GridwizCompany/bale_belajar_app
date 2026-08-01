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

  Future<String> startPrototypeSession() async {
    final data = await apiClient.post('/prototype/student/session');
    final json = data as Map<String, dynamic>;
    return json['studentProfileId'] as String;
  }

  Future<void> savePrototypeOnboarding({
    required String studentProfileId,
    required Map<String, dynamic> answers,
    bool complete = false,
  }) async {
    if (complete) {
      await apiClient.post(
        '/prototype/student/$studentProfileId/onboarding/complete',
        body: answers,
      );
      return;
    }
    await apiClient.put(
      '/prototype/student/$studentProfileId/onboarding',
      body: answers,
    );
  }

  Future<String> startPrototypePlacement({
    required String studentProfileId,
    String? worldKey,
  }) async {
    final suffix = worldKey == null ? '' : '?worldKey=$worldKey';
    final data = await apiClient.post(
      '/prototype/student/$studentProfileId/placement/start$suffix',
    );
    final json = data as Map<String, dynamic>;
    return json['attemptId'] as String;
  }

  Future<List<Map<String, dynamic>>> getPrototypePlacementQuestions({
    required String studentProfileId,
  }) async {
    final data = await apiClient.get(
      '/prototype/student/$studentProfileId/placement/questions',
    );
    final json = data as Map<String, dynamic>;
    return (json['questions'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getPrototypeBaleVerse({
    required String studentProfileId,
  }) async {
    final data = await apiClient.get(
      '/prototype/student/$studentProfileId/baleverse',
    );
    return data as Map<String, dynamic>;
  }

  Future<void> savePrototypePlacementAnswer({
    required String attemptId,
    required String questionId,
    required String questionType,
    required Map<String, dynamic> answer,
    bool skipped = false,
  }) async {
    await apiClient.put(
      '/prototype/student/placement/$attemptId/answers/$questionId',
      body: {
        'questionType': questionType,
        'answer': answer,
        'isSkipped': skipped,
        'clientAnsweredAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> skipPrototypePlacementAnswer({
    required String attemptId,
    required String questionId,
    required String questionType,
  }) async {
    await apiClient.post(
      '/prototype/student/placement/$attemptId/skip/$questionId?questionType=$questionType',
    );
  }

  Future<void> submitPrototypePlacement(String attemptId) async {
    await apiClient.post('/prototype/student/placement/$attemptId/submit');
  }

  Future<AuthSession> _persist(AuthSession session) async {
    await tokenStore.save(session.accessToken);
    return session;
  }
}
