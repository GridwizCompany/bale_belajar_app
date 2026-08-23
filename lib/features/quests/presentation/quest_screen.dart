import 'package:flutter/material.dart';

import '../application/quest_attempt_controller.dart';
import '../domain/quest_models.dart';
import 'quest_question_view.dart';

const _questBg = Color(0xFFFFF3C6);
const _questInk = Color(0xFF3B2318);
const _questYellow = Color(0xFFF4B400);
const _questGreen = Color(0xFF4CAF50);

/// Alur lengkap mengerjakan satu Quest hari ini untuk sebuah Dunia
/// (dipakai pertama kali oleh Scientia) - ambil quest -> mulai attempt ->
/// jawab semua soal lewat [QuestQuestionView] -> submit -> tampilkan reward.
///
/// Sengaja dibuat sebagai fitur baru terpisah dari `mission_screen.dart`
/// (yang khusus 3-activity-type Numeria) supaya tidak mengganggu alur lama
/// yang sudah berjalan.
class QuestScreen extends StatefulWidget {
  const QuestScreen({required this.worldKey, super.key});

  final String worldKey;

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  late final QuestAttemptController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuestAttemptController(worldKey: widget.worldKey);
    _controller.addListener(_onChange);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    switch (_controller.status) {
      case QuestLoadStatus.loading:
        return const _QuestMessageScreen(
          message: 'Menyiapkan quest hari ini...',
          showProgress: true,
        );
      case QuestLoadStatus.error:
        return _QuestMessageScreen(
          message: _controller.errorMessage ?? 'Gagal memuat quest.',
          onRetry: _controller.load,
        );
      case QuestLoadStatus.submitting:
        return const _QuestMessageScreen(
          message: 'Mengirim jawabanmu...',
          showProgress: true,
        );
      case QuestLoadStatus.submitted:
        return _QuestRewardScreen(
          questTitle: _controller.quest?.title ?? 'Quest',
          result: _controller.result!,
          onDone: () => Navigator.of(context).pop(true),
        );
      case QuestLoadStatus.ready:
        return Stack(
          children: [
            QuestQuestionView(
              question: _controller.currentQuestion,
              currentQuestion: _controller.currentIndex + 1,
              totalQuestions: _controller.totalQuestions,
              onAnswered: _controller.answerCurrentAndAdvance,
            ),
            if (_controller.errorMessage != null)
              Positioned(
                left: 16,
                right: 16,
                top: MediaQuery.paddingOf(context).top + 12,
                child: _QuestErrorBanner(message: _controller.errorMessage!),
              ),
            if (_controller.isSavingAnswer)
              const Positioned.fill(
                child: _QuestSavingOverlay(),
              ),
          ],
        );
    }
  }
}

class _QuestErrorBanner extends StatelessWidget {
  const _QuestErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF6B6B), width: 1.3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Color(0xFFFF6B6B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: _questInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestSavingOverlay extends StatelessWidget {
  const _QuestSavingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Color(0x33000000),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width - 48,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: _questYellow,
                ),
              ),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Menyimpan jawaban...',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _questInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestMessageScreen extends StatelessWidget {
  const _QuestMessageScreen({
    required this.message,
    this.showProgress = false,
    this.onRetry,
  });

  final String message;
  final bool showProgress;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _questBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showProgress) ...[
                  const CircularProgressIndicator(color: _questYellow),
                  const SizedBox(height: 20),
                ],
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _questInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onRetry,
                    style:
                        FilledButton.styleFrom(backgroundColor: _questYellow),
                    child: const Text('Coba Lagi'),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestRewardScreen extends StatelessWidget {
  const _QuestRewardScreen({
    required this.questTitle,
    required this.result,
    required this.onDone,
  });

  final String questTitle;
  final QuestSubmitResult result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _questBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 12),
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: _questYellow,
                      size: 72,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Quest Selesai!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _questInk,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      questTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF60646F),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _RewardStat(
                            label: 'Skor',
                            value: '${result.overallScore.round()}',
                            color: _questGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RewardStat(
                            label: 'XP',
                            value: '+${result.xpGained}',
                            color: _questYellow,
                          ),
                        ),
                      ],
                    ),
                    if (result.accountLeveledUp || result.worldLeveledUp) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Naik level!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _questInk,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _LearningFeedback(result: result),
                    const SizedBox(height: 12),
                    _QuestionResultList(result: result),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(
                    backgroundColor: _questGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Kembali ke Materi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionResultList extends StatelessWidget {
  const _QuestionResultList({required this.result});

  final QuestSubmitResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE0A1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_rounded, color: _questGreen),
              SizedBox(width: 8),
              Text(
                'Hasil Tiap Soal',
                style: TextStyle(
                  color: _questInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final entry in result.questions.asMap().entries) ...[
            _QuestionResultTile(
              number: entry.key + 1,
              question: entry.value,
            ),
            if (entry.key != result.questions.length - 1)
              const Divider(height: 12, color: Color(0xFFFFE0A1)),
          ],
        ],
      ),
    );
  }
}

class _QuestionResultTile extends StatelessWidget {
  const _QuestionResultTile({
    required this.number,
    required this.question,
  });

  final int number;
  final QuestQuestionResult question;

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final color = _color;
    final icon = _icon;
    final score = question.score;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              if (score != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Skor soal: ${score.round()}',
                  style: const TextStyle(
                    color: Color(0xFF60646F),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String get _status {
    if (question.isPendingReview) return 'Menunggu review';
    if (question.isCorrect == true) return 'Benar';
    return 'Salah';
  }

  Color get _color {
    if (question.isPendingReview) return _questYellow;
    if (question.isCorrect == true) return _questGreen;
    return const Color(0xFFE53935);
  }

  IconData get _icon {
    if (question.isPendingReview) return Icons.hourglass_top_rounded;
    if (question.isCorrect == true) return Icons.check_circle_rounded;
    return Icons.cancel_rounded;
  }
}

class _LearningFeedback extends StatelessWidget {
  const _LearningFeedback({required this.result});

  final QuestSubmitResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE0A1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights_rounded, color: _questYellow),
              SizedBox(width: 8),
              Text(
                'Ringkasan Belajar',
                style: TextStyle(
                  color: _questInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Benar otomatis: ${result.correctAutoScoredCount}/${result.autoScoredCount}',
            style: const TextStyle(
              color: _questInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (result.pendingReviewCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Menunggu review: ${result.pendingReviewCount}',
              style: const TextStyle(
                color: Color(0xFF60646F),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            result.recommendation,
            style: const TextStyle(
              color: Color(0xFF60646F),
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardStat extends StatelessWidget {
  const _RewardStat(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE0A1)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF60646F), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
