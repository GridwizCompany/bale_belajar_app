import 'package:flutter/material.dart';

import 'onboarding_question_models.dart';

enum LearningGoal {
  understandSubject('UNDERSTAND_SUBJECT'),
  examPreparation('EXAM_PREPARATION'),
  improveGrade('IMPROVE_GRADE'),
  learnNewSkill('LEARN_NEW_SKILL'),
  buildThinkingSkill('BUILD_THINKING_SKILL'),
  exploreCareer('EXPLORE_CAREER'),
  needRecommendation('NEED_RECOMMENDATION');

  const LearningGoal(this.payload);

  final String payload;
}

const learningGoalQuestion = OnboardingQuestion<LearningGoal>(
  id: 'learning_goal',
  title: 'Apa yang ingin kamu capai?',
  goal: 'Mengetahui motivasi utama siswa.',
  kind: OnboardingQuestionKind.singleChoice,
  helperText:
      'Kalau memilih persiapan ujian, tanggal ujian ditanyakan setelah onboarding.',
  options: [
    OnboardingOption(
      value: LearningGoal.understandSubject,
      label: 'Lebih paham pelajaran.',
      icon: Icons.menu_book_rounded,
    ),
    OnboardingOption(
      value: LearningGoal.examPreparation,
      label: 'Persiapan ujian.',
      icon: Icons.event_available_rounded,
      note: 'Tanyakan tanggal ujian setelah onboarding.',
    ),
    OnboardingOption(
      value: LearningGoal.improveGrade,
      label: 'Mengejar nilai yang lebih baik.',
      icon: Icons.trending_up_rounded,
    ),
    OnboardingOption(
      value: LearningGoal.learnNewSkill,
      label: 'Belajar skill baru.',
      icon: Icons.auto_awesome_rounded,
    ),
    OnboardingOption(
      value: LearningGoal.buildThinkingSkill,
      label: 'Melatih logika dan kreativitas.',
      icon: Icons.psychology_rounded,
    ),
    OnboardingOption(
      value: LearningGoal.exploreCareer,
      label: 'Menjelajahi cita-cita.',
      icon: Icons.explore_rounded,
    ),
    OnboardingOption(
      value: LearningGoal.needRecommendation,
      label: 'Belum tahu, bantu saya memilih.',
      icon: Icons.help_rounded,
    ),
  ],
);
