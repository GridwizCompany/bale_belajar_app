import 'package:flutter/material.dart';

import '../../../../shared/widgets/bale_card.dart';
import '../../data/baleverse_dummy_data.dart';
import '../widgets/baleverse_widgets.dart';

class MentorHandoffScreen extends StatelessWidget {
  const MentorHandoffScreen({
    required this.selectedItems,
    required this.onToggle,
    required this.onApprove,
    super.key,
  });

  final Set<String> selectedItems;
  final ValueChanged<String> onToggle;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      children: [
        const BaleHeroCard(stateLabel: 'Minta bantuan mentor'),
        const SizedBox(height: 14),
        BaleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bantuan Manusia',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${humanHelpRecommendation.problem} ${humanHelpRecommendation.reason}',
              ),
              const SizedBox(height: 12),
              const Text(
                'Data yang akan dibagikan',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              for (final item in humanHelpRecommendation.shareableContext)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item),
                  value: selectedItems.contains(item),
                  onChanged: (_) => onToggle(item),
                ),
              const Text(
                'Chat AI lengkap, data keluarga, dan dunia lain tidak dibagikan.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onApprove,
                child: const Text('Minta Mentor Membantu'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
