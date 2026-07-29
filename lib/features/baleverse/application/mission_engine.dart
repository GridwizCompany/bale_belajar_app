import '../data/baleverse_dummy_data.dart';
import '../domain/baleverse_models.dart';
import '../state/mission_state_machine.dart' as machine;

class MissionEvaluation {
  const MissionEvaluation({
    required this.state,
    required this.feedback,
    required this.shouldApplyReward,
  });

  final machine.BaleVerseState state;
  final String feedback;
  final bool shouldApplyReward;
}

class MissionEngine {
  const MissionEngine();

  MissionEvaluation evaluate({
    required machine.BaleVerseState state,
    required String? selectedOptionId,
    required bool mistakeMarked,
    required String teachBackText,
  }) {
    return switch (state.activityType) {
      MissionActivityType.multipleChoice => _evaluateMultipleChoice(
          state,
          selectedOptionId,
        ),
      MissionActivityType.findMistake => MissionEvaluation(
          state: machine.advanceActivity(state),
          feedback: findMistakeActivity.feedback,
          shouldApplyReward: false,
        ),
      MissionActivityType.teachBack => MissionEvaluation(
          state: machine.answerCorrect(state),
          feedback: teachBackActivity.feedback,
          shouldApplyReward: true,
        ),
    };
  }

  bool canEvaluate({
    required machine.BaleVerseState state,
    required String? selectedOptionId,
    required bool mistakeMarked,
    required String teachBackText,
  }) {
    return switch (state.activityType) {
      MissionActivityType.multipleChoice => selectedOptionId != null,
      MissionActivityType.findMistake => mistakeMarked,
      MissionActivityType.teachBack => teachBackText.trim().length >= 12,
    };
  }

  MissionEvaluation _evaluateMultipleChoice(
    machine.BaleVerseState state,
    String? selectedOptionId,
  ) {
    final option = numeriaMission.options.firstWhere(
      (item) => item.id == selectedOptionId,
    );

    return MissionEvaluation(
      state: option.isCorrect
          ? machine.advanceActivity(state)
          : machine.answerWrong(state),
      feedback: option.feedback,
      shouldApplyReward: false,
    );
  }
}
