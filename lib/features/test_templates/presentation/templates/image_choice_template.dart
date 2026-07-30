import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'single_choice_template.dart';

class ImageChoiceTemplate extends StatelessWidget {
  const ImageChoiceTemplate({
    required this.question,
    required this.onCheckAnswer,
    super.key,
  });

  final TemplateQuestion question;
  final ValueChanged<String?> onCheckAnswer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (question.media?.url != null)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(question.media!.url, fit: BoxFit.contain),
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
