import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'single_choice_template.dart';

class AudioChoiceTemplate extends StatelessWidget {
  const AudioChoiceTemplate({
    required this.question,
    required this.onPlay,
    required this.onPause,
    required this.onCheckAnswer,
    super.key,
  });

  final TemplateQuestion question;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final ValueChanged<String?> onCheckAnswer;

  @override
  Widget build(BuildContext context) {
    final media = question.media;
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: IconButton(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow_rounded),
            ),
            title: Text('${media?.durationSeconds ?? 0} detik'),
            subtitle: LinearProgressIndicator(value: 0),
            trailing: IconButton(
              onPressed: onPause,
              icon: const Icon(Icons.pause_rounded),
            ),
          ),
        ),
        Expanded(
          child: SingleChoiceTemplate(
            question: question,
            onCheckAnswer: onCheckAnswer,
          ),
        ),
      ],
    );
  }
}
