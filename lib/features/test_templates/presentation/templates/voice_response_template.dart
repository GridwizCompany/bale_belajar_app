import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/test_template_models.dart';
import 'test_template_ui_helpers.dart';

const _voiceYellow = Color(0xFFF4B400);
const _voiceInk = Color(0xFF3B2318);
const _voiceGreen = Color(0xFF2F9B42);
const _voiceBlue = Color(0xFF1976D2);

class VoiceResponseTemplate extends StatefulWidget {
  const VoiceResponseTemplate({
    required this.question,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onSubmitAnswer,
    this.currentQuestion = 12,
    this.totalQuestions = 20,
    this.onBack,
    this.onHint,
    this.onSkip,
    super.key,
  });

  final TemplateQuestion question;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final ValueChanged<String> onSubmitAnswer;
  final int currentQuestion;
  final int totalQuestions;
  final VoidCallback? onBack;
  final VoidCallback? onHint;
  final VoidCallback? onSkip;

  @override
  State<VoiceResponseTemplate> createState() => _VoiceResponseTemplateState();
}

class _VoiceResponseTemplateState extends State<VoiceResponseTemplate> {
  static const int _maxSeconds = 60;

  Timer? _timer;
  bool _recording = false;
  int _elapsedSeconds = 0;
  bool _hasRecording = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.shortestSide < 600;
    final progress = widget.totalQuestions <= 0
        ? 0.0
        : (widget.currentQuestion / widget.totalQuestions).clamp(0.0, 1.0);

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
            _VoiceHeader(
              currentQuestion: widget.currentQuestion,
              totalQuestions: widget.totalQuestions,
              progress: progress,
              compact: compact,
              onBack: widget.onBack,
            ),
            SizedBox(height: compact ? 8 : 24),
            _VoiceMascotIntro(compact: compact),
            SizedBox(height: compact ? 8 : 24),
            _QuestionCard(
              question: widget.question,
              compact: compact,
              recording: _recording,
              hasRecording: _hasRecording,
              elapsedSeconds: _elapsedSeconds,
              maxSeconds: _maxSeconds,
              onPlayQuestion: () {},
              onToggleRecording: _toggleRecording,
              onSubmit: () => widget.onSubmitAnswer(
                'voice-response:${_elapsedSeconds}s',
              ),
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

  void _toggleRecording() {
    if (_recording) {
      _stopRecording();
      return;
    }
    setState(() {
      _recording = true;
      _hasRecording = false;
      _elapsedSeconds = 0;
    });
    widget.onStartRecording();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_elapsedSeconds >= _maxSeconds) {
        _stopRecording();
        return;
      }
      setState(() => _elapsedSeconds += 1);
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _recording = false;
      _hasRecording = _elapsedSeconds > 0;
    });
    widget.onStopRecording();
  }
}

class _VoiceHeader extends StatelessWidget {
  const _VoiceHeader({
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
                color: _voiceInk,
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
                  color: _voiceInk,
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
                            color: _voiceYellow,
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
                        color: _voiceInk,
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

class _VoiceMascotIntro extends StatelessWidget {
  const _VoiceMascotIntro({required this.compact});

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
                    style: TextStyle(color: _voiceGreen),
                  ),
                  const TextSpan(
                    text:
                        '!\nDengarkan pertanyaannya, lalu jawab dengan suaramu ya! Tekan tombol rekam dan sampaikan jawabanmu dengan jelas.',
                  ),
                ],
              ),
              style: TextStyle(
                color: _voiceInk,
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
    required this.compact,
    required this.recording,
    required this.hasRecording,
    required this.elapsedSeconds,
    required this.maxSeconds,
    required this.onPlayQuestion,
    required this.onToggleRecording,
    required this.onSubmit,
  });

  final TemplateQuestion question;
  final bool compact;
  final bool recording;
  final bool hasRecording;
  final int elapsedSeconds;
  final int maxSeconds;
  final VoidCallback onPlayQuestion;
  final VoidCallback onToggleRecording;
  final VoidCallback onSubmit;

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
          Row(
            children: [
              Expanded(
                child: _Badge(compact: compact),
              ),
              IconButton.filledTonal(
                onPressed: onPlayQuestion,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF7DD),
                  foregroundColor: _voiceYellow,
                ),
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 20),
          Text(
            question.prompt,
            style: TextStyle(
              color: _voiceInk,
              fontSize: compact ? 22 : 28,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            question.instruction ??
                'Setelah selesai berbicara, tekan tombol selesai.',
            style: TextStyle(
              color: const Color(0xFF8C8274),
              fontSize: compact ? 15 : 19,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 8 : 24),
          _PromptCard(compact: compact),
          SizedBox(height: compact ? 8 : 20),
          _RecorderPanel(
            compact: compact,
            recording: recording,
            hasRecording: hasRecording,
            elapsedSeconds: elapsedSeconds,
            maxSeconds: maxSeconds,
            onToggleRecording: onToggleRecording,
          ),
          SizedBox(height: compact ? 8 : 20),
          _TipsCard(compact: compact),
          SizedBox(height: compact ? 8 : 28),
          FilledButton(
            onPressed: hasRecording || elapsedSeconds > 0 ? onSubmit : null,
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(compact ? 54 : 72),
              backgroundColor: _voiceYellow,
              foregroundColor: _voiceInk,
              disabledBackgroundColor: const Color(0xFFE8E0D2),
              disabledForegroundColor: const Color(0xFF8C8274),
              elevation: 8,
              shadowColor: const Color(0x55F4B400),
              textStyle: TextStyle(
                fontSize: compact ? 19 : 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Selesai & Kirim Jawaban'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: _voiceYellow.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic_rounded,
              color: const Color(0xFFD89B00),
              size: compact ? 18 : 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Template 12 \u2022 Voice Response',
              style: TextStyle(
                color: const Color(0xFFD89B00),
                fontSize: compact ? 13 : 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEDDAE)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 92 : 126,
            height: compact ? 92 : 126,
            decoration: const BoxDecoration(
              color: Color(0xFFD9F4FF),
              shape: BoxShape.circle,
            ),
            child: CustomPaint(
              painter: _EarthPainter(),
            ),
          ),
          SizedBox(width: compact ? 8 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9A8),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Pertanyaan',
                    style: TextStyle(
                      color: Color(0xFFD89B00),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Apa yang dapat kita lakukan untuk menjaga kelestarian bumi?',
                  style: TextStyle(
                    color: _voiceInk,
                    fontSize: compact ? 18 : 23,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
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

class _RecorderPanel extends StatelessWidget {
  const _RecorderPanel({
    required this.compact,
    required this.recording,
    required this.hasRecording,
    required this.elapsedSeconds,
    required this.maxSeconds,
    required this.onToggleRecording,
  });

  final bool compact;
  final bool recording;
  final bool hasRecording;
  final int elapsedSeconds;
  final int maxSeconds;
  final VoidCallback onToggleRecording;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB7D8FF)),
      ),
      child: Column(
        children: [
          Text(
            recording
                ? 'Sedang merekam jawabanmu...'
                : hasRecording
                    ? 'Rekaman siap dikirim'
                    : 'Tekan tombol rekam untuk mulai menjawab',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _voiceBlue,
              fontSize: compact ? 14 : 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 8 : 22),
          Row(
            children: [
              const Expanded(child: _Waveform()),
              GestureDetector(
                onTap: onToggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: compact ? 74 : 92,
                  height: compact ? 74 : 92,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: recording ? const Color(0xFFFF6B6B) : _voiceBlue,
                      width: 4,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    recording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: recording ? const Color(0xFFFF6B6B) : _voiceBlue,
                    size: compact ? 38 : 48,
                  ),
                ),
              ),
              const Expanded(child: _Waveform()),
            ],
          ),
          SizedBox(height: compact ? 12 : 16),
          Text(
            '${_formatTime(elapsedSeconds)} / ${_formatTime(maxSeconds)}',
            style: TextStyle(
              color: _voiceInk,
              fontSize: compact ? 14 : 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Color(0xFF8C8274), size: 18),
              SizedBox(width: 8),
              Text(
                'Waktu menjawab maksimal 1 menit',
                style: TextStyle(
                  color: Color(0xFF8C8274),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: CustomPaint(painter: _WaveformPainter()),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAEC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            color: _voiceGreen,
            size: compact ? 34 : 42,
          ),
          SizedBox(width: compact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips',
                  style: TextStyle(
                    color: _voiceGreen,
                    fontSize: compact ? 20 : 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '• Jawab dengan jelas dan lantang.\n• Pastikan lingkunganmu tenang saat merekam.\n• Kamu bisa mendengarkan ulang sebelum mengirim.',
                  style: TextStyle(
                    color: _voiceInk,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 8 : 12),
          Icon(
            Icons.record_voice_over_rounded,
            color: const Color(0xFFFFA629),
            size: compact ? 46 : 62,
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
              color: _voiceGreen,
              size: compact ? 22 : 28,
            ),
            label: Text(
              'Butuh petunjuk?',
              style: TextStyle(
                color: _voiceGreen,
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

class _EarthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.38;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF75D6E8));
    final land = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.38, size.height * 0.42),
        width: radius * 0.9,
        height: radius * 0.55,
      ),
      land,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.62, size.height * 0.58),
        width: radius * 1.0,
        height: radius * 0.6,
      ),
      land,
    );
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.24),
      size.width * 0.08,
      Paint()..color = _voiceYellow,
    );
    final trunk = Paint()..color = const Color(0xFF8D5E34);
    final leaf = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.28, size.height * 0.55),
        width: 8,
        height: 28,
      ),
      trunk,
    );
    canvas.drawCircle(Offset(size.width * 0.24, size.height * 0.44), 16, leaf);
    canvas.drawCircle(Offset(size.width * 0.34, size.height * 0.43), 16, leaf);
    canvas.drawCircle(Offset(size.width * 0.29, size.height * 0.36), 18, leaf);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9DCAFF)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    const bars = 18;
    final gap = size.width / bars;
    for (var i = 0; i < bars; i++) {
      final wave = math.sin(i * 0.9).abs();
      final height = size.height * (0.25 + wave * 0.55);
      final x = gap * i + gap / 2;
      canvas.drawLine(
        Offset(x, (size.height - height) / 2),
        Offset(x, (size.height + height) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
