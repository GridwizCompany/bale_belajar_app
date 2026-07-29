import 'package:flutter/material.dart';

import '../../../../shared/widgets/bale_card.dart';
import '../../../../theme/bale_theme.dart';
import '../../application/baleverse_progress_service.dart';
import '../../data/baleverse_dummy_data.dart';
import '../widgets/baleverse_widgets.dart';

class LearningCircleScreen extends StatelessWidget {
  const LearningCircleScreen({
    required this.progress,
    required this.onParentSupport,
    required this.onMentorReply,
    this.onTryAgain,
    super.key,
  });

  final BaleVerseProgress progress;
  final VoidCallback onParentSupport;
  final VoidCallback onMentorReply;
  final VoidCallback? onTryAgain;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      children: [
        BaleHeroCard(
          stateLabel: progress.mentorFeedbackReceived
              ? 'Mentor membalas'
              : 'Menunggu mentor',
        ),
        const SizedBox(height: 14),
        BaleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                progress.mentorFeedbackReceived
                    ? '${mentorFeedback.mentorName} memberi feedback'
                    : 'Permintaan masuk antrean mentor',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                progress.mentorFeedbackReceived
                    ? mentorFeedback.message
                    : 'Kak Arya akan melihat nama misi, topik, jawaban terkait, hint yang dipakai, dan pola kesalahan.',
              ),
              const SizedBox(height: 12),
              Text(
                progress.mentorFeedbackReceived
                    ? mentorFeedback.masteryReview
                    : 'Status: menunggu mentor',
                style: const TextStyle(
                  color: BaleColors.warning,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              if (!progress.mentorFeedbackReceived)
                OutlinedButton(
                  onPressed: onMentorReply,
                  child: const Text('Simulasikan mentor membalas'),
                )
              else if (onTryAgain != null)
                FilledButton(
                  onPressed: onTryAgain,
                  child: const Text('Terapkan feedback di misi'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        BaleCard(
          color: const Color(0xFFF0FDF4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                progress.parentSupportSent
                    ? 'Ibu Rina mengirim dukungan.'
                    : 'Minta dukungan orang tua',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                progress.parentSupportSent
                    ? 'Istirahat sebentar boleh, lalu coba contoh ringan selama 5 menit.'
                    : 'Data yang dibagikan: target minggu ini, nama misi, dan durasi belajar yang disarankan.',
              ),
              if (!progress.parentSupportSent) ...[
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: onParentSupport,
                  child: const Text('Minta dukungan orang tua'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
