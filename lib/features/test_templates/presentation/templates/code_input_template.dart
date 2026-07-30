import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'template_widgets.dart';

class CodeInputTemplate extends StatefulWidget {
  const CodeInputTemplate({
    required this.question,
    required this.onRun,
    required this.onCheckAnswer,
    super.key,
  });

  final TemplateQuestion question;
  final ValueChanged<String> onRun;
  final ValueChanged<String> onCheckAnswer;

  @override
  State<CodeInputTemplate> createState() => _CodeInputTemplateState();
}

class _CodeInputTemplateState extends State<CodeInputTemplate> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.question.codeConfig?.initialCode ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.question.codeConfig;
    return TestTemplateShell(
      question: widget.question,
      onCheckAnswer: () => widget.onCheckAnswer(_controller.text),
      children: [
        Chip(label: Text(config?.language ?? 'kode')),
        TextField(
          controller: _controller,
          minLines: 8,
          maxLines: 14,
          style: const TextStyle(fontFamily: 'monospace'),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Tulis kode di sini',
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => widget.onRun(_controller.text),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Run'),
        ),
        const Card(
          child: ListTile(
            title: Text('Output'),
            subtitle: Text('Output akan tampil di sini.'),
          ),
        ),
      ],
    );
  }
}
