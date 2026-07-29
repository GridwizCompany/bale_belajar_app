import 'package:flutter/material.dart';

enum BaleWorldKey { numeria, kodex, detectivia }

enum MissionStep {
  login,
  dashboard,
  missionIntro,
  question,
  hintOne,
  hintTwo,
  humanHelp,
  waitingMentor,
  mentorResponded,
  reward,
}

enum AiConfidence { high, medium, low }

enum MissionActivityType { multipleChoice, findMistake, teachBack }

class BaleUser {
  const BaleUser({
    required this.name,
    required this.rank,
    required this.level,
    required this.dayaBale,
    required this.weeklyTarget,
    required this.weeklyCompleted,
    required this.xp,
    required this.mastery,
  });

  final String name;
  final String rank;
  final int level;
  final int dayaBale;
  final int weeklyTarget;
  final int weeklyCompleted;
  final Map<BaleWorldKey, int> xp;
  final Map<BaleWorldKey, int> mastery;
}

class BaleWorld {
  const BaleWorld({
    required this.key,
    required this.name,
    required this.subject,
    required this.characterClass,
    required this.color,
    required this.mastery,
  });

  final BaleWorldKey key;
  final String name;
  final String subject;
  final String characterClass;
  final Color color;
  final int mastery;
}

class MissionOption {
  const MissionOption({
    required this.id,
    required this.label,
    required this.text,
    required this.isCorrect,
    required this.feedback,
  });

  final String id;
  final String label;
  final String text;
  final bool isCorrect;
  final String feedback;
}

class BaleMission {
  const BaleMission({
    required this.title,
    required this.story,
    required this.goal,
    required this.prompt,
    required this.estimatedMinutes,
    required this.rewardXp,
    required this.rewardDayaBale,
    required this.options,
    required this.hints,
  });

  final String title;
  final String story;
  final String goal;
  final String prompt;
  final int estimatedMinutes;
  final int rewardXp;
  final int rewardDayaBale;
  final List<MissionOption> options;
  final List<String> hints;
}

class FindMistakeActivity {
  const FindMistakeActivity({
    required this.prompt,
    required this.wrongStatement,
    required this.correctedStatement,
    required this.feedback,
  });

  final String prompt;
  final String wrongStatement;
  final String correctedStatement;
  final String feedback;
}

class TeachBackActivity {
  const TeachBackActivity({
    required this.prompt,
    required this.sampleAnswer,
    required this.feedback,
  });

  final String prompt;
  final String sampleAnswer;
  final String feedback;
}

class HumanHelpRecommendation {
  const HumanHelpRecommendation({
    required this.problem,
    required this.reason,
    required this.helperName,
    required this.shareableContext,
    required this.messageDraft,
  });

  final String problem;
  final String reason;
  final String helperName;
  final List<String> shareableContext;
  final String messageDraft;
}

class MentorFeedback {
  const MentorFeedback({
    required this.mentorName,
    required this.message,
    required this.nextAction,
    required this.masteryReview,
  });

  final String mentorName;
  final String message;
  final String nextAction;
  final String masteryReview;
}
