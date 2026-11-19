import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/kas_store.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  final ValueNotifier<bool> aktifNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<int> ingatkanHariSebelumNotifier = ValueNotifier<int>(1);

  /// Inisialisasi plugin notifikasi lokal untuk Android & iOS
  Future<void> inisialisasi() async {
    if (_isInitialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // Minta izin Android 13+ (POST_NOTIFICATIONS)
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService inisialisasi notice: $e');
    }
  }

  /// Menampilkan notifikasi instan umum
  Future<void> tampilkanNotifikasi({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!aktifNotifier.value) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        'kasmate_channel_id',
        'KasMate Pengingat & Tagihan',
        channelDescription:
            'Notifikasi pengingat jatuh tempo tagihan dan konfirmasi bukti bayar',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails();

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error tampilkanNotifikasi: $e');
    }
  }

  /// Notifikasi Pengingat Tagihan Belum Lunas
  Future<void> tampilkanPengingatTagihan({
    required String judul,
    required int nominal,
    required String namaPenerima,
  }) async {
    final nominalStr = formatRupiah(nominal);
    await tampilkanNotifikasi(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Pengingat Tagihan: $judul',
      body:
          'Kamu memiliki tagihan $nominalStr kepada $namaPenerima yang belum diselesaikan. Yuk bayar sekarang!',
      payload: 'tagihan',
    );
  }

  /// Notifikasi Bukti Transfer Masuk untuk Bendahara / Penerima
  Future<void> tampilkanNotifikasiBuktiMasuk({
    required String namaPengirim,
    required String judulTagihan,
    required int nominal,
  }) async {
    final nominalStr = formatRupiah(nominal);
    await tampilkanNotifikasi(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Bukti Transfer Masuk',
      body:
          '$namaPengirim baru saja mengunggah bukti bayar $judulTagihan ($nominalStr). Buka untuk konfirmasi.',
      payload: 'konfirmasi',
    );
  }

  /// Notifikasi Hasil Verifikasi Pembayaran (Lunas / Ditolak)
  Future<void> tampilkanNotifikasiVerifikasi({
    required String namaAnggota,
    required String judulTagihan,
    required int nominal,
    required bool diterima,
  }) async {
    final nominalStr = formatRupiah(nominal);
    await tampilkanNotifikasi(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: diterima ? 'Pembayaran Diterima' : 'Pembayaran Ditolak',
      body: diterima
          ? 'Pembayaran $nominalStr dari $namaAnggota untuk "$judulTagihan" telah dikonfirmasi lunas.'
          : 'Bukti pembayaran dari $namaAnggota untuk "$judulTagihan" ditolak.',
      payload: 'verifikasi',
    );
  }

  /// Cek tagihan jatuh tempo dan tampilkan pengingat jika masuk rentang H- (Poin 24 & 37)
  void periksaJatuhTempoTagihan({
    required List<TagihanKas> daftarTagihan,
    required String myNama,
    required String? myId,
    required String? myUid,
  }) {
    if (!aktifNotifier.value) return;
    final hHari = ingatkanHariSebelumNotifier.value;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final t in daftarTagihan) {
      if (t.jatuhTempo == null) continue;
      final jatuhTempoDate =
          DateTime(t.jatuhTempo!.year, t.jatuhTempo!.month, t.jatuhTempo!.day);
      final selisihHari = jatuhTempoDate.difference(today).inDays;

      final isTertagih = (myId != null && t.anggotaDitagihIds.contains(myId)) ||
          (myUid != null && t.anggotaDitagihIds.contains(myUid)) ||
          t.porsiAnggota.containsKey(myId) ||
          t.porsiAnggota.containsKey(myNama);

      if (isTertagih && selisihHari >= 0 && selisihHari <= hHari) {
        final porsi = (myId != null ? t.porsiAnggota[myId] : null) ??
            t.porsiAnggota[myNama] ??
            t.porsiPerOrang;
        if (porsi > 0) {
          final idNotif = 'jt_${t.id}'.hashCode;
          tampilkanNotifikasi(
            id: idNotif,
            title: 'Pengingat Jatuh Tempo (H-$selisihHari)',
            body:
                'Tagihan "${t.judul}" sebesar ${formatRupiah(porsi)} jatuh tempo ${selisihHari == 0 ? "hari ini" : "$selisihHari hari lagi"}. Segera bayar ya!',
            payload: 'jatuh_tempo',
          );
        }
      }
    }
  }

  /// Batalkan semua notifikasi aktif
  Future<void> batalkanSemua() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error batalkanSemua notifikasi: $e');
    }
  }
}

final NotificationService notificationService = NotificationService();
