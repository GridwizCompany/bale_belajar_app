import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';

const _multipleSelectYellow = Color(0xFFF4B400);
const _multipleSelectInk = Color(0xFF3B2318);
const _multipleSelectGreen = Color(0xFF2F9B42);

class MultipleSelectTemplate extends StatefulWidget {
  const MultipleSelectTemplate({
    required this.question,
    required this.onCheckAnswer,
    this.currentQuestion = 2,
    this.totalQuestions = 5,
    this.onBack,
    this.onHint,
    this.onSkip,
    super.key,
  });

  final TemplateQuestion question;
  final ValueChanged<Set<String>> onCheckAnswer;
  final int currentQuestion;
  final int totalQuestions;
  final VoidCallback? onBack;
  final VoidCallback? onHint;
  final VoidCallback? onSkip;

  @override
  State<MultipleSelectTemplate> createState() => _MultipleSelectTemplateState();
}

class _MultipleSelectTemplateState extends State<MultipleSelectTemplate> {
  final Set<String> _selectedOptionIds = {};

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.shortestSide < 600 && size.height < 820;
    final progress = widget.totalQuestions <= 0
        ? 0.0
        : (widget.currentQuestion / widget.totalQuestions).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3C6),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 20,
            compact ? 10 : 18,
            compact ? 14 : 20,
            compact ? 18 : 28,
          ),
          children: [
            _MultipleSelectHeader(
              currentQuestion: widget.currentQuestion,
              totalQuestions: widget.totalQuestions,
              progress: progress,
              onBack: widget.onBack,
              compact: compact,
            ),
            SizedBox(height: compact ? 16 : 24),
            _MultipleSelectMascotIntro(compact: compact),
            SizedBox(height: compact ? 16 : 24),
            _QuestionCard(
              question: widget.question,
              selectedOptionIds: _selectedOptionIds,
              compact: compact,
              onSelected: _toggleOption,
              onCheckAnswer: _selectedOptionIds.isEmpty
                  ? null
                  : () => widget.onCheckAnswer(Set.of(_selectedOptionIds)),
            ),
            SizedBox(height: compact ? 12 : 18),
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

  void _toggleOption(String optionId) {
    setState(() {
      _selectedOptionIds.contains(optionId)
          ? _selectedOptionIds.remove(optionId)
          : _selectedOptionIds.add(optionId);
    });
  }
}

class _MultipleSelectHeader extends StatelessWidget {
  const _MultipleSelectHeader({
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
              dimension: compact ? 52 : 64,
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _multipleSelectInk,
                size: 32,
              ),
            ),
          ),
        ),
        SizedBox(width: compact ? 14 : 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cek Awal \u2022 $currentQuestion/$totalQuestions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _multipleSelectInk,
                  fontSize: compact ? 18 : 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  Container(
                    height: compact ? 24 : 30,
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
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      height: compact ? 24 : 30,
                      decoration: BoxDecoration(
                        color: _multipleSelectYellow,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      '$percent%',
                      style: TextStyle(
                        color: _multipleSelectInk,
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

class _MultipleSelectMascotIntro extends StatelessWidget {
  const _MultipleSelectMascotIntro({required this.compact});

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
            height: compact ? 130 : 180,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 11,
          child: Container(
            padding: EdgeInsets.all(compact ? 14 : 20),
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
                    text: 'Bale',
                    style: TextStyle(color: _multipleSelectGreen),
                  ),
                  const TextSpan(
                    text:
                        '!\nKali ini pilih semua jawaban yang benar ya. Bisa lebih dari satu jawaban.',
                  ),
                ],
              ),
              style: TextStyle(
                color: _multipleSelectInk,
                fontSize: compact ? 13 : 18,
                height: 1.35,
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
    required this.selectedOptionIds,
    required this.compact,
    required this.onSelected,
    required this.onCheckAnswer,
  });

  final TemplateQuestion question;
  final Set<String> selectedOptionIds;
  final bool compact;
  final ValueChanged<String> onSelected;
  final VoidCallback? onCheckAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
                color: _multipleSelectGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assignment_rounded,
                    color: _multipleSelectGreen,
                    size: compact ? 18 : 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Template 2 \u2022 Multiple Select',
                    style: TextStyle(
                      color: _multipleSelectGreen,
                      fontSize: compact ? 13 : 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: compact ? 18 : 28),
          Text(
            question.prompt,
            style: TextStyle(
              color: _multipleSelectInk,
              fontSize: compact ? 22 : 28,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (question.instruction != null) ...[
            SizedBox(height: compact ? 8 : 10),
            Text(
              question.instruction!,
              style: TextStyle(
                color: const Color(0xFF7A6F65),
                fontSize: compact ? 13 : 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          SizedBox(height: compact ? 16 : 24),
          for (var index = 0; index < question.options.length; index++) ...[
            _MultipleSelectOptionCard(
              option: question.options[index],
              letter: String.fromCharCode(65 + index),
              selected: selectedOptionIds.contains(question.options[index].id),
              compact: compact,
              onTap: () => onSelected(question.options[index].id),
            ),
            SizedBox(height: compact ? 10 : 14),
          ],
          SizedBox(height: compact ? 10 : 18),
          FilledButton(
            onPressed: onCheckAnswer,
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(compact ? 54 : 72),
              backgroundColor: _multipleSelectYellow,
              foregroundColor: _multipleSelectInk,
              disabledBackgroundColor: const Color(0xFFE8E0D2),
              disabledForegroundColor: const Color(0xFF8C8274),
              elevation: 8,
              shadowColor: const Color(0x55F4B400),
              textStyle: TextStyle(
                fontSize: compact ? 20 : 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Periksa Jawaban'),
                const SizedBox(width: 14),
                Container(
                  width: compact ? 36 : 48,
                  height: compact ? 36 : 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MultipleSelectOptionCard extends StatelessWidget {
  const _MultipleSelectOptionCard({
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
      borderRadius: BorderRadius.circular(20),
      elevation: selected ? 8 : 3,
      shadowColor: const Color(0x16000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 58 : 78),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 20,
            vertical: compact ? 10 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _multipleSelectYellow : const Color(0xFFE9E1D6),
              width: selected ? 2 : 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 42 : 56,
                height: compact ? 42 : 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? _multipleSelectYellow
                      : const Color(0xFFF4F0EA),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    color: _multipleSelectInk,
                    fontSize: compact ? 22 : 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: compact ? 18 : 28),
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    color: _multipleSelectInk,
                    fontSize: compact ? 22 : 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                child: Container(
                  width: compact ? 32 : 40,
                  height: compact ? 32 : 40,
                  decoration: const BoxDecoration(
                    color: _multipleSelectYellow,
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
            onPressed: onHint,
            icon: Icon(
              Icons.tips_and_updates_outlined,
              color: _multipleSelectGreen,
              size: compact ? 22 : 28,
            ),
            label: Text(
              'Butuh petunjuk?',
              style: TextStyle(
                color: _multipleSelectGreen,
                fontSize: compact ? 13 : 18,
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
                fontSize: compact ? 13 : 18,
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
