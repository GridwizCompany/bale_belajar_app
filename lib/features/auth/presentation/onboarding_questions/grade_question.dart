import 'package:flutter/material.dart';

import 'onboarding_question_models.dart';

enum GradeChoice {
  junior7('JUNIOR_7', 7),
  junior8('JUNIOR_8', 8),
  junior9('JUNIOR_9', 9),
  senior10('SENIOR_10', 10),
  senior11('SENIOR_11', 11),
  senior12('SENIOR_12', 12),
  graduated('GRADUATED', null),
  customLevel('CUSTOM_LEVEL', null);

  const GradeChoice(this.payload, this.gradeLevel);

  final String payload;
  final int? gradeLevel;
}

const gradeQuestion = OnboardingQuestion<GradeChoice>(
  id: 'grade',
  title: 'Sekarang kamu kelas berapa?',
  goal: 'Menyesuaikan bahasa, materi, dan tingkat kesulitan.',
  kind: OnboardingQuestionKind.singleChoice,
  helperText:
      'Ini hanya membantu kami memilih materi awal. Levelmu akan disesuaikan setelah Cek Awal.',
  options: [
    OnboardingOption(
      value: GradeChoice.junior7,
      label: 'SMP kelas 7.',
      icon: Icons.school_rounded,
    ),
    OnboardingOption(
      value: GradeChoice.junior8,
      label: 'SMP kelas 8.',
      icon: Icons.school_rounded,
    ),
    OnboardingOption(
      value: GradeChoice.junior9,
      label: 'SMP kelas 9.',
      icon: Icons.school_rounded,
    ),
    OnboardingOption(
      value: GradeChoice.senior10,
      label: 'SMA/SMK kelas 10.',
      icon: Icons.workspace_premium_rounded,
    ),
    OnboardingOption(
      value: GradeChoice.senior11,
      label: 'SMA/SMK kelas 11.',
      icon: Icons.workspace_premium_rounded,
    ),
    OnboardingOption(
      value: GradeChoice.senior12,
      label: 'SMA/SMK kelas 12.',
      icon: Icons.workspace_premium_rounded,
    ),
    OnboardingOption(
      value: GradeChoice.graduated,
      label: 'Sudah lulus.',
      icon: Icons.verified_rounded,
    ),
    OnboardingOption(
      value: GradeChoice.customLevel,
      label: 'Saya ingin memilih level sendiri.',
      icon: Icons.tune_rounded,
    ),
  ],
);
