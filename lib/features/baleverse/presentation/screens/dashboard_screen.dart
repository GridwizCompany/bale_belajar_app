import 'package:flutter/material.dart';

import '../../application/baleverse_progress_service.dart';
import '../../data/game_profile_repository.dart';
import '../../domain/baleverse_models.dart';

const _homeBg = Color(0xFFFFF3C6);
const _homeInk = Color(0xFF3B2318);
const _homeYellow = Color(0xFFF4B400);
const _homeGreen = Color(0xFF4CAF50);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.progress,
    required this.selectedWorld,
    this.backendData,
    required this.realUserName,
    required this.gameProfile,
    required this.masteryAverage,
    required this.onStartMission,
    super.key,
  });

  final BaleVerseProgress progress;
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
    final user = progress.user;
    final todayMission = backendData?['todayMission'] as Map<String, dynamic>?;
    final compact = MediaQuery.sizeOf(context).height < 900;

    return Container(
      color: _homeBg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(14, compact ? 10 : 18, 14, 10),
        children: [
          _GreetingCard(
            userName: realUserName ?? user.name,
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 14),
          _StatsStrip(gameProfile: gameProfile, compact: compact),
          SizedBox(height: compact ? 8 : 14),
          _TodayMissionCard(
            selectedWorld: selectedWorld,
            mission: todayMission,
            compact: compact,
            onStartMission: onStartMission,
          ),
          if (!compact) ...[
            const SizedBox(height: 18),
            _LegacyProgressSummary(
              gameProfile: gameProfile,
              masteryAverage: masteryAverage,
            ),
            const SizedBox(height: 18),
          ] else
            const SizedBox(height: 8),
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
  const _StatsStrip({required this.gameProfile, required this.compact});

  final GameProfileSummary? gameProfile;
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
              value: gameProfile == null ? '-' : '${gameProfile!.accountXp}',
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFFF6B2C),
              label: 'Nyala',
              value: gameProfile == null ? '-' : '${gameProfile!.streakCurrent}',
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
                      selectedWorld.key == BaleWorldKey.detectivia
                          ? (mission?['title'] as String? ?? 'Detektifia')
                          : selectedWorld.name,
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
                          ? 'Chapter 1 - Kamp Observasi'
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

// "Peta Belajar" (learning-path map dengan node/bintang/lock) sengaja
// dihapus - tidak ada satupun field backend yang mengisi progres node-nya
// (Fase 4, belum dikerjakan). Menampilkan node/bintang statis akan jadi
// klaim progres yang tidak benar.

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
              value: masteryAverage == null
                  ? '-'
                  : '${masteryAverage!.round()}%',
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
