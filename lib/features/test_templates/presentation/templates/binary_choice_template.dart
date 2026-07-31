import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'test_template_ui_helpers.dart';

const _binaryChoiceYellow = Color(0xFFF4B400);
const _binaryChoiceInk = Color(0xFF3B2318);
const _binaryChoiceGreen = Color(0xFF2F9B42);

class BinaryChoiceTemplate extends StatefulWidget {
  const BinaryChoiceTemplate({
    required this.question,
    required this.onCheckAnswer,
    this.leftLabel = 'Benar',
    this.rightLabel = 'Salah',
    this.currentQuestion = 3,
    this.totalQuestions = 5,
    this.onBack,
    this.onHint,
    this.onSkip,
    super.key,
  });

  final TemplateQuestion question;
  final String leftLabel;
  final String rightLabel;
  final ValueChanged<bool?> onCheckAnswer;
  final int currentQuestion;
  final int totalQuestions;
  final VoidCallback? onBack;
  final VoidCallback? onHint;
  final VoidCallback? onSkip;

  @override
  State<BinaryChoiceTemplate> createState() => _BinaryChoiceTemplateState();
}

class _BinaryChoiceTemplateState extends State<BinaryChoiceTemplate> {
  bool? _answer;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.shortestSide < 600;
    final progress = widget.totalQuestions <= 0
        ? 0.0
        : (widget.currentQuestion / widget.totalQuestions).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3C6),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            compact ? 10 : 20,
            compact ? 8 : 18,
            compact ? 10 : 20,
            compact ? 10 : 28,
          ),
          children: [
            _BinaryChoiceHeader(
              currentQuestion: widget.currentQuestion,
              totalQuestions: widget.totalQuestions,
              progress: progress,
              onBack: widget.onBack,
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 24),
            _BinaryChoiceMascotIntro(compact: compact),
            SizedBox(height: compact ? 8 : 24),
            _QuestionCard(
              question: widget.question,
              leftLabel: widget.leftLabel,
              rightLabel: widget.rightLabel,
              answer: _answer,
              compact: compact,
              onSelected: (answer) => setState(() => _answer = answer),
              onCheckAnswer:
                  _answer == null ? null : () => widget.onCheckAnswer(_answer),
            ),
            SizedBox(height: compact ? 6 : 18),
            _BottomActions(
              onHint: widget.onHint,
              onSkip: widget.onSkip,
              compact: compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _BinaryChoiceHeader extends StatelessWidget {
  const _BinaryChoiceHeader({
    required this.currentQuestion,
    required this.totalQuestions,
    required this.progress,
    required this.compact,
    this.onBack,
  });

  final int currentQuestion;
  final int totalQuestions;
  final double progress;
  final bool compact;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          elevation: 8,
          shadowColor: const Color(0x18000000),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(22),
            child: SizedBox.square(
              dimension: 0,
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _binaryChoiceInk,
                size: 0,
              ),
            ),
          ),
        ),
        const SizedBox.shrink(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cek Awal \u2022 $currentQuestion/$totalQuestions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _binaryChoiceInk,
                  fontSize: compact ? 0 : 0,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 0),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  Container(
                    height: compact ? 18 : 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x15000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: compact ? 18 : 30,
                          decoration: BoxDecoration(
                            color: _binaryChoiceYellow,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      '$percent%',
                      style: TextStyle(
                        color: _binaryChoiceInk,
                        fontSize: compact ? 14 : 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BinaryChoiceMascotIntro extends StatelessWidget {
  const _BinaryChoiceMascotIntro({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 8,
          child: Image.asset(
            'assets/mascot/kenalan.png',
            height: compact ? 172 : 300,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 11,
          child: Container(
            padding: EdgeInsets.all(compact ? 8 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x16000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Hai, aku '),
                  TextSpan(
                    text: 'Babe',
                    style: TextStyle(color: _binaryChoiceGreen),
                  ),
                  const TextSpan(
                    text:
                        '!\nKali ini pilih satu jawaban yang paling tepat ya. Baca pernyataannya dulu, lalu tentukan benar atau salah.',
                  ),
                ],
              ),
              style: TextStyle(
                color: _binaryChoiceInk,
                fontSize: compact ? 11 : 18,
                height: compact ? 1.22 : 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.leftLabel,
    required this.rightLabel,
    required this.answer,
    required this.compact,
    required this.onSelected,
    required this.onCheckAnswer,
  });

  final TemplateQuestion question;
  final String leftLabel;
  final String rightLabel;
  final bool? answer;
  final bool compact;
  final ValueChanged<bool> onSelected;
  final VoidCallback? onCheckAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x13000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 16,
                vertical: compact ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: _binaryChoiceGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assignment_rounded,
                    color: _binaryChoiceGreen,
                    size: compact ? 18 : 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Template 3 \u2022 Benar atau Salah',
                    style: TextStyle(
                      color: _binaryChoiceGreen,
                      fontSize: compact ? 11 : 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 28),
          Text(
            question.instruction ?? 'Pernyataan berikut ini, benar atau salah?',
            style: TextStyle(
              color: _binaryChoiceInk,
              fontSize: compact ? 16 : 28,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 8 : 24),
          Container(
            constraints: BoxConstraints(minHeight: compact ? 72 : 100),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 28,
              vertical: compact ? 8 : 24,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9E1D6), width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              question.prompt,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _binaryChoiceInk,
                fontSize: compact ? 20 : 26,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 24),
          _BinaryChoiceOptionCard(
            label: leftLabel,
            selected: answer == true,
            compact: compact,
            selectedIcon: Icons.check_rounded,
            onTap: () => onSelected(true),
          ),
          SizedBox(height: compact ? 10 : 14),
          _BinaryChoiceOptionCard(
            label: rightLabel,
            selected: answer == false,
            compact: compact,
            selectedIcon: Icons.close_rounded,
            onTap: () => onSelected(false),
          ),
          SizedBox(height: compact ? 8 : 28),
          FilledButton(
            onPressed: onCheckAnswer,
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(compact ? 46 : 72),
              backgroundColor: _binaryChoiceYellow,
              foregroundColor: _binaryChoiceInk,
              disabledBackgroundColor: const Color(0xFFE8E0D2),
              disabledForegroundColor: const Color(0xFF8C8274),
              elevation: 8,
              shadowColor: const Color(0x55F4B400),
              textStyle: TextStyle(
                fontSize: compact ? 17 : 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Periksa Jawaban'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BinaryChoiceOptionCard extends StatelessWidget {
  const _BinaryChoiceOptionCard({
    required this.label,
    required this.selected,
    required this.compact,
    required this.selectedIcon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool compact;
  final IconData selectedIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF8D9) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: selected ? 8 : 3,
      shadowColor: const Color(0x16000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 52 : 78),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 20,
            vertical: compact ? 10 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _binaryChoiceYellow : const Color(0xFFE9E1D6),
              width: selected ? 2 : 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 34 : 56,
                height: compact ? 34 : 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      selected ? _binaryChoiceYellow : const Color(0xFFF4F0EA),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selected ? selectedIcon : Icons.circle,
                  color: selected ? _binaryChoiceInk : const Color(0xFFF4F0EA),
                  size: compact ? 28 : 36,
                ),
              ),
              SizedBox(width: compact ? 8 : 28),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: _binaryChoiceInk,
                    fontSize: compact ? 16 : 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                child: Container(
                  width: compact ? 26 : 40,
                  height: compact ? 26 : 40,
                  decoration: const BoxDecoration(
                    color: _binaryChoiceYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.compact,
    this.onHint,
    this.onSkip,
  });

  final bool compact;
  final VoidCallback? onHint;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: onHint ?? () => showTemplateHintSheet(context),
            icon: Icon(
              Icons.tips_and_updates_outlined,
              color: _binaryChoiceGreen,
              size: compact ? 22 : 28,
            ),
            label: Text(
              'Butuh petunjuk?',
              style: TextStyle(
                color: _binaryChoiceGreen,
                fontSize: compact ? 11 : 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Container(width: 1, height: 34, color: const Color(0xFFE4D8C8)),
        Expanded(
          child: TextButton.icon(
            onPressed: onSkip,
            label: Text(
              'Lewati untuk sekarang',
              style: TextStyle(
                color: const Color(0xFF7D7A78),
                fontSize: compact ? 11 : 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            iconAlignment: IconAlignment.end,
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF7D7A78),
            ),
          ),
        ),
      ],
    );
  }
}
