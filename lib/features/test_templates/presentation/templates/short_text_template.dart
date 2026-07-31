// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/test_template_models.dart';
import 'test_template_ui_helpers.dart';

const _shortTextYellow = Color(0xFFF4B400);
const _shortTextInk = Color(0xFF3B2318);
const _shortTextGreen = Color(0xFF2F9B42);

class ShortTextTemplate extends StatefulWidget {
  const ShortTextTemplate({
    required this.question,
    required this.onCheckAnswer,
    this.currentQuestion = 4,
    this.totalQuestions = 5,
    this.tipText,
    this.onBack,
    this.onHint,
    this.onSkip,
    super.key,
  });

  final TemplateQuestion question;
  final ValueChanged<String> onCheckAnswer;
  final int currentQuestion;
  final int totalQuestions;
  final String? tipText;
  final VoidCallback? onBack;
  final VoidCallback? onHint;
  final VoidCallback? onSkip;

  @override
  State<ShortTextTemplate> createState() => _ShortTextTemplateState();
}

class _ShortTextTemplateState extends State<ShortTextTemplate> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.shortestSide < 600;
    final progress = widget.totalQuestions <= 0
        ? 0.0
        : (widget.currentQuestion / widget.totalQuestions).clamp(0.0, 1.0);
    final config = widget.question.responseConfig ?? const ResponseConfig();
    final answer = _controller.text.trim();
    final canSubmit = config.allowEmpty || answer.isNotEmpty;

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
            _ShortTextHeader(
              currentQuestion: widget.currentQuestion,
              totalQuestions: widget.totalQuestions,
              progress: progress,
              onBack: widget.onBack,
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 24),
            _ShortTextMascotIntro(compact: compact),
            SizedBox(height: compact ? 8 : 24),
            _QuestionCard(
              question: widget.question,
              controller: _controller,
              config: config,
              tipText: widget.tipText,
              compact: compact,
              onCheckAnswer:
                  canSubmit ? () => widget.onCheckAnswer(answer) : null,
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

class _ShortTextHeader extends StatelessWidget {
  const _ShortTextHeader({
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
                color: _shortTextInk,
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
                  color: _shortTextInk,
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
                            color: _shortTextYellow,
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
                        color: _shortTextInk,
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

class _ShortTextMascotIntro extends StatelessWidget {
  const _ShortTextMascotIntro({required this.compact});

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
                    style: TextStyle(color: _shortTextGreen),
                  ),
                  const TextSpan(
                    text: '!\nTulis jawabanmu pada kotak di bawah ini ya.',
                  ),
                ],
              ),
              style: TextStyle(
                color: _shortTextInk,
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
    required this.controller,
    required this.config,
    required this.tipText,
    required this.compact,
    required this.onCheckAnswer,
  });

  final TemplateQuestion question;
  final TextEditingController controller;
  final ResponseConfig config;
  final String? tipText;
  final bool compact;
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
                color: _shortTextYellow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: const Color(0xFFD89B00),
                    size: compact ? 18 : 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Template 4 \u2022 Short Answer',
                    style: TextStyle(
                      color: const Color(0xFFD89B00),
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
            question.prompt,
            style: TextStyle(
              color: _shortTextInk,
              fontSize: compact ? 16 : 28,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            question.instruction ?? _instructionFor(config),
            style: TextStyle(
              color: const Color(0xFF8C8274),
              fontSize: compact ? 16 : 21,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 8 : 28),
          Stack(
            children: [
              TextField(
                controller: controller,
                keyboardType: _keyboardFor(config.inputMode),
                maxLength: config.maxLength,
                maxLines: compact ? 3 : 4,
                minLines: compact ? 3 : 4,
                textAlignVertical: TextAlignVertical.top,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(config.maxLength),
                ],
                style: TextStyle(
                  color: _shortTextInk,
                  fontSize: compact ? 16 : 28,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Tulis jawaban di sini...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF9A9690),
                    fontSize: compact ? 19 : 24,
                    fontWeight: FontWeight.w800,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFFCF5),
                  contentPadding: EdgeInsets.fromLTRB(
                    compact ? 18 : 24,
                    compact ? 18 : 24,
                    compact ? 84 : 104,
                    compact ? 18 : 24,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _shortTextYellow,
                      width: 1.6,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _shortTextYellow,
                      width: 2,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: compact ? 8 : 22,
                bottom: compact ? 8 : 22,
                child: _InputModeBadge(config: config, compact: compact),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 28),
          FilledButton(
            onPressed: onCheckAnswer,
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(compact ? 46 : 72),
              backgroundColor: _shortTextYellow,
              foregroundColor: _shortTextInk,
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

  TextInputType _keyboardFor(TextInputMode mode) => switch (mode) {
        TextInputMode.numeric => TextInputType.number,
        TextInputMode.decimal => const TextInputType.numberWithOptions(
            decimal: true,
          ),
        _ => TextInputType.text,
      };

  String _instructionFor(ResponseConfig config) => switch (config.inputMode) {
        TextInputMode.numeric => 'Tulis jawaban berupa angka saja.',
        TextInputMode.decimal => 'Tulis jawaban berupa angka desimal.',
        TextInputMode.fraction => 'Tulis jawaban berupa pecahan.',
        TextInputMode.code => 'Tulis potongan kode singkat.',
        TextInputMode.text => 'Tulis jawaban singkat dan jelas.',
      };

  String _defaultTipFor(ResponseConfig config) => switch (config.inputMode) {
        TextInputMode.numeric => 'Ingat, hitung pelan-pelan dari soalnya.',
        TextInputMode.decimal => 'Perhatikan tanda koma atau titik desimal.',
        TextInputMode.fraction => 'Sederhanakan pecahan kalau bisa.',
        TextInputMode.code => 'Periksa nama variabel dan tanda baca kodenya.',
        TextInputMode.text => 'Gunakan kata paling penting dari pertanyaan.',
      };
}

class _InputModeBadge extends StatelessWidget {
  const _InputModeBadge({required this.config, required this.compact});

  final ResponseConfig config;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = switch (config.inputMode) {
      TextInputMode.numeric => '123',
      TextInputMode.decimal => '1.2',
      TextInputMode.fraction => '1/2',
      TextInputMode.code => '</>',
      TextInputMode.text => 'Aa',
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 18,
        vertical: compact ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0C2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFFD89B00),
          fontSize: compact ? 0 : 0,
          fontWeight: FontWeight.w900,
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
      padding: EdgeInsets.all(compact ? 8 : 22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 36 : 44,
            height: compact ? 36 : 44,
            decoration: const BoxDecoration(
              color: _shortTextYellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: _shortTextInk,
            ),
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
                SizedBox(height: compact ? 6 : 8),
                Text(
                  text,
                  style: TextStyle(
                    color: _shortTextInk,
                    fontSize: compact ? 12 : 19,
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
              color: _shortTextGreen,
              size: compact ? 22 : 28,
            ),
            label: Text(
              'Butuh petunjuk?',
              style: TextStyle(
                color: _shortTextGreen,
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
