import '../../../core/api/api_client.dart';
import '../../../core/auth/token_store.dart';
import '../domain/quest_models.dart';

/// Panggil 5 endpoint `student-quests` di backend - lihat
/// `BALE_BELAJAR_BE/src/modules/student-quests`.
class QuestRepository {
  QuestRepository({ApiClient? apiClient})
      : _apiClient =
            apiClient ?? ApiClient(tokenProvider: const SecureTokenStore().read);

  final ApiClient _apiClient;

  Future<QuestSummary> getTodayQuest(String worldKey) async {
    final data = await _apiClient.get(
      '/student/quests/today',
      query: {'worldKey': worldKey},
    );
    return QuestSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<String> startAttempt(String assignmentId) async {
    final data = await _apiClient.post('/student/quests/$assignmentId/start');
    return (data as Map<String, dynamic>)['id'] as String;
  }

  Future<void> saveAnswer({
    required String attemptId,
    required String questionId,
    required Map<String, dynamic> payload,
  }) {
    return _apiClient.put(
      '/student/quest-attempts/$attemptId/answers/$questionId',
      body: {'payload': payload},
    );
  }

  Future<QuestSubmitResult> submitAttempt(String attemptId) async {
    final data = await _apiClient.post('/student/quest-attempts/$attemptId/submit');
    return QuestSubmitResult.fromJson(data as Map<String, dynamic>);
  }

  Future<QuestSubmitResult> getResult(String attemptId) async {
    final data = await _apiClient.get('/student/quest-attempts/$attemptId/result');
    return QuestSubmitResult.fromJson(data as Map<String, dynamic>);
  }
}
