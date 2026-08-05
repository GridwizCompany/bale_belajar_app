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
              Text(
                'Menyimpan jawaban...',
                style: TextStyle(
                  color: _questInk,
                  fontWeight: FontWeight.w900,
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
    final pendingReview =
        result.questions.where((q) => q.isPendingReview).length;

    return Scaffold(
      backgroundColor: _questBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Icon(Icons.emoji_events_rounded,
                  color: _questYellow, size: 72),
              const SizedBox(height: 12),
              Text(
                'Quest Selesai!',
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
                  'Naik level! 🎉',
                  style:
                      TextStyle(color: _questInk, fontWeight: FontWeight.w900),
                ),
              ],
              if (pendingReview > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFE0A1)),
                  ),
                  child: Text(
                    '$pendingReview jawaban menunggu review mentor - belum masuk skor otomatis.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF60646F), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              const Spacer(),
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
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        ),
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
