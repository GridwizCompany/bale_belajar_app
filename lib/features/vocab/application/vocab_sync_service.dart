import 'dart:convert';
import 'dart:ui';

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
/// Izin notifikasi dan pemasangan widget diminta secara aktif lewat
/// `VocabPermissionGateScreen` (lihat `auth_gate.dart`) - layar wajib-lihat
/// yang muncul setiap kali user mencapai status signedIn (login BARU maupun
/// yang SUDAH punya akun/sesi tersimpan) selama izin notifikasi belum
/// diberikan atau widget belum ditaruh di home screen. Method di kelas ini
/// (`requestNotificationPermission`, `requestPinWidget`, dst) dipanggil dari
/// sana, bukan otomatis di dalam [syncToday] - supaya alurnya deterministik
/// (satu tempat yang memicu dialog OS) dan tidak dobel-minta.
class VocabSyncService {
  VocabSyncService({VocabRepository? repository})
      : _repository = repository ?? VocabRepository();

  static const _prefsDateKey = 'vocab_sync_date';
  static const _androidWidgetProvider = 'VocabWidgetProvider';
  static const _notificationChannelId = 'vocab_lock_screen';
  static const _notificationCurrentId = 6100;
  static const _notificationScheduledBaseId = 6110;
  static const _maxScheduledNotifications = 24;

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
      settings:
          const InitializationSettings(android: androidInit, iOS: iosInit),
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
  /// tidak menunggu hari berganti dulu. Mengembalikan `null` kalau fetch ke
  /// backend gagal (mis. offline) - dipakai `auth_gate.dart` untuk tahu
  /// setting notifikasi/widget terbaru saat memutuskan perlu menampilkan
  /// `VocabPermissionGateScreen` atau tidak.
  Future<DailyVocab?> syncToday({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (!force && prefs.getString(_prefsDateKey) == today) return null;

    DailyVocab daily;
    try {
      daily = await _repository.fetchDaily();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('VocabSyncService.syncToday gagal: $error');
      }
      return null;
    }

    await prefs.setString(_prefsDateKey, today);
    try {
      await _updateWidget(daily);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('VocabSyncService._updateWidget gagal: $error');
      }
    }
    try {
      await _updateNotifications(daily);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('VocabSyncService._updateNotifications gagal: $error');
      }
    }
    return daily;
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
                'indonesian': _indonesianMeaning(word),
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

    await _notifications.cancel(id: _notificationCurrentId);
    for (var i = 0; i < _maxScheduledNotifications; i++) {
      await _notifications.cancel(id: _notificationScheduledBaseId + i);
    }

    final setting = daily.setting;
    if (!setting.notificationEnabled || daily.words.isEmpty) return;

    final words = daily.words.take(_maxScheduledNotifications).toList();
    final now = tz.TZDateTime.now(tz.local);
    final currentWord = words.first;

    await _notifications.show(
      id: _notificationCurrentId,
      title: currentWord.korean,
      body: _lockScreenBody(currentWord),
      notificationDetails: _lockScreenNotificationDetails(currentWord),
      payload: currentWord.id,
    );

    final slots = _upcomingHourlySlots(
      now: now,
      startHour: setting.notificationStartHour,
      endHour: setting.notificationEndHour,
      maxSlots: words.length - 1,
    );

    for (var i = 0; i < slots.length; i++) {
      final word = words[i + 1];
      await _notifications.zonedSchedule(
        id: _notificationScheduledBaseId + i,
        scheduledDate: slots[i],
        title: word.korean,
        body: _lockScreenBody(word),
        notificationDetails: _lockScreenNotificationDetails(word),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: word.id,
      );
    }
  }

  NotificationDetails _lockScreenNotificationDetails(VocabWord word) {
    final body = _lockScreenBody(word);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _notificationChannelId,
        'Kosakata Lock Screen',
        channelDescription:
            'Kosakata Korea yang tampil di lock screen dan berubah tiap jam',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        autoCancel: false,
        channelShowBadge: false,
        onlyAlertOnce: true,
        showWhen: false,
        timeoutAfter: const Duration(minutes: 65).inMilliseconds,
        color: const Color(0xFFF4B400),
        ticker: word.korean,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: word.korean,
          summaryText: 'BaleBelajar Korea',
        ),
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  List<tz.TZDateTime> _upcomingHourlySlots({
    required tz.TZDateTime now,
    required int startHour,
    required int endHour,
    required int maxSlots,
  }) {
    final normalizedEnd = endHour <= startHour ? startHour + 1 : endHour;
    var cursor = tz.TZDateTime(tz.local, now.year, now.month, now.day, now.hour)
        .add(const Duration(hours: 1));
    final firstAllowed =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, startHour);
    final lastAllowed =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, normalizedEnd);
    if (cursor.isBefore(firstAllowed)) cursor = firstAllowed;

    final slots = <tz.TZDateTime>[];
    while (cursor.isBefore(lastAllowed) && slots.length < maxSlots) {
      slots.add(cursor);
      cursor = cursor.add(const Duration(hours: 1));
    }
    return slots;
  }

  String _lockScreenBody(VocabWord word) {
    final romanized =
        word.koreanRomanized != null ? '(${word.koreanRomanized})' : '';
    return [
      if (romanized.isNotEmpty) romanized,
      'EN: ${word.english}',
      'ID: ${_indonesianMeaning(word)}',
    ].join('\n');
  }

  String _indonesianMeaning(VocabWord word) {
    final provided = word.indonesian?.trim();
    if (provided != null && provided.isNotEmpty) return provided;
    return _fallbackIndonesian[word.english.toLowerCase()] ?? word.english;
  }
}

const _fallbackIndonesian = <String, String>{
  'hello': 'halo',
  'goodbye': 'selamat tinggal',
  'thank you': 'terima kasih',
  'sorry': 'maaf',
  'yes': 'ya',
  'no': 'tidak',
  'please': 'tolong',
  'water': 'air',
  'house': 'rumah',
  'room': 'ruangan',
  'friend': 'teman',
  'food': 'makanan',
  'restaurant': 'restoran',
  'school': 'sekolah',
  'teacher': 'guru',
  'student': 'siswa',
  'book': 'buku',
  'family': 'keluarga',
  'mother': 'ibu',
  'father': 'ayah',
  'train': 'kereta',
  'bus': 'bus',
  'taxi': 'taksi',
  'hotel': 'hotel',
  'hospital': 'rumah sakit',
  'doctor': 'dokter',
  'computer': 'komputer',
  'screen': 'layar',
  'culture': 'budaya',
  'history': 'sejarah',
  'problem': 'masalah',
  'solution': 'solusi',
};
