import 'package:flutter/material.dart';

import '../../data/game_profile_repository.dart';

const _profileBg = Color(0xFFFFF3C6);
const _profileInk = Color(0xFF3B2318);
const _profileYellow = Color(0xFFF4B400);
const _profileGreen = Color(0xFF4CAF50);

class BaleProfilePage extends StatelessWidget {
  const BaleProfilePage({
    this.backendData,
    required this.realUserName,
    required this.gameProfile,
    required this.masteryAverage,
    this.onSignOut,
    super.key,
  });

  final Map<String, dynamic>? backendData;
  // Data akun REAL dari GET /student/game-profile dan /student/mastery -
  // null berarti belum termuat/gagal, ditampilkan jujur sebagai '-',
  // BUKAN diam-diam pakai baleUser dummy atau blob prototype.
  final String? realUserName;
  final GameProfileSummary? gameProfile;
  final double? masteryAverage;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final backendProfile = backendData?['profile'] as Map<String, dynamic>?;
    final backendStats = backendData?['stats'] as Map<String, dynamic>?;
    final compact = MediaQuery.sizeOf(context).height < 900;
    return Container(
      color: _profileBg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(14, compact ? 10 : 22, 14, 10),
        children: [
          _ProfileHeader(
            fallbackName: 'Pengguna',
            backendProfile: backendProfile,
            realUserName: realUserName,
            gameProfile: gameProfile,
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 16),
          _ProfileProgress(
            gameProfile: gameProfile,
            backendStats: backendStats,
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 14),
          _ProfileMenuTile(
            icon: Icons.school_rounded,
            title: 'Jalur belajar',
            subtitle: 'Atur jalur belajarmu',
            color: _profileYellow,
            compact: compact,
            onTap: () {},
          ),
          _ProfileMenuTile(
            icon: Icons.notifications_rounded,
            title: 'Pengingat belajar',
            subtitle: 'Atur pengingat belajar',
            color: _profileGreen,
            compact: compact,
            onTap: () {},
          ),
          _ProfileMenuTile(
            icon: Icons.verified_user_rounded,
            title: 'Data & keamanan',
            subtitle: 'Kelola keamanan akun',
            color: const Color(0xFF0E3A5F),
            compact: compact,
            onTap: () {},
          ),
          if (onSignOut != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Keluar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.fallbackName,
    required this.backendProfile,
    required this.realUserName,
    required this.gameProfile,
    required this.compact,
  });

  final String fallbackName;
  final Map<String, dynamic>? backendProfile;
  final String? realUserName;
  final GameProfileSummary? gameProfile;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 20),
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
          CircleAvatar(
            radius: compact ? 34 : 52,
            backgroundColor: const Color(0xFFFFF8E5),
            child: Image.asset(
              'assets/mascot/login.png',
              height: compact ? 62 : 96,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: compact ? 10 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  backendProfile?['name'] as String? ??
                      realUserName ??
                      fallbackName,
                  style: TextStyle(
                    color: _profileInk,
                    fontSize: compact ? 25 : 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 3 : 6),
                Text(
                  gameProfile == null
                      ? (backendProfile?['foundation'] as String? ?? '-')
                      : '${_formatRank(gameProfile!.rank)} - Level ${gameProfile!.accountLevel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF60646F),
                    fontSize: compact ? 12 : 15,
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

String _formatRank(String rank) {
  final lower = rank.toLowerCase().replaceAll('_', ' ');
  return lower
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _ProfileProgress extends StatelessWidget {
  const _ProfileProgress({
    required this.gameProfile,
    required this.backendStats,
    required this.compact,
  });

  final GameProfileSummary? gameProfile;
  final Map<String, dynamic>? backendStats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final profile = gameProfile;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan progres',
            style: TextStyle(
              color: _profileInk,
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 8 : 14),
          _ProgressRow(
            label: 'Menuju Level Berikutnya',
            value: backendStats?['xp'] != null
                ? '${backendStats!['xp']} XP'
                : profile == null
                    ? '-'
                    : '${profile.xpIntoCurrentLevel}/${profile.xpRequiredForNextLevel} XP',
            progress: profile?.levelProgress ?? 0,
            color: _profileYellow,
          ),
          SizedBox(height: compact ? 8 : 12),
          _ProgressRow(
            label: 'Nyala belajar mingguan',
            value: backendStats?['weeklyCompleted'] != null
                ? '${backendStats!['weeklyCompleted']}/${backendStats!['weeklyTarget'] ?? 3} hari'
                : profile == null
                    ? '-'
                    : '${profile.streakCurrent}/${profile.streakTargetPerWeek} hari',
            progress: profile == null || profile.streakTargetPerWeek == 0
                ? 0
                : profile.streakCurrent / profile.streakTargetPerWeek,
            color: _profileGreen,
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _profileInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF60646F),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 10,
            color: color,
            backgroundColor: const Color(0xFFE8DDB8),
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 14),
            child: Row(
              children: [
                Container(
                  width: compact ? 42 : 54,
                  height: compact ? 42 : 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: compact ? 23 : 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: _profileInk,
                          fontSize: compact ? 15 : 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF60646F),
                          fontSize: compact ? 11 : 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
