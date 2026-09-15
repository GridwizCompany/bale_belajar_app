enum VocabLevel { beginner, intermediate, advanced }

extension VocabLevelJson on VocabLevel {
  String get apiValue => switch (this) {
        VocabLevel.beginner => 'BEGINNER',
        VocabLevel.intermediate => 'INTERMEDIATE',
        VocabLevel.advanced => 'ADVANCED',
      };

  String get label => switch (this) {
        VocabLevel.beginner => 'Pemula',
        VocabLevel.intermediate => 'Menengah',
        VocabLevel.advanced => 'Lanjut',
      };

  static VocabLevel fromApi(String value) => switch (value) {
        'INTERMEDIATE' => VocabLevel.intermediate,
        'ADVANCED' => VocabLevel.advanced,
        _ => VocabLevel.beginner,
      };
}

enum VocabDisplayLanguage { enToKo, koToEn, both }

extension VocabDisplayLanguageJson on VocabDisplayLanguage {
  String get apiValue => switch (this) {
        VocabDisplayLanguage.enToKo => 'EN_TO_KO',
        VocabDisplayLanguage.koToEn => 'KO_TO_EN',
        VocabDisplayLanguage.both => 'BOTH',
      };

  String get label => switch (this) {
        VocabDisplayLanguage.enToKo => 'Inggris → Korea',
        VocabDisplayLanguage.koToEn => 'Korea → Inggris',
        VocabDisplayLanguage.both => 'Keduanya',
      };

  static VocabDisplayLanguage fromApi(String value) => switch (value) {
        'EN_TO_KO' => VocabDisplayLanguage.enToKo,
        'KO_TO_EN' => VocabDisplayLanguage.koToEn,
        _ => VocabDisplayLanguage.both,
      };
}

class VocabCategory {
  const VocabCategory(
      {required this.id, required this.key, required this.name});

  final String id;
  final String key;
  final String name;

  factory VocabCategory.fromJson(Map<String, dynamic> json) => VocabCategory(
        id: json['id'] as String,
        key: json['key'] as String,
        name: json['name'] as String,
      );
}

class VocabWord {
  const VocabWord({
    required this.id,
    required this.english,
    this.indonesian,
    required this.korean,
    required this.level,
    required this.category,
    this.koreanRomanized,
    this.exampleSentenceEn,
    this.exampleSentenceKo,
  });

  final String id;
  final String english;
  final String? indonesian;
  final String korean;
  final String? koreanRomanized;
  final String? exampleSentenceEn;
  final String? exampleSentenceKo;
  final VocabLevel level;
  final String category;

  factory VocabWord.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return VocabWord(
      id: json['id'] as String,
      english: json['english'] as String,
      indonesian: json['indonesian'] as String?,
      korean: json['korean'] as String,
      koreanRomanized: json['koreanRomanized'] as String?,
      exampleSentenceEn: json['exampleSentenceEn'] as String?,
      exampleSentenceKo: json['exampleSentenceKo'] as String?,
      level: VocabLevelJson.fromApi(json['level'] as String? ?? 'BEGINNER'),
      category: category?['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'english': english,
        'indonesian': indonesian,
        'korean': korean,
        'koreanRomanized': koreanRomanized,
        'exampleSentenceEn': exampleSentenceEn,
        'exampleSentenceKo': exampleSentenceKo,
        'level': level.apiValue,
        'category': category,
      };
}

class VocabSetting {
  const VocabSetting({
    required this.dailyCount,
    required this.displayLanguage,
    required this.notificationEnabled,
    required this.widgetEnabled,
    required this.notificationStartHour,
    required this.notificationEndHour,
    required this.levels,
    required this.categoryKeys,
  });

  final int dailyCount;
  final VocabDisplayLanguage displayLanguage;
  final bool notificationEnabled;
  final bool widgetEnabled;
  final int notificationStartHour;
  final int notificationEndHour;
  final List<VocabLevel> levels;
  final List<String> categoryKeys;

  factory VocabSetting.fromJson(Map<String, dynamic> json) => VocabSetting(
        dailyCount: json['dailyCount'] as int,
        displayLanguage: VocabDisplayLanguageJson.fromApi(
            json['displayLanguage'] as String? ?? 'BOTH'),
        notificationEnabled: json['notificationEnabled'] as bool? ?? true,
        widgetEnabled: json['widgetEnabled'] as bool? ?? true,
        notificationStartHour: json['notificationStartHour'] as int? ?? 8,
        notificationEndHour: json['notificationEndHour'] as int? ?? 20,
        levels: ((json['levels'] as List?) ?? const [])
            .map((value) => VocabLevelJson.fromApi(value as String))
            .toList(),
        categoryKeys:
            ((json['categoryKeys'] as List?) ?? const []).cast<String>(),
      );

  VocabSetting copyWith({
    int? dailyCount,
    VocabDisplayLanguage? displayLanguage,
    bool? notificationEnabled,
    bool? widgetEnabled,
    int? notificationStartHour,
    int? notificationEndHour,
    List<VocabLevel>? levels,
    List<String>? categoryKeys,
  }) {
    return VocabSetting(
      dailyCount: dailyCount ?? this.dailyCount,
      displayLanguage: displayLanguage ?? this.displayLanguage,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      widgetEnabled: widgetEnabled ?? this.widgetEnabled,
      notificationStartHour:
          notificationStartHour ?? this.notificationStartHour,
      notificationEndHour: notificationEndHour ?? this.notificationEndHour,
      levels: levels ?? this.levels,
      categoryKeys: categoryKeys ?? this.categoryKeys,
    );
  }
}

class DailyVocab {
  const DailyVocab(
      {required this.date, required this.setting, required this.words});

  final String date;
  final VocabSetting setting;
  final List<VocabWord> words;

  factory DailyVocab.fromJson(Map<String, dynamic> json) => DailyVocab(
        date: json['date'] as String,
        setting: VocabSetting.fromJson(json['setting'] as Map<String, dynamic>),
        words: ((json['words'] as List?) ?? const [])
            .map((value) => VocabWord.fromJson(value as Map<String, dynamic>))
            .toList(),
      );
}
