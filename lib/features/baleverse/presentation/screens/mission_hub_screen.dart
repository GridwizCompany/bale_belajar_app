import 'package:flutter/material.dart';

import '../../../quests/data/quest_repository.dart';
import '../../../quests/domain/quest_models.dart';
import '../../data/game_profile_repository.dart';
import '../../data/mastery_repository.dart';

const _progressBg = Color(0xFFFFF3C6);
const _progressInk = Color(0xFF3B2318);
const _progressYellow = Color(0xFFF4B400);
const _progressGreen = Color(0xFF4CAF50);
const _progressBlue = Color(0xFF2D8CFF);
const _progressMuted = Color(0xFF6F655D);

class MissionHubScreen extends StatefulWidget {
  const MissionHubScreen({
    this.backendData,
    this.adaptivePlan,
    this.gameProfile,
    this.masteryAverage,
    required this.worldKey,
    required this.onOpenCurriculum,
    super.key,
  });

  final Map<String, dynamic>? backendData;
  final Map<String, dynamic>? adaptivePlan;
  final GameProfileSummary? gameProfile;
  final double? masteryAverage;
  final String worldKey;
  final VoidCallback onOpenCurriculum;

  @override
  State<MissionHubScreen> createState() => _MissionHubScreenState();
}

class _MissionHubScreenState extends State<MissionHubScreen> {
  final QuestRepository _questRepository = QuestRepository();
  final MasteryRepository _masteryRepository = MasteryRepository();

  late Future<_ProgressData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant MissionHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.worldKey != widget.worldKey) {
      _future = _load();
    }
  }

  Future<_ProgressData> _load() async {
    final results = await Future.wait<Object>([
      _questRepository.fetchHistory(worldKey: widget.worldKey),
      _masteryRepository.fetchGrowthMap(worldKey: widget.worldKey),
    ]);
    return _ProgressData(
      history: results[0] as QuestHistory,
      mastery: (results[1] as List<CompetencyMastery>),
    );
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 820;
    return Container(
      color: _progressBg,
      child: RefreshIndicator(
        color: _progressYellow,
        onRefresh: _refresh,
        child: FutureBuilder<_ProgressData>(
          future: _future,
          builder: (context, snapshot) {
            final data = snapshot.data;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(14, compact ? 10 : 18, 14, 18),
              children: [
                _ProgressHeader(
                  compact: compact,
                  worldName: _worldName(widget.worldKey),
                  masteryAverage: widget.masteryAverage,
                  gameProfile: widget.gameProfile,
                ),
                SizedBox(height: compact ? 10 : 14),
                if (snapshot.connectionState == ConnectionState.waiting &&
                    data == null)
                  const _LoadingCard()
                else if (snapshot.hasError && data == null)
                  _EmptyStateCard(
                    icon: Icons.wifi_off_rounded,
                    title: 'Progress belum terbaca',
                    subtitle: 'Tarik layar ke bawah untuk coba lagi.',
                    actionLabel: 'Coba lagi',
                    onAction: _refresh,
                  )
                else ...[
                  _SummaryGrid(
                    compact: compact,
                    history: data!.history,
                    gameProfile: widget.gameProfile,
                    masteryAverage: widget.masteryAverage,
                  ),
                  SizedBox(height: compact ? 10 : 14),
                  _PriorityPanel(
                    mastery: data.mastery,
                    weakSpots: data.history.weakSpots,
                    adaptivePlan: widget.adaptivePlan,
                    onOpenCurriculum: widget.onOpenCurriculum,
                  ),
                  SizedBox(height: compact ? 10 : 14),
                  _HistoryPanel(
                    attempts: data.history.recentAttempts,
                    onOpenCurriculum: widget.onOpenCurriculum,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProgressData {
  const _ProgressData({required this.history, required this.mastery});

  final QuestHistory history;
  final List<CompetencyMastery> mastery;
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.compact,
    required this.worldName,
    required this.masteryAverage,
    required this.gameProfile,
  });

  final bool compact;
  final String worldName;
  final double? masteryAverage;
  final GameProfileSummary? gameProfile;

  @override
  Widget build(BuildContext context) {
    final mastery = (masteryAverage ?? 0).round();
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/mascot/welcome.png',
            height: compact ? 76 : 104,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress',
                  style: TextStyle(
                    color: _progressInk,
                    fontSize: compact ? 28 : 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$worldName • Level ${gameProfile?.accountLevel ?? 1}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _progressMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: (mastery / 100).clamp(0, 1),
                    backgroundColor: const Color(0xFFFFE9A8),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_progressGreen),
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

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.compact,
    required this.history,
    required this.gameProfile,
    required this.masteryAverage,
  });

  final bool compact;
  final QuestHistory history;
  final GameProfileSummary? gameProfile;
  final double? masteryAverage;

  @override
  Widget build(BuildContext context) {
    final summary = history.summary;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: compact ? 1.55 : 1.75,
      children: [
        _MetricCard(
          icon: Icons.show_chart_rounded,
          color: _progressGreen,
          value: '${(masteryAverage ?? summary.averageScore).round()}%',
          label: 'Penguasaan',
        ),
        _MetricCard(
          icon: Icons.task_alt_rounded,
          color: _progressYellow,
          value: '${summary.completedAttempts}',
          label: 'Latihan selesai',
        ),
        _MetricCard(
          icon: Icons.bolt_rounded,
          color: _progressBlue,
          value: '${summary.accuracy}%',
          label: 'Akurasi',
        ),
        _MetricCard(
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFF7043),
          value: '${gameProfile?.streakCurrent ?? 0}',
          label: 'Streak',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _progressInk,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _progressMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
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

class _PriorityPanel extends StatelessWidget {
  const _PriorityPanel({
    required this.mastery,
    required this.weakSpots,
    required this.adaptivePlan,
    required this.onOpenCurriculum,
  });

  final List<CompetencyMastery> mastery;
  final List<QuestWeakSpot> weakSpots;
  final Map<String, dynamic>? adaptivePlan;
  final VoidCallback onOpenCurriculum;

  @override
  Widget build(BuildContext context) {
    final needsPractice = mastery
        .where((item) =>
            item.status == 'NEEDS_PRACTICE' ||
            (item.evidenceCount > 0 && item.masteryScore < 70))
        .toList()
      ..sort((a, b) => a.masteryScore.compareTo(b.masteryScore));
    final items = needsPractice.take(3).toList();
    final planTitle = adaptivePlan?['title'] as String?;

    return _Panel(
      title: 'Fokus berikutnya',
      trailing: TextButton(
        onPressed: onOpenCurriculum,
        child: const Text('Buka'),
      ),
      child: Column(
        children: [
          if (items.isEmpty && weakSpots.isEmpty)
            _SoftMessage(
              icon: Icons.emoji_events_rounded,
              title: 'Belum ada yang berat',
              subtitle: planTitle ?? 'Lanjutkan dari kurikulum.',
            )
          else ...[
            for (final item in items)
              _FocusTile(
                icon: Icons.school_rounded,
                title: item.competencyName,
                subtitle: '${item.masteryScore.round()}% penguasaan',
                color: _progressGreen,
              ),
            for (final item in weakSpots.take(3 - items.length))
              _FocusTile(
                icon: Icons.refresh_rounded,
                title: item.label,
                subtitle: '${item.count} kali perlu diulang',
                color: const Color(0xFFF57C00),
              ),
          ],
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.attempts,
    required this.onOpenCurriculum,
  });

  final List<QuestHistoryAttempt> attempts;
  final VoidCallback onOpenCurriculum;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Riwayat jawaban',
      child: attempts.isEmpty
          ? _SoftMessage(
              icon: Icons.history_rounded,
              title: 'Belum ada riwayat',
              subtitle: 'Mulai dari kurikulum.',
              actionLabel: 'Mulai',
              onAction: onOpenCurriculum,
            )
          : Column(
              children: [
                for (final attempt in attempts) _HistoryTile(attempt: attempt),
              ],
            ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE0A1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _progressInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _FocusTile extends StatelessWidget {
  const _FocusTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _progressInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _progressMuted,
                    fontSize: 12,
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.attempt});

  final QuestHistoryAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final color = attempt.score >= 80
        ? _progressGreen
        : attempt.score >= 60
            ? _progressYellow
            : const Color(0xFFF57C00);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${attempt.score}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _progressInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${attempt.correctAnswers}/${attempt.totalQuestions} benar • ${_shortDate(attempt.submittedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _progressMuted,
                    fontSize: 12,
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

class _SoftMessage extends StatelessWidget {
  const _SoftMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: _progressYellow, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _progressInk,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _progressMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: _progressYellow,
                foregroundColor: _progressInk,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      child: _SoftMessage(
        icon: icon,
        title: title,
        subtitle: subtitle,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const CircularProgressIndicator(color: _progressYellow),
    );
  }
}

String _worldName(String key) => switch (key.toLowerCase()) {
      'numeria' => 'Numeria',
      'kodex' => 'KodeX',
      'detectivia' => 'Detectivia',
      'scientia' => 'Scientia',
      _ => key.isEmpty ? 'Dunia Belajar' : key,
    };

String _shortDate(DateTime? date) {
  if (date == null) return '-';
  final now = DateTime.now();
  if (now.year == date.year && now.month == date.month && now.day == date.day) {
    return 'Hari ini';
  }
  return '${date.day}/${date.month}/${date.year}';
}
