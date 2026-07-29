import 'package:flutter/material.dart';

import '../../../../shared/widgets/bale_card.dart';
import '../../../../theme/bale_theme.dart';
import '../../application/baleverse_progress_service.dart';
import '../../data/baleverse_dummy_data.dart';
import '../../domain/baleverse_models.dart';
import '../widgets/baleverse_widgets.dart';

class RewardScreen extends StatelessWidget {
  const RewardScreen({
    required this.progress,
    required this.onBackToDashboard,
    super.key,
  });

  final BaleVerseProgress progress;
  final VoidCallback onBackToDashboard;

  @override
  Widget build(BuildContext context) {
    final mastery = progress.user.mastery[BaleWorldKey.numeria] ?? 0;

    return PageShell(
      children: [
        const BaleHeroCard(stateLabel: 'Misi selesai'),
        const SizedBox(height: 14),
        BaleCard(
          color: BaleColors.ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SmallCaps('Reward'),
              const SizedBox(height: 8),
              Text(
                'Gerbang Distribusi terbuka.',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'XP bertambah karena aktivitas selesai. Mastery bertambah karena jawabanmu membuktikan pemahaman.',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RewardPill(label: '+${numeriaMission.rewardXp} XP'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RewardPill(
                      label: '+${numeriaMission.rewardDayaBale} Daya',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RewardPill(label: 'Mastery Matematika $mastery%'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onBackToDashboard,
                child: const Text('Kembali ke Dashboard'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
