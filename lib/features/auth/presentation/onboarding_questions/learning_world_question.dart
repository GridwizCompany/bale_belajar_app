import 'package:flutter/material.dart';

import 'onboarding_question_models.dart';

enum LearningWorld {
  numeria('NUMERIA'),
  kodex('KODEX'),
  detectivia('DETECTIVIA'),
  bahasa('BAHASA'),
  sains('SAINS'),
  tryAll('TRY_ALL');

  const LearningWorld(this.payload);

  final String payload;
}

const learningWorldQuestion = OnboardingQuestion<LearningWorld>(
  id: 'learning_world',
  title: 'Dunia mana yang paling menarik untukmu?',
  goal: 'Menentukan dunia pertama.',
  kind: OnboardingQuestionKind.singleChoice,
  helperText: 'Jika memilih semua, tetap minta satu dunia untuk misi pertama.',
  afterSelectionMessage:
      'Kita mulai dari satu dunia dulu. Kamu bisa membuka yang lain kapan saja.',
  options: [
    OnboardingOption(
      value: LearningWorld.numeria,
      label: 'Numeria',
      description: 'Matematika terasa seperti petualangan angka.',
      illustration: 'assets/onboarding/worlds/numeria.png',
      character: 'Numa si penjaga angka',
      exampleMission: 'Bantu Numa menemukan pola angka yang hilang.',
      icon: Icons.functions_rounded,
    ),
    OnboardingOption(
      value: LearningWorld.kodex,
      label: 'KodeX',
      description: 'Belajar informatika lewat logika, kode, dan eksperimen.',
      illustration: 'assets/onboarding/worlds/kodex.png',
      character: 'Kiko si perakit kode',
      exampleMission: 'Susun instruksi agar robot sampai ke tujuan.',
      icon: Icons.code_rounded,
    ),
    OnboardingOption(
      value: LearningWorld.detectivia,
      label: 'Detectivia',
      description:
          'Amati petunjuk, susun kronologi, dan pecahkan kasus secara logis.',
      illustration: 'assets/onboarding/worlds/detectivia.png',
      character: 'Deta si detektif muda',
      exampleMission: 'Cari bukti yang tidak cocok dalam laporan saksi.',
      icon: Icons.travel_explore_rounded,
    ),
    OnboardingOption(
      value: LearningWorld.bahasa,
      label: 'Dunia Bahasa',
      description: 'Latih membaca, menulis, dan memahami makna dengan cerita.',
      illustration: 'assets/onboarding/worlds/bahasa.png',
      character: 'Bara si penjaga kata',
      exampleMission: 'Pilih kalimat terbaik untuk melanjutkan cerita.',
      icon: Icons.translate_rounded,
    ),
    OnboardingOption(
      value: LearningWorld.sains,
      label: 'Dunia Sains',
      description: 'Jelajahi fenomena alam lewat observasi dan percobaan.',
      illustration: 'assets/onboarding/worlds/sains.png',
      character: 'Sani si penjelajah lab',
      exampleMission: 'Tentukan penyebab es lebih cepat mencair.',
      icon: Icons.science_rounded,
    ),
    OnboardingOption(
      value: LearningWorld.tryAll,
      label: 'Saya ingin mencoba semuanya.',
      description: 'Coba semua dunia, mulai dari satu misi pertama.',
      illustration: 'assets/onboarding/worlds/all.png',
      character: 'Bale si pemandu belajar',
      exampleMission: 'Pilih dunia pertama, lalu buka dunia lain kapan saja.',
      icon: Icons.grid_view_rounded,
    ),
  ],
);
