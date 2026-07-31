import 'package:flutter/material.dart';

const testTemplateYellow = Color(0xFFF4B400);
const testTemplateInk = Color(0xFF3B2318);
const testTemplateGreen = Color(0xFF2F9B42);

void showTemplateHintSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Image.asset(
                  'assets/mascot/kenalan.png',
                  width: 86,
                  height: 86,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Petunjuk dari Babe',
                        style: TextStyle(
                          color: testTemplateInk,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Babe bantu kamu pelan-pelan.',
                        style: TextStyle(
                          color: Color(0xFF675D55),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Baca soalnya pelan-pelan, cari kata kunci, lalu pilih jawaban yang paling sesuai. Kamu masih bisa mengubah jawaban sebelum menekan Periksa Jawaban.',
              style: TextStyle(
                color: Color(0xFF675D55),
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: testTemplateYellow,
                foregroundColor: testTemplateInk,
              ),
              child: const Text(
                'Mengerti',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class TypewriterMessage extends StatefulWidget {
  const TypewriterMessage({
    required this.text,
    required this.style,
    this.highlight = 'Babe',
    this.highlightColor = testTemplateGreen,
    super.key,
  });

  final String text;
  final String highlight;
  final Color highlightColor;
  final TextStyle style;

  @override
  State<TypewriterMessage> createState() => _TypewriterMessageState();
}

class _TypewriterMessageState extends State<TypewriterMessage> {
  int _visibleLength = 0;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  @override
  void didUpdateWidget(covariant TypewriterMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _visibleLength = 0;
      _tick();
    }
  }

  void _tick() {
    Future<void>.delayed(const Duration(milliseconds: 22), () {
      if (!mounted || _visibleLength >= widget.text.length) return;
      setState(() => _visibleLength++);
      _tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.text.substring(0, _visibleLength);
    final parts = visible.split(widget.highlight);
    final spans = <TextSpan>[];

    for (var index = 0; index < parts.length; index++) {
      if (parts[index].isNotEmpty) spans.add(TextSpan(text: parts[index]));
      if (index != parts.length - 1) {
        spans.add(
          TextSpan(
            text: widget.highlight,
            style: TextStyle(color: widget.highlightColor),
          ),
        );
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      style: widget.style,
    );
  }
}
