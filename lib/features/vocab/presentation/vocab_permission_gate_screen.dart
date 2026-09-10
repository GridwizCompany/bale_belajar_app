import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../shared/widgets/bale_card.dart';
import '../../../theme/bale_theme.dart';
import '../application/vocab_sync_service.dart';

/// Layar wajib-lihat yang muncul begitu user mencapai status signedIn -
/// baik login BARU maupun yang SUDAH punya akun/sesi tersimpan - selama izin
/// notifikasi belum diberikan atau widget kosakata belum ditaruh di home
/// screen. Begitu layar ini terbuka, dialog izin OS langsung dipicu otomatis
/// (tidak menunggu user menekan tombol dulu) - lihat [_autoRequestOnOpen].
///
/// Android/iOS tidak mengizinkan aplikasi benar-benar memaksa user memberi
/// izin (mereka selalu bisa menolak di dialog OS), jadi "paksa" di sini
/// berarti: selalu tampil lagi tiap kali user sampai di halaman utama sampai
/// izin diberikan ATAU widget ditaruh - bukan cuma sekali seumur hidup app.
/// Tombol "Lewati" tetap disediakan (Play Store melarang mengunci akses app
/// di balik izin opsional seperti notifikasi), tapi kecil dan di bawah.
class VocabPermissionGateScreen extends StatefulWidget {
  const VocabPermissionGateScreen({
    required this.onContinue,
    required this.needsNotification,
    required this.needsWidget,
    VocabSyncService? syncService,
    super.key,
  }) : _syncService = syncService;

  final VoidCallback onContinue;
  final bool needsNotification;
  final bool needsWidget;
  final VocabSyncService? _syncService;

  @override
  State<VocabPermissionGateScreen> createState() =>
      _VocabPermissionGateScreenState();
}

class _VocabPermissionGateScreenState extends State<VocabPermissionGateScreen>
    with WidgetsBindingObserver {
  late final VocabSyncService _syncService =
      widget._syncService ?? VocabSyncService();

  PermissionStatus? _notifStatus;
  bool _widgetPinned = false;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autoRequestOnOpen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // User mungkin baru balik dari Pengaturan HP (izin) atau dari home
    // screen (setelah nambah widget) - cek ulang statusnya.
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _autoRequestOnOpen() async {
    PermissionStatus? requestedNotificationStatus;
    if (widget.needsNotification) {
      requestedNotificationStatus =
          await _syncService.requestNotificationPermission();
    }
    if (widget.needsWidget) {
      final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
      if (supported && !(await _syncService.isWidgetPinned())) {
        await _syncService.requestPinWidget();
      }
    }
    if (requestedNotificationStatus?.isGranted ?? false) {
      await _syncService.syncToday(force: true);
    }
    await _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final status = await _syncService.notificationPermissionStatus();
    final pinned = await _syncService.isWidgetPinned();
    if (!mounted) return;
    setState(() {
      _notifStatus = status;
      _widgetPinned = pinned;
      _busy = false;
    });
  }

  Future<void> _handleEnableNotifications() async {
    setState(() => _busy = true);
    final status = await _syncService.requestNotificationPermission();
    if (!mounted) return;
    if (status.isGranted) {
      await _syncService.syncToday(force: true);
      if (!mounted) return;
    }
    setState(() {
      _notifStatus = status;
      _busy = false;
    });
    if (status.isPermanentlyDenied) {
      await _syncService.openNotificationSettings();
    }
  }

  Future<void> _handleContinuePressed({required bool skipping}) async {
    if (!skipping) {
      widget.onContinue();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lewati dulu?'),
        content: const Text(
          'Tanpa izin notifikasi/widget, kamu tidak akan diingatkan kosakata '
          'harian secara otomatis. Kamu tetap bisa mengaktifkannya nanti '
          'lewat Profil > Kosakata Korea.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Lewati'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onContinue();
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
  }

  @override
  Widget build(BuildContext context) {
    final notifStatus = _notifStatus;
    final notifGranted = notifStatus?.isGranted ?? false;
    final notifSatisfied = !widget.needsNotification || notifGranted;
    final widgetSatisfied = !widget.needsWidget || _widgetPinned;

    return Scaffold(
      backgroundColor: BaleColors.soft,
      body: SafeArea(
        child: _busy && notifStatus == null
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 44,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(Icons.notifications_active_rounded,
                                size: 56, color: BaleColors.warning),
                            const SizedBox(height: 16),
                            Text(
                              'Aktifkan Pengingat Kosakata Korea',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Supaya kosakata Inggris-Korea harianmu muncul lewat '
                              'notifikasi dan widget di home screen, izinkan dua hal '
                              'berikut ini.',
                            ),
                            const SizedBox(height: 20),
                            if (widget.needsNotification)
                              _GateItem(
                                icon: Icons.notifications_rounded,
                                title: 'Izin Notifikasi',
                                satisfied: notifSatisfied,
                                actionLabel:
                                    (notifStatus?.isPermanentlyDenied ?? false)
                                        ? 'Buka Pengaturan'
                                        : 'Izinkan',
                                onAction: _handleEnableNotifications,
                              ),
                            if (widget.needsNotification && widget.needsWidget)
                              const SizedBox(height: 10),
                            if (widget.needsWidget)
                              _GateItem(
                                icon: Icons.add_to_home_screen_rounded,
                                title: 'Widget di Home Screen',
                                satisfied: widgetSatisfied,
                                actionLabel: 'Tambahkan',
                                onAction: _handleAddWidget,
                              ),
                            const Spacer(),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: () => _handleContinuePressed(
                                skipping: !(notifSatisfied && widgetSatisfied),
                              ),
                              child: Text(
                                notifSatisfied && widgetSatisfied
                                    ? 'Lanjutkan'
                                    : 'Lewati untuk sekarang',
                              ),
                            ),
                            if (!(notifSatisfied && widgetSatisfied)) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'Kamu tetap bisa mengaktifkannya nanti lewat Profil > Kosakata Korea.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _GateItem extends StatelessWidget {
  const _GateItem({
    required this.icon,
    required this.title,
    required this.satisfied,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final bool satisfied;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return BaleCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 330;
          final status = satisfied
              ? const Icon(Icons.check_circle_rounded,
                  color: BaleColors.success)
              : OutlinedButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel,
                    overflow: TextOverflow.ellipsis,
                  ),
                );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(icon, color: BaleColors.ink),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: status),
              ],
            );
          }

          return Row(
            children: [
              Icon(icon, color: BaleColors.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                  child:
                      Align(alignment: Alignment.centerRight, child: status)),
            ],
          );
        },
      ),
    );
  }
}
