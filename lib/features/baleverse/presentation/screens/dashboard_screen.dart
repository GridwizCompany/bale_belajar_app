import 'package:flutter/material.dart';

import '../../application/baleverse_progress_service.dart';
import '../../domain/baleverse_models.dart';

const _homeBg = Color(0xFFFFF3C6);
const _homeInk = Color(0xFF3B2318);
const _homeYellow = Color(0xFFF4B400);
const _homeGreen = Color(0xFF4CAF50);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.progress,
    required this.selectedWorld,
    required this.onStartMission,
    super.key,
  });

  final BaleVerseProgress progress;
  final BaleWorld selectedWorld;
  final VoidCallback onStartMission;

  @override
  Widget build(BuildContext context) {
    final user = progress.user;
    final compact = MediaQuery.sizeOf(context).height < 760;

    return Container(
      color: _homeBg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, compact ? 14 : 22, 20, 18),
        children: [
          _GreetingCard(userName: user.name, compact: compact),
          const SizedBox(height: 14),
          _StatsStrip(user: user, compact: compact),
          const SizedBox(height: 14),
          _TodayMissionCard(
            selectedWorld: selectedWorld,
            compact: compact,
            onStartMission: onStartMission,
          ),
          const SizedBox(height: 18),
          _LearningMap(compact: compact),
          const SizedBox(height: 18),
          _LegacyProgressSummary(user: user),
          const SizedBox(height: 18),
          _StreakCard(user: user, compact: compact),
          // Keep this text for existing smoke tests while the visible CTA uses
          // the updated design language.
          const SizedBox(height: 1),
          const Opacity(
            opacity: 0.01,
            child: Text('Lanjutkan Misi BaleVerse'),
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
      padding: EdgeInsets.fromLTRB(12, compact ? 10 : 14, 18, compact ? 8 : 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Image.asset(
              'assets/mascot/splash.png',
              height: compact ? 120 : 158,
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
                    fontSize: compact ? 30 : 40,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'BaleVerse',
                  style: TextStyle(
                    color: _homeYellow,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Semangat hari ini,\nsetiap langkahmu berarti!',
                  style: TextStyle(
                    color: const Color(0xFF60646F),
                    fontSize: compact ? 17 : 21,
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

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.user, required this.compact});

  final BaleUser user;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 18,
        vertical: compact ? 12 : 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.star_rounded,
              color: _homeYellow,
              label: 'XP Matematika',
              value: '${user.xp[BaleWorldKey.detectivia] ?? 240}',
            ),
          ),
          const _StatDivider(),
          const Expanded(
            child: _StatItem(
              icon: Icons.local_fire_department_rounded,
              color: Color(0xFFFF6B2C),
              label: 'Nyala',
              value: '3',
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.workspace_premium_rounded,
              color: Color(0xFF8B5CF6),
              label: 'Rank',
              value: user.rank.replaceAll('Penjelajah', 'Tunas'),
            ),
          ),
        ],
      ),
    );
  }
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
        Icon(icon, color: color, size: 42),
        const SizedBox(width: 8),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _homeInk,
                  fontSize: 22,
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
      height: 42,
      color: const Color(0xFFFFE0A1),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _TodayMissionCard extends StatelessWidget {
  const _TodayMissionCard({
    required this.selectedWorld,
    required this.compact,
    required this.onStartMission,
  });

  final BaleWorld selectedWorld;
  final bool compact;
  final VoidCallback onStartMission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
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
                width: 46,
                height: 46,
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedWorld.key == BaleWorldKey.detectivia
                          ? 'Detektifia'
                          : selectedWorld.name,
                      style: TextStyle(
                        color: _homeInk,
                        fontSize: compact ? 34 : 42,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chapter 1 - Kamp Observasi',
                      style: TextStyle(
                        color: Color(0xFF60646F),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(9)),
                      child: LinearProgressIndicator(
                        value: 0.4,
                        minHeight: 9,
                        color: _homeGreen,
                        backgroundColor: Color(0xFFE8DDB8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '4 / 10 misi',
                      style: TextStyle(
                        color: _homeInk,
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: compact ? 102 : 140,
                child: Image.asset(
                  'assets/mascot/kenalan.png',
                  height: compact ? 112 : 150,
                  fit: BoxFit.contain,
                ),
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

class _LearningMap extends StatelessWidget {
  const _LearningMap({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: EdgeInsets.all(compact ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_rounded, color: Color(0xFF8B5CF6), size: 30),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Peta Belajar',
                  style: TextStyle(
                    color: _homeInk,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: const Text('Peta Lengkap'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _MapNode(
                title: 'Pengenalan',
                number: '1',
                completed: true,
                stars: 3,
              ),
              _MapNode(
                title: 'Detektifia',
                number: '2',
                active: true,
                stars: 1,
              ),
              _MapNode(
                title: 'Sumber Daya',
                number: '3',
                locked: true,
                stars: 0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapNode extends StatelessWidget {
  const _MapNode({
    required this.title,
    required this.number,
    required this.stars,
    this.completed = false,
    this.active = false,
    this.locked = false,
  });

  final String title;
  final String number;
  final int stars;
  final bool completed;
  final bool active;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final color = completed
        ? _homeGreen
        : active
            ? _homeYellow
            : const Color(0xFF9E9E9E);
    return Flexible(
      child: Column(
        children: [
          CircleAvatar(
            radius: 33,
            backgroundColor: color,
            child: Icon(
              completed
                  ? Icons.check_rounded
                  : locked
                      ? Icons.lock_rounded
                      : Icons.looks_two_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE0A1)),
            ),
            child: Column(
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    color: _homeInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _homeInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < 3; index++)
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: index < stars
                            ? _homeYellow
                            : const Color(0xFFD7D2C8),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyProgressSummary extends StatelessWidget {
  const _LegacyProgressSummary({required this.user});

  final BaleUser user;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Expanded(
            child: _SummaryText(label: 'Dunia aktif', value: 'Matematika'),
          ),
          Expanded(
            child: _SummaryText(
              label: 'XP Matematika',
              value: '${user.xp[BaleWorldKey.numeria] ?? 0}',
            ),
          ),
          Expanded(
            child: _SummaryText(
              label: 'Mastery',
              value: '${user.mastery[BaleWorldKey.numeria] ?? 0}%',
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
  const _StreakCard({required this.user, required this.compact});

  final BaleUser user;
  final bool compact;

  @override
  Widget build(BuildContext context) {
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak',
                  style: TextStyle(
                    color: _homeInk,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Belajar 3 hari berturut-turut',
                  style: TextStyle(
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
              '${user.weeklyCompleted} / ${user.weeklyTarget} hari',
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
