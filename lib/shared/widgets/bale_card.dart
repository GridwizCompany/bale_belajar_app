import 'package:flutter/material.dart';

import '../../theme/bale_theme.dart';

class BaleCard extends StatelessWidget {
  const BaleCard({
    required this.child,
    this.color = BaleColors.surface,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: BaleColors.line),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class BaleProgressBar extends StatelessWidget {
  const BaleProgressBar({
    required this.value,
    this.color = BaleColors.success,
    super.key,
  });

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        minHeight: 10,
        value: value.clamp(0, 1),
        backgroundColor: const Color(0xFFEFF4FA),
        color: color,
      ),
    );
  }
}
