import 'package:flutter/material.dart';

import '../../application/baleverse_progress_service.dart';
import '../../data/baleverse_dummy_data.dart';

const _missionBg = Color(0xFFFFF3C6);
const _missionInk = Color(0xFF3B2318);
const _missionYellow = Color(0xFFF4B400);
const _missionGreen = Color(0xFF4CAF50);

class MissionHubScreen extends StatelessWidget {
  const MissionHubScreen({
    required this.progress,
    required this.onStartMission,
    super.key,
  });

  final BaleVerseProgress progress;
  final VoidCallback onStartMission;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 900;
    return Container(
      color: _missionBg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(14, compact ? 10 : 22, 14, 10),
        children: [
          _MissionHeader(compact: compact),
          SizedBox(height: compact ? 8 : 16),
          _ActiveMissionCard(compact: compact, onStartMission: onStartMission),
          SizedBox(height: compact ? 8 : 14),
          _MissionListTile(
            icon: Icons.visibility_rounded,
            title: 'Latihan Observasi',
            subtitle: 'Kenali petunjuk penting dari gambar.',
            meta: '6 menit',
            color: Color(0xFF4CAF50),
            unlocked: true,
            compact: compact,
          ),
          _MissionListTile(
            icon: Icons.timeline_rounded,
            title: 'Urutan Kejadian',
            subtitle: 'Susun cerita dari awal sampai akhir.',
            meta: '8 menit',
            color: Color(0xFFF4B400),
            unlocked: true,
            compact: compact,
          ),
          if (!compact)
            _MissionListTile(
              icon: Icons.lock_rounded,
              title: 'Papan Bukti',
              subtitle: 'Terbuka setelah dua misi selesai.',
              meta: 'Terkunci',
              color: Color(0xFF8B8179),
              unlocked: false,
              compact: compact,
            ),
        ],
      ),
    );
  }
}

class _MissionHeader extends StatelessWidget {
  const _MissionHeader({required this.compact});

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
          Image.asset(
            'assets/mascot/welcome.png',
            height: compact ? 74 : 148,
            fit: BoxFit.contain,
          ),
          SizedBox(width: compact ? 8 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Misi Belajar',
                  style: TextStyle(
                    color: _missionInk,
                    fontSize: compact ? 26 : 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 4 : 8),
                Text(
                  compact
                      ? 'Pilih misi pendek.'
                      : 'Pilih misi pendek. Progres tetap tersimpan walau kamu berhenti.',
                  style: TextStyle(
                    color: Color(0xFF60646F),
                    fontSize: compact ? 12 : 15,
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

class _ActiveMissionCard extends StatelessWidget {
  const _ActiveMissionCard({
    required this.compact,
    required this.onStartMission,
  });

  final bool compact;
  final VoidCallback onStartMission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD05A), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Misi aktif',
            style: TextStyle(
              color: Color(0xFFF57C00),
              fontSize: compact ? 14 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 4 : 8),
          Text(
            numeriaMission.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _missionInk,
              fontSize: compact ? 25 : 34,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 4 : 8),
          Text(
            numeriaMission.goal,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF60646F),
              fontSize: compact ? 12 : 15,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 8 : 16),
          Row(
            children: [
              _MissionBadge(
                icon: Icons.schedule_rounded,
                label: '${numeriaMission.estimatedMinutes} menit',
              ),
              const SizedBox(width: 8),
              _MissionBadge(
                icon: Icons.star_rounded,
                label: '+${numeriaMission.rewardXp} XP',
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
                backgroundColor: _missionGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
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

class _MissionBadge extends StatelessWidget {
  const _MissionBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFE0A1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _missionYellow, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _missionInk,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionListTile extends StatelessWidget {
  const _MissionListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.color,
    required this.unlocked,
    required this.compact,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final Color color;
  final bool unlocked;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 12),
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 42 : 56,
            height: compact ? 42 : 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: compact ? 24 : 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _missionInk,
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
          Text(
            meta,
            style: TextStyle(
              color: unlocked ? _missionYellow : const Color(0xFF8B8179),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
