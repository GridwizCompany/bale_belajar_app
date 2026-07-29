import 'package:flutter/material.dart';

import '../../../../shared/widgets/bale_card.dart';
import '../../../../theme/bale_theme.dart';
import '../../data/baleverse_dummy_data.dart';
import '../../domain/baleverse_models.dart';

class PageShell extends StatelessWidget {
  const PageShell({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        const AppHeader(),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: BaleColors.success,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.menu_book_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BaleBelajar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              Text(
                'BaleVerse mobile',
                style:
                    TextStyle(fontWeight: FontWeight.w700, color: Colors.grey),
              ),
            ],
          ),
        ),
        const MetricPill(icon: Icons.local_fire_department, label: '2/3'),
      ],
    );
  }
}

class BaleHeroCard extends StatelessWidget {
  const BaleHeroCard({required this.stateLabel, super.key});

  final String stateLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'BaleHero sedang $stateLabel',
      child: BaleCard(
        child: Row(
          children: [
            BaleHeroAvatar(stateLabel: stateLabel),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SmallCaps('BaleHero'),
                  Text(
                    stateLabel,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text('Kita fokus ke satu langkah kecil dulu.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BaleHeroAvatar extends StatelessWidget {
  const BaleHeroAvatar({required this.stateLabel, super.key});

  final String stateLabel;

  @override
  Widget build(BuildContext context) {
    final askingMentor = stateLabel.toLowerCase().contains('mentor');
    final celebrating = stateLabel.toLowerCase().contains('selesai');
    final confused = stateLabel.toLowerCase().contains('berpikir') ||
        stateLabel.toLowerCase().contains('kesalahan');
    final accent = askingMentor
        ? BaleColors.warning
        : celebrating
            ? BaleColors.success
            : confused
                ? BaleColors.detectivia
                : BaleColors.info;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 2),
      ),
      child: CustomPaint(
        painter: _BaleHeroPainter(
          accent: accent,
          confused: confused,
          celebrating: celebrating,
        ),
      ),
    );
  }
}

class _BaleHeroPainter extends CustomPainter {
  const _BaleHeroPainter({
    required this.accent,
    required this.confused,
    required this.celebrating,
  });

  final Color accent;
  final bool confused;
  final bool celebrating;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final center = Offset(size.width / 2, size.height / 2);

    paint.color = accent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 48, height: 54),
        const Radius.circular(18),
      ),
      paint,
    );

    paint.color = const Color(0xFFFFE0BD);
    canvas.drawCircle(Offset(center.dx, center.dy - 8), 20, paint);

    paint.color = BaleColors.ink;
    canvas.drawCircle(Offset(center.dx - 7, center.dy - 12), 2.8, paint);
    canvas.drawCircle(Offset(center.dx + 7, center.dy - 12), 2.8, paint);

    final mouth = Path();
    if (confused) {
      mouth.moveTo(center.dx - 8, center.dy + 3);
      mouth.quadraticBezierTo(
          center.dx, center.dy - 2, center.dx + 8, center.dy + 3);
    } else {
      mouth.moveTo(center.dx - 8, center.dy + 1);
      mouth.quadraticBezierTo(
          center.dx, center.dy + 9, center.dx + 8, center.dy + 1);
    }
    canvas.drawPath(
      mouth,
      Paint()
        ..color = BaleColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    if (celebrating) {
      paint.color = BaleColors.dayaBale;
      canvas.drawCircle(const Offset(18, 18), 4, paint);
      canvas.drawCircle(Offset(size.width - 18, 16), 3, paint);
      canvas.drawCircle(Offset(size.width - 20, size.height - 18), 3.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BaleHeroPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.confused != confused ||
        oldDelegate.celebrating != celebrating;
  }
}

class StatCard extends StatelessWidget {
  const StatCard({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return BaleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label),
        ],
      ),
    );
  }
}

class MetricPill extends StatelessWidget {
  const MetricPill({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: BaleColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: BaleColors.warning),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class SmallCaps extends StatelessWidget {
  const SmallCaps(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: BaleColors.dayaBale,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    );
  }
}

class WorldSelector extends StatelessWidget {
  const WorldSelector({
    required this.selectedWorld,
    required this.onSelectWorld,
    super.key,
  });

  final BaleWorld selectedWorld;
  final ValueChanged<BaleWorldKey> onSelectWorld;

  @override
  Widget build(BuildContext context) {
    return BaleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pilih Dunia', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final world in baleWorlds) ...[
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelectWorld(world.key),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selectedWorld.key == world.key
                      ? world.color.withValues(alpha: 0.10)
                      : BaleColors.soft,
                  border: Border.all(
                    color: selectedWorld.key == world.key
                        ? world.color
                        : BaleColors.line,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      world.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('${world.subject} - ${world.characterClass}'),
                    const SizedBox(height: 8),
                    BaleProgressBar(
                      value: world.mastery / 100,
                      color: world.color,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class RewardPill extends StatelessWidget {
  const RewardPill({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
