import '../domain/baleverse_models.dart';

class BaleVerseState {
  const BaleVerseState({
    this.step = MissionStep.login,
    this.selectedWorld = BaleWorldKey.numeria,
    this.activityType = MissionActivityType.multipleChoice,
    this.wrongAttempts = 0,
  });

  final MissionStep step;
  final BaleWorldKey selectedWorld;
  final MissionActivityType activityType;
  final int wrongAttempts;

  BaleVerseState copyWith({
    MissionStep? step,
    BaleWorldKey? selectedWorld,
    MissionActivityType? activityType,
    int? wrongAttempts,
  }) {
    return BaleVerseState(
      step: step ?? this.step,
      selectedWorld: selectedWorld ?? this.selectedWorld,
      activityType: activityType ?? this.activityType,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
    );
  }
}

BaleVerseState login(BaleVerseState state) {
  return state.copyWith(step: MissionStep.dashboard);
}

BaleVerseState selectWorld(BaleVerseState state, BaleWorldKey world) {
  return state.copyWith(selectedWorld: world);
}

BaleVerseState startMission(BaleVerseState state) {
  return state.copyWith(
    step: MissionStep.missionIntro,
    activityType: MissionActivityType.multipleChoice,
    wrongAttempts: 0,
  );
}

BaleVerseState beginQuestion(BaleVerseState state) {
  return state.copyWith(step: MissionStep.question);
}

BaleVerseState answerWrong(BaleVerseState state) {
  final attempts = state.wrongAttempts + 1;
  final nextStep = switch (attempts) {
    1 => MissionStep.hintOne,
    2 => MissionStep.hintTwo,
    _ => MissionStep.humanHelp,
  };
  return state.copyWith(step: nextStep, wrongAttempts: attempts);
}

BaleVerseState answerCorrect(BaleVerseState state) {
  return state.copyWith(step: MissionStep.reward);
}

BaleVerseState advanceActivity(BaleVerseState state) {
  final nextActivity = switch (state.activityType) {
    MissionActivityType.multipleChoice => MissionActivityType.findMistake,
    MissionActivityType.findMistake => MissionActivityType.teachBack,
    MissionActivityType.teachBack => MissionActivityType.teachBack,
  };
  return state.copyWith(
    step: MissionStep.question,
    activityType: nextActivity,
    wrongAttempts: 0,
  );
}

BaleVerseState requestMentor(BaleVerseState state) {
  return state.copyWith(step: MissionStep.waitingMentor);
}

BaleVerseState receiveMentorFeedback(BaleVerseState state) {
  return state.copyWith(step: MissionStep.mentorResponded);
}
