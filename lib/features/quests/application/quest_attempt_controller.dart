import 'package:flutter/foundation.dart';

import '../data/quest_repository.dart';
import '../domain/quest_models.dart';

enum QuestLoadStatus { loading, ready, submitting, submitted, error }

/// State holder untuk satu sesi mengerjakan Quest - pola tangan
/// (ChangeNotifier) yang sama seperti BaleVerseProgressService, karena app
/// ini memang tidak pakai Provider/Riverpod di level manapun.
///
/// Jawaban disimpan TERSTRUKTUR per tipe soal (`Map<String,dynamic>` payload),
/// bukan di-toString() seperti bug yang ditemukan di alur placement test
/// lama (`simple_auth_screen.dart`) - supaya matching/ordering/hotspot/dst
/// terkirim dengan bentuk yang benar ke backend.
class QuestAttemptController extends ChangeNotifier {
  QuestAttemptController({required this.worldKey, QuestRepository? repository})
      : _repository = repository ?? QuestRepository();

  final String worldKey;
  final QuestRepository _repository;

  QuestLoadStatus status = QuestLoadStatus.loading;
  String? errorMessage;
  QuestSummary? quest;
  String? _attemptId;
  int currentIndex = 0;
  final Map<String, Map<String, dynamic>> answers = {};
  QuestSubmitResult? result;

  int get totalQuestions => quest?.questions.length ?? 0;
  bool get isLastQuestion => currentIndex >= totalQuestions - 1;
  dynamic get currentQuestion => quest!.questions[currentIndex];

  Future<void> load() async {
    status = QuestLoadStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final summary = await _repository.getTodayQuest(worldKey);
      var attemptId = summary.attemptId;
      attemptId ??= await _repository.startAttempt(summary.assignmentId);
      quest = summary;
      _attemptId = attemptId;
      currentIndex = 0;
      status = QuestLoadStatus.ready;
    } catch (error) {
      errorMessage = error.toString();
      status = QuestLoadStatus.error;
    }
    notifyListeners();
  }

  /// Simpan jawaban soal saat ini lalu maju ke soal berikutnya, atau submit
  /// kalau ini soal terakhir.
  Future<void> answerCurrentAndAdvance(Map<String, dynamic> payload) async {
    final question = currentQuestion;
    answers[question.id as String] = payload;
    notifyListeners();

    final attemptId = _attemptId;
    if (attemptId != null) {
      try {
        await _repository.saveAnswer(
          attemptId: attemptId,
          questionId: question.id as String,
          payload: payload,
        );
      } catch (_) {
        // Autosave best-effort: coba sekali lagi, kalau tetap gagal jawaban
        // tetap ada di `answers` lokal (ditampilkan ke siswa), tapi tidak
        // akan ikut ternilai server sampai berhasil ter-PUT.
        try {
          await _repository.saveAnswer(
            attemptId: attemptId,
            questionId: question.id as String,
            payload: payload,
          );
        } catch (_) {}
      }
    }

    if (isLastQuestion) {
      await submit();
    } else {
      currentIndex += 1;
      notifyListeners();
    }
  }

  Future<void> submit() async {
    final attemptId = _attemptId;
    if (attemptId == null) return;
    status = QuestLoadStatus.submitting;
    notifyListeners();
    try {
      result = await _repository.submitAttempt(attemptId);
      status = QuestLoadStatus.submitted;
    } catch (error) {
      errorMessage = error.toString();
      status = QuestLoadStatus.ready;
    }
    notifyListeners();
  }
}
