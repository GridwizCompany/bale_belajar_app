import '../domain/baleverse_models.dart';

class BaleVerseState {
  const BaleVerseState({
    this.step = MissionStep.login,
    this.selectedWorld = BaleWorldKey.numeria,
    this.wrongAttempts = 0,
  });

  final MissionStep step;
  final BaleWorldKey selectedWorld;
  final int wrongAttempts;

  BaleVerseState copyWith({
    MissionStep? step,
    BaleWorldKey? selectedWorld,
    int? wrongAttempts,
  }) {
    return BaleVerseState(
      step: step ?? this.step,
      selectedWorld: selectedWorld ?? this.selectedWorld,
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
  return state.copyWith(step: MissionStep.missionIntro, wrongAttempts: 0);
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

BaleVerseState requestMentor(BaleVerseState state) {
  return state.copyWith(step: MissionStep.waitingMentor);
}

BaleVerseState receiveMentorFeedback(BaleVerseState state) {
  return state.copyWith(step: MissionStep.mentorResponded);
}
