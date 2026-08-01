import 'package:flutter/material.dart';

import '../../application/baleverse_progress_service.dart';
import '../../domain/baleverse_models.dart';

const _profileBg = Color(0xFFFFF3C6);
const _profileInk = Color(0xFF3B2318);
const _profileYellow = Color(0xFFF4B400);
const _profileGreen = Color(0xFF4CAF50);

class BaleProfilePage extends StatelessWidget {
  const BaleProfilePage({
    required this.progress,
    this.backendData,
    this.onSignOut,
    super.key,
  });

  final BaleVerseProgress progress;
  final Map<String, dynamic>? backendData;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final user = progress.user;
    final profile = backendData?['profile'] as Map<String, dynamic>?;
    final stats = backendData?['stats'] as Map<String, dynamic>?;
    final compact = MediaQuery.sizeOf(context).height < 900;
    return Container(
      color: _profileBg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(14, compact ? 10 : 22, 14, 10),
        children: [
          _ProfileHeader(user: user, profile: profile, compact: compact),
          SizedBox(height: compact ? 8 : 16),
          _ProfileProgress(user: user, stats: stats, compact: compact),
          SizedBox(height: compact ? 8 : 14),
          _ProfileMenuTile(
            icon: Icons.school_rounded,
            title: 'Jalur belajar',
            subtitle: 'Foundation 3 - Detektifia',
            color: _profileYellow,
            compact: compact,
            onTap: () {},
          ),
          _ProfileMenuTile(
            icon: Icons.notifications_rounded,
            title: 'Pengingat belajar',
            subtitle: 'Sore hari, 10 menit',
            color: _profileGreen,
            compact: compact,
            onTap: () {},
          ),
          _ProfileMenuTile(
            icon: Icons.verified_user_rounded,
            title: 'Data & keamanan',
            subtitle: 'Data belajar tersimpan aman',
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
    required this.user,
    required this.profile,
    required this.compact,
  });

  final BaleUser user;
  final Map<String, dynamic>? profile;
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
                  profile?['name'] as String? ?? user.name,
                  style: TextStyle(
                    color: _profileInk,
                    fontSize: compact ? 25 : 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 3 : 6),
                Text(
                  '${profile?['rank'] ?? user.rank} - Level ${profile?['level'] ?? user.level}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF60646F),
                    fontSize: compact ? 12 : 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 6 : 10),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10, vertical: compact ? 5 : 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E5),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFFE0A1)),
                  ),
                  child: Text(
                    _formatFoundation(profile?['foundation'] as String?),
                    style: const TextStyle(
                      color: _profileYellow,
                      fontWeight: FontWeight.w900,
                    ),
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

String _formatFoundation(String? value) {
  if (value == null || value.isEmpty) return 'Foundation 3';
  return value
      .toLowerCase()
      .split('_')
      .map((word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

class _ProfileProgress extends StatelessWidget {
  const _ProfileProgress({
    required this.user,
    required this.stats,
    required this.compact,
  });

  final BaleUser user;
  final Map<String, dynamic>? stats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
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
            label: 'XP Detectivia',
            value: '${stats?['xp'] ?? user.xp[BaleWorldKey.detectivia] ?? 0}',
            progress: 0.62,
            color: _profileYellow,
          ),
          SizedBox(height: compact ? 8 : 12),
          _ProgressRow(
            label: 'Target mingguan',
            value:
                '${stats?['weeklyCompleted'] ?? user.weeklyCompleted}/${stats?['weeklyTarget'] ?? user.weeklyTarget} hari',
            progress:
                ((stats?['weeklyCompleted'] ?? user.weeklyCompleted) as num) /
                    ((stats?['weeklyTarget'] ?? user.weeklyTarget) as num),
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
