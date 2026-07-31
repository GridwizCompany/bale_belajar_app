import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'test_template_ui_helpers.dart';

const _matchingYellow = Color(0xFFF4B400);
const _matchingInk = Color(0xFF3B2318);
const _matchingGreen = Color(0xFF2F9B42);

class MatchingTemplate extends StatefulWidget {
  const MatchingTemplate({
    required this.question,
    required this.onCheckAnswer,
    this.currentQuestion = 5,
    this.totalQuestions = 7,
    this.onBack,
    this.onHint,
    this.onSkip,
    super.key,
  });

  final TemplateQuestion question;
  final ValueChanged<Map<String, String>> onCheckAnswer;
  final int currentQuestion;
  final int totalQuestions;
  final VoidCallback? onBack;
  final VoidCallback? onHint;
  final VoidCallback? onSkip;

  @override
  State<MatchingTemplate> createState() => _MatchingTemplateState();
}

class _MatchingTemplateState extends State<MatchingTemplate> {
  final Map<String, String> _matches = {};
  String? _activeLeftId;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.shortestSide < 600;
    final progress = widget.totalQuestions <= 0
        ? 0.0
        : (widget.currentQuestion / widget.totalQuestions).clamp(0.0, 1.0);
    final canSubmit = _matches.length == widget.question.matchingPairs.length;

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
            _MatchingHeader(
              currentQuestion: widget.currentQuestion,
              totalQuestions: widget.totalQuestions,
              progress: progress,
              onBack: widget.onBack,
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 24),
            _MatchingMascotIntro(compact: compact),
            SizedBox(height: compact ? 8 : 24),
            _QuestionCard(
              question: widget.question,
              matches: _matches,
              activeLeftId: _activeLeftId,
              compact: compact,
              onLeftTap: (leftId) => setState(() => _activeLeftId = leftId),
              onRightTap: _matchActiveLeft,
              onDropped: _setMatch,
              onClearMatch: _clearMatch,
              onCheckAnswer: canSubmit
                  ? () => widget.onCheckAnswer(Map.of(_matches))
                  : null,
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

  void _matchActiveLeft(String rightId) {
    if (_activeLeftId == null) return;
    _setMatch(_activeLeftId!, rightId);
    setState(() => _activeLeftId = null);
  }

  void _setMatch(String leftId, String rightId) {
    setState(() {
      _matches.removeWhere((_, matchedRightId) => matchedRightId == rightId);
      _matches[leftId] = rightId;
    });
  }

  void _clearMatch(String leftId) {
    setState(() => _matches.remove(leftId));
  }
}

class _MatchingHeader extends StatelessWidget {
  const _MatchingHeader({
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
                color: _matchingInk,
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
                  color: _matchingInk,
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
                            color: _matchingYellow,
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
                        color: _matchingInk,
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

class _MatchingMascotIntro extends StatelessWidget {
  const _MatchingMascotIntro({required this.compact});

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
                    style: TextStyle(color: _matchingGreen),
                  ),
                  const TextSpan(
                    text:
                        '!\nTarik jawaban di kanan dan pasangkan dengan yang sesuai di kiri ya.',
                  ),
                ],
              ),
              style: TextStyle(
                color: _matchingInk,
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
    required this.matches,
    required this.activeLeftId,
    required this.compact,
    required this.onLeftTap,
    required this.onRightTap,
    required this.onDropped,
    required this.onClearMatch,
    required this.onCheckAnswer,
  });

  final TemplateQuestion question;
  final Map<String, String> matches;
  final String? activeLeftId;
  final bool compact;
  final ValueChanged<String> onLeftTap;
  final ValueChanged<String> onRightTap;
  final void Function(String leftId, String rightId) onDropped;
  final ValueChanged<String> onClearMatch;
  final VoidCallback? onCheckAnswer;

  @override
  Widget build(BuildContext context) {
    final rightPairs = question.matchingPairs;
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
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 16,
                vertical: compact ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: _matchingYellow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.hub_rounded,
                    color: const Color(0xFFD89B00),
                    size: compact ? 18 : 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Template 5 \u2022 Matching',
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
          SizedBox(height: compact ? 8 : 20),
          Text(
            question.prompt,
            style: TextStyle(
              color: _matchingInk,
              fontSize: compact ? 22 : 28,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            question.instruction ??
                'Tarik jawaban dari kanan ke kotak di kiri.',
            style: TextStyle(
              color: const Color(0xFF8C8274),
              fontSize: compact ? 15 : 19,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 8 : 28),
          Row(
            children: [
              Expanded(
                child: _ColumnTitle(text: 'Istilah', compact: compact),
              ),
              SizedBox(width: compact ? 6 : 18),
              Expanded(
                child: _ColumnTitle(text: 'Pengertian', compact: compact),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (var index = 0;
                        index < question.matchingPairs.length;
                        index++) ...[
                      _LeftMatchCard(
                        pair: question.matchingPairs[index],
                        number: index + 1,
                        matchedLabel: _rightLabelFor(
                            matches[question.matchingPairs[index].leftId]),
                        selected: activeLeftId ==
                            question.matchingPairs[index].leftId,
                        compact: compact,
                        onTap: () =>
                            onLeftTap(question.matchingPairs[index].leftId),
                        onDropped: (rightId) => onDropped(
                          question.matchingPairs[index].leftId,
                          rightId,
                        ),
                        onClear: () =>
                            onClearMatch(question.matchingPairs[index].leftId),
                      ),
                      SizedBox(height: compact ? 10 : 14),
                    ],
                  ],
                ),
              ),
              SizedBox(width: compact ? 6 : 18),
              Expanded(
                child: Column(
                  children: [
                    for (var index = 0; index < rightPairs.length; index++) ...[
                      _RightMatchCard(
                        pair: rightPairs[index],
                        letter: String.fromCharCode(65 + index),
                        used: matches.containsValue(rightPairs[index].rightId),
                        compact: compact,
                        onTap: () => onRightTap(rightPairs[index].rightId),
                      ),
                      SizedBox(height: compact ? 10 : 14),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 14),
          FilledButton(
            onPressed: onCheckAnswer,
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(compact ? 54 : 72),
              backgroundColor: _matchingYellow,
              foregroundColor: _matchingInk,
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

  String? _rightLabelFor(String? rightId) {
    if (rightId == null) return null;
    for (final pair in question.matchingPairs) {
      if (pair.rightId == rightId) return pair.rightLabel;
    }
    return null;
  }
}

class _ColumnTitle extends StatelessWidget {
  const _ColumnTitle({required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 20,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0C2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: _matchingInk,
            fontSize: compact ? 12 : 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LeftMatchCard extends StatelessWidget {
  const _LeftMatchCard({
    required this.pair,
    required this.number,
    required this.matchedLabel,
    required this.selected,
    required this.compact,
    required this.onTap,
    required this.onDropped,
    required this.onClear,
  });

  final MatchingPair pair;
  final int number;
  final String? matchedLabel;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;
  final ValueChanged<String> onDropped;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onDropped(details.data),
      builder: (context, candidateData, _) {
        final hovering = candidateData.isNotEmpty;
        return Material(
          color: selected || hovering
              ? const Color(0xFFFFF8D9)
              : const Color(0xFFFFFCF5),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: BoxConstraints(minHeight: compact ? 70 : 90),
              padding: EdgeInsets.all(compact ? 10 : 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected || hovering
                      ? _matchingYellow
                      : const Color(0xFFEEDDAE),
                  width: selected || hovering ? 2 : 1.2,
                ),
              ),
              child: Row(
                children: [
                  _CircleLabel(label: '$number', compact: compact),
                  SizedBox(width: compact ? 8 : 12),
                  Expanded(
                    child: Text(
                      pair.leftLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _matchingInk,
                        fontSize: compact ? 14 : 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(width: compact ? 8 : 12),
                  GestureDetector(
                    onTap: matchedLabel == null ? null : onClear,
                    child: Container(
                      width: compact ? 54 : 76,
                      height: compact ? 46 : 58,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: matchedLabel == null
                            ? Colors.transparent
                            : const Color(0xFFFFF0C2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _matchingYellow,
                          width: 1.4,
                          style: matchedLabel == null
                              ? BorderStyle.solid
                              : BorderStyle.none,
                        ),
                      ),
                      child: matchedLabel == null
                          ? const SizedBox.shrink()
                          : Text(
                              matchedLabel!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _matchingInk,
                                fontSize: compact ? 10 : 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RightMatchCard extends StatelessWidget {
  const _RightMatchCard({
    required this.pair,
    required this.letter,
    required this.used,
    required this.compact,
    required this.onTap,
  });

  final MatchingPair pair;
  final String letter;
  final bool used;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: used ? const Color(0xFFFFF8D9) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: used ? 1 : 3,
      shadowColor: const Color(0x12000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 70 : 90),
          padding: EdgeInsets.all(compact ? 10 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEDDAE), width: 1.1),
          ),
          child: Row(
            children: [
              Icon(
                Icons.drag_indicator_rounded,
                color: const Color(0xFF9A9690),
                size: compact ? 18 : 24,
              ),
              SizedBox(width: compact ? 4 : 8),
              _CircleLabel(label: letter, compact: compact),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Text(
                  pair.rightLabel,
                  maxLines: compact ? 3 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _matchingInk,
                    fontSize: compact ? 12 : 16,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Draggable<String>(
      data: pair.rightId,
      feedback: SizedBox(
        width: compact ? 150 : 190,
        child: Material(
          color: Colors.transparent,
          child: Opacity(opacity: 0.92, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.45, child: card),
      child: card,
    );
  }
}

class _CircleLabel extends StatelessWidget {
  const _CircleLabel({required this.label, required this.compact});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 30 : 38,
      height: compact ? 30 : 38,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFFFE9A8),
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _matchingInk,
          fontSize: compact ? 14 : 17,
          fontWeight: FontWeight.w900,
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
              color: _matchingGreen,
              size: compact ? 22 : 28,
            ),
            label: Text(
              'Butuh petunjuk?',
              style: TextStyle(
                color: _matchingGreen,
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
