import 'package:flutter/foundation.dart';

import '../domain/baleverse_models.dart';
import 'progress_store.dart';

class BaleVerseProgress {
  const BaleVerseProgress({
    required this.user,
    required this.parentSupportSent,
    required this.mentorFeedbackReceived,
  });

  final BaleUser user;
  final bool parentSupportSent;
  final bool mentorFeedbackReceived;

  BaleVerseProgress copyWith({
    BaleUser? user,
    bool? parentSupportSent,
    bool? mentorFeedbackReceived,
  }) {
    return BaleVerseProgress(
      user: user ?? this.user,
      parentSupportSent: parentSupportSent ?? this.parentSupportSent,
      mentorFeedbackReceived:
          mentorFeedbackReceived ?? this.mentorFeedbackReceived,
    );
  }
}

class BaleVerseProgressService extends ChangeNotifier {
  BaleVerseProgressService({ProgressStore? store})
      : _store = store ?? InMemoryProgressStore() {
    _progress = _store.load();
  }

  final ProgressStore _store;
  late BaleVerseProgress _progress;

  BaleVerseProgress get snapshot => _progress;

  void applyMissionReward(BaleMission mission) {
    final current = _progress.user;
    final updatedXp = Map<BaleWorldKey, int>.from(current.xp);
    final updatedMastery = Map<BaleWorldKey, int>.from(current.mastery);
    updatedXp[BaleWorldKey.numeria] =
        (updatedXp[BaleWorldKey.numeria] ?? 0) + mission.rewardXp;
    updatedMastery[BaleWorldKey.numeria] =
        ((updatedMastery[BaleWorldKey.numeria] ?? 0) + 2).clamp(0, 100);

    _progress = _progress.copyWith(
      user: BaleUser(
        name: current.name,
        rank: current.rank,
        level: current.level,
        dayaBale: current.dayaBale + mission.rewardDayaBale,
        weeklyTarget: current.weeklyTarget,
        weeklyCompleted: current.weeklyCompleted,
        xp: updatedXp,
        mastery: updatedMastery,
      ),
    );
    _store.save(_progress);
    notifyListeners();
  }

  void markParentSupportSent() {
    _progress = _progress.copyWith(parentSupportSent: true);
    _store.save(_progress);
    notifyListeners();
  }

  void markMentorFeedbackReceived() {
    _progress = _progress.copyWith(mentorFeedbackReceived: true);
    _store.save(_progress);
    notifyListeners();
  }
}
