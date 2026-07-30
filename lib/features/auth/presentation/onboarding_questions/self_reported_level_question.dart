import 'package:flutter/material.dart';

import 'onboarding_question_models.dart';

enum SelfReportedLevel {
  beginner('BEGINNER'),
  basic('BASIC'),
  foundationReady('FOUNDATION_READY'),
  intermediate('INTERMEDIATE'),
  advanced('ADVANCED'),
  unsure('UNSURE');

  const SelfReportedLevel(this.payload);

  final String payload;
}

const selfReportedLevelQuestion = OnboardingQuestion<SelfReportedLevel>(
  id: 'self_reported_level',
  title: 'Seberapa nyaman kamu dengan bidang ini?',
  goal: 'Mendapatkan estimasi level sebelum placement test.',
  kind: OnboardingQuestionKind.singleChoice,
  helperText:
      'Jawaban ini hanya digunakan untuk memilih tes awal, bukan menentukan mastery.',
  options: [
    OnboardingOption(
      value: SelfReportedLevel.beginner,
      label: 'Baru mulai.',
      icon: Icons.spa_rounded,
    ),
    OnboardingOption(
      value: SelfReportedLevel.basic,
      label: 'Tahu sedikit.',
      icon: Icons.lightbulb_outline_rounded,
    ),
    OnboardingOption(
      value: SelfReportedLevel.foundationReady,
      label: 'Cukup memahami dasar.',
      icon: Icons.foundation_rounded,
    ),
    OnboardingOption(
      value: SelfReportedLevel.intermediate,
      label: 'Sering mengerjakan soal menengah.',
      icon: Icons.task_alt_rounded,
    ),
    OnboardingOption(
      value: SelfReportedLevel.advanced,
      label: 'Siap tantangan.',
      icon: Icons.local_fire_department_rounded,
    ),
    OnboardingOption(
      value: SelfReportedLevel.unsure,
      label: 'Saya tidak yakin.',
      icon: Icons.help_outline_rounded,
    ),
  ],
);
