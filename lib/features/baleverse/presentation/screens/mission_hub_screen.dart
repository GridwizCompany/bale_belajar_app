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
    final compact = MediaQuery.sizeOf(context).height < 760;
    return Container(
      color: _missionBg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, compact ? 14 : 22, 20, 18),
        children: [
          _MissionHeader(compact: compact),
          const SizedBox(height: 16),
          _ActiveMissionCard(compact: compact, onStartMission: onStartMission),
          const SizedBox(height: 14),
          const _MissionListTile(
            icon: Icons.visibility_rounded,
            title: 'Latihan Observasi',
            subtitle: 'Kenali petunjuk penting dari gambar.',
            meta: '6 menit',
            color: Color(0xFF4CAF50),
            unlocked: true,
          ),
          const _MissionListTile(
            icon: Icons.timeline_rounded,
            title: 'Urutan Kejadian',
            subtitle: 'Susun cerita dari awal sampai akhir.',
            meta: '8 menit',
            color: Color(0xFFF4B400),
            unlocked: true,
          ),
          const _MissionListTile(
            icon: Icons.lock_rounded,
            title: 'Papan Bukti',
            subtitle: 'Terbuka setelah dua misi selesai.',
            meta: 'Terkunci',
            color: Color(0xFF8B8179),
            unlocked: false,
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
          Image.asset(
            'assets/mascot/welcome.png',
            height: compact ? 112 : 148,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Misi Belajar',
                  style: TextStyle(
                    color: _missionInk,
                    fontSize: compact ? 30 : 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pilih misi pendek. Progres tetap tersimpan walau kamu berhenti.',
                  style: TextStyle(
                    color: Color(0xFF60646F),
                    fontSize: 15,
                    height: 1.35,
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
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD05A), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Misi aktif',
            style: TextStyle(
              color: Color(0xFFF57C00),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            numeriaMission.title,
            style: TextStyle(
              color: _missionInk,
              fontSize: compact ? 28 : 34,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            numeriaMission.goal,
            style: const TextStyle(
              color: Color(0xFF60646F),
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: compact ? 54 : 62,
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final Color color;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
            width: 56,
            height: 56,
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
                    color: _missionInk,
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
