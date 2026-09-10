import 'package:flutter/foundation.dart';

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
    int? gradeLevel,
  }) async {
    final data = await apiClient.post('/auth/register', body: {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      if (gradeLevel != null) 'gradeLevel': gradeLevel,
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

  /// Simpan jawaban 7 pertanyaan onboarding ke backend REAL yang
  /// authenticated (`PUT /student/onboarding/answers`) - beda dari
  /// `savePrototypeOnboarding` di bawah yang menulis ke modul prototype
  /// tanpa auth. Field payload-nya (learningGoal/learningWorld/dst) sudah
  /// cocok persis dengan `SaveOnboardingDto` di backend.
  Future<void> saveOnboardingAnswers(Map<String, dynamic> answers) async {
    await apiClient.put('/student/onboarding/answers', body: answers);
  }

  Future<void> finishOnboarding(Map<String, dynamic> answers) async {
    await apiClient.post('/student/onboarding/complete', body: answers);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await apiClient.post(
      '/auth/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> logout() async {
    try {
      await apiClient.post('/auth/logout');
    } finally {
      await tokenStore.clear();
    }
  }

  Future<String> startPrototypeSession() async {
    _assertPrototypeAllowed();
    final data = await apiClient.post('/prototype/student/session');
    final json = data as Map<String, dynamic>;
    return json['studentProfileId'] as String;
  }

  Future<void> savePrototypeOnboarding({
    required String studentProfileId,
    required Map<String, dynamic> answers,
    bool complete = false,
  }) async {
    _assertPrototypeAllowed();
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
    _assertPrototypeAllowed();
    final suffix = worldKey == null ? '' : '?worldKey=$worldKey';
    final data = await apiClient.post(
      '/prototype/student/$studentProfileId/placement/start$suffix',
    );
    final json = data as Map<String, dynamic>;
    return json['attemptId'] as String;
  }

  Future<String> startPlacement({String? worldKey}) async {
    final data = await apiClient.post(
      '/student/placement/start',
      body: {
        if (worldKey != null) 'worldKey': worldKey,
      },
    );
    final json = data as Map<String, dynamic>;
    return ((json['attempt'] as Map<String, dynamic>)['id']) as String;
  }

  Future<List<Map<String, dynamic>>> getPrototypePlacementQuestions({
    required String studentProfileId,
  }) async {
    _assertPrototypeAllowed();
    final data = await apiClient.get(
      '/prototype/student/$studentProfileId/placement/questions',
    );
    final json = data as Map<String, dynamic>;
    return (json['questions'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getPlacementQuestions() async {
    final data = await apiClient.get('/student/placement/questions');
    final json = data as Map<String, dynamic>;
    return (json['questions'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getPrototypeBaleVerse({
    required String studentProfileId,
  }) async {
    _assertPrototypeAllowed();
    final data = await apiClient.get(
      '/prototype/student/$studentProfileId/baleverse',
    );
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBaleVerse() async {
    final data = await apiClient.get('/student/baleverse');
    return data as Map<String, dynamic>;
  }

  Future<void> savePlacementAnswer({
    required String attemptId,
    required String questionId,
    required String questionType,
    required Map<String, dynamic> answer,
    bool skipped = false,
  }) async {
    await apiClient.put(
      '/student/placement/$attemptId/answers/$questionId',
      body: {
        'questionType': questionType,
        'answer': answer,
        'isSkipped': skipped,
        'clientAnsweredAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> skipPlacementAnswer({
    required String attemptId,
    required String questionId,
    required String questionType,
  }) async {
    await apiClient.post(
      '/student/placement/$attemptId/skip/$questionId?questionType=$questionType',
    );
  }

  Future<void> submitPlacement(String attemptId) async {
    await apiClient.post('/student/placement/$attemptId/submit');
  }

  Future<void> savePrototypePlacementAnswer({
    required String attemptId,
    required String questionId,
    required String questionType,
    required Map<String, dynamic> answer,
    bool skipped = false,
  }) async {
    _assertPrototypeAllowed();
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
    _assertPrototypeAllowed();
    await apiClient.post(
      '/prototype/student/placement/$attemptId/skip/$questionId?questionType=$questionType',
    );
  }

  Future<void> submitPrototypePlacement(String attemptId) async {
    _assertPrototypeAllowed();
    await apiClient.post('/prototype/student/placement/$attemptId/submit');
  }

  void _assertPrototypeAllowed() {
    if (kReleaseMode) {
      throw UnsupportedError('Prototype endpoints are disabled in release.');
    }
  }

  Future<AuthSession> _persist(AuthSession session) async {
    await tokenStore.save(session.accessToken);
    return session;
  }
}
