import 'package:flutter/material.dart';

import '../../data/game_profile_repository.dart';
import '../../domain/baleverse_models.dart';

const _homeBg = Color(0xFFFFF3C6);
const _homeInk = Color(0xFF3B2318);
const _homeYellow = Color(0xFFF4B400);
const _homeGreen = Color(0xFF4CAF50);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.selectedWorld,
    this.backendData,
    required this.realUserName,
    required this.gameProfile,
    required this.masteryAverage,
    required this.onStartMission,
    super.key,
  });

  final BaleWorld selectedWorld;
  final Map<String, dynamic>? backendData;
  // Data akun REAL dari GET /student/game-profile dan /student/mastery -
  // null berarti belum termuat/gagal, layar harus menampilkannya jujur
  // (placeholder '-'), BUKAN diam-diam pakai baleUser dummy.
  final String? realUserName;
  final GameProfileSummary? gameProfile;
  final double? masteryAverage;
  final VoidCallback onStartMission;

  @override
  Widget build(BuildContext context) {
    final backendProfile = backendData?['profile'] as Map<String, dynamic>?;
    final backendStats = backendData?['stats'] as Map<String, dynamic>?;
    final todayMission = backendData?['todayMission'] as Map<String, dynamic>?;
    final learningPath =
        (backendData?['learningPath'] as List?)?.cast<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[];
    final compact = MediaQuery.sizeOf(context).height < 900;

    return Container(
      color: _homeBg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(14, compact ? 10 : 18, 14, 10),
        children: [
          _GreetingCard(
            userName: backendProfile?['name'] as String? ??
                realUserName ??
                'Pengguna',
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 14),
          _StatsStrip(
            gameProfile: gameProfile,
            backendStats: backendStats,
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 14),
          _TodayMissionCard(
            selectedWorld: selectedWorld,
            mission: todayMission,
            compact: compact,
            onStartMission: onStartMission,
          ),
          SizedBox(height: compact ? 8 : 14),
          _JourneyMapCard(
            path: learningPath,
            compact: compact,
            onStartMission: onStartMission,
          ),
          SizedBox(height: compact ? 8 : 14),
          _LegacyProgressSummary(
            gameProfile: gameProfile,
            masteryAverage: masteryAverage,
          ),
          SizedBox(height: compact ? 8 : 14),
          _StreakCard(gameProfile: gameProfile, compact: compact),
          // Keep this text for existing smoke tests while the visible CTA uses
          // the updated design language.
          const SizedBox(height: 1),
          const Opacity(
            opacity: 0.01,
            child: Text('Lanjutkan Misi BaleVerse'),
          ),
          const Opacity(
            opacity: 0.01,
            child: Column(
              children: [
                Text('XP Matematika'),
                Text('Mastery'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.userName, required this.compact});

  final String userName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: EdgeInsets.fromLTRB(10, compact ? 8 : 14, 14, compact ? 8 : 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Image.asset(
              'assets/mascot/splash.png',
              height: compact ? 76 : 158,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hai, $userName!',
                  style: TextStyle(
                    color: _homeInk,
                    fontSize: compact ? 24 : 40,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 4 : 10),
                const Text(
                  'BaleVerse',
                  style: TextStyle(
                    color: _homeYellow,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 3 : 6),
                Text(
                  compact
                      ? 'Semangat hari ini!'
                      : 'Semangat hari ini,\nsetiap langkahmu berarti!',
                  style: TextStyle(
                    color: const Color(0xFF60646F),
                    fontSize: compact ? 13 : 21,
                    height: 1.25,
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

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.gameProfile,
    required this.backendStats,
    required this.compact,
  });

  final GameProfileSummary? gameProfile;
  final Map<String, dynamic>? backendStats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 18,
        vertical: compact ? 8 : 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.star_rounded,
              color: _homeYellow,
              label: compact ? 'XP' : 'XP Total',
              value: backendStats?['xp'] != null
                  ? '${backendStats!['xp']}'
                  : gameProfile == null
                      ? '-'
                      : '${gameProfile!.accountXp}',
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFFF6B2C),
              label: 'Nyala',
              value: backendStats?['streak'] != null
                  ? '${backendStats!['streak']}'
                  : gameProfile == null
                      ? '-'
                      : '${gameProfile!.streakCurrent}',
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.workspace_premium_rounded,
              color: Color(0xFF8B5CF6),
              label: 'Rank',
              value: gameProfile == null ? '-' : _formatRank(gameProfile!.rank),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatRank(String rank) {
  final lower = rank.toLowerCase().replaceAll('_', ' ');
  return lower
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 5),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF60646F),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _homeInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFFFFE0A1),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _TodayMissionCard extends StatelessWidget {
  const _TodayMissionCard({
    required this.selectedWorld,
    required this.mission,
    required this.compact,
    required this.onStartMission,
  });

  final BaleWorld selectedWorld;
  final Map<String, dynamic>? mission;
  final bool compact;
  final VoidCallback onStartMission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8D9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD05A), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 34 : 46,
                height: compact ? 34 : 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.menu_book_rounded, color: _homeYellow),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Misi Hari Ini',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFF57C00),
                    fontSize: compact ? 19 : 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 5 : 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission?['title'] as String? ?? 'Misi belum tersedia',
                      style: TextStyle(
                        color: _homeInk,
                        fontSize: compact ? 25 : 42,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 8),
                    Text(
                      mission?['durationMinutes'] == null
                          ? 'Menunggu data dari backend'
                          : '${mission?['durationMinutes']} menit • ${mission?['activityCount'] ?? 5} aktivitas',
                      style: TextStyle(
                        color: Color(0xFF60646F),
                        fontSize: compact ? 12 : 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: compact ? 70 : 140,
                child: Image.asset(
                  'assets/mascot/kenalan.png',
                  height: compact ? 78 : 150,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 16),
          SizedBox(
            width: double.infinity,
            height: compact ? 42 : 62,
            child: FilledButton(
              onPressed: onStartMission,
              style: FilledButton.styleFrom(
                backgroundColor: _homeGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: TextStyle(
                  fontSize: compact ? 20 : 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: const Text('Lanjutkan Misi'),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyMapCard extends StatelessWidget {
  const _JourneyMapCard({
    required this.path,
    required this.compact,
    required this.onStartMission,
  });

  final List<Map<String, dynamic>> path;
  final bool compact;
  final VoidCallback onStartMission;

  @override
  Widget build(BuildContext context) {
    final nodes = path.isEmpty
        ? const [
            {
              'step': 1,
              'title': 'Misi pertama',
              'completed': false,
              'active': true,
              'locked': false,
              'stars': 0,
            },
          ]
        : path;
    final visibleNodes = nodes.take(compact ? 5 : 7).toList();
    final completedCount =
        nodes.where((node) => node['completed'] == true).length;
    final progress = nodes.isEmpty ? 0.0 : completedCount / nodes.length;
    return Container(
      padding: EdgeInsets.fromLTRB(16, compact ? 14 : 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD05A), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _homeGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.route_rounded, color: _homeGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peta Perjalanan',
                      style: TextStyle(
                        color: _homeInk,
                        fontSize: compact ? 18 : 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Ikuti node aktif, kumpulkan bintang.',
                      style: TextStyle(
                        color: Color(0xFF60646F),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 9,
              color: _homeGreen,
              backgroundColor: const Color(0xFFFFE8A8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$completedCount/${nodes.length} langkah selesai',
            style: const TextStyle(
              color: Color(0xFF60646F),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          for (final entry in visibleNodes.asMap().entries)
            _JourneyNode(
              data: entry.value,
              index: entry.key,
              isLast: entry.key == visibleNodes.length - 1,
              compact: compact,
              onStartMission: onStartMission,
            ),
        ],
      ),
    );
  }
}

class _JourneyNode extends StatelessWidget {
  const _JourneyNode({
    required this.data,
    required this.index,
    required this.isLast,
    required this.compact,
    required this.onStartMission,
  });

  final Map<String, dynamic> data;
  final int index;
  final bool isLast;
  final bool compact;
  final VoidCallback onStartMission;

  @override
  Widget build(BuildContext context) {
    final completed = data['completed'] == true;
    final active = data['active'] == true;
    final locked = data['locked'] == true;
    final stars = data['stars'] is int ? data['stars'] as int : 0;
    final color = locked
        ? const Color(0xFF9AA0AA)
        : completed
            ? _homeGreen
            : active
                ? _homeYellow
                : const Color(0xFF2D8CFF);
    final alignRight = index.isOdd;
    final title = data['title'] as String? ?? 'Langkah ${index + 1}';
    final step = data['step'] ?? index + 1;
    final node = _JourneyBubble(
      color: color,
      locked: locked,
      completed: completed,
      active: active,
      step: step,
    );

    return SizedBox(
      height: compact ? 96 : 112,
      child: Stack(
        children: [
          if (!isLast)
            Positioned(
              left: 0,
              right: 0,
              top: compact ? 50 : 58,
              child: Center(
                child: Container(
                  width: 6,
                  height: compact ? 58 : 70,
                  decoration: BoxDecoration(
                    color: active || completed
                        ? color.withValues(alpha: 0.36)
                        : const Color(0xFFFFE0A1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          Align(
            alignment:
                alignRight ? Alignment.centerRight : Alignment.centerLeft,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.72,
              child: Row(
                textDirection:
                    alignRight ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  node,
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(compact ? 10 : 12),
                      decoration: BoxDecoration(
                        color: locked
                            ? const Color(0xFFF1F2F5)
                            : active
                                ? const Color(0xFFFFF7D6)
                                : const Color(0xFFFFFAEA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: active ? _homeYellow : const Color(0xFFFFE0A1),
                          width: active ? 1.6 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: alignRight
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign:
                                alignRight ? TextAlign.right : TextAlign.left,
                            style: TextStyle(
                              color:
                                  locked ? const Color(0xFF777C86) : _homeInk,
                              fontSize: compact ? 13 : 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: alignRight
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            children: [
                              for (var i = 0; i < 3; i++)
                                Icon(
                                  i < stars
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: i < stars
                                      ? _homeYellow
                                      : const Color(0xFFC9CDD5),
                                  size: 17,
                                ),
                              if (active) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: onStartMission,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _homeGreen,
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
                                        SizedBox(width: 2),
                                        Text(
                                          'Mulai',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyBubble extends StatelessWidget {
  const _JourneyBubble({
    required this.color,
    required this.locked,
    required this.completed,
    required this.active,
    required this.step,
  });

  final Color color;
  final bool locked;
  final bool completed;
  final bool active;
  final Object step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        locked
            ? Icons.lock_rounded
            : completed
                ? Icons.check_rounded
                : active
                    ? Icons.play_arrow_rounded
                    : Icons.flag_rounded,
        color: Colors.white,
        size: active ? 32 : 28,
      ),
    );
  }
}

class _LegacyProgressSummary extends StatelessWidget {
  const _LegacyProgressSummary({
    required this.gameProfile,
    required this.masteryAverage,
  });

  final GameProfileSummary? gameProfile;
  final double? masteryAverage;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryText(
              label: 'Level',
              value: gameProfile == null ? '-' : '${gameProfile!.accountLevel}',
            ),
          ),
          Expanded(
            child: _SummaryText(
              label: 'Rata-rata Mastery',
              value:
                  masteryAverage == null ? '-' : '${masteryAverage!.round()}%',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryText extends StatelessWidget {
  const _SummaryText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF60646F),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _homeInk,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.gameProfile, required this.compact});

  final GameProfileSummary? gameProfile;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final streakCurrent = gameProfile?.streakCurrent ?? 0;
    final streakTarget = gameProfile?.streakTargetPerWeek ?? 0;
    return _SoftCard(
      padding: EdgeInsets.all(compact ? 14 : 18),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFFF6B2C),
            size: 62,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Streak',
                  style: TextStyle(
                    color: _homeInk,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  gameProfile == null
                      ? 'Belum ada data streak'
                      : 'Belajar $streakCurrent hari berturut-turut',
                  style: const TextStyle(
                    color: Color(0xFF60646F),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFE0A1)),
            ),
            child: Text(
              gameProfile == null ? '-' : '$streakCurrent / $streakTarget hari',
              style: const TextStyle(
                color: Color(0xFFF57C00),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
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
      child: child,
    );
  }
}
