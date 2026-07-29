import 'package:flutter/material.dart';

import '../../domain/baleverse_models.dart';
import '../widgets/baleverse_widgets.dart';

class WorldsScreen extends StatelessWidget {
  const WorldsScreen({
    required this.selectedWorld,
    required this.onSelectWorld,
    super.key,
  });

  final BaleWorld selectedWorld;
  final ValueChanged<BaleWorldKey> onSelectWorld;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      children: [
        const BaleHeroCard(stateLabel: 'Pilih dunia yang ingin kamu kuatkan'),
        const SizedBox(height: 14),
        WorldSelector(
          selectedWorld: selectedWorld,
          onSelectWorld: onSelectWorld,
        ),
      ],
    );
  }
}
