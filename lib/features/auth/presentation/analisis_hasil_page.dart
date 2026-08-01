import 'dart:async';

import 'package:flutter/material.dart';

const _hasilPrimary = Color(0xFFF4B400);
const _hasilBg = Color(0xFFFFF3C6);
const _hasilInk = Color(0xFF3B2318);
const _hasilMuted = Color(0xFF747985);

bool _compactHasilLayout(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.shortestSide < 600 && size.height < 880;
}

class AnalisisHasilPage extends StatefulWidget {
  const AnalisisHasilPage({
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<AnalisisHasilPage> createState() => _AnalisisHasilPageState();
}

class _AnalisisHasilPageState extends State<AnalisisHasilPage> {
  Timer? _timer;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() => _showResult = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = _compactHasilLayout(context);
    return Scaffold(
      backgroundColor: _hasilBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SizedBox(
                width: constraints.maxWidth.clamp(0.0, 520.0),
                height: constraints.maxHeight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _showResult
                      ? _ResultView(
                          key: const ValueKey('analisis-hasil-result'),
                          compact: compact,
                          onBack: widget.onBack,
                          onContinue: widget.onContinue,
                        )
                      : _LoadingView(
                          key: const ValueKey('analisis-hasil-loading'),
                          compact: compact,
                          onBack: widget.onBack,
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({
    required this.compact,
    required this.onBack,
    super.key,
  });

  final bool compact;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, compact ? 12 : 22, 20, 18),
      children: [
        _HasilHeader(
          title: 'Cek Awal - Analisis',
          subtitle: 'Kami sedang menganalisis jawabanmu',
          onBack: onBack,
          compact: compact,
        ),
        SizedBox(height: compact ? 18 : 28),
        const _HasilStepProgress(step: 2),
        SizedBox(height: compact ? 24 : 36),
        Image.asset(
          'assets/mascot/analisis.png',
          height: compact ? 260 : 360,
          fit: BoxFit.contain,
          semanticLabel: 'Bale sedang menganalisis jawaban cek awal',
        ),
        SizedBox(height: compact ? 12 : 20),
        Text(
          'Bale sedang menganalisis\njawabanmu...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _hasilInk,
            fontSize: compact ? 28 : 36,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tenang ya, sebentar lagi kami temukan\ntitik awal terbaik untukmu!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _hasilMuted,
            fontSize: compact ? 15 : 18,
            height: 1.35,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: compact ? 20 : 28),
        const _AnalysisTaskCard(),
        SizedBox(height: compact ? 14 : 18),
        const _TipsCard(),
        SizedBox(height: compact ? 16 : 22),
        const _SafeDataNote(),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.compact,
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  final bool compact;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, compact ? 12 : 22, 20, 18),
      children: [
        _HasilHeader(
          title: 'Cek Awal - Hasil',
          subtitle: 'Rekomendasi awalmu sudah siap',
          onBack: onBack,
          compact: compact,
        ),
        SizedBox(height: compact ? 18 : 28),
        const _HasilStepProgress(step: 3),
        SizedBox(height: compact ? 22 : 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 5,
              child: Image.asset(
                'assets/mascot/analisis.png',
                height: compact ? 170 : 230,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: Container(
                padding: EdgeInsets.all(compact ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  'Aku sudah menemukan titik awal belajar yang cocok buatmu.',
                  style: TextStyle(
                    color: _hasilInk,
                    fontSize: compact ? 15 : 18,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 16 : 22),
        Container(
          padding: EdgeInsets.all(compact ? 18 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Titik awalmu sudah ditemukan!',
                style: TextStyle(
                  color: _hasilInk,
                  fontSize: compact ? 25 : 32,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              const _LevelCard(),
              const SizedBox(height: 18),
              const _ChipSection(
                icon: Icons.verified_user_rounded,
                title: 'Kekuatanmu',
                color: Color(0xFF4CAF50),
                chips: ['Mengenali pola', 'Memahami gambar', 'Menyusun urutan'],
              ),
              const Divider(height: 28),
              const _ChipSection(
                icon: Icons.track_changes_rounded,
                title: 'Fokus berikutnya',
                color: _hasilPrimary,
                chips: [
                  'Menjelaskan alasan',
                  'Memeriksa informasi',
                  'Langkah bertahap',
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 14 : 18),
        const _FirstMissionCard(),
        SizedBox(height: compact ? 16 : 20),
        SizedBox(
          height: compact ? 58 : 68,
          child: FilledButton(
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              backgroundColor: _hasilPrimary,
              foregroundColor: _hasilInk,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              textStyle: TextStyle(
                fontSize: compact ? 20 : 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: const Text('Mulai Misi Pertama'),
          ),
        ),
      ],
    );
  }
}

class _HasilHeader extends StatelessWidget {
  const _HasilHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(18),
                child: SizedBox.square(
                  dimension: compact ? 52 : 60,
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: _hasilInk,
                    size: 32,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: _hasilInk,
                fontSize: compact ? 20 : 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            SizedBox(width: compact ? 52 : 60),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _hasilMuted,
            fontSize: compact ? 14 : 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HasilStepProgress extends StatelessWidget {
  const _HasilStepProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _StepNode(
            label: 'Jawaban\nDiterima',
            icon: Icons.check_rounded,
            active: true,
          ),
        ),
        Expanded(
          child: Container(height: 4, color: _hasilPrimary),
        ),
        Expanded(
          child: _StepNode(
            label: 'Menganalisis',
            number: '2',
            active: step >= 2,
          ),
        ),
        Expanded(
          child: Container(
            height: 4,
            color: step >= 3 ? _hasilPrimary : const Color(0xFFE4E0D8),
          ),
        ),
        Expanded(
          child: _StepNode(
            label: 'Rekomendasi\nSiap',
            number: '3',
            active: step >= 3,
          ),
        ),
      ],
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.label,
    this.icon,
    this.number,
    this.active = false,
  });

  final String label;
  final IconData? icon;
  final String? number;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: active ? 54 : 46,
          height: active ? 54 : 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? _hasilPrimary : const Color(0xFFE9E6DF),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 5),
          ),
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 26)
              : Text(
                  number ?? '',
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF8B8179),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _hasilInk,
            fontSize: 12,
            height: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AnalysisTaskCard extends StatelessWidget {
  const _AnalysisTaskCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        children: [
          _TaskRow(
            icon: Icons.assignment_turned_in_rounded,
            title: 'Memeriksa jawabanmu',
            subtitle: 'Semua jawaban sudah diterima dengan aman.',
            active: true,
          ),
          Divider(height: 22),
          _TaskRow(
            icon: Icons.psychology_rounded,
            title: 'Menganalisis kemampuan',
            subtitle: 'Bale sedang memetakan kekuatan dan fokus belajarmu.',
            active: true,
          ),
          Divider(height: 22),
          _TaskRow(
            icon: Icons.track_changes_rounded,
            title: 'Menyiapkan rekomendasi',
            subtitle: 'Menentukan level dan misi terbaik untukmu.',
            locked: true,
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.active = false,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor:
              active ? const Color(0xFFFFF3C6) : const Color(0xFFEDEBE8),
          child: Icon(
            icon,
            color: active ? _hasilPrimary : const Color(0xFF8B8179),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: locked ? const Color(0xFF8B8179) : _hasilInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _hasilMuted,
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SizedBox.square(
          dimension: 32,
          child: locked
              ? const Icon(Icons.lock_outline_rounded, color: Color(0xFF8B8179))
              : const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: _hasilPrimary,
                ),
        ),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE2A4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: _hasilPrimary, size: 34),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Hasil ini akan membantumu mulai perjalanan belajar yang lebih seru dan tepat sasaran!',
              style: TextStyle(
                color: _hasilInk,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafeDataNote extends StatelessWidget {
  const _SafeDataNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFFE8F6EA),
          child: Icon(Icons.verified_user_rounded, color: Color(0xFF2F9B42)),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Data kamu aman dan hanya digunakan untuk pengalaman belajarmu.',
            style: TextStyle(
              color: _hasilMuted,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Icon(Icons.lock_outline_rounded, color: Color(0xFF8B8179)),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE1A0)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Icon(Icons.star_rounded, color: _hasilPrimary, size: 46),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level rekomendasi',
                  style: TextStyle(
                    color: _hasilInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Foundation 3',
                  style: TextStyle(
                    color: Color(0xFFEFA500),
                    fontSize: 32,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Cocok untuk tantangan dasar hingga menengah.',
                  style: TextStyle(
                    color: _hasilMuted,
                    fontSize: 13,
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

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.chips,
  });

  final IconData icon;
  final String title;
  final Color color;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: _hasilInk,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chip in chips)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.34)),
                ),
                child: Text(
                  chip,
                  style: const TextStyle(
                    color: _hasilInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FirstMissionCard extends StatelessWidget {
  const _FirstMissionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFFFFF4D7),
            child: Icon(Icons.event_note_rounded, color: _hasilPrimary),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Misi pertamamu',
                  style: TextStyle(
                    color: _hasilMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Misteri Jadwal yang Berubah',
                  style: TextStyle(
                    color: _hasilInk,
                    fontSize: 19,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '8 menit - 5 aktivitas - +30 XP',
                  style: TextStyle(
                    color: _hasilInk,
                    fontSize: 13,
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
