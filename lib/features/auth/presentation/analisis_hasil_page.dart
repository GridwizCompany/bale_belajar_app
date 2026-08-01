import 'dart:async';

import 'package:flutter/material.dart';

const _hasilPrimary = Color(0xFFF4B400);
const _hasilBg = Color(0xFFFFF3C6);
const _hasilInk = Color(0xFF3B2318);
const _hasilMuted = Color(0xFF747985);

bool _compactHasilLayout(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.shortestSide < 600;
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
      padding: EdgeInsets.fromLTRB(16, compact ? 8 : 18, 16, 12),
      children: [
        _HasilHeader(
          title: 'Cek Awal - Analisis',
          subtitle: 'Bale sedang membaca hasil cek awalmu.',
          onBack: onBack,
          compact: compact,
        ),
        SizedBox(height: compact ? 10 : 22),
        const _HasilStepProgress(step: 2),
        SizedBox(height: compact ? 14 : 28),
        Image.asset(
          'assets/mascot/analisis.png',
          height: compact ? 170 : 300,
          fit: BoxFit.contain,
          semanticLabel: 'Bale sedang menganalisis jawaban cek awal',
        ),
        SizedBox(height: compact ? 8 : 18),
        Text(
          'Sebentar, Bale cek hasilmu...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _hasilInk,
            fontSize: compact ? 24 : 34,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kami siapkan level awal dan misi pertama yang paling pas.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _hasilMuted,
            fontSize: compact ? 13 : 17,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: compact ? 12 : 24),
        _AnalysisTaskCard(compact: compact),
        SizedBox(height: compact ? 10 : 16),
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
      padding: EdgeInsets.fromLTRB(16, compact ? 8 : 18, 16, 12),
      children: [
        _HasilHeader(
          title: 'Cek Awal - Hasil',
          subtitle: 'Rekomendasi awalmu siap.',
          onBack: onBack,
          compact: compact,
        ),
        SizedBox(height: compact ? 10 : 22),
        const _HasilStepProgress(step: 3),
        SizedBox(height: compact ? 12 : 26),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 5,
              child: Image.asset(
                'assets/mascot/analisis.png',
                height: compact ? 105 : 220,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 6,
              child: Container(
                padding: EdgeInsets.all(compact ? 12 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  'Aku sudah punya titik awal yang pas buatmu.',
                  style: TextStyle(
                    color: _hasilInk,
                    fontSize: compact ? 13 : 18,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 10 : 22),
        Container(
          padding: EdgeInsets.all(compact ? 14 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
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
                'Mulai dari sini',
                style: TextStyle(
                  color: _hasilInk,
                  fontSize: compact ? 23 : 32,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: compact ? 10 : 16),
              _LevelCard(compact: compact),
              SizedBox(height: compact ? 12 : 18),
              _ChipSection(
                icon: Icons.verified_user_rounded,
                title: 'Kamu sudah kuat di',
                color: Color(0xFF4CAF50),
                chips: compact
                    ? const ['Pola', 'Gambar', 'Urutan']
                    : const [
                        'Mengenali pola',
                        'Memahami gambar',
                        'Menyusun urutan',
                      ],
              ),
              Divider(height: compact ? 18 : 28),
              _ChipSection(
                icon: Icons.track_changes_rounded,
                title: 'Latihan berikutnya',
                color: _hasilPrimary,
                chips: compact
                    ? const ['Alasan', 'Info', 'Langkah']
                    : const [
                        'Menjelaskan alasan',
                        'Memeriksa informasi',
                        'Langkah bertahap',
                      ],
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 10 : 18),
        _FirstMissionCard(compact: compact),
        SizedBox(height: compact ? 10 : 20),
        SizedBox(
          height: compact ? 50 : 68,
          child: FilledButton(
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              backgroundColor: _hasilPrimary,
              foregroundColor: _hasilInk,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              textStyle: TextStyle(
                fontSize: compact ? 17 : 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: const Text('Mulai Misi'),
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
                  dimension: compact ? 44 : 60,
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: _hasilInk,
                    size: 30,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: _hasilInk,
                fontSize: compact ? 19 : 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            SizedBox(width: compact ? 44 : 60),
          ],
        ),
        SizedBox(height: compact ? 4 : 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _hasilMuted,
            fontSize: compact ? 12 : 17,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          flex: 3,
          child: _StepNode(
            label: 'Diterima',
            icon: Icons.check_rounded,
            active: true,
          ),
        ),
        Expanded(
          child: Container(height: 4, color: _hasilPrimary),
        ),
        Expanded(
          flex: 3,
          child: _StepNode(
            label: 'Analisis',
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
          flex: 3,
          child: _StepNode(
            label: 'Siap',
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
          width: active ? 42 : 36,
          height: active ? 42 : 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? _hasilPrimary : const Color(0xFFE9E6DF),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 22)
              : Text(
                  number ?? '',
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF8B8179),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _hasilInk,
            fontSize: 11,
            height: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AnalysisTaskCard extends StatelessWidget {
  const _AnalysisTaskCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.fromLTRB(14, compact ? 12 : 16, 14, compact ? 12 : 16),
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
      child: Column(
        children: [
          _TaskRow(
            icon: Icons.assignment_turned_in_rounded,
            title: 'Jawaban diterima',
            subtitle: 'Semua data aman.',
            active: true,
            compact: compact,
          ),
          Divider(height: compact ? 14 : 22),
          _TaskRow(
            icon: Icons.psychology_rounded,
            title: 'Mencari level awal',
            subtitle: 'Bale memilih misi yang pas.',
            active: true,
            compact: compact,
          ),
          if (!compact) ...[
            const Divider(height: 22),
            const _TaskRow(
              icon: Icons.track_changes_rounded,
              title: 'Menyiapkan rekomendasi',
              subtitle: 'Menentukan level dan misi terbaik.',
              locked: true,
            ),
          ],
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
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final bool locked;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: compact ? 21 : 25,
          backgroundColor:
              active ? const Color(0xFFFFF3C6) : const Color(0xFFEDEBE8),
          child: Icon(
            icon,
            color: active ? _hasilPrimary : const Color(0xFF8B8179),
          ),
        ),
        SizedBox(width: compact ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: locked ? const Color(0xFF8B8179) : _hasilInk,
                  fontSize: compact ? 15 : 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: compact ? 1 : 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _hasilMuted,
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SizedBox.square(
          dimension: compact ? 26 : 32,
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
  const _LevelCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE1A0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: compact ? 25 : 34,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.star_rounded,
              color: _hasilPrimary,
              size: compact ? 34 : 46,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level awal',
                  style: TextStyle(
                    color: _hasilInk,
                    fontSize: compact ? 13 : 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Foundation 3',
                  style: TextStyle(
                    color: Color(0xFFEFA500),
                    fontSize: compact ? 27 : 32,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!compact)
                  const Text(
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
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: _hasilInk,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chip in chips)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.34)),
                ),
                child: Text(
                  chip,
                  style: const TextStyle(
                    color: _hasilInk,
                    fontSize: 12,
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
  const _FirstMissionCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: compact ? 24 : 34,
            backgroundColor: Color(0xFFFFF4D7),
            child: Icon(Icons.event_note_rounded, color: _hasilPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Misi pertamamu',
                  style: TextStyle(
                    color: _hasilMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Misteri Jadwal yang Berubah',
                  style: TextStyle(
                    color: _hasilInk,
                    fontSize: compact ? 16 : 19,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 3 : 6),
                Text(
                  '8 menit - 5 aktivitas',
                  style: TextStyle(
                    color: _hasilInk,
                    fontSize: 12,
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
