import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'test_template_ui_helpers.dart';

const _insightYellow = Color(0xFFF4B400);
const _insightInk = Color(0xFF3B2318);
const _insightGreen = Color(0xFF2F9B42);

class CodeInputTemplate extends StatefulWidget {
  const CodeInputTemplate({
    required this.question,
    required this.onCheckAnswer,
    this.onRun,
    this.currentQuestion = 10,
    this.totalQuestions = 10,
    this.readingText,
    this.tipText,
    this.onBack,
    this.onHint,
    this.onSkip,
    this.onBookmark,
    super.key,
  });

  final TemplateQuestion question;
  final ValueChanged<String?> onCheckAnswer;
  final ValueChanged<String>? onRun;
  final int currentQuestion;
  final int totalQuestions;
  final String? readingText;
  final String? tipText;
  final VoidCallback? onBack;
  final VoidCallback? onHint;
  final VoidCallback? onSkip;
  final VoidCallback? onBookmark;

  @override
  State<CodeInputTemplate> createState() => _CodeInputTemplateState();
}

class _CodeInputTemplateState extends State<CodeInputTemplate> {
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
            _InsightHeader(
              currentQuestion: widget.currentQuestion,
              totalQuestions: widget.totalQuestions,
              progress: progress,
              onBack: widget.onBack,
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 24),
            _InsightMascotIntro(compact: compact),
            SizedBox(height: compact ? 8 : 24),
            _QuestionCard(
              question: widget.question,
              selectedOptionId: _selectedOptionId,
              readingText: widget.readingText,
              tipText: widget.tipText,
              compact: compact,
              onBookmark: widget.onBookmark,
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

class _InsightHeader extends StatelessWidget {
  const _InsightHeader({
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
                color: _insightInk,
                size: 32,
              ),
            ),
          ),
        ),
        SizedBox(width: compact ? 8 : 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cek Awal \u2022 $currentQuestion/$totalQuestions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _insightInk,
                  fontSize: compact ? 18 : 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
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
                            color: _insightYellow,
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
                        color: _insightInk,
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

class _InsightMascotIntro extends StatelessWidget {
  const _InsightMascotIntro({required this.compact});

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
            height: compact ? 104 : 190,
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
                    style: TextStyle(color: _insightGreen),
                  ),
                  const TextSpan(
                    text:
                        '!\nPertanyaan terakhir! Kamu hampir selesai. Tetap semangat!',
                  ),
                ],
              ),
              style: TextStyle(
                color: _insightInk,
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
    required this.readingText,
    required this.tipText,
    required this.compact,
    required this.onBookmark,
    required this.onSelected,
    required this.onCheckAnswer,
  });

  final TemplateQuestion question;
  final String? selectedOptionId;
  final String? readingText;
  final String? tipText;
  final bool compact;
  final VoidCallback? onBookmark;
  final ValueChanged<String> onSelected;
  final VoidCallback? onCheckAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 22),
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
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 16,
                      vertical: compact ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: _insightYellow.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          color: const Color(0xFFD89B00),
                          size: compact ? 18 : 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Template 10 \u2022 Insight',
                          style: TextStyle(
                            color: const Color(0xFFD89B00),
                            fontSize: compact ? 13 : 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: compact ? 10 : 14),
              OutlinedButton.icon(
                onPressed: onBookmark,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _insightInk,
                  side: const BorderSide(color: Color(0xFFE9E1D6)),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 14,
                    vertical: compact ? 8 : 10,
                  ),
                ),
                icon: Icon(
                  Icons.bookmark_border_rounded,
                  size: compact ? 18 : 22,
                ),
                label: Text(
                  'Tandai',
                  style: TextStyle(
                    fontSize: compact ? 12 : 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 20),
          Text(
            question.prompt,
            style: TextStyle(
              color: _insightInk,
              fontSize: compact ? 22 : 28,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 8 : 22),
          Container(
            padding: EdgeInsets.all(compact ? 8 : 22),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEDDAE), width: 1.2),
            ),
            child: Text(
              readingText ?? question.instruction ?? _defaultReading,
              style: TextStyle(
                color: _insightInk,
                fontSize: compact ? 15 : 19,
                height: compact ? 1.22 : 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: compact ? 14 : 18),
          for (var index = 0; index < question.options.length; index++) ...[
            _InsightOptionCard(
              option: question.options[index],
              letter: String.fromCharCode(65 + index),
              selected: selectedOptionId == question.options[index].id,
              compact: compact,
              onTap: () => onSelected(question.options[index].id),
            ),
            SizedBox(height: compact ? 10 : 14),
          ],
          SizedBox(height: compact ? 4 : 6),
          _TipCard(
            text: tipText ??
                'Kesimpulan yang baik mencakup inti informasi dari keseluruhan bacaan, bukan hanya satu detail tertentu.',
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 28),
          FilledButton(
            onPressed: onCheckAnswer,
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(compact ? 54 : 72),
              backgroundColor: _insightYellow,
              foregroundColor: _insightInk,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _defaultReading =
    'Di sebuah desa, warga berinisiatif membuat tempat sampah organik dan anorganik di setiap rumah. Mereka juga rutin membersihkan lingkungan setiap minggu. Kini, desa tersebut menjadi bersih, sehat, dan nyaman untuk ditinggali.';

class _InsightOptionCard extends StatelessWidget {
  const _InsightOptionCard({
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
      elevation: selected ? 6 : 2,
      shadowColor: const Color(0x14000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 54 : 68),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 10 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _insightYellow : const Color(0xFFE9E1D6),
              width: selected ? 2 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 34 : 42,
                height: compact ? 34 : 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? _insightYellow : const Color(0xFFFFE9A8),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    color: _insightInk,
                    fontSize: compact ? 8 : 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Text(
                  option.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _insightInk,
                    fontSize: compact ? 14 : 18,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                child: Container(
                  width: compact ? 28 : 34,
                  height: compact ? 28 : 34,
                  decoration: const BoxDecoration(
                    color: _insightYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
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

class _TipCard extends StatelessWidget {
  const _TipCard({required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 34 : 42,
            height: compact ? 34 : 42,
            decoration: const BoxDecoration(
              color: _insightYellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_rounded, color: _insightInk),
          ),
          SizedBox(width: compact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips',
                  style: TextStyle(
                    color: const Color(0xFFD89B00),
                    fontSize: compact ? 20 : 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  text,
                  style: TextStyle(
                    color: _insightInk,
                    fontSize: compact ? 14 : 17,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
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
              color: _insightGreen,
              size: compact ? 22 : 28,
            ),
            label: Text(
              'Butuh petunjuk?',
              style: TextStyle(
                color: _insightGreen,
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
