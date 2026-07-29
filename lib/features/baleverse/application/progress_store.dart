import 'dart:convert';

import '../data/baleverse_dummy_data.dart';
import '../domain/baleverse_models.dart';
import 'baleverse_progress_service.dart';

abstract class ProgressStore {
  BaleVerseProgress load();
  void save(BaleVerseProgress progress);
}

class InMemoryProgressStore implements ProgressStore {
  InMemoryProgressStore([String? initialJson]) : _json = initialJson;

  String? _json;

  @override
  BaleVerseProgress load() {
    if (_json == null) {
      return const BaleVerseProgress(
        user: baleUser,
        parentSupportSent: false,
        mentorFeedbackReceived: false,
      );
    }
    return progressFromJson(_json!);
  }

  @override
  void save(BaleVerseProgress progress) {
    _json = progressToJson(progress);
  }
}

String progressToJson(BaleVerseProgress progress) {
  return jsonEncode({
    'parentSupportSent': progress.parentSupportSent,
    'mentorFeedbackReceived': progress.mentorFeedbackReceived,
    'user': {
      'name': progress.user.name,
      'rank': progress.user.rank,
      'level': progress.user.level,
      'dayaBale': progress.user.dayaBale,
      'weeklyTarget': progress.user.weeklyTarget,
      'weeklyCompleted': progress.user.weeklyCompleted,
      'xp': _worldMapToJson(progress.user.xp),
      'mastery': _worldMapToJson(progress.user.mastery),
    },
  });
}

BaleVerseProgress progressFromJson(String source) {
  final data = jsonDecode(source) as Map<String, dynamic>;
  final user = data['user'] as Map<String, dynamic>;
  return BaleVerseProgress(
    user: BaleUser(
      name: user['name'] as String,
      rank: user['rank'] as String,
      level: user['level'] as int,
      dayaBale: user['dayaBale'] as int,
      weeklyTarget: user['weeklyTarget'] as int,
      weeklyCompleted: user['weeklyCompleted'] as int,
      xp: _worldMapFromJson(user['xp'] as Map<String, dynamic>),
      mastery: _worldMapFromJson(user['mastery'] as Map<String, dynamic>),
    ),
    parentSupportSent: data['parentSupportSent'] as bool,
    mentorFeedbackReceived: data['mentorFeedbackReceived'] as bool,
  );
}

Map<String, int> _worldMapToJson(Map<BaleWorldKey, int> source) {
  return source.map((key, value) => MapEntry(key.name, value));
}

Map<BaleWorldKey, int> _worldMapFromJson(Map<String, dynamic> source) {
  return source.map(
    (key, value) => MapEntry(
      BaleWorldKey.values.firstWhere((world) => world.name == key),
      value as int,
    ),
  );
}
