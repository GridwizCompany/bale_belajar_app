import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _notificationCurrentId = 6100;
  static const _notificationScheduledBaseId = 6110;
  static const _maxScheduledNotifications = 24;
  static const _wallpaperChannel = MethodChannel(
    'com.balebelajar.bale_belajar_app/vocab_lock_wallpaper',
  );

  final VocabRepository _repository;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _notificationsInitialized = false;

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
    if (!force && prefs.getString(_prefsDateKey) == today) {
      try {
        await _wallpaperChannel.invokeMethod<bool>('setCurrent');
      } catch (error) {
        if (kDebugMode) {
          debugPrint('VocabSyncService.restoreWallpaper gagal: $error');
        }
      }
      return null;
    }

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
    final wordsJson = _encodeWords(daily);
    try {
      await _updateWidget(daily, wordsJson: wordsJson);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('VocabSyncService._updateWidget gagal: $error');
      }
    }
    try {
      await _updateLockWallpaper(daily, wordsJson: wordsJson);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('VocabSyncService._updateLockWallpaper gagal: $error');
      }
    }
    await _cancelNotifications();
    return daily;
  }

  String _encodeWords(DailyVocab daily) {
    final words = daily.words.where(_isSingleVocabWord);
    return jsonEncode(
      words
          .map((word) => {
                'english': word.english,
                'indonesian': _indonesianMeaning(word),
                'korean': word.korean,
                'koreanRomanized': word.koreanRomanized,
              })
          .toList(),
    );
  }

  bool _isSingleVocabWord(VocabWord word) {
    final english = word.english.trim();
    final korean = word.korean.trim();
    if (english.isEmpty || korean.isEmpty) return false;
    final englishIsOneWord = RegExp(r"^[A-Za-z][A-Za-z'-]*$").hasMatch(english);
    final koreanHasNoSpacing = !RegExp(r'\s').hasMatch(korean);
    return englishIsOneWord && koreanHasNoSpacing;
  }

  Future<void> _updateWidget(
    DailyVocab daily, {
    required String wordsJson,
  }) async {
    final setting = daily.setting;
    final hasWords = _hasEncodedWords(wordsJson);
    await HomeWidget.saveWidgetData<bool>(
      'vocab_widget_enabled',
      setting.widgetEnabled && hasWords,
    );
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

  Future<DailyVocab?> showLockScreenNow() async {
    try {
      final daily = await _repository.fetchDaily();
      final wordsJson = _encodeWords(daily);
      await _updateWidget(daily, wordsJson: wordsJson);
      await _updateLockWallpaper(daily, wordsJson: wordsJson);
      await _cancelNotifications();
      return daily;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('VocabSyncService.showLockScreenNow gagal: $error');
      }
      return null;
    }
  }

  Future<void> _updateLockWallpaper(
    DailyVocab daily, {
    required String wordsJson,
  }) async {
    if (daily.words.isEmpty || !_hasEncodedWords(wordsJson)) {
      await _wallpaperChannel.invokeMethod<bool>('cancelHourly');
      return;
    }
    final changed = await _wallpaperChannel.invokeMethod<bool>(
      'setCurrent',
      {'wordsJson': wordsJson},
    );
    if (changed != true) {
      throw StateError('Wallpaper tidak berubah karena data vocab kosong.');
    }
  }

  bool _hasEncodedWords(String wordsJson) {
    final decoded = jsonDecode(wordsJson);
    return decoded is List && decoded.isNotEmpty;
  }

  Future<void> _cancelNotifications() async {
    try {
      await _ensureNotificationsReady();
      await _notifications.cancel(id: _notificationCurrentId);
      for (var i = 0; i < _maxScheduledNotifications; i++) {
        await _notifications.cancel(id: _notificationScheduledBaseId + i);
      }
    } catch (_) {
      // Notification cleanup is best-effort; wallpaper should keep working.
    }
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
