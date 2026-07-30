import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'template_widgets.dart';

class LongTextTemplate extends StatefulWidget {
  const LongTextTemplate({
    required this.question,
    required this.onSubmitAnswer,
    super.key,
  });

  final TemplateQuestion question;
  final ValueChanged<String> onSubmitAnswer;

  @override
  State<LongTextTemplate> createState() => _LongTextTemplateState();
}

class _LongTextTemplateState extends State<LongTextTemplate> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TestTemplateShell(
      question: widget.question,
      checkLabel: 'Kirim Jawaban',
      onCheckAnswer: () => widget.onSubmitAnswer(_controller.text.trim()),
      children: [
        TextField(
          controller: _controller,
          minLines: 6,
          maxLines: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Jelaskan dengan kata-katamu sendiri',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
            'Hasil bisa: sedang diperiksa, AI tersedia, atau review mentor.'),
      ],
    );
  }
}
