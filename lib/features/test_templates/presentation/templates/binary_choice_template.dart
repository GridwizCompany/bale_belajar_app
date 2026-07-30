import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'template_widgets.dart';

class BinaryChoiceTemplate extends StatefulWidget {
  const BinaryChoiceTemplate({
    required this.question,
    required this.onCheckAnswer,
    this.leftLabel = 'Didukung bukti',
    this.rightLabel = 'Hanya asumsi',
    super.key,
  });

  final TemplateQuestion question;
  final String leftLabel;
  final String rightLabel;
  final ValueChanged<bool?> onCheckAnswer;

  @override
  State<BinaryChoiceTemplate> createState() => _BinaryChoiceTemplateState();
}

class _BinaryChoiceTemplateState extends State<BinaryChoiceTemplate> {
  bool? _answer;

  @override
  Widget build(BuildContext context) {
    return TestTemplateShell(
      question: widget.question,
      onCheckAnswer: () => widget.onCheckAnswer(_answer),
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: () => setState(() => _answer = true),
                child: Text(widget.leftLabel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonal(
                onPressed: () => setState(() => _answer = false),
                child: Text(widget.rightLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
