import '../../../core/api/api_client.dart';
import '../../../core/auth/token_store.dart';
import '../domain/vocab_models.dart';

class VocabRepository {
  VocabRepository({ApiClient? apiClient})
      : _apiClient = apiClient ??
            ApiClient(tokenProvider: const SecureTokenStore().read);

  final ApiClient _apiClient;

  Future<DailyVocab> fetchDaily() async {
    final data = await _apiClient.get('/student/vocab/daily');
    return DailyVocab.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<VocabSetting> fetchSettings() async {
    final data = await _apiClient.get('/student/vocab/settings');
    return VocabSetting.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<VocabSetting> updateSettings({
    int? dailyCount,
    VocabDisplayLanguage? displayLanguage,
    bool? notificationEnabled,
    bool? widgetEnabled,
    int? notificationStartHour,
    int? notificationEndHour,
    List<VocabLevel>? levels,
    List<String>? categoryKeys,
  }) async {
    final body = <String, dynamic>{
      if (dailyCount != null) 'dailyCount': dailyCount,
      if (displayLanguage != null) 'displayLanguage': displayLanguage.apiValue,
      if (notificationEnabled != null) 'notificationEnabled': notificationEnabled,
      if (widgetEnabled != null) 'widgetEnabled': widgetEnabled,
      if (notificationStartHour != null)
        'notificationStartHour': notificationStartHour,
      if (notificationEndHour != null) 'notificationEndHour': notificationEndHour,
      if (levels != null) 'levels': levels.map((level) => level.apiValue).toList(),
      if (categoryKeys != null) 'categoryKeys': categoryKeys,
    };
    final data = await _apiClient.patch('/student/vocab/settings', body: body);
    return VocabSetting.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<VocabCategory>> fetchCategories() async {
    final data = await _apiClient.get('/student/vocab/categories');
    final list = (data as List).cast<Map<String, dynamic>>();
    return list.map(VocabCategory.fromJson).toList();
  }
}
