import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'test_template_ui_helpers.dart';

const _singleChoiceYellow = Color(0xFFF4B400);
const _singleChoiceInk = Color(0xFF3B2318);
const _singleChoiceGreen = Color(0xFF2F9B42);

class SingleChoiceTemplate extends StatefulWidget {
  const SingleChoiceTemplate({
    required this.question,
    required this.onCheckAnswer,
    this.currentQuestion = 1,
    this.totalQuestions = 5,
    this.onBack,
    this.onHint,
    this.onSkip,
    super.key,
  });

  final TemplateQuestion question;
  final ValueChanged<String?> onCheckAnswer;
  final int currentQuestion;
  final int totalQuestions;
  final VoidCallback? onBack;
  final VoidCallback? onHint;
  final VoidCallback? onSkip;

  @override
  State<SingleChoiceTemplate> createState() => _SingleChoiceTemplateState();
}

class _SingleChoiceTemplateState extends State<SingleChoiceTemplate> {
  String? _selectedOptionId;

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
            _SingleChoiceHeader(
              currentQuestion: widget.currentQuestion,
              totalQuestions: widget.totalQuestions,
              progress: progress,
              onBack: widget.onBack,
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 24),
            _SingleChoiceMascotIntro(compact: compact),
            SizedBox(height: compact ? 8 : 24),
            _QuestionCard(
              question: widget.question,
              selectedOptionId: _selectedOptionId,
              compact: compact,
              onSelected: (optionId) =>
                  setState(() => _selectedOptionId = optionId),
              onCheckAnswer: _selectedOptionId == null
                  ? null
                  : () => widget.onCheckAnswer(_selectedOptionId),
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

class _SingleChoiceHeader extends StatelessWidget {
  const _SingleChoiceHeader({
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
              child: Icon(
                Icons.arrow_back_rounded,
                color: _singleChoiceInk,
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
                'Cek Awal • $currentQuestion/$totalQuestions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _singleChoiceInk,
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
                            color: _singleChoiceYellow,
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
                        color: _singleChoiceInk,
                        fontSize: compact ? 12 : 18,
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

class _SingleChoiceMascotIntro extends StatelessWidget {
  const _SingleChoiceMascotIntro({required this.compact});

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
            padding: EdgeInsets.all(compact ? 10 : 20),
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
            child: TypewriterMessage(
              text:
                  'Hai, aku Babe!\nYuk jawab pertanyaan pertama. Pilih satu jawaban yang paling tepat ya.',
              highlightColor: _singleChoiceGreen,
              style: TextStyle(
                color: _singleChoiceInk,
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
    required this.selectedOptionId,
    required this.compact,
    required this.onSelected,
    required this.onCheckAnswer,
  });

  final TemplateQuestion question;
  final String? selectedOptionId;
  final bool compact;
  final ValueChanged<String> onSelected;
  final VoidCallback? onCheckAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 22),
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
                vertical: compact ? 6 : 10,
              ),
              decoration: BoxDecoration(
                color: _singleChoiceGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assignment_rounded,
                    color: _singleChoiceGreen,
                    size: compact ? 18 : 22,
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.58,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Template 1 • Single Choice',
                        style: TextStyle(
                          color: _singleChoiceGreen,
                          fontSize: compact ? 11 : 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 28),
          Text(
            question.prompt,
            style: TextStyle(
              color: _singleChoiceInk,
              fontSize: compact ? 17 : 28,
              height: compact ? 1.12 : 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 8 : 24),
          for (var index = 0; index < question.options.length; index++) ...[
            _SingleChoiceOptionCard(
              option: question.options[index],
              letter: String.fromCharCode(65 + index),
              selected: selectedOptionId == question.options[index].id,
              compact: compact,
              onTap: () => onSelected(question.options[index].id),
            ),
            SizedBox(height: compact ? 6 : 14),
          ],
          SizedBox(height: compact ? 4 : 18),
          FilledButton(
            onPressed: onCheckAnswer,
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(compact ? 50 : 72),
              backgroundColor: _singleChoiceYellow,
              foregroundColor: _singleChoiceInk,
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
                const Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Periksa Jawaban'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleChoiceOptionCard extends StatelessWidget {
  const _SingleChoiceOptionCard({
    required this.option,
    required this.letter,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final TemplateOption option;
  final String letter;
  final bool selected;
  final bool compact;
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
          constraints: BoxConstraints(minHeight: compact ? 54 : 78),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 20,
            vertical: compact ? 8 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _singleChoiceYellow : const Color(0xFFE9E1D6),
              width: selected ? 2 : 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 36 : 56,
                height: compact ? 36 : 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      selected ? _singleChoiceYellow : const Color(0xFFF4F0EA),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    color: _singleChoiceInk,
                    fontSize: compact ? 16 : 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: compact ? 12 : 28),
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    color: _singleChoiceInk,
                    fontSize: compact ? 16 : 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (selected)
                Container(
                  width: compact ? 28 : 40,
                  height: compact ? 28 : 40,
                  decoration: const BoxDecoration(
                    color: _singleChoiceYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
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
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
              minimumSize: Size(0, compact ? 34 : 44),
            ),
            icon: Icon(
              Icons.tips_and_updates_outlined,
              color: _singleChoiceGreen,
              size: compact ? 8 : 28,
            ),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Butuh petunjuk?',
                style: TextStyle(
                  color: _singleChoiceGreen,
                  fontSize: compact ? 11 : 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        Container(
            width: 1,
            height: compact ? 26 : 34,
            color: const Color(0xFFE4D8C8)),
        Expanded(
          child: TextButton.icon(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
              minimumSize: Size(0, compact ? 34 : 44),
            ),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Lewati',
                style: TextStyle(
                  color: const Color(0xFF7D7A78),
                  fontSize: compact ? 11 : 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            iconAlignment: IconAlignment.end,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFF7D7A78),
              size: compact ? 18 : 24,
            ),
          ),
        ),
      ],
    );
  }
}
