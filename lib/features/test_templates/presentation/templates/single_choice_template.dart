import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'template_widgets.dart';

class SingleChoiceTemplate extends StatefulWidget {
  const SingleChoiceTemplate({
    required this.question,
    required this.onCheckAnswer,
    super.key,
  });

  final TemplateQuestion question;
  final ValueChanged<String?> onCheckAnswer;

  @override
  State<SingleChoiceTemplate> createState() => _SingleChoiceTemplateState();
}

class _SingleChoiceTemplateState extends State<SingleChoiceTemplate> {
  String? _selectedOptionId;

  @override
  Widget build(BuildContext context) {
    return TestTemplateShell(
      question: widget.question,
      onCheckAnswer: () => widget.onCheckAnswer(_selectedOptionId),
      children: [
        for (final option in widget.question.options)
          TemplateOptionTile(
            option: option,
            selected: _selectedOptionId == option.id,
            onTap: () => setState(() => _selectedOptionId = option.id),
          ),
      ],
    );
  }
}
