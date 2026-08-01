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
    this.onSignOut,
    super.key,
  });

  final BaleVerseProgress progress;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final user = progress.user;
    final compact = MediaQuery.sizeOf(context).height < 760;
    return Container(
      color: _profileBg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, compact ? 14 : 22, 20, 18),
        children: [
          _ProfileHeader(user: user, compact: compact),
          const SizedBox(height: 16),
          _ProfileProgress(user: user),
          const SizedBox(height: 14),
          _ProfileMenuTile(
            icon: Icons.school_rounded,
            title: 'Jalur belajar',
            subtitle: 'Foundation 3 - Detektifia',
            color: _profileYellow,
            onTap: () {},
          ),
          _ProfileMenuTile(
            icon: Icons.notifications_rounded,
            title: 'Pengingat belajar',
            subtitle: 'Sore hari, 10 menit',
            color: _profileGreen,
            onTap: () {},
          ),
          _ProfileMenuTile(
            icon: Icons.verified_user_rounded,
            title: 'Data & keamanan',
            subtitle: 'Data belajar tersimpan aman',
            color: const Color(0xFF0E3A5F),
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
  const _ProfileHeader({required this.user, required this.compact});

  final BaleUser user;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
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
            radius: compact ? 42 : 52,
            backgroundColor: const Color(0xFFFFF8E5),
            child: Image.asset(
              'assets/mascot/login.png',
              height: compact ? 78 : 96,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    color: _profileInk,
                    fontSize: compact ? 30 : 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${user.rank} - Level ${user.level}',
                  style: const TextStyle(
                    color: Color(0xFF60646F),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E5),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFFE0A1)),
                  ),
                  child: const Text(
                    'Foundation 3',
                    style: TextStyle(
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

class _ProfileProgress extends StatelessWidget {
  const _ProfileProgress({required this.user});

  final BaleUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan progres',
            style: TextStyle(
              color: _profileInk,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _ProgressRow(
            label: 'XP Detectivia',
            value: '${user.xp[BaleWorldKey.detectivia] ?? 0}',
            progress: 0.62,
            color: _profileYellow,
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            label: 'Target mingguan',
            value: '${user.weeklyCompleted}/${user.weeklyTarget} hari',
            progress: user.weeklyCompleted / user.weeklyTarget,
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _profileInk,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF60646F),
                          fontSize: 13,
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
