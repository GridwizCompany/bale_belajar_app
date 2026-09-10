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
    final pinned = await _syncService.isWidgetPinned();
    if (!mounted) return;
    setState(() {
      _notifStatus = status;
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
    final status = await _syncService.requestNotificationPermission();
    if (!mounted) return;
    setState(() => _notifStatus = status);
    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifikasi ditolak permanen. Aktifkan manual lewat Pengaturan.',
          ),
        ),
      );
    }
  }

  Future<void> _handleOpenNotificationSettings() async {
    await _syncService.openNotificationSettings();
  }

  Future<void> _handleAddWidget() async {
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    if (!mounted) return;
    if (!supported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Launcher ini tidak mendukung tambah widget otomatis. '
            'Tambahkan lewat tekan-lama layar utama > Widget > Bale Belajar.',
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
    final showNotifBanner =
        !_checkingPermissions &&
        setting.notificationEnabled &&
        notifStatus != null &&
        !notifStatus.isGranted;
    final showWidgetBanner =
        !_checkingPermissions && setting.widgetEnabled && !_widgetPinned;

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
                max: 20,
                divisions: 19,
                value: setting.dailyCount.toDouble(),
                label: '${setting.dailyCount}',
                onChanged: _saving
                    ? null
                    : (value) => setState(() {
                          _setting = setting.copyWith(dailyCount: value.round());
                        }),
                onChangeEnd: (value) =>
                    _persist(setting.copyWith(dailyCount: value.round())),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _HourDropdown(
                      label: 'Mulai jam',
                      value: setting.notificationStartHour,
                      onChanged: _saving
                          ? null
                          : (hour) => _persist(
                              setting.copyWith(notificationStartHour: hour)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HourDropdown(
                      label: 'Sampai jam',
                      value: setting.notificationEndHour,
                      onChanged: _saving
                          ? null
                          : (hour) => _persist(
                              setting.copyWith(notificationEndHour: hour)),
                    ),
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
              Text('Notifikasi & Widget',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notifikasi harian'),
                subtitle: const Text('Kirim pengingat kosakata di rentang jam di atas'),
                value: setting.notificationEnabled,
                onChanged: _saving
                    ? null
                    : (value) =>
                        _persist(setting.copyWith(notificationEnabled: value)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Widget home-screen'),
                subtitle: const Text('Tampilkan kosakata hari ini di widget Android'),
                value: setting.widgetEnabled,
                onChanged: _saving
                    ? null
                    : (value) => _persist(setting.copyWith(widgetEnabled: value)),
              ),
              if (setting.widgetEnabled) ...[
                const SizedBox(height: 8),
                if (_widgetPinned)
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: BaleColors.success, size: 18),
                      SizedBox(width: 8),
                      Text('Widget sudah terpasang di home screen'),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _handleAddWidget,
                    icon: const Icon(Icons.add_to_home_screen_rounded),
                    label: const Text('Tambahkan Widget ke Home Screen'),
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(word.english,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const Icon(Icons.sync_alt_rounded, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      word.koreanRomanized != null
                          ? '${word.korean} (${word.koreanRomanized})'
                          : word.korean,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
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
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
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
