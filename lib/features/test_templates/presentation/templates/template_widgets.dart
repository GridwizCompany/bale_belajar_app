import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';

class TestTemplateShell extends StatelessWidget {
  const TestTemplateShell({
    required this.question,
    required this.children,
    required this.onCheckAnswer,
    this.checkLabel = 'Periksa Jawaban',
    super.key,
  });

  final TemplateQuestion question;
  final List<Widget> children;
  final VoidCallback onCheckAnswer;
  final String checkLabel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          question.prompt,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (question.instruction != null) ...[
          const SizedBox(height: 8),
          Text(question.instruction!),
        ],
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onCheckAnswer,
          child: Text(checkLabel),
        ),
      ],
    );
  }
}

class TemplateOptionTile extends StatelessWidget {
  const TemplateOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final TemplateOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        selected: selected,
        onTap: onTap,
        title: Text(option.label),
        subtitle: option.description == null ? null : Text(option.description!),
        trailing: Icon(
          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        ),
      ),
    );
  }
}
