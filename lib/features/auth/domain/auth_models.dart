enum CareerPath { detective, animalDoctor, koreanTeacher }

extension CareerPathPayload on CareerPath {
  String get payload => switch (this) {
        CareerPath.detective => 'DETECTIVE',
        CareerPath.animalDoctor => 'ANIMAL_DOCTOR',
        CareerPath.koreanTeacher => 'KOREAN_TEACHER',
      };

  String get label => switch (this) {
        CareerPath.detective => 'Detektif',
        CareerPath.animalDoctor => 'Dokter Hewan',
        CareerPath.koreanTeacher => 'Guru Bahasa Korea',
      };
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.avatarUrl,
    this.schoolId,
    this.studentProfileId,
    this.gradeLevel,
    this.careerPath,
    this.onboardingCompleted = false,
  });

  final String id;
  final String name;
  final String role;
  final String? email;
  final String? avatarUrl;
  final String? schoolId;
  final String? studentProfileId;
  final int? gradeLevel;
  final CareerPath? careerPath;
  final bool onboardingCompleted;

  bool get hasStudentProfile => studentProfileId != null;
  bool get hasCompletedOnboarding =>
      onboardingCompleted || (gradeLevel != null && careerPath != null);

  AuthUser copyWith({
    String? name,
    int? gradeLevel,
    CareerPath? careerPath,
  }) {
    return AuthUser(
      id: id,
      name: name ?? this.name,
      role: role,
      email: email,
      avatarUrl: avatarUrl,
      schoolId: schoolId,
      studentProfileId: studentProfileId,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      careerPath: careerPath ?? this.careerPath,
      onboardingCompleted: onboardingCompleted,
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final studentProfile = json['studentProfile'];
    final profile =
        studentProfile is Map<String, dynamic> ? studentProfile : null;
    return AuthUser(
      id: json['id'] as String,
      name: (profile?['fullName'] ?? json['name'] ?? 'Siswa') as String,
      role: (json['role'] ?? 'STUDENT') as String,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      schoolId: (profile?['schoolId'] ?? json['schoolId']) as String?,
      studentProfileId: (profile?['id'] ?? json['studentProfileId']) as String?,
      gradeLevel: profile?['gradeLevel'] as int?,
      careerPath: _careerPathFromJson(profile?['careerPath'] as String?),
      onboardingCompleted:
          json['hasCompletedOnboarding'] as bool? ??
              ((profile?['onboarding'] as Map<String, dynamic>?)?['completedAt'] !=
                  null),
    );
  }

  static CareerPath? _careerPathFromJson(String? value) {
    return switch (value) {
      'DETECTIVE' => CareerPath.detective,
      'ANIMAL_DOCTOR' => CareerPath.animalDoctor,
      'KOREAN_TEACHER' => CareerPath.koreanTeacher,
      _ => null,
    };
  }
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
