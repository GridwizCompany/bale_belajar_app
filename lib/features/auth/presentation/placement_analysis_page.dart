import 'dart:async';

import 'package:flutter/material.dart';

const _analysisPrimary = Color(0xFFF4B400);
const _analysisDark = Color(0xFF0E3A5F);
const _analysisInk = Color(0xFF3B2318);

bool _compactPhoneLayout(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.shortestSide < 600 && size.height < 980;
}

class PlacementAnalysisPage extends StatefulWidget {
  const PlacementAnalysisPage({
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<PlacementAnalysisPage> createState() => _PlacementAnalysisPageState();
}

class _PlacementAnalysisPageState extends State<PlacementAnalysisPage> {
  Timer? _resultTimer;
  late final ScrollController _analysisScrollController;
  late final ScrollController _resultScrollController;
  bool _resultReady = false;

  @override
  void initState() {
    super.initState();
    _analysisScrollController = ScrollController();
    _resultScrollController = ScrollController();
    _resultTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() => _resultReady = true);
    });
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    _analysisScrollController.dispose();
    _resultScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = _compactPhoneLayout(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3C6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ColoredBox(
              color: const Color(0xFFFFF3C6),
              child: Center(
                child: SizedBox(
                  width: constraints.maxWidth.clamp(0.0, 520.0),
                  height: constraints.maxHeight,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 14 : 22,
                      compact ? 10 : 18,
                      compact ? 14 : 22,
                      compact ? 8 : 18,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _resultReady
                          ? _buildResult(context)
                          : _buildAnalyzing(context),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnalyzing(BuildContext context) {
    final compact = _compactPhoneLayout(context);
    return ListView(
      key: const ValueKey('analysis-loading'),
      controller: _analysisScrollController,
      primary: false,
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            _AnalysisBackButton(onPressed: widget.onBack),
            const Spacer(),
            Text(
              'Cek Awal - Analisis',
              style: TextStyle(
                color: _analysisDark,
                fontSize: compact ? 20 : 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            SizedBox(width: compact ? 52 : 60),
          ],
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(
          'Kami sedang menganalisis jawabanmu',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF747985),
            fontSize: compact ? 14 : 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: compact ? 22 : 28),
        const _AnalysisProgress(),
        SizedBox(height: compact ? 26 : 36),
        Image.asset(
          'assets/mascot/analisis.png',
          height: compact ? 250 : 340,
          fit: BoxFit.contain,
          semanticLabel: 'Bale sedang menganalisis jawaban',
        ),
        SizedBox(height: compact ? 14 : 20),
        Text(
          'Bale sedang menganalisis\njawabanmu...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _analysisInk,
            fontSize: compact ? 28 : 36,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 10 : 12),
        Text(
          'Tenang ya, sebentar lagi kami temukan\ntitik awal terbaik untukmu!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF747985),
            fontSize: compact ? 16 : 19,
            height: 1.35,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: compact ? 22 : 28),
        const _AnalysisChecklist(),
        SizedBox(height: compact ? 14 : 18),
        const _AnalysisTipCard(),
        SizedBox(height: compact ? 18 : 24),
        const _AnalysisSecurityNote(),
        SizedBox(height: compact ? 16 : 24),
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    final compact = _compactPhoneLayout(context);
    return ListView(
      key: const ValueKey('analysis-result'),
      controller: _resultScrollController,
      primary: false,
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            _AnalysisBackButton(onPressed: widget.onBack),
            const Spacer(),
            Text(
              'Cek Awal - Hasil',
              style: TextStyle(
                color: _analysisInk,
                fontSize: compact ? 20 : 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            SizedBox(width: compact ? 52 : 60),
          ],
        ),
        SizedBox(height: compact ? 20 : 26),
        const _AnalysisProgress(resultReady: true),
        SizedBox(height: compact ? 18 : 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 5,
              child: Image.asset(
                'assets/mascot/splash.png',
                height: compact ? 160 : 220,
                fit: BoxFit.contain,
                semanticLabel: 'Maskot Bale memberi rekomendasi belajar',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: _ResultSpeechBubble(compact: compact),
            ),
          ],
        ),
        SizedBox(height: compact ? 16 : 22),
        _ResultSummaryCard(compact: compact),
        SizedBox(height: compact ? 14 : 18),
        _FirstMissionCard(compact: compact),
        SizedBox(height: compact ? 16 : 20),
        _ResultPrimaryButton(
          compact: compact,
          onPressed: widget.onContinue,
        ),
        TextButton(
          onPressed: () => _showResultDetails(context),
          child: Text(
            'Lihat detail hasil',
            style: TextStyle(
              color: _analysisInk,
              fontSize: compact ? 16 : 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(height: compact ? 10 : 18),
      ],
    );
  }

  void _showResultDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Detail hasil',
              style: TextStyle(
                color: _analysisInk,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Kamu cocok mulai dari Foundation 3. Misi awal akan fokus pada pola, gambar, dan urutan sebelum naik ke tantangan berikutnya.',
              style: TextStyle(
                color: Color(0xFF747985),
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisBackButton extends StatelessWidget {
  const _AnalysisBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final compact = _compactPhoneLayout(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox.square(
          dimension: compact ? 52 : 60,
          child: const Icon(
            Icons.arrow_back_rounded,
            color: _analysisInk,
            size: 32,
          ),
        ),
      ),
    );
  }
}

class _AnalysisProgress extends StatelessWidget {
  const _AnalysisProgress({this.resultReady = false});

  final bool resultReady;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _AnalysisProgressNode(
            label: 'Jawaban\nDiterima',
            icon: Icons.check_rounded,
            active: true,
            completed: true,
          ),
        ),
        Expanded(child: Container(height: 4, color: _analysisPrimary)),
        const Expanded(
          child: _AnalysisProgressNode(
            label: 'Menganalisis',
            number: '2',
            active: true,
          ),
        ),
        Expanded(
          child: Container(
            height: 4,
            color: resultReady ? _analysisPrimary : const Color(0xFFE4E0D8),
          ),
        ),
        Expanded(
          child: _AnalysisProgressNode(
            label:
                resultReady ? 'Rekomendasi\nSiap' : 'Menyiapkan\nRekomendasi',
            number: '3',
            active: resultReady,
          ),
        ),
      ],
    );
  }
}

class _AnalysisProgressNode extends StatelessWidget {
  const _AnalysisProgressNode({
    required this.label,
    this.icon,
    this.number,
    this.active = false,
    this.completed = false,
  });

  final String label;
  final IconData? icon;
  final String? number;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final fill = active ? _analysisPrimary : const Color(0xFFE9E6DF);
    final foreground = active ? Colors.white : const Color(0xFF8B8179);
    return Column(
      children: [
        Container(
          width: active ? 54 : 46,
          height: active ? 54 : 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22F4B400),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: completed
              ? Icon(icon, color: foreground, size: 26)
              : Text(
                  number ?? '',
                  style: TextStyle(
                    color: foreground,
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
            color: _analysisInk,
            fontSize: 12,
            height: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ResultSpeechBubble extends StatelessWidget {
  const _ResultSpeechBubble({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 24,
        compact ? 16 : 22,
        compact ? 18 : 24,
        compact ? 16 : 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 26 : 32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x13000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        'Hai, aku Bale!\nAku sudah menemukan titik awal belajar yang cocok buatmu.',
        style: TextStyle(
          color: _analysisInk,
          fontSize: compact ? 15 : 19,
          height: 1.32,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ResultSummaryCard extends StatelessWidget {
  const _ResultSummaryCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: _analysisInk,
              fontSize: compact ? 25 : 32,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 14 : 18),
          Container(
            padding: EdgeInsets.all(compact ? 14 : 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEE),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFE1A0)),
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 64 : 82,
                  height: compact ? 64 : 82,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: _analysisPrimary,
                    size: 48,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level rekomendasi',
                        style: TextStyle(
                          color: _analysisInk,
                          fontSize: compact ? 16 : 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Foundation 3',
                        style: TextStyle(
                          color: const Color(0xFFEFA500),
                          fontSize: compact ? 30 : 40,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Cocok untuk tantangan dasar hingga menengah.',
                        style: TextStyle(
                          color: const Color(0xFF747985),
                          fontSize: compact ? 13 : 15,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 16 : 20),
          _ResultSection(
            compact: compact,
            icon: Icons.verified_user_rounded,
            iconColor: const Color(0xFF4CAF50),
            title: 'Kekuatanmu',
            chipColor: const Color(0xFFEFF8EA),
            chipBorder: const Color(0xFFCFE8C6),
            chipIconColor: const Color(0xFF5BAF3E),
            chips: const [
              'Mengenali pola',
              'Memahami gambar',
              'Menyusun urutan'
            ],
          ),
          const Divider(height: 24),
          _ResultSection(
            compact: compact,
            icon: Icons.track_changes_rounded,
            iconColor: _analysisPrimary,
            title: 'Fokus berikutnya',
            chipColor: const Color(0xFFFFF8E5),
            chipBorder: const Color(0xFFFFD88B),
            chipIconColor: _analysisPrimary,
            chips: const [
              'Menjelaskan alasan',
              'Memeriksa informasi',
              'Langkah bertahap',
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.compact,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.chipColor,
    required this.chipBorder,
    required this.chipIconColor,
    required this.chips,
  });

  final bool compact;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color chipColor;
  final Color chipBorder;
  final Color chipIconColor;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: compact ? 24 : 30),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: _analysisInk,
                fontSize: compact ? 19 : 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 10 : 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chip in chips)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 13,
                  vertical: compact ? 7 : 9,
                ),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: chipBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: chipIconColor,
                      size: compact ? 16 : 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chip,
                      style: TextStyle(
                        color: _analysisInk,
                        fontSize: compact ? 12 : 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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
      padding: EdgeInsets.all(compact ? 14 : 18),
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
          Container(
            width: compact ? 76 : 96,
            height: compact ? 64 : 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFE3A4)),
            ),
            child: Icon(
              Icons.event_note_rounded,
              color: _analysisPrimary,
              size: compact ? 38 : 48,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Misi pertamamu',
                  style: TextStyle(
                    color: const Color(0xFF747985),
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Misteri Jadwal yang Berubah',
                  style: TextStyle(
                    color: _analysisInk,
                    fontSize: compact ? 18 : 22,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 6 : 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: const [
                    _MissionMeta(
                        icon: Icons.schedule_rounded, label: '8 menit'),
                    _MissionMeta(
                      icon: Icons.list_alt_rounded,
                      label: '5 aktivitas',
                    ),
                    _MissionMeta(icon: Icons.star_rounded, label: '+30 XP'),
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

class _MissionMeta extends StatelessWidget {
  const _MissionMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF8B8179), size: 17),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: _analysisInk,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ResultPrimaryButton extends StatelessWidget {
  const _ResultPrimaryButton({
    required this.compact,
    required this.onPressed,
  });

  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 58 : 68,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _analysisPrimary,
          foregroundColor: _analysisInk,
          elevation: 7,
          shadowColor: const Color(0x55F4B400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 18 : 22),
          ),
          textStyle: TextStyle(
            fontSize: compact ? 20 : 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        child: const Text('Mulai Misi Pertama'),
      ),
    );
  }
}

class _AnalysisChecklist extends StatelessWidget {
  const _AnalysisChecklist();

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
          _AnalysisChecklistItem(
            icon: Icons.assignment_turned_in_rounded,
            title: 'Memeriksa jawabanmu',
            subtitle: 'Semua jawaban sudah diterima dengan aman.',
            active: true,
          ),
          Divider(height: 22),
          _AnalysisChecklistItem(
            icon: Icons.psychology_rounded,
            title: 'Menganalisis kemampuan',
            subtitle: 'Bale sedang memetakan kekuatan dan fokus belajarmu.',
            active: true,
          ),
          Divider(height: 22),
          _AnalysisChecklistItem(
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

class _AnalysisChecklistItem extends StatelessWidget {
  const _AnalysisChecklistItem({
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
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFFF3C6) : const Color(0xFFEDEBE8),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: active ? _analysisPrimary : const Color(0xFF8B8179),
            size: 28,
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
                  color: locked ? const Color(0xFF8B8179) : _analysisInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF747985),
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 34,
          height: 34,
          child: locked
              ? const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF8B8179),
                  size: 28,
                )
              : const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: _analysisPrimary,
                ),
        ),
      ],
    );
  }
}

class _AnalysisTipCard extends StatelessWidget {
  const _AnalysisTipCard();

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
          Icon(
            Icons.lightbulb_outline_rounded,
            color: _analysisPrimary,
            size: 34,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Bale',
                  style: TextStyle(
                    color: Color(0xFFB87900),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Hasil ini akan membantumu mulai belajar dengan lebih tepat.',
                  style: TextStyle(
                    color: _analysisInk,
                    fontSize: 13,
                    height: 1.3,
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

class _AnalysisSecurityNote extends StatelessWidget {
  const _AnalysisSecurityNote();

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
              color: Color(0xFF747985),
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
