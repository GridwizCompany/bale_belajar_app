import 'package:flutter/material.dart';

import '../../../../shared/widgets/bale_card.dart';
import '../../../../theme/bale_theme.dart';
import '../../application/baleverse_progress_service.dart';
import '../../data/baleverse_dummy_data.dart';
import '../../domain/baleverse_models.dart';
import '../widgets/baleverse_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.progress,
    required this.selectedWorld,
    required this.onStartMission,
    super.key,
  });

  final BaleVerseProgress progress;
  final BaleWorld selectedWorld;
  final VoidCallback onStartMission;

  @override
  Widget build(BuildContext context) {
    final user = progress.user;

    return PageShell(
      children: [
        BaleCard(
          color: BaleColors.ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SmallCaps('Misi aktif'),
              const SizedBox(height: 8),
              Text(
                'Hai ${user.name}, lanjutkan satu langkah.',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                numeriaMission.goal,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onStartMission,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Lanjutkan Misi'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const BaleHeroCard(stateLabel: 'Siap belajar'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'XP Matematika',
                value: '${user.xp[BaleWorldKey.numeria]}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Mastery',
                value: '${user.mastery[BaleWorldKey.numeria]}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        WorldSelector(
          selectedWorld: selectedWorld,
          onSelectWorld: (_) {},
        ),
      ],
    );
  }
}
