import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'template_widgets.dart';

class MultipleSelectTemplate extends StatefulWidget {
  const MultipleSelectTemplate({
    required this.question,
    required this.onCheckAnswer,
    super.key,
  });

  final TemplateQuestion question;
  final ValueChanged<Set<String>> onCheckAnswer;

  @override
  State<MultipleSelectTemplate> createState() => _MultipleSelectTemplateState();
}

class _MultipleSelectTemplateState extends State<MultipleSelectTemplate> {
  final Set<String> _selectedOptionIds = {};

  @override
  Widget build(BuildContext context) {
    return TestTemplateShell(
      question: widget.question,
      onCheckAnswer: () => widget.onCheckAnswer(_selectedOptionIds),
      children: [
        const Text(
          'Pilih semua jawaban yang sesuai.',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final option in widget.question.options)
          TemplateOptionTile(
            option: option,
            selected: _selectedOptionIds.contains(option.id),
            onTap: () {
              setState(() {
                _selectedOptionIds.contains(option.id)
                    ? _selectedOptionIds.remove(option.id)
                    : _selectedOptionIds.add(option.id);
              });
            },
          ),
      ],
    );
  }
}
