import 'package:flutter/material.dart';

import '../../domain/baleverse_models.dart';

const _worldBg = Color(0xFFFFF3C6);
const _worldInk = Color(0xFF3B2318);
const _worldYellow = Color(0xFFF4B400);
const _worldGreen = Color(0xFF4CAF50);

class WorldsScreen extends StatelessWidget {
  const WorldsScreen({
    required this.selectedWorld,
    required this.selectedBackendWorldKey,
    required this.realWorlds,
    required this.onSelectWorld,
    super.key,
  });

  final BaleWorld selectedWorld;
  final String selectedBackendWorldKey;
  // Selalu dari GET /student/worlds (lihat WorldsRepository) - tidak ada
  // fallback dummy. Kosong berarti belum termuat/gagal, tampilkan loading,
  // bukan daftar dunia karangan.
  final List<Map<String, dynamic>> realWorlds;
  // Memilih dunia TIDAK langsung membuka soal - lihat baleverse_demo_screen
  // ._selectWorldFromList, yang menandai dunia terpilih lalu kembali ke
  // Beranda supaya user mulai misinya dari sana.
  final ValueChanged<Map<String, dynamic>> onSelectWorld;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 900;
    final selectedKeyUpper = selectedBackendWorldKey.isEmpty
        ? selectedWorld.key.name.toUpperCase()
        : selectedBackendWorldKey.toUpperCase();
    return Container(
      color: _worldBg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(14, compact ? 10 : 22, 14, 10),
        children: [
          _WorldHeader(compact: compact),
          SizedBox(height: compact ? 8 : 16),
          if (realWorlds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFFE0A1)),
                ),
                child: const Row(
                  children: [
                    CircularProgressIndicator(color: _worldYellow),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Memuat dunia belajar...',
                        style: TextStyle(
                          color: _worldInk,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final world in realWorlds) ...[
              _BackendWorldCard(
                world: world,
                selected: world['key'] == selectedKeyUpper,
                compact: compact,
                onTap: () => onSelectWorld(world),
              ),
              SizedBox(height: compact ? 8 : 12),
            ],
          if (!compact) _ComingSoonWorldCard(compact: compact),
        ],
      ),
    );
  }
}

class _BackendWorldCard extends StatelessWidget {
  const _BackendWorldCard({
    required this.world,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final Map<String, dynamic> world;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (world['key']) {
      'NUMERIA' => const Color(0xFF2D8CFF),
      'KODEX' => const Color(0xFF4CAF50),
      'DETECTIVIA' => const Color(0xFF8D5E34),
      _ => _worldYellow,
    };
    final icon = switch (world['key']) {
      'NUMERIA' => Icons.calculate_rounded,
      'KODEX' => Icons.code_rounded,
      'DETECTIVIA' => Icons.search_rounded,
      _ => Icons.public_rounded,
    };
    final questions = world['activeQuestionCount'] as int? ?? 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        key: ValueKey('world-card-${world['key']}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? _worldYellow : const Color(0xFFFFE0A1),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 56 : 70,
                height: compact ? 56 : 70,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(compact ? 18 : 20),
                ),
                child: Icon(icon, color: color, size: compact ? 30 : 38),
              ),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      world['name'] as String? ?? 'Dunia',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _worldInk,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      world['subject'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF60646F),
                        fontSize: compact ? 12 : 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 8),
                    _WorldChip(
                      label: '$questions soal',
                      color: color,
                      compact: compact,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (selected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _worldGreen.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: _worldGreen,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Aktif',
                        style: TextStyle(
                          color: _worldGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Icon(Icons.chevron_right_rounded, color: color, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorldChip extends StatelessWidget {
  const _WorldChip({
    required this.label,
    required this.color,
    required this.compact,
  });

  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WorldHeader extends StatelessWidget {
  const _WorldHeader({required this.compact});

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
            'assets/mascot/kenalan.png',
            height: compact ? 74 : 150,
            fit: BoxFit.contain,
          ),
          SizedBox(width: compact ? 8 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Dunia',
                  style: TextStyle(
                    color: _worldInk,
                    fontSize: compact ? 25 : 38,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 4 : 8),
                Text(
                  'Ketuk dunia, lanjut dari Beranda.',
                  style: TextStyle(
                    color: const Color(0xFF60646F),
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

class _ComingSoonWorldCard extends StatelessWidget {
  const _ComingSoonWorldCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE0A1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: _worldYellow, size: 34),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Dunia Bahasa segera hadir.',
              style: TextStyle(
                color: _worldInk,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
