import 'dart:math';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/widgets/bale_card.dart';
import '../../../theme/bale_theme.dart';
import '../application/vocab_sync_service.dart';
import '../data/vocab_repository.dart';
import '../domain/vocab_models.dart';

const _knownVocabKey = 'known_vocab_word_ids';

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
  DailyVocab? _daily;
  List<VocabCategory> _categories = const [];
  List<VocabWord> _todayWords = const [];
  Set<String> _knownWordIds = {};

  PermissionStatus? _notifStatus;
  bool _widgetPinned = false;
  bool _widgetPinSupported = true;

  List<VocabWord> get _visibleWords =>
      _todayWords.where((word) => !_knownWordIds.contains(word.id)).toList();

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
    if (state == AppLifecycleState.resumed) _refreshPermissionStatus();
  }

  Future<void> _loadKnownWords() async {
    final prefs = await SharedPreferences.getInstance();
    _knownWordIds = (prefs.getStringList(_knownVocabKey) ?? const []).toSet();
  }

  Future<void> _saveKnownWords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_knownVocabKey, _knownWordIds.toList());
  }

  Future<void> _refreshPermissionStatus() async {
    final status = await _syncService.notificationPermissionStatus();
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    final pinned = await _syncService.isWidgetPinned();
    if (!mounted) return;
    setState(() {
      _notifStatus = status;
      _widgetPinSupported = supported;
      _widgetPinned = pinned;
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _loadKnownWords();
      final results = await Future.wait([
        _repository.fetchSettings(),
        _repository.fetchCategories(),
        _repository.fetchDaily(),
      ]);
      final daily = results[2] as DailyVocab;
      if (!mounted) return;
      setState(() {
        _setting = results[0] as VocabSetting;
        _categories = results[1] as List<VocabCategory>;
        _daily = daily;
        _todayWords = daily.words;
      });
      await _syncVisibleWords();
      await _refreshPermissionStatus();
    } catch (error) {
      if (mounted) setState(() => _error = 'Kosakata belum bisa dimuat.');
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
      final daily = await _repository.fetchDaily();
      if (!mounted) return;
      setState(() {
        _setting = saved;
        _daily = daily;
        _todayWords = daily.words;
      });
      await _syncVisibleWords();
      await _refreshPermissionStatus();
    } catch (error) {
      if (mounted) {
        setState(() => _setting = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan belum tersimpan.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _syncVisibleWords() async {
    final daily = _daily;
    if (daily == null) return;
    await _syncService.syncWords(daily, _visibleWords);
  }

  Future<void> _shuffleWords() async {
    final next = [..._todayWords]..shuffle(Random());
    setState(() => _todayWords = next);
    await _syncVisibleWords();
  }

  Future<void> _markKnown(VocabWord word) async {
    setState(() => _knownWordIds = {..._knownWordIds, word.id});
    await _saveKnownWords();
    await _syncVisibleWords();
  }

  Future<void> _resetKnown() async {
    setState(() => _knownWordIds = {});
    await _saveKnownWords();
    await _syncVisibleWords();
  }

  Future<void> _handleEnableNotifications() async {
    if (_notifStatus?.isPermanentlyDenied ?? false) {
      await _syncService.openNotificationSettings();
      return;
    }
    final status = await _syncService.requestNotificationPermission();
    if (!mounted) return;
    setState(() => _notifStatus = status);
    if (status.isPermanentlyDenied) {
      await _syncService.openNotificationSettings();
    }
  }

  Future<void> _handleAddWidget() async {
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    if (!mounted) return;
    if (!supported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tekan lama layar utama > Widget > Bale Belajar.'),
        ),
      );
      return;
    }
    await _syncService.requestPinWidget();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaleColors.soft,
      appBar: AppBar(title: const Text('Pengingat Kosakata')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final setting = _setting!;
    final visibleWords = _visibleWords;
    final primaryWord = visibleWords.isEmpty ? null : visibleWords.first;
    final notifAllowed = _notifStatus?.isGranted ?? false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _HeroVocabCard(
          word: primaryWord,
          knownCount: _knownWordIds.length,
          onShuffle: _shuffleWords,
          onKnown: primaryWord == null ? null : () => _markKnown(primaryWord),
          onReset: _resetKnown,
        ),
        const SizedBox(height: 14),
        BaleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingSwitch(
                icon: Icons.notifications_active_rounded,
                title: 'Muncul di lock screen',
                subtitle: notifAllowed
                    ? 'Aktif, kata berganti otomatis.'
                    : 'Butuh izin notifikasi.',
                value: setting.notificationEnabled,
                onChanged: _saving
                    ? null
                    : (value) async {
                        await _persist(
                          setting.copyWith(notificationEnabled: value),
                        );
                        if (value && !notifAllowed) {
                          await _handleEnableNotifications();
                        }
                      },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _HourDropdown(
                      label: 'Mulai',
                      value: setting.notificationStartHour,
                      onChanged: _saving
                          ? null
                          : (hour) => _persist(
                                setting.copyWith(
                                  notificationStartHour: hour,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HourDropdown(
                      label: 'Sampai',
                      value: setting.notificationEndHour,
                      onChanged: _saving
                          ? null
                          : (hour) => _persist(
                                setting.copyWith(notificationEndHour: hour),
                              ),
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
              _SettingSwitch(
                icon: Icons.widgets_rounded,
                title: 'Widget home screen',
                subtitle: _widgetPinned
                    ? 'Sudah terpasang.'
                    : 'Tampilkan kata tanpa buka app.',
                value: setting.widgetEnabled,
                onChanged: _saving
                    ? null
                    : (value) =>
                        _persist(setting.copyWith(widgetEnabled: value)),
              ),
              if (setting.widgetEnabled && !_widgetPinned) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _widgetPinSupported ? _handleAddWidget : null,
                  icon: const Icon(Icons.add_to_home_screen_rounded),
                  label: Text(
                    _widgetPinSupported
                        ? 'Tambahkan widget'
                        : 'Tambah manual dari home screen',
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
              Row(
                children: [
                  const Icon(Icons.tune_rounded, color: BaleColors.warning),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Materi kosakata',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _openMaterialSheet,
                    child: const Text('Atur'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${setting.dailyCount} kata per hari - ${_levelSummary(setting)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (visibleWords.length > 1) ...[
          const SizedBox(height: 14),
          _SmallWordList(
            words: visibleWords.skip(1).take(5).toList(),
            onKnown: _markKnown,
          ),
        ],
      ],
    );
  }

  Future<void> _openMaterialSheet() async {
    final base = _setting!;
    var dailyCount = base.dailyCount;
    var levels = [...base.levels];
    var categories = [...base.categoryKeys];

    final sheetMaxHeight = MediaQuery.sizeOf(context).height * 0.82;
    final topicMaxHeight = MediaQuery.sizeOf(context).height * 0.24;

    final updated = await showModalBottomSheet<VocabSetting>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            constraints: BoxConstraints(maxHeight: sheetMaxHeight),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Materi kosakata',
                    style: TextStyle(
                      color: BaleColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Kata per hari: $dailyCount'),
                  Slider(
                    min: 1,
                    max: 12,
                    divisions: 11,
                    value: dailyCount.toDouble(),
                    label: '$dailyCount',
                    onChanged: (value) =>
                        setSheetState(() => dailyCount = value.round()),
                  ),
                  const SizedBox(height: 8),
                  const Text('Level'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final level in VocabLevel.values)
                        FilterChip(
                          label: Text(level.label),
                          selected: levels.contains(level),
                          onSelected: (selected) {
                            setSheetState(() {
                              levels = [...levels];
                              if (selected) {
                                if (!levels.contains(level)) levels.add(level);
                              } else {
                                levels.remove(level);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Topik'),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: topicMaxHeight),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final category in _categories)
                            FilterChip(
                              label: Text(category.name),
                              selected: categories.contains(category.key),
                              onSelected: (selected) {
                                setSheetState(() {
                                  categories = [...categories];
                                  if (selected) {
                                    if (!categories.contains(category.key)) {
                                      categories.add(category.key);
                                    }
                                  } else {
                                    categories.remove(category.key);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      base.copyWith(
                        dailyCount: dailyCount,
                        levels: levels,
                        categoryKeys: categories,
                      ),
                    ),
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (updated != null) await _persist(updated);
  }

  String _levelSummary(VocabSetting setting) {
    if (setting.levels.isEmpty) return 'semua level';
    return setting.levels.map((level) => level.label).join(', ');
  }
}

class _HeroVocabCard extends StatelessWidget {
  const _HeroVocabCard({
    required this.word,
    required this.knownCount,
    required this.onShuffle,
    required this.onKnown,
    required this.onReset,
  });

  final VocabWord? word;
  final int knownCount;
  final VoidCallback onShuffle;
  final VoidCallback? onKnown;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final item = word;
    return BaleCard(
      color: const Color(0xFFFFFBF0),
      child: item == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: BaleColors.success, size: 46),
                const SizedBox(height: 8),
                const Text(
                  'Semua kata hari ini sudah kamu tahu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onReset,
                  child: const Text('Tampilkan lagi'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
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
                        'K',
                        style: TextStyle(
                          color: BaleColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        knownCount == 0
                            ? 'Kata hari ini'
                            : '$knownCount kata disembunyikan',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  item.korean,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: BaleColors.ink,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (item.koreanRomanized?.isNotEmpty ?? false)
                  Text(
                    item.koreanRomanized!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6F655D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '${item.english} - ${item.indonesian ?? item.english}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: BaleColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShuffle,
                        icon: const Icon(Icons.shuffle_rounded),
                        label: const Text('Acak'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onKnown,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Sudah tahu'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SmallWordList extends StatelessWidget {
  const _SmallWordList({required this.words, required this.onKnown});

  final List<VocabWord> words;
  final ValueChanged<VocabWord> onKnown;

  @override
  Widget build(BuildContext context) {
    return BaleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Berikutnya',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (final word in words)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(word.korean),
              subtitle:
                  Text('${word.english} - ${word.indonesian ?? word.english}'),
              trailing: IconButton(
                tooltip: 'Sudah tahu',
                onPressed: () => onKnown(word),
                icon: const Icon(Icons.check_circle_outline_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: BaleColors.warning),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
