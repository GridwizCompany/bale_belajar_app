import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/change_password_screen.dart';
import '../../../vocab/presentation/vocab_settings_screen.dart';
import '../../data/game_profile_repository.dart';

const _profileBg = Color(0xFFFFF3C6);
const _profileInk = Color(0xFF3B2318);
const _profileYellow = Color(0xFFF4B400);
const _profileGreen = Color(0xFF4CAF50);
const _profileBlue = Color(0xFF2D8CFF);
const _profileMuted = Color(0xFF6F655D);

const _nameKey = 'bale_profile_display_name';
const _avatarKey = 'bale_profile_avatar_asset';
const _defaultAvatar = 'assets/mascot/login.png';
const _avatarOptions = [
  'assets/mascot/login.png',
  'assets/mascot/welcome.png',
  'assets/mascot/kenalan.png',
  'assets/mascot/splash.png',
  'assets/mascot/analisis.png',
];

class BaleProfilePage extends StatefulWidget {
  const BaleProfilePage({
    this.backendData,
    required this.realUserName,
    required this.gameProfile,
    required this.masteryAverage,
    this.onSignOut,
    this.onOpenWorlds,
    this.authService,
    super.key,
  });

  final Map<String, dynamic>? backendData;
  final String? realUserName;
  final GameProfileSummary? gameProfile;
  final double? masteryAverage;
  final VoidCallback? onSignOut;
  final VoidCallback? onOpenWorlds;
  final AuthService? authService;

  @override
  State<BaleProfilePage> createState() => _BaleProfilePageState();
}

class _BaleProfilePageState extends State<BaleProfilePage> {
  String? _localName;
  String _avatarAsset = _defaultAvatar;

  @override
  void initState() {
    super.initState();
    _loadLocalProfile();
  }

  Future<void> _loadLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _localName = prefs.getString(_nameKey);
      _avatarAsset = prefs.getString(_avatarKey) ?? _defaultAvatar;
    });
  }

  Future<void> _saveLocalProfile({
    required String name,
    required String avatar,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
    await prefs.setString(_avatarKey, avatar);
    if (!mounted) return;
    setState(() {
      _localName = name.trim();
      _avatarAsset = avatar;
    });
  }

  String get _displayName {
    final backendProfile =
        widget.backendData?['profile'] as Map<String, dynamic>?;
    final name = _localName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return backendProfile?['name'] as String? ??
        widget.realUserName ??
        'Pengguna';
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 820;
    return Container(
      color: _profileBg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(14, compact ? 10 : 18, 14, 18),
        children: [
          _ProfileHeader(
            name: _displayName,
            avatarAsset: _avatarAsset,
            gameProfile: widget.gameProfile,
            compact: compact,
            onTap: _openProfileEditor,
          ),
          SizedBox(height: compact ? 10 : 14),
          _AccountCard(
            gameProfile: widget.gameProfile,
            compact: compact,
          ),
          SizedBox(height: compact ? 10 : 14),
          _ProPlanCard(
            compact: compact,
            onTap: _showProInfo,
          ),
          SizedBox(height: compact ? 10 : 14),
          _ProfileSection(
            title: 'Pengaturan',
            children: [
              _ProfileMenuTile(
                icon: Icons.edit_rounded,
                title: 'Edit profil',
                subtitle: 'Nama dan avatar',
                color: _profileYellow,
                compact: compact,
                onTap: _openProfileEditor,
              ),
              _ProfileMenuTile(
                icon: Icons.notifications_rounded,
                title: 'Pengingat',
                subtitle: 'Notifikasi dan widget',
                color: _profileBlue,
                compact: compact,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const VocabSettingsScreen(),
                  ),
                ),
              ),
              _ProfileMenuTile(
                icon: Icons.shield_rounded,
                title: 'Keamanan',
                subtitle: 'Ubah kata sandi',
                color: const Color(0xFF0E3A5F),
                compact: compact,
                onTap: _openSecurity,
              ),
            ],
          ),
          if (widget.onSignOut != null) ...[
            const SizedBox(height: 12),
            _LogoutButton(onPressed: _confirmSignOut),
          ],
        ],
      ),
    );
  }

  void _openSecurity() {
    final service = widget.authService;
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Belum bisa dibuka. Coba muat ulang app.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangePasswordScreen(authService: service),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu perlu login lagi untuk lanjut belajar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: _profileYellow,
              foregroundColor: _profileInk,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (shouldSignOut == true) widget.onSignOut?.call();
  }

  Future<void> _showProInfo() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Bale Pro'),
        content: const Text(
          'Bale Pro membuka semua dunia, lock screen kosakata, widget, '
          'notifikasi, dan riwayat belajar lengkap. Harga dan pembayaran '
          'sebaiknya diatur dari website agar bisa berubah tanpa update app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: _profileYellow,
              foregroundColor: _profileInk,
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Future<void> _openProfileEditor() async {
    final controller = TextEditingController(text: _displayName);
    var selectedAvatar = _avatarAsset;
    final result = await showModalBottomSheet<_ProfileEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit profil',
                      style: TextStyle(
                        color: _profileInk,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: const Color(0xFFFFF8E5),
                        child: Image.asset(selectedAvatar, height: 94),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 76,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _avatarOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final avatar = _avatarOptions[index];
                          final selected = avatar == selectedAvatar;
                          return GestureDetector(
                            onTap: () =>
                                setSheetState(() => selectedAvatar = avatar),
                            child: Container(
                              width: 68,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFFFF3C6)
                                    : const Color(0xFFF7F1E9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? _profileYellow
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Image.asset(avatar, fit: BoxFit.contain),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Nama tampilan',
                        prefixIcon: const Icon(Icons.person_rounded),
                        filled: true,
                        fillColor: const Color(0xFFFFFBF0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              final name = controller.text.trim();
                              if (name.isEmpty) return;
                              Navigator.of(context).pop(
                                _ProfileEditResult(name, selectedAvatar),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: _profileYellow,
                              foregroundColor: _profileInk,
                            ),
                            child: const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    controller.dispose();
    if (result == null) return;
    await _saveLocalProfile(name: result.name, avatar: result.avatar);
  }
}

class _ProfileEditResult {
  const _ProfileEditResult(this.name, this.avatar);

  final String name;
  final String avatar;
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.avatarAsset,
    required this.gameProfile,
    required this.compact,
    required this.onTap,
  });

  final String name;
  final String avatarAsset;
  final GameProfileSummary? gameProfile;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: EdgeInsets.all(compact ? 14 : 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: compact ? 40 : 52,
                    backgroundColor: const Color(0xFFFFF8E5),
                    child: Image.asset(
                      avatarAsset,
                      height: compact ? 74 : 96,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _profileYellow,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: _profileInk,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _profileInk,
                        fontSize: compact ? 27 : 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gameProfile == null
                          ? 'Profil belajar'
                          : '${_formatRank(gameProfile!.rank)} - Level ${gameProfile!.accountLevel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _profileMuted,
                        fontSize: compact ? 12 : 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _profileMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.gameProfile,
    required this.compact,
  });

  final GameProfileSummary? gameProfile;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE0A1)),
      ),
      child: Row(
        children: [
          _MiniInfo(
            icon: Icons.workspace_premium_rounded,
            label: 'Level',
            value: '${gameProfile?.accountLevel ?? '-'}',
            color: _profileYellow,
          ),
          const SizedBox(width: 10),
          _MiniInfo(
            icon: Icons.bolt_rounded,
            label: 'XP',
            value: '${gameProfile?.accountXp ?? '-'}',
            color: _profileBlue,
          ),
          const SizedBox(width: 10),
          _MiniInfo(
            icon: Icons.favorite_rounded,
            label: 'Energi',
            value: '${gameProfile?.dayaBale ?? '-'}',
            color: _profileGreen,
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _profileInk,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: _profileMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProPlanCard extends StatelessWidget {
  const _ProPlanCard({
    required this.compact,
    required this.onTap,
  });

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _profileInk,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.all(compact ? 14 : 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _profileYellow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: _profileInk,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bale Free',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Upgrade Pro untuk semua dunia dan fitur pengingat.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFFFE9B0),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: _profileInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE0A1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title,
              style: const TextStyle(
                color: _profileInk,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _profileInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _profileMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _profileMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Keluar'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFB3261E),
          side: const BorderSide(color: Color(0xFFFFC9C5)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

String _formatRank(String rank) {
  final lower = rank.toLowerCase().replaceAll('_', ' ');
  return lower
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
