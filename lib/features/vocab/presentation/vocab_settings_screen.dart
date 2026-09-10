import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

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

class _VocabSettingsScreenState extends State<VocabSettingsScreen> {
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

  @override
  void initState() {
    super.initState();
    _load();
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
    } catch (error) {
      setState(() => _error = 'Gagal memuat pengaturan kosakata: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestPinWidget() async {
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
    await HomeWidget.requestPinWidget(androidName: 'VocabWidgetProvider');
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

  Widget _buildContent(BuildContext context) {
    final setting = _setting!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
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
                OutlinedButton.icon(
                  onPressed: _requestPinWidget,
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
