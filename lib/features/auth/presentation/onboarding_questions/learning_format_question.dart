import 'package:flutter/material.dart';

import 'onboarding_question_models.dart';

enum LearningFormat {
  visual('VISUAL'),
  practiceFirst('PRACTICE_FIRST'),
  audio('AUDIO'),
  story('STORY'),
  challenge('CHALLENGE'),
  teachBack('TEACH_BACK'),
  social('SOCIAL');

  const LearningFormat(this.payload);

  final String payload;
}

const learningFormatQuestion = OnboardingQuestion<LearningFormat>(
  id: 'learning_format',
  title: 'Kamu lebih suka belajar seperti apa?',
  goal: 'Menentukan format misi awal.',
  kind: OnboardingQuestionKind.multiChoice,
  maxSelections: 3,
  helperText:
      'Pilih maksimal tiga. Ini preferensi awal, bukan gaya belajar permanen.',
  options: [
    OnboardingOption(
      value: LearningFormat.visual,
      label: 'Melihat gambar dan contoh.',
      icon: Icons.image_rounded,
    ),
    OnboardingOption(
      value: LearningFormat.practiceFirst,
      label: 'Langsung mencoba.',
      icon: Icons.touch_app_rounded,
    ),
    OnboardingOption(
      value: LearningFormat.audio,
      label: 'Mendengar penjelasan.',
      icon: Icons.headphones_rounded,
    ),
    OnboardingOption(
      value: LearningFormat.story,
      label: 'Belajar lewat cerita.',
      icon: Icons.auto_stories_rounded,
    ),
    OnboardingOption(
      value: LearningFormat.challenge,
      label: 'Menyelesaikan tantangan.',
      icon: Icons.flag_rounded,
    ),
    OnboardingOption(
      value: LearningFormat.teachBack,
      label: 'Menjelaskan dengan kata-kata sendiri.',
      icon: Icons.record_voice_over_rounded,
    ),
    OnboardingOption(
      value: LearningFormat.social,
      label: 'Belajar bersama mentor atau teman.',
      icon: Icons.groups_rounded,
    ),
  ],
);
