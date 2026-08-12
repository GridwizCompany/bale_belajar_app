import '../../test_templates/domain/test_template_models.dart';

/// Ringkasan Quest hari ini - dipetakan dari respons
/// `GET /student/quests/today` (field `quest` + `assignmentId` + `attempt`).
class QuestSummary {
  const QuestSummary({
    required this.assignmentId,
    required this.attemptId,
    required this.title,
    required this.story,
    required this.objective,
    required this.studentInstruction,
    required this.estimatedMinutes,
    required this.rewardXp,
    required this.hints,
    required this.chapterTitle,
    required this.questions,
    this.attemptStatus,
  });

  factory QuestSummary.fromJson(Map<String, dynamic> json) {
    final quest = json['quest'] as Map<String, dynamic>;
    final attempt = json['attempt'] as Map<String, dynamic>?;
    final chapter = quest['chapter'] as Map<String, dynamic>?;
    final questions = (json['questions'] as List)
        .cast<Map<String, dynamic>>()
        .map(questionFromBackendJson)
        .toList();

    return QuestSummary(
      assignmentId: json['assignmentId'] as String,
      attemptId: attempt?['id'] as String?,
      title: quest['title'] as String? ?? 'Quest',
      story: quest['story'] as String? ?? '',
      objective: quest['objective'] as String? ?? '',
      studentInstruction: quest['studentInstruction'] as String? ?? '',
      estimatedMinutes: quest['estimatedMinutes'] as int? ?? 10,
      rewardXp: quest['rewardXp'] as int? ?? 0,
      hints: (quest['hints'] as List?)?.cast<String>() ?? const [],
      chapterTitle: chapter?['title'] as String?,
      questions: questions,
      attemptStatus: attempt?['status'] as String?,
    );
  }

  final String assignmentId;
  final String? attemptId;
  final String title;
  final String story;
  final String objective;
  final String studentInstruction;
  final int estimatedMinutes;
  final int rewardXp;
  final List<String> hints;
  final String? chapterTitle;
  final List<TemplateQuestion> questions;
  final String? attemptStatus;
}

/// Hasil satu soal setelah submit (kunci jawaban sudah boleh terlihat).
class QuestQuestionResult {
  const QuestQuestionResult({
    required this.questionId,
    required this.score,
    required this.isCorrect,
    required this.evaluationStatus,
  });

  factory QuestQuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestQuestionResult(
      questionId: json['id'] as String,
      score: (json['score'] as num?)?.toDouble(),
      isCorrect: json['isCorrect'] as bool?,
      evaluationStatus: json['evaluationStatus'] as String? ?? 'MENTOR_REVIEW_NEEDED',
    );
  }

  final String questionId;
  final double? score;
  final bool? isCorrect;
  final String evaluationStatus;

  bool get isPendingReview => evaluationStatus == 'MENTOR_REVIEW_NEEDED';
}

/// Ringkasan hasil submit keseluruhan quest.
class QuestSubmitResult {
  const QuestSubmitResult({
    required this.attemptId,
    required this.overallScore,
    required this.xpGained,
    required this.accountLevel,
    required this.accountLeveledUp,
    required this.worldLevel,
    required this.worldLeveledUp,
    required this.questions,
  });

  factory QuestSubmitResult.fromJson(Map<String, dynamic> json) {
    final gameProfile = json['gameProfile'] as Map<String, dynamic>? ?? const {};
    return QuestSubmitResult(
      attemptId: json['attemptId'] as String,
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0,
      xpGained: json['xpGained'] as int? ?? 0,
      accountLevel: gameProfile['accountLevel'] as int?,
      accountLeveledUp: gameProfile['accountLeveledUp'] as bool? ?? false,
      worldLevel: gameProfile['worldLevel'] as int?,
      worldLeveledUp: gameProfile['worldLeveledUp'] as bool? ?? false,
      questions: (json['questions'] as List)
          .cast<Map<String, dynamic>>()
          .map(QuestQuestionResult.fromJson)
          .toList(),
    );
  }

  final String attemptId;
  final double overallScore;
  final int xpGained;
  final int? accountLevel;
  final bool accountLeveledUp;
  final int? worldLevel;
  final bool worldLeveledUp;
  final List<QuestQuestionResult> questions;
}

/// Konversi bentuk JSON per-soal dari backend `student-quests` ke
/// [TemplateQuestion] supaya 14 widget yang sudah ada di
/// `test_templates/presentation/templates` bisa dipakai apa adanya tanpa
/// perlu ditulis ulang.
TemplateQuestion questionFromBackendJson(Map<String, dynamic> json) {
  final type = QuestionType.values.firstWhere(
    (t) => t.payload == json['questionType'],
    orElse: () => QuestionType.shortText,
  );

  final mediaList = (json['media'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final media = mediaList.isEmpty
      ? null
      : TemplateMedia(
          type: mediaList.first['mediaType'] as String? ?? 'audio',
          url: mediaList.first['url'] as String? ?? '',
          durationSeconds: mediaList.first['durationSeconds'] as int?,
          maxReplay: mediaList.first['maxReplay'] as int?,
          transcriptAvailable: mediaList.first['transcriptAvailable'] as bool? ?? false,
          transcript: mediaList.first['transcript'] as String?,
        );

  final options = (json['options'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((o) => TemplateOption(
                id: o['id'] as String,
                label: o['label'] as String? ?? '',
                imageUrl: o['imageUrl'] as String?,
                description: o['description'] as String?,
              ))
          .toList() ??
      const [];

  final left = (json['matchingLeftOptions'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final right = (json['matchingRightOptions'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final pairCount = left.length < right.length ? left.length : right.length;
  final matchingPairs = List.generate(
    pairCount,
    (i) => MatchingPair(
      leftId: left[i]['id'] as String,
      leftLabel: left[i]['label'] as String? ?? '',
      rightId: right[i]['id'] as String,
      rightLabel: right[i]['label'] as String? ?? '',
    ),
  );

  final items = (json['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final orderingItems = type == QuestionType.ordering
      ? items.map((i) => OrderingItem(id: i['id'] as String, label: i['label'] as String? ?? '')).toList()
      : const <OrderingItem>[];
  final timelineItems = type == QuestionType.timelineBuilder
      ? items
          .map((i) => TimelineItem(
                id: i['id'] as String,
                label: i['label'] as String? ?? '',
                timeLabel: i['timeLabel'] as String?,
                description: i['description'] as String?,
              ))
          .toList()
      : const <TimelineItem>[];

  final hotspotAreas = (json['hotspotAreas'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((h) => HotspotArea(
                id: h['id'] as String,
                label: h['label'] as String? ?? '',
                x: (h['x'] as num?)?.toDouble() ?? 0,
                y: (h['y'] as num?)?.toDouble() ?? 0,
                radius: (h['radius'] as num?)?.toDouble() ?? 0.08,
              ))
          .toList() ??
      const [];

  final evidenceItems = (json['evidenceItems'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((e) => EvidenceItem(
                id: e['id'] as String,
                label: e['label'] as String? ?? '',
                description: e['description'] as String?,
                category: e['category'] as String?,
              ))
          .toList() ??
      const [];

  final codeConfigJson = json['codeConfig'] as Map<String, dynamic>?;
  final codeConfig = codeConfigJson == null
      ? null
      : CodeConfig(
          language: codeConfigJson['language'] as String? ?? 'text',
          initialCode: codeConfigJson['initialCode'] as String? ?? '',
          readOnlyPrefix: codeConfigJson['readOnlyPrefix'] as String?,
        );

  final inputMode = switch (json['inputMode']) {
    'numeric' => TextInputMode.numeric,
    'decimal' => TextInputMode.decimal,
    'fraction' => TextInputMode.fraction,
    'code' => TextInputMode.code,
    _ => TextInputMode.text,
  };

  return TemplateQuestion(
    id: json['id'] as String,
    questionType: type,
    prompt: json['questionText'] as String? ?? '',
    instruction: json['instruction'] as String?,
    options: options,
    media: media,
    responseConfig: ResponseConfig(
      inputMode: inputMode,
      maxLength: json['maxLength'] as int? ?? 200,
    ),
    matchingPairs: matchingPairs,
    orderingItems: orderingItems,
    hotspotAreas: hotspotAreas,
    timelineItems: timelineItems,
    evidenceItems: evidenceItems,
    codeConfig: codeConfig,
  );
}
