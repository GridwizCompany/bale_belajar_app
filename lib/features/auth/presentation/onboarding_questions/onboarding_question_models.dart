import 'package:flutter/material.dart';

enum OnboardingQuestionKind { singleChoice, multiChoice }

class OnboardingQuestion<T extends Object> {
  const OnboardingQuestion({
    required this.id,
    required this.title,
    required this.goal,
    required this.kind,
    required this.options,
    this.description,
    this.helperText,
    this.maxSelections,
    this.afterSelectionMessage,
  });

  final String id;
  final String title;
  final String goal;
  final OnboardingQuestionKind kind;
  final List<OnboardingOption<T>> options;
  final String? description;
  final String? helperText;
  final int? maxSelections;
  final String? afterSelectionMessage;
}

class OnboardingOption<T extends Object> {
  const OnboardingOption({
    required this.value,
    required this.label,
    this.description,
    this.illustration,
    this.character,
    this.exampleMission,
    this.icon,
    this.note,
  });

  final T value;
  final String label;
  final String? description;
  final String? illustration;
  final String? character;
  final String? exampleMission;
  final IconData? icon;
  final String? note;
}
