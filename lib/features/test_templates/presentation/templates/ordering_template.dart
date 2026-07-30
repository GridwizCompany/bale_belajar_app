import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'template_widgets.dart';

class OrderingTemplate extends StatefulWidget {
  const OrderingTemplate({
    required this.question,
    required this.onCheckAnswer,
    super.key,
  });

  final TemplateQuestion question;
  final ValueChanged<List<String>> onCheckAnswer;

  @override
  State<OrderingTemplate> createState() => _OrderingTemplateState();
}

class _OrderingTemplateState extends State<OrderingTemplate> {
  late final List<OrderingItem> _items = [...widget.question.orderingItems];

  @override
  Widget build(BuildContext context) {
    return TestTemplateShell(
      question: widget.question,
      onCheckAnswer: () => widget.onCheckAnswer(
        _items.map((item) => item.id).toList(),
      ),
      children: [
        for (var index = 0; index < _items.length; index++)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(_items[index].label),
              trailing: Wrap(
                children: [
                  IconButton(
                    onPressed: index == 0 ? null : () => _move(index, -1),
                    icon: const Icon(Icons.keyboard_arrow_up_rounded),
                  ),
                  IconButton(
                    onPressed: index == _items.length - 1
                        ? null
                        : () => _move(index, 1),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _move(int index, int delta) {
    setState(() {
      final item = _items.removeAt(index);
      _items.insert(index + delta, item);
    });
  }
}
