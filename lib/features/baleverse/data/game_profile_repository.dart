import '../../../core/api/api_client.dart';
import '../../../core/auth/token_store.dart';

/// Ringkasan gamifikasi akun siswa (level, XP, rank, Daya Bale, streak) -
/// dari `GET /student/game-profile`, sumber kebenaran XP yang dipisah total
/// dari mastery (lihat prinsip CLAUDE.md backend). Sebelumnya Dashboard dan
/// Profile tidak pernah memanggil endpoint ini sama sekali, cuma pakai blob
/// prototype hardcode atau state lokal `BaleVerseProgressService`.
class GameProfileSummary {
  const GameProfileSummary({
    required this.accountLevel,
    required this.accountXp,
    required this.xpIntoCurrentLevel,
    required this.xpRequiredForNextLevel,
    required this.rank,
    required this.dayaBale,
    required this.streakCurrent,
    required this.streakLongest,
    required this.streakTargetPerWeek,
  });

  factory GameProfileSummary.fromJson(Map<String, dynamic> json) {
    return GameProfileSummary(
      accountLevel: json['accountLevel'] as int? ?? 1,
      accountXp: json['accountXp'] as int? ?? 0,
      xpIntoCurrentLevel: json['xpIntoCurrentLevel'] as int? ?? 0,
      xpRequiredForNextLevel: json['xpRequiredForNextLevel'] as int? ?? 100,
      rank: json['rank'] as String? ?? '-',
      dayaBale: json['dayaBale'] as int? ?? 0,
      streakCurrent: json['streakCurrent'] as int? ?? 0,
      streakLongest: json['streakLongest'] as int? ?? 0,
      streakTargetPerWeek: json['streakTargetPerWeek'] as int? ?? 0,
    );
  }

  final int accountLevel;
  final int accountXp;
  final int xpIntoCurrentLevel;
  final int xpRequiredForNextLevel;
  final String rank;
  final int dayaBale;
  final int streakCurrent;
  final int streakLongest;
  final int streakTargetPerWeek;

  /// Rasio progres menuju level berikutnya, 0.0-1.0.
  double get levelProgress {
    if (xpRequiredForNextLevel <= 0) return 0;
    return (xpIntoCurrentLevel / xpRequiredForNextLevel).clamp(0, 1);
  }
}

class GameProfileRepository {
  GameProfileRepository({ApiClient? apiClient})
      : _apiClient =
            apiClient ?? ApiClient(tokenProvider: const SecureTokenStore().read);

  final ApiClient _apiClient;

  Future<GameProfileSummary> fetchGameProfile() async {
    final data = await _apiClient.get('/student/game-profile');
    return GameProfileSummary.fromJson(data as Map<String, dynamic>);
  }
}
