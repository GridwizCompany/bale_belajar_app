// ignore_for_file: unused_element

import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'test_template_ui_helpers.dart';

const _yellow = Color(0xFFF4B400);
const _ink = Color(0xFF3B2318);
const _green = Color(0xFF2F9B42);

class EvidenceBoardTemplate extends StatefulWidget {
  const EvidenceBoardTemplate({
    required this.question,
    required this.onCheckAnswer,
    this.currentQuestion = 14,
    this.totalQuestions = 20,
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
  State<EvidenceBoardTemplate> createState() => _EvidenceBoardTemplateState();
}

class _EvidenceBoardTemplateState extends State<EvidenceBoardTemplate> {
  final Map<String, String> _placements = {};
  String? _selectedEvidenceId;

  late final List<EvidenceItem> _evidenceItems =
      widget.question.evidenceItems.isNotEmpty
          ? [...widget.question.evidenceItems]
          : _fallbackEvidence;

  static const _categories = [
    _EvidenceCategory(
      id: 'person',
      title: 'Orang / Pelaku',
      description: 'Bukti yang berkaitan dengan orang atau pelaku.',
      color: Color(0xFF25A85A),
      icon: Icons.fingerprint_rounded,
    ),
    _EvidenceCategory(
      id: 'location',
      title: 'Lokasi',
      description: 'Bukti yang berkaitan dengan tempat atau lokasi.',
      color: Color(0xFF2D7FD3),
      icon: Icons.location_on_rounded,
    ),
    _EvidenceCategory(
      id: 'object',
      title: 'Barang / Benda',
      description: 'Bukti yang berupa barang atau benda penting.',
      color: Color(0xFFF26B21),
      icon: Icons.search_rounded,
    ),
    _EvidenceCategory(
      id: 'document',
      title: 'Dokumen / Catatan',
      description: 'Bukti berupa surat, catatan, atau dokumen.',
      color: Color(0xFF8E44AD),
      icon: Icons.description_rounded,
    ),
  ];

  static const _fallbackEvidence = [
    EvidenceItem(
      id: 'shoe-print',
      label: 'Jejak sepatu di tanah',
      category: 'object',
    ),
    EvidenceItem(
      id: 'note',
      label: 'Catatan tulisan tangan',
      category: 'document',
    ),
    EvidenceItem(id: 'black-hat', label: 'Topi hitam', category: 'object'),
    EvidenceItem(id: 'map', label: 'Peta lokasi gudang', category: 'location'),
    EvidenceItem(
      id: 'cctv',
      label: 'Rekaman CCTV pukul 20.45',
      category: 'document',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.shortestSide < 600;
    final progress = widget.totalQuestions <= 0
        ? 0.0
        : (widget.currentQuestion / widget.totalQuestions).clamp(0.0, 1.0);
    final usedIds = _placements.keys.toSet();
    final canSubmit = _placements.isNotEmpty;

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
            _Header(
              currentQuestion: widget.currentQuestion,
              totalQuestions: widget.totalQuestions,
              progress: progress,
              compact: compact,
              onBack: widget.onBack,
            ),
            SizedBox(height: compact ? 8 : 22),
            _MascotIntro(compact: compact),
            SizedBox(height: compact ? 8 : 22),
            _QuestionCard(
              question: widget.question,
              categories: _categories,
              evidenceItems: _evidenceItems,
              placements: _placements,
              usedIds: usedIds,
              selectedEvidenceId: _selectedEvidenceId,
              compact: compact,
              onSelectEvidence: (id) =>
                  setState(() => _selectedEvidenceId = id),
              onPlaceEvidence: _placeEvidence,
              onRemoveEvidence: _removeEvidence,
              onCheckAnswer: canSubmit
                  ? () => widget.onCheckAnswer(
                        _placements.entries
                            .map((entry) => '${entry.key}:${entry.value}')
                            .toSet(),
                      )
                  : null,
            ),
            SizedBox(height: compact ? 10 : 16),
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

  void _placeEvidence(String categoryId, String evidenceId) {
    setState(() {
      _placements[evidenceId] = categoryId;
      _selectedEvidenceId = null;
    });
  }

  void _removeEvidence(String evidenceId) {
    setState(() => _placements.remove(evidenceId));
  }
}

class _Header extends StatelessWidget {
  const _Header({
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
                color: _ink,
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
                  color: _ink,
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
                            color: _yellow,
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
                        color: _ink,
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

class _MascotIntro extends StatelessWidget {
  const _MascotIntro({required this.compact});

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
          flex: 12,
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
                  const TextSpan(
                    text: 'Babe',
                    style: TextStyle(color: _green),
                  ),
                  const TextSpan(
                    text:
                        '!\nKamu adalah detektif hebat! Susun bukti ke papan yang sesuai.',
                  ),
                ],
              ),
              style: TextStyle(
                color: _ink,
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
    required this.categories,
    required this.evidenceItems,
    required this.placements,
    required this.usedIds,
    required this.selectedEvidenceId,
    required this.compact,
    required this.onSelectEvidence,
    required this.onPlaceEvidence,
    required this.onRemoveEvidence,
    required this.onCheckAnswer,
  });

  final TemplateQuestion question;
  final List<_EvidenceCategory> categories;
  final List<EvidenceItem> evidenceItems;
  final Map<String, String> placements;
  final Set<String> usedIds;
  final String? selectedEvidenceId;
  final bool compact;
  final ValueChanged<String> onSelectEvidence;
  final void Function(String categoryId, String evidenceId) onPlaceEvidence;
  final ValueChanged<String> onRemoveEvidence;
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
          const _Badge(),
          SizedBox(height: compact ? 8 : 20),
          Text(
            question.prompt,
            style: TextStyle(
              color: _ink,
              fontSize: compact ? 21 : 26,
              height: 1.18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            question.instruction ??
                'Drag & drop kartu bukti ke papan bukti di bawah ini.',
            style: TextStyle(
              color: const Color(0xFF82786E),
              fontSize: compact ? 14 : 16,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 8 : 22),
          _CategoryBoard(
            categories: categories,
            evidenceItems: evidenceItems,
            placements: placements,
            selectedEvidenceId: selectedEvidenceId,
            compact: compact,
            onPlaceEvidence: onPlaceEvidence,
            onRemoveEvidence: onRemoveEvidence,
          ),
          SizedBox(height: compact ? 8 : 22),
          _EvidenceTray(
            evidenceItems: evidenceItems,
            usedIds: usedIds,
            selectedEvidenceId: selectedEvidenceId,
            compact: compact,
            onSelectEvidence: onSelectEvidence,
          ),
          SizedBox(height: compact ? 8 : 22),
          FilledButton(
            onPressed: onCheckAnswer,
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(compact ? 54 : 66),
              backgroundColor: _yellow,
              foregroundColor: _ink,
              disabledBackgroundColor: const Color(0xFFE8E0D2),
              disabledForegroundColor: const Color(0xFF8C8274),
              elevation: 8,
              shadowColor: const Color(0x55F4B400),
              textStyle: TextStyle(
                fontSize: compact ? 20 : 26,
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
  const _Badge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _yellow.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business_center_rounded, color: Color(0xFFD89B00)),
            SizedBox(width: 8),
            Text(
              'Template 14 • Evidence Board',
              style: TextStyle(
                color: Color(0xFFD89B00),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBoard extends StatelessWidget {
  const _CategoryBoard({
    required this.categories,
    required this.evidenceItems,
    required this.placements,
    required this.selectedEvidenceId,
    required this.compact,
    required this.onPlaceEvidence,
    required this.onRemoveEvidence,
  });

  final List<_EvidenceCategory> categories;
  final List<EvidenceItem> evidenceItems;
  final Map<String, String> placements;
  final String? selectedEvidenceId;
  final bool compact;
  final void Function(String categoryId, String evidenceId) onPlaceEvidence;
  final ValueChanged<String> onRemoveEvidence;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 560 ? 2 : 4;
        final gap = compact ? 10.0 : 14.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final category in categories)
              SizedBox(
                width: width,
                child: _CategoryColumn(
                  category: category,
                  evidenceItems: evidenceItems
                      .where((item) => placements[item.id] == category.id)
                      .toList(),
                  selectedEvidenceId: selectedEvidenceId,
                  compact: compact,
                  onPlaceEvidence: onPlaceEvidence,
                  onRemoveEvidence: onRemoveEvidence,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryColumn extends StatelessWidget {
  const _CategoryColumn({
    required this.category,
    required this.evidenceItems,
    required this.selectedEvidenceId,
    required this.compact,
    required this.onPlaceEvidence,
    required this.onRemoveEvidence,
  });

  final _EvidenceCategory category;
  final List<EvidenceItem> evidenceItems;
  final String? selectedEvidenceId;
  final bool compact;
  final void Function(String categoryId, String evidenceId) onPlaceEvidence;
  final ValueChanged<String> onRemoveEvidence;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) =>
          onPlaceEvidence(category.id, details.data),
      builder: (context, candidateData, _) {
        final hovering = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: selectedEvidenceId == null
              ? null
              : () => onPlaceEvidence(category.id, selectedEvidenceId!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.all(compact ? 10 : 12),
            constraints: BoxConstraints(minHeight: compact ? 172 : 230),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: hovering ? 0.12 : 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: category.color.withValues(alpha: hovering ? 0.65 : 0.28),
                width: hovering ? 2 : 1.2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  category.icon,
                  color: category.color,
                  size: compact ? 24 : 30,
                ),
                const SizedBox(height: 6),
                Text(
                  category.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: category.color,
                    fontSize: compact ? 12 : 14,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 7 : 10),
                Text(
                  category.description,
                  textAlign: TextAlign.center,
                  maxLines: compact ? 3 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: compact ? 10 : 12,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: compact ? 10 : 14),
                Expanded(
                  child: evidenceItems.isEmpty
                      ? _DropPlaceholder(category: category, compact: compact)
                      : ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: evidenceItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) => _PlacedEvidenceChip(
                            evidence: evidenceItems[index],
                            category: category,
                            compact: compact,
                            onRemove: () =>
                                onRemoveEvidence(evidenceItems[index].id),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DropPlaceholder extends StatelessWidget {
  const _DropPlaceholder({required this.category, required this.compact});

  final _EvidenceCategory category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: category.color.withValues(alpha: 0.55),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: category.color.withValues(alpha: 0.32),
            size: compact ? 34 : 46,
          ),
          const SizedBox(height: 8),
          Text(
            'Letakkan di sini',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF6F727A),
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacedEvidenceChip extends StatelessWidget {
  const _PlacedEvidenceChip({
    required this.evidence,
    required this.category,
    required this.compact,
    required this.onRemove,
  });

  final EvidenceItem evidence;
  final _EvidenceCategory category;
  final bool compact;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 9,
            vertical: compact ? 7 : 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: category.color.withValues(alpha: 0.35)),
          ),
          child: Text(
            evidence.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _ink,
              fontSize: compact ? 10 : 12,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _EvidenceTray extends StatelessWidget {
  const _EvidenceTray({
    required this.evidenceItems,
    required this.usedIds,
    required this.selectedEvidenceId,
    required this.compact,
    required this.onSelectEvidence,
  });

  final List<EvidenceItem> evidenceItems;
  final Set<String> usedIds;
  final String? selectedEvidenceId;
  final bool compact;
  final ValueChanged<String> onSelectEvidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2ECF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih kartu bukti di bawah ini, lalu seret ke papan yang sesuai.',
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
                for (var index = 0; index < evidenceItems.length; index++) ...[
                  _EvidenceCard(
                    evidence: evidenceItems[index],
                    number: index + 1,
                    used: usedIds.contains(evidenceItems[index].id),
                    selected: selectedEvidenceId == evidenceItems[index].id,
                    compact: compact,
                    onTap: () => onSelectEvidence(evidenceItems[index].id),
                  ),
                  if (index != evidenceItems.length - 1)
                    SizedBox(width: compact ? 10 : 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.evidence,
    required this.number,
    required this.used,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final EvidenceItem evidence;
  final int number;
  final bool used;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: selected ? const Color(0xFFFFF8D9) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: selected ? 5 : 2,
      shadowColor: const Color(0x15000000),
      child: InkWell(
        onTap: used ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: used ? 0.42 : 1,
          child: Container(
            width: compact ? 106 : 126,
            height: compact ? 142 : 166,
            padding: EdgeInsets.all(compact ? 8 : 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? _yellow : const Color(0xFFE9E1D6),
                width: selected ? 2 : 1.1,
              ),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: compact ? 24 : 28,
                    height: compact ? 24 : 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _yellow,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  _evidenceIcon(evidence),
                  color: const Color(0xFF5F6570),
                  size: compact ? 42 : 52,
                ),
                const Spacer(),
                Text(
                  evidence.label,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: compact ? 11 : 13,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Icon(
                  Icons.drag_indicator_rounded,
                  color: Color(0xFFD8CBB5),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Draggable<String>(
      data: evidence.id,
      feedback: SizedBox(
        width: compact ? 106 : 126,
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

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 13 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAEC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            color: _green,
            size: compact ? 32 : 40,
          ),
          SizedBox(width: compact ? 10 : 14),
          const Expanded(
            child: Text(
              'Tips\n- Baca deskripsi setiap bukti dengan teliti.\n- Pastikan setiap bukti masuk kategori paling sesuai.\n- Kamu bisa mengubah posisi sebelum memeriksa.',
              style: TextStyle(
                color: _ink,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Icon(
            Icons.manage_search_rounded,
            color: _yellow,
            size: compact ? 44 : 58,
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
              color: _green,
              size: compact ? 22 : 28,
            ),
            label: Text(
              'Butuh petunjuk?',
              style: TextStyle(
                color: _green,
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

IconData _evidenceIcon(EvidenceItem evidence) {
  final id = evidence.id.toLowerCase();
  final label = evidence.label.toLowerCase();
  if (id.contains('shoe') || label.contains('jejak')) {
    return Icons.directions_walk_rounded;
  }
  if (id.contains('note') || label.contains('catatan')) {
    return Icons.sticky_note_2_rounded;
  }
  if (id.contains('hat') || label.contains('topi')) {
    return Icons.style_rounded;
  }
  if (id.contains('map') || label.contains('peta')) {
    return Icons.map_rounded;
  }
  if (id.contains('cctv') || label.contains('rekaman')) {
    return Icons.videocam_rounded;
  }
  return Icons.inventory_2_rounded;
}

class _EvidenceCategory {
  const _EvidenceCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final Color color;
  final IconData icon;
}
