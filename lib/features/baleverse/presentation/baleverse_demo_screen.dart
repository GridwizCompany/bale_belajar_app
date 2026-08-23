import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/audio/audio_scope.dart';
import '../../../core/audio/audio_types.dart';
import '../../auth/application/auth_controller.dart';
import '../data/game_profile_repository.dart';
import '../data/mastery_repository.dart';
import '../data/worlds_repository.dart';
import '../domain/baleverse_models.dart';
import 'screens/bale_profile_page.dart';
import 'screens/dashboard_screen.dart';
import 'screens/mission_hub_screen.dart';
import 'screens/world_curriculum_screen.dart';
import 'screens/worlds_screen.dart';

enum BaleTab { home, worlds, mission, profile }

class BaleVerseDemoScreen extends StatefulWidget {
  const BaleVerseDemoScreen({
    this.skipDemoLogin = true,
    this.authController,
    this.prototypeStudentProfileId,
    super.key,
  });

  final bool skipDemoLogin;
  final AuthController? authController;
  final String? prototypeStudentProfileId;

  @override
  State<BaleVerseDemoScreen> createState() => _BaleVerseDemoScreenState();
}

class _BaleVerseDemoScreenState extends State<BaleVerseDemoScreen> {
  final WorldsRepository _worldsRepository = WorldsRepository();
  final GameProfileRepository _gameProfileRepository = GameProfileRepository();
  final MasteryRepository _masteryRepository = MasteryRepository();

  BaleTab _tab = BaleTab.home;
  BackgroundMusicId? _lastRequestedMusic;
  Map<String, dynamic>? _backendData;
  Map<String, dynamic>? _adaptivePlan;
  List<Map<String, dynamic>> _realWorlds = [];
  GameProfileSummary? _gameProfile;
  double? _masteryAverage;
  bool _backendLoading = true;
  String? _backendError;

  String get _selectedBackendWorldKey {
    final direct = _backendData?['selectedWorld'] as String?;
    final missionWorld = (_backendData?['todayMission']
        as Map<String, dynamic>?)?['worldKey'] as String?;
    final key = (direct ?? missionWorld ?? 'scientia').trim();
    return key.isEmpty ? 'scientia' : key.toLowerCase();
  }

  BaleWorld get _selectedWorld => BaleWorld(
        key: BaleWorldKey.detectivia,
        name: _worldDisplayName(_selectedBackendWorldKey),
        subject: _worldSubject(_selectedBackendWorldKey),
        characterClass: _worldDisplayName(_selectedBackendWorldKey),
        color: const Color(0xFFF4B400),
        mastery: (_masteryAverage ?? 0).round(),
      );

  @override
  void initState() {
    super.initState();
    _loadBackendData();
  }

  Future<void> _loadBackendData() async {
    if (mounted) {
      setState(() {
        _backendLoading = true;
        _backendError = null;
      });
    }
    await _loadPrototypeBlob();
    await Future.wait([
      _loadRealWorlds(),
      _loadGameProfile(),
      _loadMastery(),
      _loadAdaptivePlan(),
    ]);
    if (mounted) {
      setState(() => _backendLoading = false);
    }
  }

  Future<void> _loadPrototypeBlob() async {
    final authController = widget.authController;
    if (authController == null) return;
    try {
      final data = authController.user != null
          ? await authController.authService.getBaleVerse()
          : kReleaseMode || widget.prototypeStudentProfileId == null
              ? null
              : await authController.authService.getPrototypeBaleVerse(
                  studentProfileId: widget.prototypeStudentProfileId!,
                );
      if (data == null || !mounted) return;
      setState(() => _backendData = Map<String, dynamic>.from(data));
    } on BaleApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _backendData = null;
        _backendError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _backendData = null;
        _backendError =
            'Data BaleVerse belum bisa dimuat. Periksa koneksi lalu coba lagi.';
      });
    }
  }

  Future<void> _loadRealWorlds() async {
    try {
      final worlds = await _worldsRepository.fetchWorlds();
      if (!mounted) return;
      setState(() {
        _realWorlds = worlds;
        if (worlds.isNotEmpty) {
          _backendError = null;
          _backendData ??= _fallbackBackendData(worlds);
        }
      });
    } catch (_) {}
    if (!mounted) return;
    if (_realWorlds.isEmpty) {
      setState(() => _backendError ??= 'Daftar dunia belum bisa dimuat.');
    }
  }

  Future<void> _loadGameProfile() async {
    try {
      final profile = await _gameProfileRepository.fetchGameProfile();
      if (!mounted) return;
      setState(() => _gameProfile = profile);
    } catch (_) {}
  }

  Future<void> _loadMastery() async {
    try {
      final competencies = await _masteryRepository.fetchGrowthMap(
        worldKey: _selectedBackendWorldKey,
      );
      if (!mounted) return;
      setState(() => _masteryAverage = averageMasteryScore(competencies));
    } catch (_) {}
  }

  Future<void> _loadAdaptivePlan() async {
    try {
      final plan = await _worldsRepository.fetchAdaptivePlan(
        worldKey: _selectedBackendWorldKey,
      );
      if (!mounted) return;
      setState(() => _adaptivePlan = plan);
    } catch (_) {
      if (!mounted) return;
      setState(() => _adaptivePlan = null);
    }
  }

  void _goToTab(BaleTab tab) {
    if (_tab == tab) return;
    AudioScope.maybeOf(context)?.playSound(SoundEffectId.buttonTap);
    setState(() => _tab = tab);
    _syncMusic();
  }

  void _startMission() {
    final backendWorldKey = _selectedBackendWorldKey;
    if (backendWorldKey.isNotEmpty) {
      AudioScope.maybeOf(context)?.playSound(SoundEffectId.pageTransition);
      Navigator.of(context)
          .push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => WorldCurriculumScreen(worldKey: backendWorldKey),
        ),
      )
          .then((completed) {
        if (!mounted || completed != true) return;
        _loadBackendData();
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Misi belum siap dari backend. Coba muat ulang.'),
      ),
    );
  }

  Map<String, dynamic> _fallbackBackendData(List<Map<String, dynamic>> worlds) {
    final selected = worlds.first;
    final selectedKey =
        (selected['key'] as String? ?? 'SCIENTIA').toLowerCase();
    final missionTitle =
        selected['exampleMission'] as String? ?? 'Misi belajar pertama';
    return {
      'profile': {
        'name': widget.authController?.user?.name ?? 'Pengguna',
        'rank': 'Pemula',
        'level': 7,
        'foundation': 'FOUNDATION_1',
      },
      'stats': {
        'xp': _gameProfile?.accountXp ?? 0,
        'streak': _gameProfile?.streakCurrent ?? 0,
        'weeklyCompleted': 0,
        'weeklyTarget': 3,
      },
      'selectedWorld': selectedKey,
      'todayMission': {
        'id': 'fallback-$selectedKey',
        'worldKey': selectedKey,
        'title': missionTitle,
        'durationMinutes': 10,
        'activityCount': 10,
        'rewardXp': 25,
      },
      'worlds': worlds,
      'missions': [
        {
          'id': 'fallback-$selectedKey',
          'worldKey': selectedKey,
          'title': missionTitle,
          'description': selected['description'] as String? ?? '',
          'durationMinutes': 10,
          'rewardXp': 25,
          'questionCount': 10,
          'active': true,
        },
      ],
      'learningPath': [
        {
          'step': 1,
          'title': selected['name'] as String? ?? 'Materi awal',
          'completed': false,
          'active': true,
          'locked': false,
          'stars': 0,
        },
      ],
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMusic();
  }

  void _syncMusic() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final audio = AudioScope.maybeOf(context);
      if (audio == null) return;
      final target = _targetMusic;
      if (target == null) {
        _lastRequestedMusic = null;
        audio.stopMusic();
        return;
      }
      if (_lastRequestedMusic == target) return;
      _lastRequestedMusic = target;
      audio.playMusic(target);
    });
  }

  BackgroundMusicId? get _targetMusic {
    if (_tab == BaleTab.profile) return null;
    if (_tab == BaleTab.mission) return BackgroundMusicId.learning;
    return BackgroundMusicId.home;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: _buildBody(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: _tab.index,
        onDestinationSelected: (index) => _goToTab(BaleTab.values[index]),
        indicatorColor: const Color(0xFFFFF3C6),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_rounded),
            label: 'Dunia',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_rounded),
            label: 'Misi',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if ((widget.prototypeStudentProfileId != null ||
            widget.authController?.user != null) &&
        _backendData == null &&
        _backendLoading) {
      return const ColoredBox(
        key: ValueKey('baleverse-backend-loading'),
        color: Color(0xFFFFF3C6),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFF4B400)),
        ),
      );
    }

    if ((widget.prototypeStudentProfileId != null ||
            widget.authController?.user != null) &&
        _backendData == null &&
        _backendError != null) {
      return _BaleVerseErrorScreen(
        key: const ValueKey('baleverse-backend-error'),
        message: _backendError!,
        onRetry: _loadBackendData,
      );
    }

    if (_tab == BaleTab.home) {
      return DashboardScreen(
        key: const ValueKey('dashboard'),
        selectedWorld: _selectedWorld,
        backendData: _backendData,
        realUserName: widget.authController?.user?.name,
        gameProfile: _gameProfile,
        masteryAverage: _masteryAverage,
        onStartMission: _startMission,
      );
    }

    if (_tab == BaleTab.worlds) {
      return WorldsScreen(
        key: const ValueKey('worlds'),
        selectedWorld: _selectedWorld,
        selectedBackendWorldKey: _selectedBackendWorldKey,
        realWorlds: _realWorlds,
        onSelectWorld: (_) {},
      );
    }

    if (_tab == BaleTab.profile) {
      return BaleProfilePage(
        key: const ValueKey('profile'),
        backendData: _backendData,
        realUserName: widget.authController?.user?.name,
        gameProfile: _gameProfile,
        masteryAverage: _masteryAverage,
        onSignOut: widget.authController?.signOut,
      );
    }

    return MissionHubScreen(
      key: const ValueKey('missionHub'),
      backendData: _backendData,
      adaptivePlan: _adaptivePlan,
      onStartMission: _startMission,
    );
  }
}

String _worldDisplayName(String key) => switch (key.toLowerCase()) {
      'numeria' => 'Numeria',
      'kodex' => 'KodeX',
      'detectivia' => 'Detectivia',
      'scientia' => 'Scientia',
      _ => key.isEmpty ? 'Dunia Belajar' : key,
    };

String _worldSubject(String key) => switch (key.toLowerCase()) {
      'numeria' => 'Matematika',
      'kodex' => 'Informatika',
      'detectivia' => 'Observasi dan Analisis Bukti',
      'scientia' => 'Sains',
      _ => 'Belajar',
    };

class _BaleVerseErrorScreen extends StatelessWidget {
  const _BaleVerseErrorScreen({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFF3C6),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/mascot/splash.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Data belum siap',
                  style: TextStyle(
                    color: Color(0xFF3B2318),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF60646F),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF4B400),
                      foregroundColor: const Color(0xFF3B2318),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
