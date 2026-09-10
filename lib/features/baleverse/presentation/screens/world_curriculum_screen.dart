import 'package:flutter/material.dart';

import '../../../quests/data/quest_repository.dart';
import '../../../quests/domain/quest_models.dart';
import '../../../quests/presentation/quest_screen.dart';
import '../../data/worlds_repository.dart';
import '../../domain/world_curriculum_models.dart';

const _bg = Color(0xFFFFF3C6);
const _ink = Color(0xFF3B2318);
const _yellow = Color(0xFFF4B400);
const _green = Color(0xFF4CAF50);

class WorldCurriculumScreen extends StatefulWidget {
  const WorldCurriculumScreen({required this.worldKey, super.key});

  final String worldKey;

  @override
  State<WorldCurriculumScreen> createState() => _WorldCurriculumScreenState();
}

class _WorldCurriculumScreenState extends State<WorldCurriculumScreen> {
  final WorldsRepository _repository = WorldsRepository();
  final QuestRepository _questRepository = QuestRepository();

  late Future<WorldCurriculum> _future;
  QuestDailyProgress? _dailyProgress;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchCurriculum(worldKey: widget.worldKey);
    _loadDailyProgress();
  }

  void _retry() {
    setState(() {
      _future = _repository.fetchCurriculum(worldKey: widget.worldKey);
    });
  }

  // Panel progress + "misi per hari" bersifat pelengkap - kalau gagal dimuat
  // (mis. offline), alur "Mulai Quest" utama tetap harus jalan seperti biasa.
  Future<void> _loadDailyProgress() async {
    try {
      final progress = await _questRepository.fetchTodayAll(widget.worldKey);
      if (mounted) setState(() => _dailyProgress = progress);
    } catch (_) {
      // diam-diam - lihat komentar di atas
    }
  }

  Future<void> _updateDailyQuestCount(int value) async {
    final previous = _dailyProgress;
    try {
      await _questRepository.updateDailyQuestCount(value);
      await _loadDailyProgress();
    } catch (error) {
      if (mounted) {
        setState(() => _dailyProgress = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan pengaturan: $error')),
        );
      }
    }
  }

  void _openQuest({required bool requestNext}) {
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => QuestScreen(
              worldKey: widget.worldKey,
              requestNext: requestNext,
            ),
          ),
        )
        .then((_) => _loadDailyProgress());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FutureBuilder<WorldCurriculum>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _CenteredState(
                message: 'Menyiapkan materi...',
                showProgress: true,
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _CenteredState(
                message: 'Materi belum bisa dimuat.',
                onRetry: _retry,
              );
            }
            return _CurriculumContent(
              curriculum: snapshot.data!,
              dailyProgress: _dailyProgress,
              onStartQuest: () => _openQuest(requestNext: false),
              onRequestNext: () => _openQuest(requestNext: true),
              onChangeDailyQuestCount: _updateDailyQuestCount,
            );
          },
        ),
      ),
    );
  }
}

class _CurriculumContent extends StatelessWidget {
  const _CurriculumContent({
    required this.curriculum,
    required this.dailyProgress,
    required this.onStartQuest,
    required this.onRequestNext,
    required this.onChangeDailyQuestCount,
  });

  final WorldCurriculum curriculum;
  final QuestDailyProgress? dailyProgress;
  final VoidCallback onStartQuest;
  final VoidCallback onRequestNext;
  final ValueChanged<int> onChangeDailyQuestCount;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 820;
    final modules = curriculum.modules;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, compact ? 12 : 18, 16, 18),
            children: [
              _Header(curriculum: curriculum),
              const SizedBox(height: 14),
              _QuestDailySettingPanel(
                progress: dailyProgress,
                onChangeDailyQuestCount: onChangeDailyQuestCount,
              ),
              const SizedBox(height: 14),
              for (final module in modules) ...[
                _ModuleSection(module: module),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          color: _bg,
          child: _QuestActionButton(
            progress: dailyProgress,
            onStartQuest: onStartQuest,
            onRequestNext: onRequestNext,
          ),
        ),
      ],
    );
  }
}

/// Kartu "misi hari ini" + slider berapa misi per hari yang mau siswa ambil
/// (1-5, lihat StudentQuestSetting di backend) - mirip pola pengaturan
/// jumlah kosakata harian di VocabSettingsScreen.
class _QuestDailySettingPanel extends StatelessWidget {
  const _QuestDailySettingPanel({
    required this.progress,
    required this.onChangeDailyQuestCount,
  });

  final QuestDailyProgress? progress;
  final ValueChanged<int> onChangeDailyQuestCount;

  @override
  Widget build(BuildContext context) {
    final data = progress;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded, color: _green),
              const SizedBox(width: 8),
              Text(
                data == null
                    ? 'Misi hari ini'
                    : 'Misi hari ini: ${data.completedCount}/${data.assignments.length.clamp(1, 99)} selesai',
                style: const TextStyle(color: _ink, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Misi per hari:',
                style: TextStyle(color: Color(0xFF60646F), fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 10),
              for (var count = 1; count <= 5; count++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('$count'),
                    selected: data?.dailyQuestCount == count,
                    onSelected: data == null
                        ? null
                        : (_) => onChangeDailyQuestCount(count),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestActionButton extends StatelessWidget {
  const _QuestActionButton({
    required this.progress,
    required this.onStartQuest,
    required this.onRequestNext,
  });

  final QuestDailyProgress? progress;
  final VoidCallback onStartQuest;
  final VoidCallback onRequestNext;

  @override
  Widget build(BuildContext context) {
    final data = progress;
    final label = _label(data);
    final onPressed = _isDone(data) ? null : (data != null && data.canRequestNext
        ? onRequestNext
        : onStartQuest);

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  bool _isDone(QuestDailyProgress? data) {
    if (data == null) return false;
    return data.assignments.isNotEmpty &&
        data.completedCount == data.assignments.length &&
        !data.canRequestNext &&
        data.assignments.length >= data.dailyQuestCount;
  }

  String _label(QuestDailyProgress? data) {
    if (_isDone(data)) return 'Misi hari ini selesai semua';
    if (data == null || data.assignments.isEmpty) return 'Mulai Quest';
    if (data.canRequestNext) return 'Misi Lagi';
    return 'Lanjutkan Quest';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.curriculum});

  final WorldCurriculum curriculum;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Image.asset(
            'assets/mascot/kenalan.png',
            height: 92,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  curriculum.name,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  curriculum.characterClass,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _yellow,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  curriculum.themeDescription,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF60646F),
                    fontSize: 13,
                    height: 1.25,
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

class _ModuleSection extends StatelessWidget {
  const _ModuleSection({required this.module});

  final CurriculumModule module;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: _yellow),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  module.title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${module.estimatedMinutes}m',
                style: const TextStyle(
                  color: Color(0xFF60646F),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (module.simpleGoal.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              module.simpleGoal,
              style: const TextStyle(
                color: Color(0xFF60646F),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          for (final lesson in module.lessons) ...[
            _LessonBlock(lesson: lesson),
            const SizedBox(height: 10),
          ],
          if (module.caseStudies.isNotEmpty)
            for (final caseStudy in module.caseStudies) ...[
              _CaseStudyBlock(caseStudy: caseStudy),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _LessonBlock extends StatelessWidget {
  const _LessonBlock({required this.lesson});

  final CurriculumLesson lesson;

  @override
  Widget build(BuildContext context) {
    final items = lesson.items.isNotEmpty ? lesson.items : lesson.examples;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAEA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE0A1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.title,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (lesson.body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              lesson.body,
              style: const TextStyle(
                color: Color(0xFF60646F),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final item in items.take(4))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: _green,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: _ink,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CaseStudyBlock extends StatelessWidget {
  const _CaseStudyBlock({required this.caseStudy});

  final CurriculumCaseStudy caseStudy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB8E0BD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_alt_rounded, color: _green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  caseStudy.title,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (caseStudy.story.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              caseStudy.story,
              style: const TextStyle(
                color: Color(0xFF405C43),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (caseStudy.analysisSteps.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final step in caseStudy.analysisSteps)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.arrow_right_rounded,
                      color: _green,
                      size: 19,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(
                          color: Color(0xFF405C43),
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (caseStudy.commonMistake.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              caseStudy.commonMistake,
              style: const TextStyle(
                color: Color(0xFF7A4B18),
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE0A1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.message,
    this.showProgress = false,
    this.onRetry,
  });

  final String message;
  final bool showProgress;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress) ...[
              const CircularProgressIndicator(color: _yellow),
              const SizedBox(height: 18),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(backgroundColor: _yellow),
                child: const Text('Coba Lagi'),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}
