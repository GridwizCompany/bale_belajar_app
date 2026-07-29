import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum BeloPose {
  senang,
  ceria,
  ngantuk,
  bingung,
  jatuhCinta,
  kedip,
  kaget,
  sedih,
  melambai,
  bacaBuku,
  lompatKegirangan,
  jempolOke,
  wisuda,
  mimpiIndah,
  lariSemangat,
  nulisCatatan,
  hero,
}

extension _BeloPoseAsset on BeloPose {
  String get slug => switch (this) {
        BeloPose.senang => 'senang',
        BeloPose.ceria => 'ceria',
        BeloPose.ngantuk => 'ngantuk',
        BeloPose.bingung => 'bingung',
        BeloPose.jatuhCinta => 'jatuh-cinta',
        BeloPose.kedip => 'kedip',
        BeloPose.kaget => 'kaget',
        BeloPose.sedih => 'sedih',
        BeloPose.melambai => 'melambai',
        BeloPose.bacaBuku => 'baca-buku',
        BeloPose.lompatKegirangan => 'lompat-kegirangan',
        BeloPose.jempolOke => 'jempol-oke',
        BeloPose.wisuda => 'wisuda',
        BeloPose.mimpiIndah => 'mimpi-indah',
        BeloPose.lariSemangat => 'lari-semangat',
        BeloPose.nulisCatatan => 'nulis-catatan',
        BeloPose.hero => 'hero',
      };

  String get label => switch (this) {
        BeloPose.senang => 'Belo senang',
        BeloPose.ceria => 'Belo ceria',
        BeloPose.ngantuk => 'Belo ngantuk',
        BeloPose.bingung => 'Belo bingung',
        BeloPose.jatuhCinta => 'Belo jatuh cinta',
        BeloPose.kedip => 'Belo mengedipkan mata',
        BeloPose.kaget => 'Belo kaget',
        BeloPose.sedih => 'Belo sedih',
        BeloPose.melambai => 'Belo melambai',
        BeloPose.bacaBuku => 'Belo membaca buku',
        BeloPose.lompatKegirangan => 'Belo melompat kegirangan',
        BeloPose.jempolOke => 'Belo memberi jempol',
        BeloPose.wisuda => 'Belo wisuda',
        BeloPose.mimpiIndah => 'Belo bermimpi indah',
        BeloPose.lariSemangat => 'Belo berlari semangat',
        BeloPose.nulisCatatan => 'Belo menulis catatan',
        BeloPose.hero => 'Belo melambai menyambut',
      };
}

/// Rasio tinggi/lebar tetap Belo (viewBox 160x192) supaya tidak gepeng di ukuran berapa pun.
const double _beloAspectRatio = 192 / 160;

class BeloMascot extends StatelessWidget {
  const BeloMascot({
    this.pose = BeloPose.senang,
    this.size = 160,
    this.animate = false,
    super.key,
  });

  final BeloPose pose;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final svg = SvgPicture.asset(
      'assets/mascot/belo-${pose.slug}.svg',
      width: size,
      height: size * _beloAspectRatio,
      semanticsLabel: pose.label,
      placeholderBuilder: (_) => _BeloFallback(size: size),
    );
    return animate ? _BeloBob(child: svg) : svg;
  }
}

class _BeloFallback extends StatelessWidget {
  const _BeloFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * _beloAspectRatio,
      child: CustomPaint(painter: _BeloFallbackPainter()),
    );
  }
}

class _BeloFallbackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final w = size.width;
    final h = size.height;

    paint.color = const Color(0x2238BDF8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.83),
        width: w * 0.55,
        height: h * 0.07,
      ),
      paint,
    );

    final book = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.2, w * 0.64, h * 0.48),
      Radius.circular(w * 0.12),
    );
    paint.color = const Color(0xFF38BDF8);
    canvas.drawRRect(book, paint);

    paint.color = const Color(0xFF0284C7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.48, h * 0.2, w * 0.06, h * 0.5),
        Radius.circular(w * 0.03),
      ),
      paint,
    );

    paint.color = Colors.white;
    canvas.drawCircle(Offset(w * 0.38, h * 0.38), w * 0.09, paint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.38), w * 0.09, paint);

    paint.color = const Color(0xFF172033);
    canvas.drawCircle(Offset(w * 0.39, h * 0.39), w * 0.028, paint);
    canvas.drawCircle(Offset(w * 0.61, h * 0.39), w * 0.028, paint);

    final smile = Path()
      ..moveTo(w * 0.42, h * 0.51)
      ..quadraticBezierTo(w * 0.5, h * 0.58, w * 0.58, h * 0.51);
    canvas.drawPath(
      smile,
      Paint()
        ..isAntiAlias = true
        ..color = const Color(0xFF172033)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.025
        ..strokeCap = StrokeCap.round,
    );

    paint.color = const Color(0xFFF59E0B);
    canvas.drawCircle(Offset(w * 0.38, h * 0.73), w * 0.04, paint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.73), w * 0.04, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BeloBob extends StatefulWidget {
  const _BeloBob({required this.child});

  final Widget child;

  @override
  State<_BeloBob> createState() => _BeloBobState();
}

class _BeloBobState extends State<_BeloBob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final wave = math.sin(_controller.value * math.pi * 2);
        return Transform.translate(
          offset: Offset(0, wave * 5),
          child: Transform.rotate(angle: wave * 0.035, child: child),
        );
      },
      child: widget.child,
    );
  }
}
