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
    required this.onSwitchWorld,
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
  // Beranda tidak lagi punya CTA untuk langsung mulai quest (itu tugas tab
  // Misi) - tombol di kartu langkah aktif sekarang jadi jalan pintas ganti
  // dunia lewat tab Dunia.
  final VoidCallback onSwitchWorld;

  @override
  Widget build(BuildContext context) {
    final backendProfile = backendData?['profile'] as Map<String, dynamic>?;
    final backendStats = backendData?['stats'] as Map<String, dynamic>?;
    final learningPath =
        (backendData?['learningPath'] as List?)?.cast<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[];
    final compact = MediaQuery.sizeOf(context).height < 900;

    return Container(
      color: _homeBg,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, compact ? 10 : 18, 14, 10),
        child: Column(
          children: [
            _HeroStatsCard(
              userName: backendProfile?['name'] as String? ??
                  realUserName ??
                  'Pengguna',
              gameProfile: gameProfile,
              backendStats: backendStats,
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 14),
            Expanded(
              child: _JourneyMapCard(
                path: learningPath,
                compact: compact,
                onSwitchWorld: onSwitchWorld,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatsCard extends StatelessWidget {
  const _HeroStatsCard({
    required this.userName,
    required this.gameProfile,
    required this.backendStats,
    required this.compact,
  });

  final String userName;
  final GameProfileSummary? gameProfile;
  final Map<String, dynamic>? backendStats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18, compact ? 14 : 20, 18, compact ? 14 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_homeYellow, Color(0xFFFFC94D)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33F4B400),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat datang di BaleVerse',
                      style: TextStyle(
                        color: Color(0xCC3B2318),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hai, $userName!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _homeInk,
                        fontSize: compact ? 20 : 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: compact ? 44 : 52,
                height: compact ? 44 : 52,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.waving_hand_rounded,
                  color: _homeYellow,
                  size: compact ? 22 : 26,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 18),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 14,
              vertical: compact ? 10 : 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                    color: const Color(0xFF8B5CF6),
                    label: 'Rank',
                    value:
                        gameProfile == null ? '-' : _formatRank(gameProfile!.rank),
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

class _JourneyMapCard extends StatelessWidget {
  const _JourneyMapCard({
    required this.path,
    required this.compact,
    required this.onSwitchWorld,
  });

  final List<Map<String, dynamic>> path;
  final bool compact;
  final VoidCallback onSwitchWorld;

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
    final completedCount =
        nodes.where((node) => node['completed'] == true).length;
    final progress = nodes.isEmpty ? 0.0 : completedCount / nodes.length;
    return Container(
      padding: EdgeInsets.fromLTRB(16, compact ? 12 : 16, 16, 10),
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
                width: compact ? 34 : 42,
                height: compact ? 34 : 42,
                decoration: BoxDecoration(
                  color: _homeGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: _homeGreen,
                  size: compact ? 20 : 24,
                ),
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
                        fontSize: compact ? 16 : 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (!compact)
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
          SizedBox(height: compact ? 8 : 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              color: _homeGreen,
              backgroundColor: const Color(0xFFFFE8A8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$completedCount/${nodes.length} langkah selesai',
            style: const TextStyle(
              color: Color(0xFF60646F),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 6 : 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const minNodeHeight = 54.0;
                const maxNodeHeight = 110.0;
                const baseNodeHeight = 96.0;
                var visibleCount = nodes.length.clamp(1, 6);
                var nodeHeight = constraints.maxHeight / visibleCount;
                while (nodeHeight < minNodeHeight && visibleCount > 1) {
                  visibleCount--;
                  nodeHeight = constraints.maxHeight / visibleCount;
                }
                nodeHeight = nodeHeight.clamp(minNodeHeight, maxNodeHeight);
                final scale = (nodeHeight / baseNodeHeight).clamp(0.58, 1.15);
                final visibleNodes = nodes.take(visibleCount).toList();
                return Column(
                  children: [
                    for (final entry in visibleNodes.asMap().entries)
                      SizedBox(
                        height: nodeHeight,
                        child: _JourneyNode(
                          data: entry.value,
                          index: entry.key,
                          isLast: entry.key == visibleNodes.length - 1,
                          scale: scale,
                          onSwitchWorld: onSwitchWorld,
                        ),
                      ),
                  ],
                );
              },
            ),
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
    required this.scale,
    required this.onSwitchWorld,
  });

  final Map<String, dynamic> data;
  final int index;
  final bool isLast;
  final double scale;
  final VoidCallback onSwitchWorld;

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
      scale: scale,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleTap(context, title: title, stars: stars),
      child: Stack(
        children: [
          if (!isLast)
            Positioned(
              left: 0,
              right: 0,
              top: 50 * scale,
              child: Center(
                child: Container(
                  width: 6,
                  height: 58 * scale,
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
                  SizedBox(width: 10 * scale),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(10 * scale),
                      decoration: BoxDecoration(
                        color: locked
                            ? const Color(0xFFF1F2F5)
                            : active
                                ? const Color(0xFFFFF7D6)
                                : const Color(0xFFFFFAEA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              active ? _homeYellow : const Color(0xFFFFE0A1),
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
                              fontSize: (13 * scale).clamp(10.0, 15.0),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 5 * scale),
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
                                  size: (17 * scale).clamp(12.0, 17.0),
                                ),
                              if (active) ...[
                                SizedBox(width: 8 * scale),
                                GestureDetector(
                                  onTap: onSwitchWorld,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8 * scale,
                                      vertical: 4 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _homeGreen,
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.swap_horiz_rounded,
                                          color: Colors.white,
                                          size: (15 * scale).clamp(11.0, 15.0),
                                        ),
                                        SizedBox(width: 2 * scale),
                                        Text(
                                          'Ganti Dunia',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize:
                                                (11 * scale).clamp(9.0, 11.0),
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

  // Ketuk kartu langkah hanya membuka info singkat. Beranda tidak lagi
  // membuka quest sama sekali (itu tugas tab Misi) - tombol "Ganti Dunia"
  // di kartu aktif cuma jalan pintas balik ke tab Dunia.
  void _handleTap(BuildContext context,
      {required String title, required int stars}) {
    final completed = data['completed'] == true;
    final active = data['active'] == true;
    final locked = data['locked'] == true;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(
          locked
              ? 'Langkah ini masih terkunci. Selesaikan langkah sebelumnya dulu ya.'
              : completed
                  ? 'Kamu sudah menyelesaikan langkah ini dengan $stars dari 3 bintang.'
                  : active
                      ? 'Ini langkah aktifmu sekarang. Untuk mengerjakan soal, buka tab Misi.'
                      : 'Langkah ini belum bisa dimulai sekarang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
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
    required this.scale,
  });

  final Color color;
  final bool locked;
  final bool completed;
  final bool active;
  final Object step;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = (62 * scale).clamp(40.0, 62.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: (4 * scale).clamp(2.0, 4.0)),
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
        size: ((active ? 32 : 28) * scale).clamp(20.0, 32.0),
      ),
    );
  }
}
