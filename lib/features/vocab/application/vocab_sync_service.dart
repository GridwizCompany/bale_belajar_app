import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:home_widget/home_widget.dart';
import 'package:permission_handler/permission_handler.dart';
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
///
/// Izin notifikasi dan pemasangan widget SENGAJA diminta secara aktif (bukan
/// menunggu user membuka halaman setting): begitu sync pertama kali berhasil
/// dan fitur terkait masih ON, OS diminta menampilkan dialog izin/pasang-widget
/// langsung (lihat [_maybeRequestNotificationPermission] & [_maybeRequestPinWidget]).
/// Ini hanya terjadi SEKALI per perangkat (ditandai di SharedPreferences) supaya
/// tidak menyebalkan kalau user sudah menolak - status tetap bisa dicek ulang
/// dan diminta manual lewat [notificationPermissionStatus]/[requestPinWidget]
/// di layar pengaturan.
class VocabSyncService {
  VocabSyncService({VocabRepository? repository})
      : _repository = repository ?? VocabRepository();

  static const _prefsDateKey = 'vocab_sync_date';
  static const _prefsNotifAskedKey = 'vocab_notif_permission_asked';
  static const _prefsWidgetAskedKey = 'vocab_widget_pin_asked';
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
    _notificationsInitialized = true;
  }

  /// Status izin notifikasi OS saat ini - dipakai layar setting untuk
  /// menampilkan banner "belum diizinkan" dengan tombol yang sesuai.
  Future<PermissionStatus> notificationPermissionStatus() =>
      Permission.notification.status;

  /// Minta izin notifikasi lewat dialog OS. Kalau sebelumnya sudah ditolak
  /// permanen ("Jangan tanya lagi"), OS tidak akan menampilkan dialog lagi -
  /// di kondisi itu layar setting harus arahkan user ke [openNotificationSettings].
  Future<PermissionStatus> requestNotificationPermission() =>
      Permission.notification.request();

  Future<bool> openNotificationSettings() => openAppSettings();

  /// Apakah widget kosakata sudah benar-benar ditaruh di home screen (bukan
  /// cuma "tersedia untuk ditaruh").
  Future<bool> isWidgetPinned() async {
    try {
      final widgets = await HomeWidget.getInstalledWidgets();
      return widgets.any(
        (widget) =>
            (widget.androidClassName ?? '').contains(_androidWidgetProvider),
      );
    } catch (_) {
      return false;
    }
  }

  /// Minta OS menampilkan dialog "Tambahkan ke Home Screen" untuk widget
  /// kosakata. Hanya didukung sebagian launcher Android 8+ - layar setting
  /// harus punya fallback instruksi manual kalau [HomeWidget.isRequestPinWidgetSupported]
  /// mengembalikan false.
  Future<void> requestPinWidget() =>
      HomeWidget.requestPinWidget(androidName: _androidWidgetProvider);

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
    await _maybeRequestNotificationPermission(daily, prefs);
    await _updateWidget(daily);
    await _updateNotifications(daily);
    await _maybeRequestPinWidget(daily, prefs);
  }

  /// Begitu kosakata harian pertama kali berhasil disinkronkan dan
  /// notifikasi masih ON, langsung minta izin OS - jangan tunggu user
  /// buka halaman setting duluan. Hanya sekali seumur install.
  Future<void> _maybeRequestNotificationPermission(
    DailyVocab daily,
    SharedPreferences prefs,
  ) async {
    if (!daily.setting.notificationEnabled) return;
    if (prefs.getBool(_prefsNotifAskedKey) == true) return;
    await prefs.setBool(_prefsNotifAskedKey, true);
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  /// Sama seperti notifikasi - begitu widget masih ON dan belum pernah
  /// ditaruh di home screen, langsung tawarkan lewat dialog OS. Hanya
  /// sekali seumur install supaya tidak menyebalkan kalau user menolak.
  Future<void> _maybeRequestPinWidget(
    DailyVocab daily,
    SharedPreferences prefs,
  ) async {
    if (!daily.setting.widgetEnabled) return;
    if (prefs.getBool(_prefsWidgetAskedKey) == true) return;
    await prefs.setBool(_prefsWidgetAskedKey, true);
    if (await isWidgetPinned()) return;
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    if (!supported) return;
    await requestPinWidget();
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
