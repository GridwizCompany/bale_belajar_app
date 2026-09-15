import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../shared/widgets/bale_card.dart';
import '../../../theme/bale_theme.dart';
import '../application/vocab_sync_service.dart';
import '../data/vocab_repository.dart';
import '../domain/vocab_models.dart';

class VocabSettingsScreen extends StatefulWidget {
  const VocabSettingsScreen({
    VocabRepository? repository,
    VocabSyncService? syncService,
    super.key,
  })  : _repository = repository,
        _syncService = syncService;

  final VocabRepository? _repository;
  final VocabSyncService? _syncService;

  @override
  State<VocabSettingsScreen> createState() => _VocabSettingsScreenState();
}

class _VocabSettingsScreenState extends State<VocabSettingsScreen>
    with WidgetsBindingObserver {
  late final VocabRepository _repository =
      widget._repository ?? VocabRepository();
  late final VocabSyncService _syncService =
      widget._syncService ?? VocabSyncService(repository: _repository);

  bool _loading = true;
  bool _saving = false;
  String? _error;

  VocabSetting? _setting;
  List<VocabCategory> _categories = const [];
  List<VocabWord> _todayWords = const [];

  PermissionStatus? _notifStatus;
  bool _widgetPinned = false;
  bool _widgetPinSupported = true;
  bool _checkingPermissions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // User mungkin baru balik dari system settings (izin notifikasi) atau
    // dari home screen (setelah nambah widget) - cek ulang statusnya.
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionStatus();
    }
  }

  Future<void> _refreshPermissionStatus() async {
    setState(() => _checkingPermissions = true);
    final status = await _syncService.notificationPermissionStatus();
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    final pinned = await _syncService.isWidgetPinned();
    if (!mounted) return;
    setState(() {
      _notifStatus = status;
      _widgetPinSupported = supported;
      _widgetPinned = pinned;
      _checkingPermissions = false;
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.fetchSettings(),
        _repository.fetchCategories(),
        _repository.fetchDaily(),
      ]);
      setState(() {
        _setting = results[0] as VocabSetting;
        _categories = results[1] as List<VocabCategory>;
        _todayWords = (results[2] as DailyVocab).words;
      });
      await _refreshPermissionStatus();
    } catch (error) {
      setState(() => _error = 'Gagal memuat pengaturan kosakata: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persist(VocabSetting updated) async {
    final previous = _setting;
    setState(() {
      _setting = updated;
      _saving = true;
    });
    try {
      final saved = await _repository.updateSettings(
        dailyCount: updated.dailyCount,
        displayLanguage: updated.displayLanguage,
        notificationEnabled: updated.notificationEnabled,
        widgetEnabled: updated.widgetEnabled,
        notificationStartHour: updated.notificationStartHour,
        notificationEndHour: updated.notificationEndHour,
        levels: updated.levels,
        categoryKeys: updated.categoryKeys,
      );
      setState(() => _setting = saved);
      await _syncService.syncToday(force: true);
      final daily = await _repository.fetchDaily();
      if (mounted) setState(() => _todayWords = daily.words);
      await _refreshPermissionStatus();
    } catch (error) {
      setState(() => _setting = previous);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan pengaturan: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kosakata Korea')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : _buildContent(context),
    );
  }

  Future<void> _handleEnableNotifications() async {
    if (_notifStatus?.isPermanentlyDenied ?? false) {
      await _syncService.openNotificationSettings();
      return;
    }
    final status = await _syncService.requestNotificationPermission();
    if (!mounted) return;
    if (status.isGranted) {
      await _syncService.showLockScreenNow();
      if (!mounted) return;
    }
    setState(() => _notifStatus = status);
    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifikasi ditolak permanen. Aktifkan manual lewat Pengaturan.',
          ),
        ),
      );
      await _syncService.openNotificationSettings();
    }
  }

  Future<void> _handleOpenNotificationSettings() async {
    await _syncService.openNotificationSettings();
  }

  Future<void> _handleShowLockScreenNow() async {
    final messenger = ScaffoldMessenger.of(context);
    final daily = await _syncService.showLockScreenNow();
    if (!mounted) return;
    if (daily == null || daily.words.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'Belum ada kosakata harian dari backend. Jalankan seed vocab dulu.'),
        ),
      );
      return;
    }
    setState(() => _todayWords = daily.words);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Wallpaper lock screen kosakata sudah dipasang.'),
      ),
    );
  }

  Future<void> _handleAddWidget() async {
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    if (!mounted) return;
    if (!supported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tambahkan manual: tekan lama layar utama > Widget > Bale Belajar.',
          ),
        ),
      );
      return;
    }
    await _syncService.requestPinWidget();
    // Pemasangan widget dikonfirmasi user di dialog OS, bukan langsung -
    // status baru bisa dicek ulang begitu app kembali ke foreground
    // (lihat didChangeAppLifecycleState).
  }

  Widget _buildContent(BuildContext context) {
    final setting = _setting!;
    final notifStatus = _notifStatus;
    final showNotifBanner = !_checkingPermissions &&
        setting.notificationEnabled &&
        notifStatus != null &&
        !notifStatus.isGranted;
    final showWidgetBanner = !_checkingPermissions &&
        setting.widgetEnabled &&
        _widgetPinSupported &&
        !_widgetPinned;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        if (showNotifBanner)
          _PermissionBanner(
            title: 'Notifikasi belum diizinkan',
            message: notifStatus.isPermanentlyDenied
                ? 'Kamu menolak izin notifikasi. Aktifkan manual lewat Pengaturan HP supaya pengingat kosakata harian bisa muncul.'
                : 'Izinkan notifikasi supaya kosakata harian bisa mengingatkanmu lewat notifikasi.',
            actionLabel: notifStatus.isPermanentlyDenied
                ? 'Buka Pengaturan'
                : 'Izinkan Notifikasi',
            onAction: notifStatus.isPermanentlyDenied
                ? _handleOpenNotificationSettings
                : _handleEnableNotifications,
          ),
        if (showWidgetBanner)
          _PermissionBanner(
            title: 'Widget belum ditambahkan',
            message:
                'Tambahkan widget kosakata ke home screen supaya kata hari ini selalu kelihatan tanpa buka app.',
            actionLabel: 'Tambahkan Widget',
            onAction: _handleAddWidget,
          ),
        if (showNotifBanner || showWidgetBanner) const SizedBox(height: 14),
        if (_todayWords.isNotEmpty) _TodayPreviewCard(words: _todayWords),
        const SizedBox(height: 14),
        BaleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Jumlah & Jadwal',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Berapa kosakata baru muncul tiap hari, dan di jam berapa saja notifikasinya dikirim.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text('Kosakata per hari: ${setting.dailyCount}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              Slider(
                min: 1,
                max: 24,
                divisions: 23,
                value: setting.dailyCount.toDouble(),
                label: '${setting.dailyCount}',
                onChanged: _saving
                    ? null
                    : (value) => setState(() {
                          _setting =
                              setting.copyWith(dailyCount: value.round());
                        }),
                onChangeEnd: (value) =>
                    _persist(setting.copyWith(dailyCount: value.round())),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final start = _HourDropdown(
                    label: 'Mulai jam',
                    value: setting.notificationStartHour,
                    onChanged: _saving
                        ? null
                        : (hour) => _persist(
                            setting.copyWith(notificationStartHour: hour)),
                  );
                  final end = _HourDropdown(
                    label: 'Sampai jam',
                    value: setting.notificationEndHour,
                    onChanged: _saving
                        ? null
                        : (hour) => _persist(
                            setting.copyWith(notificationEndHour: hour)),
                  );

                  if (constraints.maxWidth < 360) {
                    return Column(
                      children: [
                        start,
                        const SizedBox(height: 10),
                        end,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: start),
                      const SizedBox(width: 12),
                      Expanded(child: end),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        BaleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tampilan', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final lang in VocabDisplayLanguage.values)
                    ChoiceChip(
                      label: Text(lang.label),
                      selected: setting.displayLanguage == lang,
                      onSelected: _saving || setting.displayLanguage == lang
                          ? null
                          : (_) =>
                              _persist(setting.copyWith(displayLanguage: lang)),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        BaleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Lock Screen & Widget',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              if (_todayWords.isNotEmpty) ...[
                _NotificationWidgetPreview(word: _todayWords.first),
                const SizedBox(height: 10),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Wallpaper lock screen harian'),
                subtitle: const Text(
                    'Pasang kosakata Korea di lock screen dan ganti per jam'),
                value: setting.notificationEnabled,
                onChanged: _saving
                    ? null
                    : (value) =>
                        _persist(setting.copyWith(notificationEnabled: value)),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saving ? null : _handleShowLockScreenNow,
                icon: const Icon(Icons.wallpaper_rounded),
                label: const Text(
                  'Pasang Wallpaper Lock Screen',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Widget home-screen'),
                subtitle:
                    const Text('Tampilkan kosakata hari ini di widget Android'),
                value: setting.widgetEnabled,
                onChanged: _saving
                    ? null
                    : (value) =>
                        _persist(setting.copyWith(widgetEnabled: value)),
              ),
              if (setting.widgetEnabled) ...[
                const SizedBox(height: 8),
                if (_widgetPinned)
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: BaleColors.success, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Widget sudah terpasang di home screen'),
                      ),
                    ],
                  )
                else if (!_widgetPinSupported)
                  const _WidgetManualHint()
                else
                  OutlinedButton.icon(
                    onPressed: _handleAddWidget,
                    icon: const Icon(Icons.add_to_home_screen_rounded),
                    label: const Text(
                      'Tambahkan Widget ke Home Screen',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        BaleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tingkat Kesulitan',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Kosongkan semua untuk memakai semua tingkat.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final level in VocabLevel.values)
                    FilterChip(
                      label: Text(level.label),
                      selected: setting.levels.contains(level),
                      onSelected: _saving
                          ? null
                          : (selected) {
                              final next = [...setting.levels];
                              if (selected) {
                                next.add(level);
                              } else {
                                next.remove(level);
                              }
                              _persist(setting.copyWith(levels: next));
                            },
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        BaleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Kategori Kosakata',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Pilih topik yang mau dipelajari. Kosongkan semua untuk semua topik.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in _categories)
                    FilterChip(
                      label: Text(category.name),
                      selected: setting.categoryKeys.contains(category.key),
                      onSelected: _saving
                          ? null
                          : (selected) {
                              final next = [...setting.categoryKeys];
                              if (selected) {
                                next.add(category.key);
                              } else {
                                next.remove(category.key);
                              }
                              _persist(setting.copyWith(categoryKeys: next));
                            },
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BaleCard(
        color: const Color(0xFFFFF1E0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: BaleColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _WidgetManualHint extends StatelessWidget {
  const _WidgetManualHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BaleColors.success.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.widgets_rounded, color: BaleColors.success, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Launcher HP ini tidak bisa ditambah widget otomatis. '
              'Tekan lama layar utama > Widget > Bale Belajar untuk menambahkannya manual.',
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationWidgetPreview extends StatelessWidget {
  const _NotificationWidgetPreview({required this.word});

  final VocabWord word;

  @override
  Widget build(BuildContext context) {
    final koreanText = word.koreanRomanized != null
        ? '${word.korean} (${word.koreanRomanized})'
        : word.korean;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF7EC), Color(0xFFFFF7D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BaleColors.warning),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BaleColors.warning,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              '한',
              style: TextStyle(
                color: BaleColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preview pengingat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: BaleColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${word.english} ↔ $koreanText',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF5F4A2C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.notifications_active_rounded,
              color: BaleColors.warning),
        ],
      ),
    );
  }
}

class _TodayPreviewCard extends StatelessWidget {
  const _TodayPreviewCard({required this.words});

  final List<VocabWord> words;

  @override
  Widget build(BuildContext context) {
    return BaleCard(
      color: BaleColors.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Kosakata Hari Ini',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final word in words)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final koreanText = word.koreanRomanized != null
                      ? '${word.korean} (${word.koreanRomanized})'
                      : word.korean;

                  if (constraints.maxWidth < 340) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          word.english,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(koreanText),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          word.english,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const Icon(Icons.sync_alt_rounded, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          koreanText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _HourDropdown extends StatelessWidget {
  const _HourDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (var hour = 0; hour < 24; hour++)
          DropdownMenuItem(
            value: hour,
            child: Text('${hour.toString().padLeft(2, '0')}:00'),
          ),
      ],
      onChanged: onChanged == null
          ? null
          : (hour) {
              if (hour != null) onChanged!(hour);
            },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
