import 'package:flutter/material.dart';

import 'onboarding_question_models.dart';

enum StudyTime {
  beforeSchool('BEFORE_SCHOOL'),
  afternoon('NOON'),
  evening('EVENING'),
  night('NIGHT'),
  differentDaily('DIFFERENT_DAILY'),
  skipForNow('SKIP_FOR_NOW');

  const StudyTime(this.payload);

  final String payload;
}

enum ReminderChoice {
  enable('ENABLE'),
  later('LATER');

  const ReminderChoice(this.payload);

  final String payload;
}

const studyTimeQuestion = OnboardingQuestion<StudyTime>(
  id: 'study_time',
  title: 'Kapan waktu yang paling nyaman untuk belajar?',
  goal: 'Menentukan rekomendasi notifikasi dan widget.',
  kind: OnboardingQuestionKind.singleChoice,
  helperText:
      'Jangan langsung membuka permission sistem. Tampilkan manfaat pengingat dulu.',
  afterSelectionMessage:
      'Kami bisa mengingatkanmu saat Misi Hari Ini siap. Mau aktifkan pengingat?',
  options: [
    OnboardingOption(
      value: StudyTime.beforeSchool,
      label: 'Sebelum sekolah.',
      icon: Icons.wb_twilight_rounded,
    ),
    OnboardingOption(
      value: StudyTime.afternoon,
      label: 'Siang.',
      icon: Icons.wb_sunny_rounded,
    ),
    OnboardingOption(
      value: StudyTime.evening,
      label: 'Sore.',
      icon: Icons.light_mode_rounded,
    ),
    OnboardingOption(
      value: StudyTime.night,
      label: 'Malam.',
      icon: Icons.nightlight_round,
    ),
    OnboardingOption(
      value: StudyTime.differentDaily,
      label: 'Jadwal berbeda setiap hari.',
      icon: Icons.event_repeat_rounded,
    ),
    OnboardingOption(
      value: StudyTime.skipForNow,
      label: 'Jangan tentukan sekarang.',
      icon: Icons.schedule_rounded,
    ),
  ],
);

const reminderOptions = [
  OnboardingOption(
    value: ReminderChoice.enable,
    label: 'Aktifkan pengingat.',
    icon: Icons.notifications_active_rounded,
  ),
  OnboardingOption(
    value: ReminderChoice.later,
    label: 'Nanti saja.',
    icon: Icons.notifications_none_rounded,
  ),
];
