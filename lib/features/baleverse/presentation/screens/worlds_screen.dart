import 'package:flutter/material.dart';

import '../../data/baleverse_dummy_data.dart';
import '../../domain/baleverse_models.dart';

const _worldBg = Color(0xFFFFF3C6);
const _worldInk = Color(0xFF3B2318);
const _worldYellow = Color(0xFFF4B400);

class WorldsScreen extends StatelessWidget {
  const WorldsScreen({
    required this.selectedWorld,
    required this.onSelectWorld,
    super.key,
  });

  final BaleWorld selectedWorld;
  final ValueChanged<BaleWorldKey> onSelectWorld;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 760;
    return Container(
      color: _worldBg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, compact ? 14 : 22, 20, 18),
        children: [
          _WorldHeader(compact: compact),
          const SizedBox(height: 16),
          for (final world in baleWorlds) ...[
            _WorldCard(
              world: world,
              selected: world.key == selectedWorld.key,
              onTap: () => onSelectWorld(world.key),
            ),
            const SizedBox(height: 12),
          ],
          _ComingSoonWorldCard(compact: compact),
        ],
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
            'assets/mascot/kenalan.png',
            height: compact ? 112 : 150,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Dunia',
                  style: TextStyle(
                    color: _worldInk,
                    fontSize: compact ? 30 : 38,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mulai dari satu dunia. Yang lain tetap bisa kamu buka kapan saja.',
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

class _WorldCard extends StatelessWidget {
  const _WorldCard({
    required this.world,
    required this.selected,
    required this.onTap,
  });

  final BaleWorld world;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = switch (world.key) {
      BaleWorldKey.numeria => (
          icon: Icons.calculate_rounded,
          mission: 'Misi contoh: Pecahkan pola angka.',
          description: 'Latih matematika lewat teka-teki ringan.'
        ),
      BaleWorldKey.kodex => (
          icon: Icons.code_rounded,
          mission: 'Misi contoh: Susun langkah algoritma.',
          description: 'Belajar logika komputer tanpa terasa berat.'
        ),
      BaleWorldKey.detectivia => (
          icon: Icons.search_rounded,
          mission: 'Misi contoh: Cari bukti yang paling kuat.',
          description: 'Amati petunjuk dan pecahkan kasus.'
        ),
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: world.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(details.icon, color: world.color, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            world.name,
                            style: const TextStyle(
                              color: _worldInk,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: _worldYellow,
                          ),
                      ],
                    ),
                    Text(
                      world.subject,
                      style: const TextStyle(
                        color: Color(0xFF60646F),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details.description,
                      style: const TextStyle(
                        color: Color(0xFF60646F),
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details.mission,
                      style: const TextStyle(
                        color: _worldInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
              'Dunia Bahasa dan Sains sedang disiapkan.',
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
