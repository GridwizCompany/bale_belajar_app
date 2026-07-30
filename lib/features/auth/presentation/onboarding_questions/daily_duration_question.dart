import 'package:flutter/material.dart';

import 'onboarding_question_models.dart';

enum DailyDuration {
  five(5),
  ten(10),
  fifteen(15),
  twenty(20),
  thirty(30),
  adaptive(null);

  const DailyDuration(this.minutes);

  final int? minutes;

  Object get payload => minutes ?? 'ADAPTIVE';
}

const dailyDurationQuestion = OnboardingQuestion<DailyDuration>(
  id: 'daily_duration',
  title: 'Berapa lama kamu ingin belajar setiap hari?',
  goal: 'Membuat target realistis.',
  kind: OnboardingQuestionKind.singleChoice,
  helperText: 'Saran default: 10-15 menit. Target awal dibuat mudah dicapai.',
  afterSelectionMessage:
      'Kami akan membuat misi sekitar 10 menit. Kamu bisa berhenti kapan saja dan progres tetap tersimpan.',
  options: [
    OnboardingOption(
      value: DailyDuration.five,
      label: '5 menit - santai.',
      icon: Icons.timer_rounded,
    ),
    OnboardingOption(
      value: DailyDuration.ten,
      label: '10 menit - ringan.',
      icon: Icons.timer_rounded,
    ),
    OnboardingOption(
      value: DailyDuration.fifteen,
      label: '15 menit - ideal.',
      icon: Icons.timer_rounded,
    ),
    OnboardingOption(
      value: DailyDuration.twenty,
      label: '20 menit - fokus.',
      icon: Icons.timer_rounded,
    ),
    OnboardingOption(
      value: DailyDuration.thirty,
      label: '30 menit - serius.',
      icon: Icons.timer_rounded,
    ),
    OnboardingOption(
      value: DailyDuration.adaptive,
      label: 'Sesuaikan otomatis.',
      icon: Icons.auto_mode_rounded,
    ),
  ],
);
