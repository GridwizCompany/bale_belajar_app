import 'package:flutter/material.dart';

import '../../../../shared/widgets/bale_card.dart';
import '../../../../theme/bale_theme.dart';
import '../../data/baleverse_dummy_data.dart';
import '../../domain/baleverse_models.dart';
import '../widgets/baleverse_widgets.dart';

class MissionIntroScreen extends StatelessWidget {
  const MissionIntroScreen({required this.onStart, super.key});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      children: [
        const BaleHeroCard(stateLabel: 'Ayo mulai pelan-pelan'),
        const SizedBox(height: 14),
        BaleCard(
          color: BaleColors.ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SmallCaps('Cerita pembuka'),
              const SizedBox(height: 8),
              Text(
                numeriaMission.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                numeriaMission.story,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onStart,
                child: const Text('Mulai Misi'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MissionQuestionScreen extends StatelessWidget {
  const MissionQuestionScreen({
    required this.step,
    required this.wrongAttempts,
    required this.selectedOptionId,
    required this.feedback,
    required this.onSelectOption,
    required this.onCheck,
    super.key,
  });

  final MissionStep step;
  final int wrongAttempts;
  final String? selectedOptionId;
  final String? feedback;
  final ValueChanged<String> onSelectOption;
  final VoidCallback? onCheck;

  @override
  Widget build(BuildContext context) {
    final showHelp = step == MissionStep.hintOne ||
        step == MissionStep.hintTwo ||
        step == MissionStep.humanHelp;

    return PageShell(
      children: [
        _MissionTopBar(progress: (wrongAttempts + 1) / 4),
        const SizedBox(height: 14),
        BaleCard(
          color: BaleColors.ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SmallCaps('Satu soal'),
              const SizedBox(height: 8),
              Text(
                numeriaMission.prompt,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final option in numeriaMission.options) ...[
          _OptionButton(
            option: option,
            selected: selectedOptionId == option.id,
            onTap: () => onSelectOption(option.id),
          ),
          const SizedBox(height: 10),
        ],
        if (feedback != null) ...[
          _FeedbackBox(message: feedback!),
          const SizedBox(height: 14),
        ],
        FilledButton(
          onPressed: onCheck,
          child: const Text('Cek Jawaban'),
        ),
        if (showHelp) ...[
          const SizedBox(height: 14),
          _TanyaBalePanel(step: step),
        ],
      ],
    );
  }
}

class _MissionTopBar extends StatelessWidget {
  const _MissionTopBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.close_rounded),
        const SizedBox(width: 10),
        Expanded(child: BaleProgressBar(value: progress)),
        const SizedBox(width: 10),
        const MetricPill(icon: Icons.bolt_rounded, label: 'Power'),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final MissionOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border.all(
            color: selected ? BaleColors.info : BaleColors.line,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: selected ? BaleColors.info : BaleColors.soft,
              child: Text(
                option.label,
                style: TextStyle(
                  color: selected ? Colors.white : BaleColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.text,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TanyaBalePanel extends StatelessWidget {
  const _TanyaBalePanel({required this.step});

  final MissionStep step;

  @override
  Widget build(BuildContext context) {
    final confidence = step == MissionStep.humanHelp
        ? AiConfidence.low
        : step == MissionStep.hintTwo
            ? AiConfidence.medium
            : AiConfidence.high;
    final hintIndex = step == MissionStep.hintTwo
        ? 1
        : step == MissionStep.humanHelp
            ? 2
            : 0;

    return BaleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tanya Bale', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(numeriaMission.hints[hintIndex]),
          const SizedBox(height: 10),
          Text(
            switch (confidence) {
              AiConfidence.high => 'Aku menemukan pola kesalahannya.',
              AiConfidence.medium =>
                'Ada dua kemungkinan. Kita cek satu hal lagi.',
              AiConfidence.low =>
                'Aku belum cukup yakin untuk menilai ini dengan adil.',
            },
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBox extends StatelessWidget {
  const _FeedbackBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF9F1239),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
