// ignore_for_file: unused_element

import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'test_template_ui_helpers.dart';

const _timelineYellow = Color(0xFFF4B400);
const _timelineInk = Color(0xFF3B2318);
const _timelineGreen = Color(0xFF2F9B42);

class TimelineBuilderTemplate extends StatefulWidget {
  const TimelineBuilderTemplate({
    required this.question,
    required this.onCheckAnswer,
    this.currentQuestion = 13,
    this.totalQuestions = 20,
    this.onBack,
    this.onHint,
    this.onSkip,
    super.key,
  });

  final TemplateQuestion question;
  final ValueChanged<List<String>> onCheckAnswer;
  final int currentQuestion;
  final int totalQuestions;
  final VoidCallback? onBack;
  final VoidCallback? onHint;
  final VoidCallback? onSkip;

  @override
  State<TimelineBuilderTemplate> createState() =>
      _TimelineBuilderTemplateState();
}

class _TimelineBuilderTemplateState extends State<TimelineBuilderTemplate> {
  late final List<TimelineItem> _items = _initialItems;
  late final List<TimelineItem?> _slots = List.filled(_items.length, null);
  String? _selectedItemId;

  List<TimelineItem> get _initialItems {
    if (widget.question.timelineItems.isNotEmpty) {
      return [...widget.question.timelineItems];
    }
    return const [
      TimelineItem(id: 'a', label: 'Ayam berkokok menyambut pagi.'),
      TimelineItem(id: 'b', label: 'Udin bangun tidur.'),
      TimelineItem(id: 'c', label: 'Udin sarapan sebelum pergi ke sekolah.'),
      TimelineItem(id: 'd', label: 'Udin sampai di sekolah tepat waktu.'),
      TimelineItem(id: 'e', label: 'Udin berangkat ke sekolah.'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.shortestSide < 600;
    final progress = widget.totalQuestions <= 0
        ? 0.0
        : (widget.currentQuestion / widget.totalQuestions).clamp(0.0, 1.0);
    final canSubmit = _slots.every((item) => item != null);

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
            _TimelineHeader(
              currentQuestion: widget.currentQuestion,
              totalQuestions: widget.totalQuestions,
              progress: progress,
              compact: compact,
              onBack: widget.onBack,
            ),
            SizedBox(height: compact ? 8 : 24),
            _TimelineMascotIntro(compact: compact),
            SizedBox(height: compact ? 8 : 24),
            _QuestionCard(
              question: widget.question,
              items: _items,
              slots: _slots,
              selectedItemId: _selectedItemId,
              compact: compact,
              onSelectItem: (itemId) =>
                  setState(() => _selectedItemId = itemId),
              onPlaceItem: _placeItem,
              onRemoveSlot: _removeSlot,
              onCheckAnswer: canSubmit
                  ? () => widget.onCheckAnswer(
                        _slots
                            .whereType<TimelineItem>()
                            .map((item) => item.id)
                            .toList(),
                      )
                  : null,
            ),
            SizedBox(height: compact ? 6 : 18),
            _BottomActions(
              compact: compact,
              onHint: widget.onHint,
              onSkip: widget.onSkip,
            ),
          ],
        ),
      ),
    );
  }

  void _placeItem(int slotIndex, String itemId) {
    final item = _items.firstWhere((item) => item.id == itemId);
    setState(() {
      for (var index = 0; index < _slots.length; index++) {
        if (_slots[index]?.id == itemId) _slots[index] = null;
      }
      _slots[slotIndex] = item;
      _selectedItemId = null;
    });
  }

  void _removeSlot(int slotIndex) {
    setState(() => _slots[slotIndex] = null);
  }
}

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({
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
                color: _timelineInk,
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
                  color: _timelineInk,
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
                            color: _timelineYellow,
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
                        color: _timelineInk,
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

class _TimelineMascotIntro extends StatelessWidget {
  const _TimelineMascotIntro({required this.compact});

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
                    style: TextStyle(color: _timelineGreen),
                  ),
                  const TextSpan(
                    text:
                        '!\nSusun peristiwa berikut menjadi urutan yang tepat dari awal hingga akhir.',
                  ),
                ],
              ),
              style: TextStyle(
                color: _timelineInk,
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
    required this.items,
    required this.slots,
    required this.selectedItemId,
    required this.compact,
    required this.onSelectItem,
    required this.onPlaceItem,
    required this.onRemoveSlot,
    required this.onCheckAnswer,
  });

  final TemplateQuestion question;
  final List<TimelineItem> items;
  final List<TimelineItem?> slots;
  final String? selectedItemId;
  final bool compact;
  final ValueChanged<String> onSelectItem;
  final void Function(int slotIndex, String itemId) onPlaceItem;
  final ValueChanged<int> onRemoveSlot;
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
          _Badge(compact: compact),
          SizedBox(height: compact ? 8 : 20),
          Text(
            question.prompt,
            style: TextStyle(
              color: _timelineInk,
              fontSize: compact ? 16 : 28,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            question.instruction ??
                'Drag & drop kartu peristiwa ke dalam timeline dari kiri ke kanan.',
            style: TextStyle(
              color: const Color(0xFF8C8274),
              fontSize: compact ? 12 : 19,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 8 : 28),
          _TimelineSlots(
            slots: slots,
            selectedItemId: selectedItemId,
            compact: compact,
            onPlaceItem: onPlaceItem,
            onRemoveSlot: onRemoveSlot,
          ),
          SizedBox(height: compact ? 8 : 22),
          _EventCardsPanel(
            items: items,
            usedIds:
                slots.whereType<TimelineItem>().map((item) => item.id).toSet(),
            selectedItemId: selectedItemId,
            compact: compact,
            onSelectItem: onSelectItem,
          ),
          SizedBox(height: compact ? 8 : 28),
          FilledButton(
            onPressed: onCheckAnswer,
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(compact ? 46 : 72),
              backgroundColor: _timelineYellow,
              foregroundColor: _timelineInk,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: _timelineYellow.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timelapse_rounded,
              color: const Color(0xFFD89B00),
              size: compact ? 18 : 22,
            ),
            const SizedBox(width: 8),
            Text(
              compact ? 'Template 13' : 'Template 13 \u2022 Timeline Builder',
              style: TextStyle(
                color: const Color(0xFFD89B00),
                fontSize: compact ? 11 : 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineSlots extends StatelessWidget {
  const _TimelineSlots({
    required this.slots,
    required this.selectedItemId,
    required this.compact,
    required this.onPlaceItem,
    required this.onRemoveSlot,
  });

  final List<TimelineItem?> slots;
  final String? selectedItemId;
  final bool compact;
  final void Function(int slotIndex, String itemId) onPlaceItem;
  final ValueChanged<int> onRemoveSlot;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < slots.length; index++) ...[
            _TimelineSlot(
              index: index,
              item: slots[index],
              selectedItemId: selectedItemId,
              compact: compact,
              onPlaceItem: onPlaceItem,
              onRemove: () => onRemoveSlot(index),
            ),
            if (index != slots.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFFE4B966),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TimelineSlot extends StatelessWidget {
  const _TimelineSlot({
    required this.index,
    required this.item,
    required this.selectedItemId,
    required this.compact,
    required this.onPlaceItem,
    required this.onRemove,
  });

  final int index;
  final TimelineItem? item;
  final String? selectedItemId;
  final bool compact;
  final void Function(int slotIndex, String itemId) onPlaceItem;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onPlaceItem(index, details.data),
      builder: (context, candidateData, _) {
        final hovering = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: selectedItemId == null
              ? item == null
                  ? null
                  : onRemove
              : () => onPlaceItem(index, selectedItemId!),
          child: Container(
            width: compact ? 112 : 144,
            height: compact ? 142 : 174,
            decoration: BoxDecoration(
              color:
                  hovering ? const Color(0xFFFFF8D9) : const Color(0xFFFFFCF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _timelineYellow,
                width: hovering ? 2 : 1.2,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: -18,
                  child: Container(
                    width: compact ? 38 : 46,
                    height: compact ? 38 : 46,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _timelineYellow,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 0 : 0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(10, compact ? 18 : 24, 10, 10),
                  child: item == null
                      ? _EmptySlotContent(
                          first: index == 0,
                          last: index == 4,
                          compact: compact,
                        )
                      : _FilledSlotContent(item: item!, compact: compact),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptySlotContent extends StatelessWidget {
  const _EmptySlotContent({
    required this.first,
    required this.last,
    required this.compact,
  });

  final bool first;
  final bool last;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          first
              ? 'Awal'
              : last
                  ? 'Akhir'
                  : '',
          style: TextStyle(
            color: _timelineInk,
            fontSize: compact ? 14 : 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        Icon(
          Icons.image_outlined,
          color: const Color(0xFFD8CBB5),
          size: compact ? 30 : 48,
        ),
        SizedBox(height: compact ? 4 : 8),
        Text(
          'Letakkan\ndi sini',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF747985),
            fontSize: compact ? 10 : 15,
            height: compact ? 1.1 : 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FilledSlotContent extends StatelessWidget {
  const _FilledSlotContent({required this.item, required this.compact});

  final TimelineItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _EventIcon(item: item, size: compact ? 42 : 54),
        const SizedBox(height: 8),
        Text(
          item.label,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _timelineInk,
            fontSize: compact ? 11 : 13,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EventCardsPanel extends StatelessWidget {
  const _EventCardsPanel({
    required this.items,
    required this.usedIds,
    required this.selectedItemId,
    required this.compact,
    required this.onSelectItem,
  });

  final List<TimelineItem> items;
  final Set<String> usedIds;
  final String? selectedItemId;
  final bool compact;
  final ValueChanged<String> onSelectItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB7D8FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih kartu peristiwa lalu susun sesuai urutan yang benar.',
            style: TextStyle(
              color: const Color(0xFF5F6570),
              fontSize: compact ? 13 : 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  _EventCard(
                    item: items[index],
                    letter: String.fromCharCode(65 + index),
                    used: usedIds.contains(items[index].id),
                    selected: selectedItemId == items[index].id,
                    compact: compact,
                    onTap: () => onSelectItem(items[index].id),
                  ),
                  if (index != items.length - 1) const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.item,
    required this.letter,
    required this.used,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final TimelineItem item;
  final String letter;
  final bool used;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: selected ? const Color(0xFFFFF8D9) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: selected ? 6 : 2,
      shadowColor: const Color(0x15000000),
      child: InkWell(
        onTap: used ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: used ? 0.45 : 1,
          child: Container(
            width: compact ? 104 : 138,
            height: compact ? 150 : 200,
            padding: EdgeInsets.all(compact ? 8 : 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _timelineYellow : const Color(0xFFE9E1D6),
                width: selected ? 2 : 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 24 : 32,
                  height: compact ? 24 : 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1976D2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    letter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 4 : 8),
                Center(child: _EventIcon(item: item, size: compact ? 40 : 70)),
                SizedBox(height: compact ? 5 : 8),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: compact ? 4 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _timelineInk,
                      fontSize: compact ? 10 : 14,
                      height: compact ? 1.08 : 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  const Center(
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: Color(0xFFD8CBB5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Draggable<String>(
      data: item.id,
      feedback: SizedBox(
        width: compact ? 104 : 138,
        child: Material(
          color: Colors.transparent,
          child: Opacity(opacity: 0.92, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }
}

class _EventIcon extends StatelessWidget {
  const _EventIcon({required this.item, required this.size});

  final TimelineItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.id) {
      'a' || 'rooster' => Icons.wb_sunny_rounded,
      'b' || 'wake' => Icons.bed_rounded,
      'c' || 'breakfast' => Icons.breakfast_dining_rounded,
      'd' || 'school' => Icons.school_rounded,
      'e' || 'walk' => Icons.directions_walk_rounded,
      _ => Icons.event_note_rounded,
    };
    final color = switch (item.id) {
      'a' || 'rooster' => const Color(0xFFFFA629),
      'b' || 'wake' => const Color(0xFF4CA5F0),
      'c' || 'breakfast' => const Color(0xFFFFB74D),
      'd' || 'school' => const Color(0xFF4CAF50),
      'e' || 'walk' => const Color(0xFF1976D2),
      _ => _timelineYellow,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size * 0.58),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAEC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            color: _timelineGreen,
            size: compact ? 34 : 42,
          ),
          SizedBox(width: compact ? 12 : 16),
          const Expanded(
            child: Text(
              'Tips\n• Perhatikan hubungan sebab-akibat antar peristiwa.\n• Bayangkan alur waktu dari awal hingga akhir.',
              style: TextStyle(
                color: _timelineInk,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: compact ? 8 : 12),
          Icon(
            Icons.record_voice_over_rounded,
            color: const Color(0xFFFFA629),
            size: compact ? 46 : 62,
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
              color: _timelineGreen,
              size: compact ? 22 : 28,
            ),
            label: Text(
              'Butuh petunjuk?',
              style: TextStyle(
                color: _timelineGreen,
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
