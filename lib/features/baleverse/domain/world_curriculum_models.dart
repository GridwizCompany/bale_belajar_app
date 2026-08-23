class WorldCurriculum {
  const WorldCurriculum({
    required this.key,
    required this.name,
    required this.characterClass,
    required this.themeDescription,
    required this.modules,
  });

  factory WorldCurriculum.fromJson(Map<String, dynamic> json) {
    return WorldCurriculum(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? 'Dunia',
      characterClass: json['characterClass'] as String? ?? '',
      themeDescription: json['themeDescription'] as String? ?? '',
      modules: (json['modules'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(CurriculumModule.fromJson)
          .toList(),
    );
  }

  final String key;
  final String name;
  final String characterClass;
  final String themeDescription;
  final List<CurriculumModule> modules;
}

class CurriculumModule {
  const CurriculumModule({
    required this.id,
    required this.title,
    required this.simpleGoal,
    required this.bigIdea,
    required this.estimatedMinutes,
    required this.lessons,
    required this.caseStudies,
  });

  factory CurriculumModule.fromJson(Map<String, dynamic> json) {
    return CurriculumModule(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Materi',
      simpleGoal: json['simpleGoal'] as String? ?? '',
      bigIdea: json['bigIdea'] as String? ?? '',
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 15,
      lessons: (json['lessons'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(CurriculumLesson.fromJson)
          .toList(),
      caseStudies: (json['caseStudies'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(CurriculumCaseStudy.fromJson)
          .toList(),
    );
  }

  final String id;
  final String title;
  final String simpleGoal;
  final String bigIdea;
  final int estimatedMinutes;
  final List<CurriculumLesson> lessons;
  final List<CurriculumCaseStudy> caseStudies;
}

class CurriculumLesson {
  const CurriculumLesson({
    required this.type,
    required this.title,
    required this.body,
    required this.examples,
    required this.items,
  });

  factory CurriculumLesson.fromJson(Map<String, dynamic> json) {
    return CurriculumLesson(
      type: json['type'] as String? ?? 'CONCEPT',
      title: json['title'] as String? ?? 'Materi',
      body: json['body'] as String? ?? '',
      examples: (json['examples'] as List?)?.cast<String>() ?? const [],
      items: (json['items'] as List?)?.cast<String>() ?? const [],
    );
  }

  final String type;
  final String title;
  final String body;
  final List<String> examples;
  final List<String> items;
}

class CurriculumCaseStudy {
  const CurriculumCaseStudy({
    required this.title,
    required this.story,
    required this.analysisSteps,
    required this.commonMistake,
  });

  factory CurriculumCaseStudy.fromJson(Map<String, dynamic> json) {
    return CurriculumCaseStudy(
      title: json['title'] as String? ?? 'Kasus latihan',
      story: json['story'] as String? ?? '',
      analysisSteps:
          (json['analysisSteps'] as List?)?.cast<String>() ?? const [],
      commonMistake: json['commonMistake'] as String? ?? '',
    );
  }

  final String title;
  final String story;
  final List<String> analysisSteps;
  final String commonMistake;
}
