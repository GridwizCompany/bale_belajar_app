import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/vocab_repository.dart';
import '../domain/vocab_models.dart';

/// Menyinkronkan kosakata hari ini ke notifikasi lokal + widget home-screen
/// Android. Tidak ada infrastruktur background-fetch (WorkManager/dsb) di sini
/// - sinkronisasi berjalan tiap kali [syncToday] dipanggil (saat app dibuka/
/// resume, setelah login, dan setelah pengaturan diubah). Jadi notifikasi dan
/// widget menampilkan kosakata "sampai hari terakhir app dibuka", bukan
/// benar-benar refresh sendiri di tengah malam kalau app tidak pernah dibuka
/// hari itu.
class VocabSyncService {
  VocabSyncService({VocabRepository? repository})
      : _repository = repository ?? VocabRepository();

  static const _prefsDateKey = 'vocab_sync_date';
  static const _androidWidgetProvider = 'VocabWidgetProvider';
  static const _notificationChannelId = 'vocab_daily';
  static const _notificationBaseId = 6100;
  static const _maxScheduledNotifications = 20;

  final VocabRepository _repository;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _timezoneReady = false;
  bool _notificationsInitialized = false;

  Future<void> _ensureTimezoneReady() async {
    if (_timezoneReady) return;
    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      // Fallback aman kalau device timezone tidak dikenali tzdata.
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }
    _timezoneReady = true;
  }

  Future<void> _ensureNotificationsReady() async {
    if (_notificationsInitialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _notifications.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _notificationsInitialized = true;
  }

  /// Panggil setelah user login dan setiap kali app kembali ke foreground.
  /// [force] = true dipakai setelah pengaturan diubah supaya sinkronisasi
  /// tidak menunggu hari berganti dulu.
  Future<void> syncToday({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (!force && prefs.getString(_prefsDateKey) == today) return;

    DailyVocab daily;
    try {
      daily = await _repository.fetchDaily();
    } catch (error) {
      if (kDebugMode) debugPrint('VocabSyncService.syncToday gagal: $error');
      return;
    }

    await prefs.setString(_prefsDateKey, today);
    await _updateWidget(daily);
    await _updateNotifications(daily);
  }

  Future<void> _updateWidget(DailyVocab daily) async {
    final setting = daily.setting;
    if (!setting.widgetEnabled || daily.words.isEmpty) {
      await HomeWidget.saveWidgetData<bool>('vocab_widget_enabled', false);
      await HomeWidget.updateWidget(androidName: _androidWidgetProvider);
      return;
    }

    final wordsJson = jsonEncode(
      daily.words
          .map((word) => {
                'english': word.english,
                'korean': word.korean,
                'koreanRomanized': word.koreanRomanized,
              })
          .toList(),
    );

    await HomeWidget.saveWidgetData<bool>('vocab_widget_enabled', true);
    await HomeWidget.saveWidgetData<String>(
      'vocab_display_language',
      setting.displayLanguage.apiValue,
    );
    await HomeWidget.saveWidgetData<String>('vocab_words_json', wordsJson);
    // Index kata yang lagi ditampilkan widget; provider Android memutar maju
    // index ini tiap kali pengguna tap widget (lihat VocabWidgetProvider.kt).
    await HomeWidget.saveWidgetData<int>('vocab_word_index', 0);
    await HomeWidget.updateWidget(androidName: _androidWidgetProvider);
  }

  Future<void> _updateNotifications(DailyVocab daily) async {
    await _ensureTimezoneReady();
    await _ensureNotificationsReady();

    for (var i = 0; i < _maxScheduledNotifications; i++) {
      await _notifications.cancel(id: _notificationBaseId + i);
    }

    final setting = daily.setting;
    if (!setting.notificationEnabled || daily.words.isEmpty) return;

    final words = daily.words.take(_maxScheduledNotifications).toList();
    final now = tz.TZDateTime.now(tz.local);
    final startHour = setting.notificationStartHour;
    final endHour = setting.notificationEndHour;
    final spanMinutes = ((endHour - startHour).clamp(1, 24)) * 60;
    final slotMinutes = spanMinutes / words.length;

    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, startHour)
          .add(Duration(minutes: (slotMinutes * i).round()));
      if (!scheduled.isAfter(now)) {
        // Slot hari ini sudah lewat (mis. baru sync jam 3 sore) - tetap
        // tampilkan, dijadwalkan beberapa menit dari sekarang.
        scheduled = now.add(Duration(minutes: 2 + i * 3));
      }

      await _notifications.zonedSchedule(
        id: _notificationBaseId + i,
        scheduledDate: scheduled,
        title: 'Kosakata Korea Hari Ini',
        body: _notificationBody(word, setting.displayLanguage),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _notificationChannelId,
            'Kosakata Harian',
            channelDescription: 'Notifikasi kosakata Inggris-Korea harian',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  String _notificationBody(VocabWord word, VocabDisplayLanguage lang) {
    final romanized =
        word.koreanRomanized != null ? ' (${word.koreanRomanized})' : '';
    return switch (lang) {
      VocabDisplayLanguage.enToKo => '${word.english} = ${word.korean}$romanized',
      VocabDisplayLanguage.koToEn => '${word.korean}$romanized = ${word.english}',
      VocabDisplayLanguage.both => '${word.english} ↔ ${word.korean}$romanized',
    };
  }
}
