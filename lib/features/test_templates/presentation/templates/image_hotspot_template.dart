import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'test_template_ui_helpers.dart';

const _hotspotYellow = Color(0xFFF4B400);
const _hotspotInk = Color(0xFF3B2318);
const _hotspotGreen = Color(0xFF2F9B42);

class ImageHotspotTemplate extends StatefulWidget {
  const ImageHotspotTemplate({
    required this.question,
    required this.onCheckAnswer,
    this.currentQuestion = 11,
    this.totalQuestions = 20,
    this.tipText,
    this.onBack,
    this.onHint,
    this.onSkip,
    super.key,
  });

  final TemplateQuestion question;
  final ValueChanged<String?> onCheckAnswer;
  final int currentQuestion;
  final int totalQuestions;
  final String? tipText;
  final VoidCallback? onBack;
  final VoidCallback? onHint;
  final VoidCallback? onSkip;

  @override
  State<ImageHotspotTemplate> createState() => _ImageHotspotTemplateState();
}

class _ImageHotspotTemplateState extends State<ImageHotspotTemplate> {
  String? _selectedHotspotId;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.shortestSide < 600;
    final progress = widget.totalQuestions <= 0
        ? 0.0
        : (widget.currentQuestion / widget.totalQuestions).clamp(0.0, 1.0);
    final selectedHotspot = _selectedHotspot;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3C6),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            compact ? 10 : 20,
            compact ? 8 : 18,
            compact ? 10 : 20,
            compact ? 10 : 28,
          ),
          children: [
            _HotspotHeader(
              currentQuestion: widget.currentQuestion,
              totalQuestions: widget.totalQuestions,
              progress: progress,
              compact: compact,
              onBack: widget.onBack,
            ),
            SizedBox(height: compact ? 8 : 24),
            _HotspotMascotIntro(compact: compact),
            SizedBox(height: compact ? 8 : 24),
            _QuestionCard(
              question: widget.question,
              selectedHotspot: selectedHotspot,
              selectedHotspotId: _selectedHotspotId,
              compact: compact,
              tipText: widget.tipText,
              onSelected: (hotspotId) => setState(
                () => _selectedHotspotId = hotspotId,
              ),
              onCheckAnswer: _selectedHotspotId == null
                  ? null
                  : () => widget.onCheckAnswer(_selectedHotspotId),
            ),
            SizedBox(height: compact ? 6 : 18),
            _BottomActions(
              compact: compact,
              onHint: widget.onHint,
              onSkip: widget.onSkip,
            ),
          ],
        ),
      ),
    );
  }

  HotspotArea? get _selectedHotspot {
    for (final hotspot in widget.question.hotspotAreas) {
      if (hotspot.id == _selectedHotspotId) return hotspot;
    }
    return null;
  }
}

class _HotspotHeader extends StatelessWidget {
  const _HotspotHeader({
    required this.currentQuestion,
    required this.totalQuestions,
    required this.progress,
    required this.compact,
    this.onBack,
  });

  final int currentQuestion;
  final int totalQuestions;
  final double progress;
  final bool compact;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          elevation: 8,
          shadowColor: const Color(0x18000000),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(22),
            child: SizedBox.square(
              dimension: compact ? 52 : 64,
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _hotspotInk,
                size: 32,
              ),
            ),
          ),
        ),
        SizedBox(width: compact ? 8 : 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cek Awal \u2022 $currentQuestion/$totalQuestions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _hotspotInk,
                  fontSize: compact ? 18 : 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  Container(
                    height: compact ? 18 : 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x15000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: compact ? 18 : 30,
                          decoration: BoxDecoration(
                            color: _hotspotYellow,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      '$percent%',
                      style: TextStyle(
                        color: _hotspotInk,
                        fontSize: compact ? 14 : 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HotspotMascotIntro extends StatelessWidget {
  const _HotspotMascotIntro({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 8,
          child: Image.asset(
            'assets/mascot/kenalan.png',
            height: compact ? 104 : 190,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 11,
          child: Container(
            padding: EdgeInsets.all(compact ? 8 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x16000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Hai, aku '),
                  TextSpan(
                    text: 'Babe',
                    style: TextStyle(color: _hotspotGreen),
                  ),
                  const TextSpan(
                    text:
                        '!\nAmati gambar berikut! Ketuk pada bagian yang sesuai dengan pertanyaan.',
                  ),
                ],
              ),
              style: TextStyle(
                color: _hotspotInk,
                fontSize: compact ? 11 : 18,
                height: compact ? 1.22 : 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.selectedHotspot,
    required this.selectedHotspotId,
    required this.compact,
    required this.tipText,
    required this.onSelected,
    required this.onCheckAnswer,
  });

  final TemplateQuestion question;
  final HotspotArea? selectedHotspot;
  final String? selectedHotspotId;
  final bool compact;
  final String? tipText;
  final ValueChanged<String> onSelected;
  final VoidCallback? onCheckAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x13000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 16,
                vertical: compact ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: _hotspotYellow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.extension_rounded,
                    color: const Color(0xFFD89B00),
                    size: compact ? 18 : 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Template 11 \u2022 Image Hotspot',
                    style: TextStyle(
                      color: const Color(0xFFD89B00),
                      fontSize: compact ? 13 : 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 20),
          Text(
            question.prompt,
            style: TextStyle(
              color: _hotspotInk,
              fontSize: compact ? 22 : 28,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            question.instruction ?? 'Ketuk titik (+) pada gambar.',
            style: TextStyle(
              color: const Color(0xFF8C8274),
              fontSize: compact ? 15 : 19,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 8 : 24),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEEDDAE)),
              ),
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final hotspots = question.hotspotAreas.isEmpty
                      ? _fallbackHotspots
                      : question.hotspotAreas;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _HotspotImage(question: question),
                      for (final hotspot in hotspots)
                        Positioned(
                          left: constraints.maxWidth * hotspot.x -
                              (compact ? 21 : 26),
                          top: constraints.maxHeight * hotspot.y -
                              (compact ? 21 : 26),
                          child: _HotspotButton(
                            hotspot: hotspot,
                            selected: selectedHotspotId == hotspot.id,
                            compact: compact,
                            onTap: () => onSelected(hotspot.id),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 20),
          _TipCard(
            text: tipText ??
                'Perhatikan gambar dengan teliti sebelum memilih jawaban.',
            compact: compact,
          ),
          SizedBox(height: compact ? 12 : 16),
          _SelectionStatus(
            selectedHotspot: selectedHotspot,
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 28),
          FilledButton(
            onPressed: onCheckAnswer,
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(compact ? 54 : 72),
              backgroundColor: _hotspotYellow,
              foregroundColor: _hotspotInk,
              disabledBackgroundColor: const Color(0xFFE8E0D2),
              disabledForegroundColor: const Color(0xFF8C8274),
              elevation: 8,
              shadowColor: const Color(0x55F4B400),
              textStyle: TextStyle(
                fontSize: compact ? 20 : 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Periksa Jawaban'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _fallbackHotspots = [
  HotspotArea(id: 'bookshelf', label: 'Rak buku', x: 0.16, y: 0.34),
  HotspotArea(id: 'pillow', label: 'Bantal', x: 0.39, y: 0.48),
  HotspotArea(id: 'cat', label: 'Kucing', x: 0.62, y: 0.50),
  HotspotArea(id: 'table', label: 'Meja', x: 0.48, y: 0.78),
  HotspotArea(id: 'plant', label: 'Tanaman', x: 0.88, y: 0.70),
];

class _HotspotImage extends StatelessWidget {
  const _HotspotImage({required this.question});

  final TemplateQuestion question;

  @override
  Widget build(BuildContext context) {
    final url = question.media?.url;
    if (url != null && url.isNotEmpty) {
      return url.startsWith('http')
          ? Image.network(url, fit: BoxFit.cover)
          : Image.asset(url, fit: BoxFit.cover);
    }
    return CustomPaint(
      painter: _LivingRoomPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _HotspotButton extends StatelessWidget {
  const _HotspotButton({
    required this.hotspot,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final HotspotArea hotspot;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 52.0;
    return Tooltip(
      message: hotspot.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: selected
                ? _hotspotYellow
                : _hotspotYellow.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            selected ? Icons.check_rounded : Icons.add_rounded,
            color: Colors.white,
            size: compact ? 28 : 34,
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            color: _hotspotYellow,
            size: compact ? 32 : 40,
          ),
          SizedBox(width: compact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips',
                  style: TextStyle(
                    color: const Color(0xFFD89B00),
                    fontSize: compact ? 20 : 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  text,
                  style: TextStyle(
                    color: _hotspotInk,
                    fontSize: compact ? 14 : 17,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
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

class _SelectionStatus extends StatelessWidget {
  const _SelectionStatus({
    required this.selectedHotspot,
    required this.compact,
  });

  final HotspotArea? selectedHotspot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final selected = selectedHotspot != null;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFF8D9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hotspotYellow,
          width: 1.2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 42 : 52,
            height: compact ? 42 : 52,
            decoration: const BoxDecoration(
              color: _hotspotYellow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              selected ? Icons.check_rounded : Icons.search_rounded,
              color: Colors.white,
              size: compact ? 26 : 32,
            ),
          ),
          SizedBox(width: compact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected
                      ? 'Dipilih: ${selectedHotspot!.label}'
                      : 'Belum ada yang dipilih',
                  style: TextStyle(
                    color: const Color(0xFFD89B00),
                    fontSize: compact ? 15 : 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selected
                      ? 'Kamu bisa mengganti pilihan dengan mengetuk titik lain.'
                      : 'Ketuk salah satu titik (+) pada gambar untuk memilih jawabanmu.',
                  style: TextStyle(
                    color: _hotspotInk,
                    fontSize: compact ? 12 : 14,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
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

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.compact,
    this.onHint,
    this.onSkip,
  });

  final bool compact;
  final VoidCallback? onHint;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: onHint ?? () => showTemplateHintSheet(context),
            icon: Icon(
              Icons.tips_and_updates_outlined,
              color: _hotspotGreen,
              size: compact ? 22 : 28,
            ),
            label: Text(
              'Butuh petunjuk?',
              style: TextStyle(
                color: _hotspotGreen,
                fontSize: compact ? 11 : 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Container(width: 1, height: 34, color: const Color(0xFFE4D8C8)),
        Expanded(
          child: TextButton.icon(
            onPressed: onSkip,
            label: Text(
              'Lewati untuk sekarang',
              style: TextStyle(
                color: const Color(0xFF7D7A78),
                fontSize: compact ? 11 : 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            iconAlignment: IconAlignment.end,
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF7D7A78),
            ),
          ),
        ),
      ],
    );
  }
}

class _LivingRoomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()..color = const Color(0xFFFFE6BD);
    final floor = Paint()..color = const Color(0xFFC68138);
    canvas.drawRect(Offset.zero & size, wall);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      floor,
    );

    final window = Paint()..color = const Color(0xFFAEE2FF);
    final frame = Paint()
      ..color = const Color(0xFF9B642F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final windowRect = Rect.fromCenter(
      center: Offset(size.width * 0.52, size.height * 0.26),
      width: size.width * 0.36,
      height: size.height * 0.32,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(windowRect, const Radius.circular(8)),
      window,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(windowRect, const Radius.circular(8)),
      frame,
    );

    final sofa = Paint()..color = const Color(0xFF6F9E45);
    final sofaRect = Rect.fromCenter(
      center: Offset(size.width * 0.55, size.height * 0.55),
      width: size.width * 0.46,
      height: size.height * 0.26,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sofaRect, const Radius.circular(22)),
      sofa,
    );

    final table = Paint()..color = const Color(0xFF9B642F);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.79),
        width: size.width * 0.26,
        height: size.height * 0.09,
      ),
      table,
    );

    final shelf = Paint()..color = const Color(0xFFA56830);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.07,
          size.height * 0.26,
          size.width * 0.18,
          size.height * 0.44,
        ),
        const Radius.circular(8),
      ),
      shelf,
    );

    final cat = Paint()..color = const Color(0xFF8A8A8A);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.62, size.height * 0.55),
        width: size.width * 0.12,
        height: size.height * 0.14,
      ),
      cat,
    );
    canvas.drawCircle(
      Offset(size.width * 0.58, size.height * 0.49),
      size.width * 0.035,
      cat,
    );

    final plant = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.87, size.height * 0.61),
        width: size.width * 0.09,
        height: size.height * 0.22,
      ),
      plant,
    );

    final pillow = Paint()..color = const Color(0xFFF6C343);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.38, size.height * 0.52),
          width: size.width * 0.11,
          height: size.height * 0.12,
        ),
        const Radius.circular(10),
      ),
      pillow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
