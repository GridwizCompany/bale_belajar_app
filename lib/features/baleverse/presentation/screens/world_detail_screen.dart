import 'package:flutter/material.dart';

import '../../data/mastery_repository.dart';
import '../../data/worlds_repository.dart';
import '../../domain/world_curriculum_models.dart';

const _bg = Color(0xFFFFF3C6);
const _ink = Color(0xFF3B2318);
const _yellow = Color(0xFFF4B400);
const _green = Color(0xFF4CAF50);

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

String _statusLabel(String status) => switch (status) {
      'MASTERED' => 'Menguasai',
      'DEVELOPING' => 'Berkembang',
      'NEEDS_PRACTICE' => 'Perlu latihan',
      _ => 'Belum ada data',
    };

Color _statusColor(String status) => switch (status) {
      'MASTERED' => _green,
      'DEVELOPING' => const Color(0xFF2D8CFF),
      'NEEDS_PRACTICE' => const Color(0xFFF57C00),
      _ => const Color(0xFF8B8179),
    };

/// Detail satu dunia - kurikulum (materi apa saja) dan progres penguasaan
/// per kompetensi. Murni informasi (tidak mengganti dunia aktif) - ganti
/// dunia aktif dilakukan lewat Peta Perjalanan di Beranda.
class WorldDetailScreen extends StatefulWidget {
  const WorldDetailScreen({required this.world, super.key});

  final Map<String, dynamic> world;

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
    } catch (_) {
      if (mounted) setState(() => _masteryLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _worldColor(widget.world['key']);
    final icon = _worldIcon(widget.world['key']);
    final questionCount = widget.world['activeQuestionCount'] as int? ?? 0;

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
          const SizedBox(height: 14),
          _ProgressCard(
            color: color,
            loading: _masteryLoading,
            mastery: _mastery,
            questionCount: questionCount,
          ),
          const SizedBox(height: 14),
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
                return const _StatePanel(
                  message: 'Kurikulum belum bisa dimuat.',
                );
              }
              return _CurriculumSection(
                modules: snapshot.data!.modules,
                color: color,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  world['name'] as String? ?? 'Dunia',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  world['subject'] as String? ?? '',
                  style: const TextStyle(
                    color: Color(0xFF60646F),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((world['description'] as String?)?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Text(
                    world['description'] as String,
                    style: const TextStyle(
                      color: Color(0xFF60646F),
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final competencies = mastery ?? const <CompetencyMastery>[];
    final average = competencies.isEmpty
        ? 0.0
        : competencies.fold<double>(0, (sum, c) => sum + c.masteryScore) /
            competencies.length;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: _green),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Progres Penguasaan',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$questionCount soal aktif',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: CircularProgressIndicator(color: _yellow),
              ),
            )
          else if (competencies.isEmpty)
            const Text(
              'Belum ada data penguasaan untuk dunia ini.',
              style: TextStyle(
                color: Color(0xFF60646F),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            Row(
              children: [
                Text(
                  '${average.round()}%',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'rata-rata',
                  style: TextStyle(
                    color: Color(0xFF60646F),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final competency in competencies) ...[
              _CompetencyRow(competency: competency, color: color),
              const SizedBox(height: 8),
            ],
          ],
        ],
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
          width: 60,
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
            color: _statusColor(competency.status).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _statusLabel(competency.status),
            style: TextStyle(
              color: _statusColor(competency.status),
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
  const _CurriculumSection({required this.modules, required this.color});

  final List<CurriculumModule> modules;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Kurikulum',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final module in modules) ...[
          _ModuleRow(module: module, color: color),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.module, required this.color});

  final CurriculumModule module;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  module.title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${module.estimatedMinutes}m',
                style: const TextStyle(
                  color: Color(0xFF60646F),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (module.simpleGoal.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              module.simpleGoal,
              style: const TextStyle(
                color: Color(0xFF60646F),
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w700,
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
              color: Color(0xFF60646F),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
