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
  QuestAttemptController({
    required this.worldKey,
    this.requestNext = false,
    QuestRepository? repository,
  }) : _repository = repository ?? QuestRepository();

  final String worldKey;
  // true = ambil misi TAMBAHAN hari ini (POST /student/quests/next) alih-alih
  // misi utama hari ini (GET /student/quests/today) - dipakai tombol "Misi
  // Lagi" di WorldCurriculumScreen setelah StudentQuestSetting.dailyQuestCount
  // mengizinkan lebih dari 1 misi/hari.
  final bool requestNext;
  final QuestRepository _repository;

  QuestLoadStatus status = QuestLoadStatus.loading;
  String? errorMessage;
  bool isSavingAnswer = false;
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
      final summary = requestNext
          ? await _repository.requestNextQuest(worldKey)
          : await _repository.getTodayQuest(worldKey);
      var attemptId = summary.attemptId;
      quest = summary;
      _attemptId = attemptId;
      currentIndex = 0;
      if (attemptId != null && summary.attemptStatus == 'SUBMITTED') {
        result = await _repository.getResult(attemptId);
        status = QuestLoadStatus.submitted;
        notifyListeners();
        return;
      }
      attemptId ??= await _repository.startAttempt(summary.assignmentId);
      _attemptId = attemptId;
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
    isSavingAnswer = true;
    errorMessage = null;
    notifyListeners();

    final attemptId = _attemptId;
    if (attemptId != null) {
      var saved = false;
      try {
        await _repository.saveAnswer(
          attemptId: attemptId,
          questionId: question.id as String,
          payload: payload,
        );
        saved = true;
      } catch (_) {
        try {
          await _repository.saveAnswer(
            attemptId: attemptId,
            questionId: question.id as String,
            payload: payload,
          );
          saved = true;
        } catch (error) {
          errorMessage =
              'Jawaban belum tersimpan. Cek koneksi lalu tekan tombol jawab lagi.';
        }
      }
      if (!saved) {
        isSavingAnswer = false;
        notifyListeners();
        return;
      }
    }

    isSavingAnswer = false;
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
      errorMessage =
          'Jawaban tersimpan, tapi submit belum berhasil. Coba kirim lagi.';
      status = QuestLoadStatus.ready;
    }
    notifyListeners();
  }
}
