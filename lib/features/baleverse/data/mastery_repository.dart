import '../../../core/api/api_client.dart';
import '../../../core/auth/token_store.dart';

/// Penguasaan satu kompetensi - dari `GET /student/mastery?worldKey=`.
/// Sumber kebenaran mastery, terpisah total dari XP (lihat prinsip
/// CLAUDE.md backend). Sebelumnya tidak pernah dipanggil dari Dashboard
/// atau Profile - keduanya cuma menampilkan angka mastery dunia hardcode
/// (42/12/8/10) dari blob prototype, atau mutasi lokal yang hilang saat
/// aplikasi ditutup.
class CompetencyMastery {
  const CompetencyMastery({
    required this.competencyId,
    required this.competencyName,
    required this.masteryScore,
    required this.status,
  });

  factory CompetencyMastery.fromJson(Map<String, dynamic> json) {
    return CompetencyMastery(
      competencyId: json['competencyId'] as String? ?? '',
      competencyName: json['competencyName'] as String? ?? '',
      masteryScore: (json['masteryScore'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'INSUFFICIENT_EVIDENCE',
    );
  }

  final String competencyId;
  final String competencyName;
  final double masteryScore;
  final String status;
}

class MasteryRepository {
  MasteryRepository({ApiClient? apiClient})
      : _apiClient =
            apiClient ?? ApiClient(tokenProvider: const SecureTokenStore().read);

  final ApiClient _apiClient;

  Future<List<CompetencyMastery>> fetchGrowthMap({required String worldKey}) async {
    final data = await _apiClient.get('/student/mastery', query: {'worldKey': worldKey});
    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(CompetencyMastery.fromJson)
        .toList();
  }
}

/// Rata-rata masteryScore dari daftar kompetensi, 0 kalau kosong.
double averageMasteryScore(List<CompetencyMastery> competencies) {
  if (competencies.isEmpty) return 0;
  final total = competencies.fold<double>(0, (sum, c) => sum + c.masteryScore);
  return total / competencies.length;
}
