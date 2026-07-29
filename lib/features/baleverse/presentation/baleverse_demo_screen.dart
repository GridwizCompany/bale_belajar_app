import 'package:flutter/material.dart';

import '../../../shared/widgets/bale_card.dart';
import '../../../theme/bale_theme.dart';
import '../data/baleverse_dummy_data.dart';
import '../domain/baleverse_models.dart';
import '../state/mission_state_machine.dart' as machine;

class BaleVerseDemoScreen extends StatefulWidget {
  const BaleVerseDemoScreen({super.key});

  @override
  State<BaleVerseDemoScreen> createState() => _BaleVerseDemoScreenState();
}

class _BaleVerseDemoScreenState extends State<BaleVerseDemoScreen> {
  machine.BaleVerseState _state = const machine.BaleVerseState();
  String? _selectedOptionId;
  String? _feedback;
  final Set<String> _mentorShare = {
    ...humanHelpRecommendation.shareableContext,
  };
  bool _parentSupportSent = false;

  BaleWorld get _selectedWorld {
    return baleWorlds.firstWhere((world) => world.key == _state.selectedWorld);
  }

  void _setState(machine.BaleVerseState next) {
    setState(() => _state = next);
  }

  void _checkAnswer() {
    final option = numeriaMission.options.firstWhere(
      (item) => item.id == _selectedOptionId,
    );
    setState(() {
      _feedback = option.feedback;
      _state = option.isCorrect
          ? machine.answerCorrect(_state)
          : machine.answerWrong(_state);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: _buildCurrentStep(context),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    return switch (_state.step) {
      MissionStep.login => _LoginView(
          onLogin: () => _setState(machine.login(_state)),
        ),
      MissionStep.dashboard => _DashboardView(
          selectedWorld: _selectedWorld,
          onSelectWorld: (world) {
            _setState(machine.selectWorld(_state, world));
          },
          onStartMission: () => _setState(machine.startMission(_state)),
        ),
      MissionStep.missionIntro => _MissionIntroView(
          onStart: () => _setState(machine.beginQuestion(_state)),
        ),
      MissionStep.reward => _RewardView(
          onBackToDashboard: () {
            setState(() {
              _feedback = null;
              _selectedOptionId = null;
              _state = _state.copyWith(
                step: MissionStep.dashboard,
                wrongAttempts: 0,
              );
            });
          },
        ),
      MissionStep.waitingMentor => _WaitingMentorView(
          parentSupportSent: _parentSupportSent,
          onParentSupport: () => setState(() => _parentSupportSent = true),
          onMentorReply: () => _setState(machine.receiveMentorFeedback(_state)),
        ),
      MissionStep.mentorResponded => _MentorRespondedView(
          onTryAgain: () {
            setState(() {
              _selectedOptionId = null;
              _feedback = null;
              _state = _state.copyWith(
                step: MissionStep.question,
                wrongAttempts: 1,
              );
            });
          },
        ),
      _ => _QuestionView(
          step: _state.step,
          wrongAttempts: _state.wrongAttempts,
          selectedOptionId: _selectedOptionId,
          feedback: _feedback,
          mentorShare: _mentorShare,
          onSelectOption: (id) => setState(() => _selectedOptionId = id),
          onCheck: _selectedOptionId == null ? null : _checkAnswer,
          onToggleShare: (item) {
            setState(() {
              if (_mentorShare.contains(item)) {
                _mentorShare.remove(item);
              } else {
                _mentorShare.add(item);
              }
            });
          },
          onRequestMentor: () => _setState(machine.requestMentor(_state)),
        ),
    };
  }
}

class _PageShell extends StatelessWidget {
  const _PageShell({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: ValueKey(children.length),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        const _AppHeader(),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

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
                'BaleVerse mobile slice',
                style:
                    TextStyle(fontWeight: FontWeight.w700, color: Colors.grey),
              ),
            ],
          ),
        ),
        const _MetricPill(icon: Icons.local_fire_department, label: '2/3'),
      ],
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      children: [
        BaleCard(
          color: BaleColors.ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SmallCaps('Demo siswa'),
              const SizedBox(height: 12),
              Text(
                'Masuk ke BaleVerse',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                'Coba alur belajar berbasis misi dengan dummy data. Tidak ada backend atau AI API yang dipakai.',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onLogin,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Masuk sebagai Nara'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.selectedWorld,
    required this.onSelectWorld,
    required this.onStartMission,
  });

  final BaleWorld selectedWorld;
  final ValueChanged<BaleWorldKey> onSelectWorld;
  final VoidCallback onStartMission;

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      children: [
        BaleCard(
          color: BaleColors.ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SmallCaps('Misi aktif'),
              const SizedBox(height: 8),
              Text(
                'Hai ${baleUser.name}, lanjutkan satu langkah.',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                numeriaMission.goal,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onStartMission,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Lanjutkan Misi'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _BaleHeroCard(stateLabel: 'Siap belajar'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'XP Matematika',
                value: '${baleUser.xp[BaleWorldKey.numeria]}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Mastery',
                value: '${baleUser.mastery[BaleWorldKey.numeria]}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _WorldSelector(
          selectedWorld: selectedWorld,
          onSelectWorld: onSelectWorld,
        ),
      ],
    );
  }
}

class _MissionIntroView extends StatelessWidget {
  const _MissionIntroView({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      children: [
        const _BaleHeroCard(stateLabel: 'Ayo mulai pelan-pelan'),
        const SizedBox(height: 14),
        BaleCard(
          color: BaleColors.ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SmallCaps('Cerita pembuka'),
              const SizedBox(height: 8),
              Text(
                numeriaMission.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                numeriaMission.story,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onStart,
                child: const Text('Mulai Misi'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.step,
    required this.wrongAttempts,
    required this.selectedOptionId,
    required this.feedback,
    required this.mentorShare,
    required this.onSelectOption,
    required this.onCheck,
    required this.onToggleShare,
    required this.onRequestMentor,
  });

  final MissionStep step;
  final int wrongAttempts;
  final String? selectedOptionId;
  final String? feedback;
  final Set<String> mentorShare;
  final ValueChanged<String> onSelectOption;
  final VoidCallback? onCheck;
  final ValueChanged<String> onToggleShare;
  final VoidCallback onRequestMentor;

  @override
  Widget build(BuildContext context) {
    final showHelp = step == MissionStep.hintOne ||
        step == MissionStep.hintTwo ||
        step == MissionStep.humanHelp;

    return _PageShell(
      children: [
        _MissionTopBar(progress: (wrongAttempts + 1) / 4),
        const SizedBox(height: 14),
        BaleCard(
          color: BaleColors.ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SmallCaps('Satu soal'),
              const SizedBox(height: 8),
              Text(
                numeriaMission.prompt,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final option in numeriaMission.options) ...[
          _OptionButton(
            option: option,
            selected: selectedOptionId == option.id,
            onTap: () => onSelectOption(option.id),
          ),
          const SizedBox(height: 10),
        ],
        if (feedback != null) ...[
          _FeedbackBox(message: feedback!),
          const SizedBox(height: 14),
        ],
        FilledButton(
          onPressed: onCheck,
          child: const Text('Cek Jawaban'),
        ),
        if (showHelp) ...[
          const SizedBox(height: 14),
          _TanyaBalePanel(step: step),
        ],
        if (step == MissionStep.humanHelp) ...[
          const SizedBox(height: 14),
          _HumanHelpCard(
            selectedItems: mentorShare,
            onToggle: onToggleShare,
            onApprove: onRequestMentor,
          ),
        ],
      ],
    );
  }
}

class _RewardView extends StatelessWidget {
  const _RewardView({required this.onBackToDashboard});

  final VoidCallback onBackToDashboard;

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      children: [
        const _BaleHeroCard(stateLabel: 'Misi selesai'),
        const SizedBox(height: 14),
        BaleCard(
          color: BaleColors.ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SmallCaps('Reward'),
              const SizedBox(height: 8),
              Text(
                'Gerbang Distribusi terbuka.',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'XP bertambah karena aktivitas selesai. Mastery bertambah karena jawabanmu membuktikan pemahaman.',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: _RewardPill(label: '+90 XP')),
                  SizedBox(width: 10),
                  Expanded(child: _RewardPill(label: '+18 Daya')),
                ],
              ),
              const SizedBox(height: 12),
              const _RewardPill(label: 'Mastery Matematika 64%'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onBackToDashboard,
                child: const Text('Kembali ke Dashboard'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WaitingMentorView extends StatelessWidget {
  const _WaitingMentorView({
    required this.parentSupportSent,
    required this.onParentSupport,
    required this.onMentorReply,
  });

  final bool parentSupportSent;
  final VoidCallback onParentSupport;
  final VoidCallback onMentorReply;

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      children: [
        const _BaleHeroCard(stateLabel: 'Menunggu mentor'),
        const SizedBox(height: 14),
        BaleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Permintaan masuk antrean mentor',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Kak Arya akan melihat nama misi, topik, jawaban terkait, hint yang dipakai, dan pola kesalahan.',
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onMentorReply,
                child: const Text('Simulasikan mentor membalas'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        BaleCard(
          color: const Color(0xFFF0FDF4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                parentSupportSent
                    ? 'Ibu Rina mengirim dukungan.'
                    : 'Minta dukungan orang tua',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                parentSupportSent
                    ? 'Istirahat sebentar boleh, lalu coba contoh ringan selama 5 menit.'
                    : 'Data yang dibagikan: target minggu ini, nama misi, dan durasi belajar yang disarankan.',
              ),
              if (!parentSupportSent) ...[
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: onParentSupport,
                  child: const Text('Minta dukungan orang tua'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MentorRespondedView extends StatelessWidget {
  const _MentorRespondedView({required this.onTryAgain});

  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      children: [
        const _BaleHeroCard(stateLabel: 'Mentor membalas'),
        const SizedBox(height: 14),
        BaleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${mentorFeedback.mentorName} memberi feedback',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(mentorFeedback.message),
              const SizedBox(height: 12),
              Text(
                mentorFeedback.masteryReview,
                style: const TextStyle(
                  color: BaleColors.warning,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onTryAgain,
                child: const Text('Terapkan feedback di misi'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorldSelector extends StatelessWidget {
  const _WorldSelector({
    required this.selectedWorld,
    required this.onSelectWorld,
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

class _BaleHeroCard extends StatelessWidget {
  const _BaleHeroCard({required this.stateLabel});

  final String stateLabel;

  @override
  Widget build(BuildContext context) {
    return BaleCard(
      child: Row(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.psychology_alt_rounded,
                size: 44, color: BaleColors.info),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SmallCaps('BaleHero'),
                Text(stateLabel, style: Theme.of(context).textTheme.titleLarge),
                const Text('Kita fokus ke satu langkah kecil dulu.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionTopBar extends StatelessWidget {
  const _MissionTopBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.close_rounded),
        const SizedBox(width: 10),
        Expanded(child: BaleProgressBar(value: progress)),
        const SizedBox(width: 10),
        const _MetricPill(icon: Icons.bolt_rounded, label: 'Power'),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final MissionOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border.all(
            color: selected ? BaleColors.info : BaleColors.line,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: selected ? BaleColors.info : BaleColors.soft,
              child: Text(
                option.label,
                style: TextStyle(
                  color: selected ? Colors.white : BaleColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.text,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TanyaBalePanel extends StatelessWidget {
  const _TanyaBalePanel({required this.step});

  final MissionStep step;

  @override
  Widget build(BuildContext context) {
    final confidence = step == MissionStep.humanHelp
        ? AiConfidence.low
        : step == MissionStep.hintTwo
            ? AiConfidence.medium
            : AiConfidence.high;
    final hintIndex = step == MissionStep.hintTwo
        ? 1
        : step == MissionStep.humanHelp
            ? 2
            : 0;

    return BaleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tanya Bale', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(numeriaMission.hints[hintIndex]),
          const SizedBox(height: 10),
          Text(
            switch (confidence) {
              AiConfidence.high => 'Aku menemukan pola kesalahannya.',
              AiConfidence.medium =>
                'Ada dua kemungkinan. Kita cek satu hal lagi.',
              AiConfidence.low =>
                'Aku belum cukup yakin untuk menilai ini dengan adil.',
            },
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _HumanHelpCard extends StatelessWidget {
  const _HumanHelpCard({
    required this.selectedItems,
    required this.onToggle,
    required this.onApprove,
  });

  final Set<String> selectedItems;
  final ValueChanged<String> onToggle;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return BaleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bantuan Manusia',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '${humanHelpRecommendation.problem} ${humanHelpRecommendation.reason}',
          ),
          const SizedBox(height: 12),
          const Text(
            'Data yang akan dibagikan',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          for (final item in humanHelpRecommendation.shareableContext)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item),
              value: selectedItems.contains(item),
              onChanged: (_) => onToggle(item),
            ),
          const Text(
            'Chat AI lengkap, data keluarga, dan dunia lain tidak dibagikan.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onApprove,
            child: const Text('Minta Mentor Membantu'),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBox extends StatelessWidget {
  const _FeedbackBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF9F1239),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

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

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label});

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

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.label});

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

class _SmallCaps extends StatelessWidget {
  const _SmallCaps(this.text);

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
