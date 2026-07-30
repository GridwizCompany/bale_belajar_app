import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'template_widgets.dart';

class MatchingTemplate extends StatefulWidget {
  const MatchingTemplate({
    required this.question,
    required this.onCheckAnswer,
    super.key,
  });

  final TemplateQuestion question;
  final ValueChanged<Map<String, String>> onCheckAnswer;

  @override
  State<MatchingTemplate> createState() => _MatchingTemplateState();
}

class _MatchingTemplateState extends State<MatchingTemplate> {
  final Map<String, String> _matches = {};
  String? _activeLeftId;

  @override
  Widget build(BuildContext context) {
    return TestTemplateShell(
      question: widget.question,
      onCheckAnswer: () => widget.onCheckAnswer(_matches),
      children: [
        const Text('Tekan item kiri, lalu tekan pasangan kanan.'),
        const SizedBox(height: 12),
        for (final pair in widget.question.matchingPairs)
          Card(
            child: ListTile(
              leading: IconButton(
                onPressed: () => setState(() => _activeLeftId = pair.leftId),
                icon: Icon(
                  _activeLeftId == pair.leftId
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                ),
              ),
              title: Text(pair.leftLabel),
              trailing: OutlinedButton(
                onPressed: _activeLeftId == null
                    ? null
                    : () => setState(() {
                          _matches[_activeLeftId!] = pair.rightId;
                          _activeLeftId = null;
                        }),
                child: Text(pair.rightLabel),
              ),
            ),
          ),
      ],
    );
  }
}
