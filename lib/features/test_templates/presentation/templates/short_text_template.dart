import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/test_template_models.dart';
import 'template_widgets.dart';

class ShortTextTemplate extends StatefulWidget {
  const ShortTextTemplate({
    required this.question,
    required this.onCheckAnswer,
    super.key,
  });

  final TemplateQuestion question;
  final ValueChanged<String> onCheckAnswer;

  @override
  State<ShortTextTemplate> createState() => _ShortTextTemplateState();
}

class _ShortTextTemplateState extends State<ShortTextTemplate> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.question.responseConfig ?? const ResponseConfig();
    return TestTemplateShell(
      question: widget.question,
      onCheckAnswer: () => widget.onCheckAnswer(_controller.text.trim()),
      children: [
        TextField(
          controller: _controller,
          keyboardType: _keyboardFor(config.inputMode),
          maxLength: config.maxLength,
          inputFormatters: [
            LengthLimitingTextInputFormatter(config.maxLength),
          ],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Tulis jawaban singkat',
          ),
        ),
      ],
    );
  }

  TextInputType _keyboardFor(TextInputMode mode) => switch (mode) {
        TextInputMode.numeric => TextInputType.number,
        TextInputMode.decimal => const TextInputType.numberWithOptions(
            decimal: true,
          ),
        _ => TextInputType.text,
      };
}
