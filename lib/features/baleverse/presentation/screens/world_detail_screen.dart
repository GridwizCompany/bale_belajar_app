import 'package:flutter/material.dart';

import '../../data/mastery_repository.dart';
import '../../data/worlds_repository.dart';
import '../../domain/world_curriculum_models.dart';

const _bg = Color(0xFFFFF3C6);
const _ink = Color(0xFF3B2318);
const _yellow = Color(0xFFF4B400);
const _green = Color(0xFF4CAF50);
const _muted = Color(0xFF60646F);

Color _worldColor(Object? key) => switch (key) {
      'NUMERIA' => const Color(0xFF2D8CFF),
      'KODEX' => const Color(0xFF4CAF50),
      'DETECTIVIA' => const Color(0xFF8D5E34),
      _ => _yellow,
    };

IconData _worldIcon(Object? key) => switch (key) {
      'NUMERIA' => Icons.calculate_rounded,
      'KODEX' => Icons.code_rounded,
      'DETECTIVIA' => Icons.search_rounded,
      _ => Icons.public_rounded,
    };

// Backend butuh evidenceCount minimum sebelum status naik dari
// INSUFFICIENT_EVIDENCE (lihat mastery.util.ts) - evidenceCount > 0 dengan
// status itu berarti siswa SUDAH coba, cuma buktinya belum cukup untuk
// menilai penguasaan. Beda dengan "belum pernah dikerjakan sama sekali".
bool _isCollectingEvidence(CompetencyMastery competency) =>
    competency.status == 'INSUFFICIENT_EVIDENCE' &&
    competency.evidenceCount > 0;

String _statusLabel(CompetencyMastery competency) {
  if (_isCollectingEvidence(competency)) return 'Sedang dikerjakan';
  return switch (competency.status) {
    'MASTERED' => 'Menguasai',
    'DEVELOPING' => 'Berkembang',
    'NEEDS_PRACTICE' => 'Perlu latihan',
    _ => 'Belum mulai',
  };
}

Color _statusColor(CompetencyMastery competency) {
  if (_isCollectingEvidence(competency)) return const Color(0xFF2D8CFF);
  return switch (competency.status) {
    'MASTERED' => _green,
    'DEVELOPING' => const Color(0xFF2D8CFF),
    'NEEDS_PRACTICE' => const Color(0xFFF57C00),
    _ => const Color(0xFF8B8179),
  };
}

// Untuk kartu topik kurikulum (bukan baris rincian kompetensi).
String _topicStatusLabel(CompetencyMastery? mastery) {
  if (mastery == null) return 'Belum mulai';
  if (_isCollectingEvidence(mastery)) return 'Sedang dikerjakan';
  return switch (mastery.status) {
    'MASTERED' => 'Dikuasai',
    'DEVELOPING' => 'Berkembang',
    'NEEDS_PRACTICE' => 'Perlu latihan',
    _ => 'Belum mulai',
  };
}

IconData _topicStatusIcon(CompetencyMastery? mastery) {
  if (mastery == null) return Icons.radio_button_unchecked_rounded;
  if (_isCollectingEvidence(mastery)) return Icons.hourglass_top_rounded;
  return switch (mastery.status) {
    'MASTERED' => Icons.check_circle_rounded,
    'DEVELOPING' => Icons.trending_up_rounded,
    'NEEDS_PRACTICE' => Icons.refresh_rounded,
    _ => Icons.radio_button_unchecked_rounded,
  };
}

Color _topicStatusColor(CompetencyMastery? mastery) {
  if (mastery == null) return const Color(0xFF8B8179);
  if (_isCollectingEvidence(mastery)) return const Color(0xFF2D8CFF);
  return switch (mastery.status) {
    'MASTERED' => _green,
    'DEVELOPING' => const Color(0xFF2D8CFF),
    'NEEDS_PRACTICE' => const Color(0xFFF57C00),
    _ => const Color(0xFF8B8179),
  };
}

/// Detail satu dunia - kurikulum (materi apa saja) dan progres penguasaan
/// per kompetensi. Murni informasi (tidak mengganti dunia aktif) - ganti
/// dunia aktif dilakukan lewat Peta Perjalanan di Beranda.
///
/// Sengaja dibuat ringkas dan bisa diketuk (bukan tembok teks) - kartu topik
/// dan rincian penguasaan sama-sama collapsed by default, terbuka saat
/// diketuk. Topik yang belum dikuasai punya tombol "Kerjakan" - backend
/// belum bisa menargetkan quest ke satu topik spesifik, jadi ini membuka
/// quest hari ini untuk dunia ini (sama seperti tab Misi / WorldCurriculumScreen).
class WorldDetailScreen extends StatefulWidget {
  const WorldDetailScreen({
    required this.world,
    required this.onStartMission,
    super.key,
  });

  final Map<String, dynamic> world;
  final ValueChanged<String?> onStartMission;

  @override
  State<WorldDetailScreen> createState() => _WorldDetailScreenState();
}

class _WorldDetailScreenState extends State<WorldDetailScreen> {
  final WorldsRepository _worldsRepository = WorldsRepository();
  final MasteryRepository _masteryRepository = MasteryRepository();

  late Future<WorldCurriculum> _curriculumFuture;
  List<CompetencyMastery>? _mastery;
  bool _masteryLoading = true;

  String get _worldKey => (widget.world['key'] as String? ?? '').toLowerCase();

  @override
  void initState() {
    super.initState();
    _curriculumFuture = _worldsRepository.fetchCurriculum(worldKey: _worldKey);
    _loadMastery();
  }

  Future<void> _loadMastery() async {
    try {
      final competencies =
          await _masteryRepository.fetchGrowthMap(worldKey: _worldKey);
      if (!mounted) return;
      setState(() {
        _mastery = competencies;
        _masteryLoading = false;
      });
    } catch (error) {
      debugPrint(
          '[WorldDetailScreen] fetchGrowthMap($_worldKey) failed: $error');
      if (mounted) setState(() => _masteryLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _worldColor(widget.world['key']);
    final icon = _worldIcon(widget.world['key']);
    final questionCount = widget.world['activeQuestionCount'] as int? ?? 0;
    final masteryByCompetency = {
      for (final competency in _mastery ?? const <CompetencyMastery>[])
        competency.competencyId: competency,
    };

    return Container(
      color: _bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          _WorldHeaderCard(
            world: widget.world,
            color: color,
            icon: icon,
          ),
          const SizedBox(height: 12),
          _ProgressCard(
            color: color,
            loading: _masteryLoading,
            mastery: _mastery,
            questionCount: questionCount,
          ),
          const SizedBox(height: 16),
          FutureBuilder<WorldCurriculum>(
            future: _curriculumFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _StatePanel(
                  message: 'Menyiapkan kurikulum...',
                  showProgress: true,
                );
              }
              if (snapshot.hasError || snapshot.data == null) {
                debugPrint(
                  '[WorldDetailScreen] fetchCurriculum($_worldKey) failed: ${snapshot.error}',
                );
                return const _StatePanel(
                  message: 'Kurikulum belum bisa dimuat.',
                );
              }
              return _CurriculumSection(
                modules: snapshot.data!.modules,
                color: color,
                masteryByCompetency: masteryByCompetency,
                onStartMission: widget.onStartMission,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WorldHeaderCard extends StatelessWidget {
  const _WorldHeaderCard({
    required this.world,
    required this.color,
    required this.icon,
  });

  final Map<String, dynamic> world;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  world['name'] as String? ?? 'Dunia',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  world['subject'] as String? ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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

/// Kartu progres - ringkas by default (angka rata-rata + jumlah soal saja).
/// Ketuk untuk membuka rincian per topik, supaya tidak jadi tembok teks.
class _ProgressCard extends StatefulWidget {
  const _ProgressCard({
    required this.color,
    required this.loading,
    required this.mastery,
    required this.questionCount,
  });

  final Color color;
  final bool loading;
  final List<CompetencyMastery>? mastery;
  final int questionCount;

  @override
  State<_ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<_ProgressCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final competencies = widget.mastery ?? const <CompetencyMastery>[];
    final average = competencies.isEmpty
        ? 0.0
        : competencies.fold<double>(0, (sum, c) => sum + c.masteryScore) /
            competencies.length;
    final canExpand = !widget.loading && competencies.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: canExpand ? () => setState(() => _expanded = !_expanded) : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.loading)
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        color: _yellow,
                        strokeWidth: 3,
                      ),
                    )
                  else
                    Text(
                      '${average.round()}%',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Penguasaan rata-rata',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${widget.questionCount} soal aktif',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canExpand)
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.expand_more_rounded,
                        color: Color(0xFF8B8179),
                      ),
                    ),
                ],
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    children: [
                      for (final competency in competencies) ...[
                        _CompetencyRow(
                          competency: competency,
                          color: widget.color,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
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

class _CompetencyRow extends StatelessWidget {
  const _CompetencyRow({required this.competency, required this.color});

  final CompetencyMastery competency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            competency.competencyName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (competency.masteryScore / 100).clamp(0, 1),
              minHeight: 6,
              color: color,
              backgroundColor: const Color(0xFFFFE0A1),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: _statusColor(competency).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _statusLabel(competency),
            style: TextStyle(
              color: _statusColor(competency),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _CurriculumSection extends StatelessWidget {
  const _CurriculumSection({
    required this.modules,
    required this.color,
    required this.masteryByCompetency,
    required this.onStartMission,
  });

  final List<CurriculumModule> modules;
  final Color color;
  final Map<String, CompetencyMastery> masteryByCompetency;
  final ValueChanged<String?> onStartMission;

  @override
  Widget build(BuildContext context) {
    final masteredCount = modules
        .where((module) =>
            masteryByCompetency[module.competencyId]?.status == 'MASTERED')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Kurikulum - $masteredCount/${modules.length} dikuasai',
            style: const TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final module in modules) ...[
          _ModuleTile(
            module: module,
            color: color,
            mastery: masteryByCompetency[module.competencyId],
            onStartMission: onStartMission,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Satu topik kurikulum - collapsed hanya judul + durasi + status
/// penguasaan, ketuk untuk buka tujuan belajarnya. Tidak menampilkan semua
/// teks sekaligus.
class _ModuleTile extends StatefulWidget {
  const _ModuleTile({
    required this.module,
    required this.color,
    required this.mastery,
    required this.onStartMission,
  });

  final CurriculumModule module;
  final Color color;
  final CompetencyMastery? mastery;
  final ValueChanged<String?> onStartMission;

  @override
  State<_ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<_ModuleTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final hasGoal = module.simpleGoal.isNotEmpty;
    final mastery = widget.mastery;
    final statusColor = _topicStatusColor(mastery);
    final needsWork = mastery?.status != 'MASTERED';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: mastery?.status == 'MASTERED'
                  ? _green.withValues(alpha: 0.4)
                  : const Color(0xFFFFE0A1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _topicStatusIcon(mastery),
                      color: statusColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      module.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Detail topik',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showCurriculumDetail(
                      context,
                      title: module.title,
                      body:
                          '${_topicStatusLabel(mastery)}\n${module.estimatedMinutes} menit belajar${module.simpleGoal.isEmpty ? '' : '\n\n${module.simpleGoal}'}',
                    ),
                    icon: const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF8B8179),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _topicStatusLabel(mastery),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: Color(0xFF8B8179),
                      size: 20,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 8, left: 44),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasGoal) ...[
                        Text(
                          module.simpleGoal,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        '${module.estimatedMinutes} menit belajar',
                        style: const TextStyle(
                          color: Color(0xFF8B8179),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (needsWork) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () =>
                              widget.onStartMission(module.competencyId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _green,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Kerjakan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
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

void _showCurriculumDetail(
  BuildContext context, {
  required String title,
  required String body,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: const TextStyle(
                color: _muted,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
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

class _StatePanel extends StatelessWidget {
  const _StatePanel({required this.message, this.showProgress = false});

  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          if (showProgress) ...[
            const CircularProgressIndicator(color: _yellow),
            const SizedBox(height: 10),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
