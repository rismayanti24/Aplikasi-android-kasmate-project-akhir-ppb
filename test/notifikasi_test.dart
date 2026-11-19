import 'package:flutter_test/flutter_test.dart';
import 'package:ppb1/data/kas_store.dart';

void main() {
  group('NotifikasiItem tests (Fase 6.1 - 6.3)', () {
    test('waktuDinamis memformat waktu relatif dengan benar', () {
      final now = DateTime.now();

      // Baru saja (< 1 menit)
      final n1 = NotifikasiItem(
        id: 'n_1',
        judul: 'Tagihan Baru',
        pesan: 'Pesan',
        waktu: 'Baru saja',
        tipe: TipeNotifikasi.tagihanBaru,
        createdAt: now.subtract(const Duration(seconds: 30)),
      );
      expect(n1.waktuDinamis, equals('Baru saja'));

      // 10 menit lalu
      final n2 = NotifikasiItem(
        id: 'n_2',
        judul: 'Tagihan Baru',
        pesan: 'Pesan',
        waktu: 'Baru saja',
        tipe: TipeNotifikasi.tagihanBaru,
        createdAt: now.subtract(const Duration(minutes: 10)),
      );
      expect(n2.waktuDinamis, equals('10 menit lalu'));

      // 3 jam lalu
      final n3 = NotifikasiItem(
        id: 'n_3',
        judul: 'Tagihan Baru',
        pesan: 'Pesan',
        waktu: 'Baru saja',
        tipe: TipeNotifikasi.tagihanBaru,
        createdAt: now.subtract(const Duration(hours: 3)),
      );
      expect(n3.waktuDinamis, equals('3 jam lalu'));

      // Kemarin (1 hari lalu)
      final n4 = NotifikasiItem(
        id: 'n_4',
        judul: 'Tagihan Baru',
        pesan: 'Pesan',
        waktu: 'Baru saja',
        tipe: TipeNotifikasi.tagihanBaru,
        createdAt: now.subtract(const Duration(days: 1)),
      );
      expect(n4.waktuDinamis, equals('Kemarin'));

      // 4 hari lalu
      final n5 = NotifikasiItem(
        id: 'n_5',
        judul: 'Tagihan Baru',
        pesan: 'Pesan',
        waktu: 'Baru saja',
        tipe: TipeNotifikasi.tagihanBaru,
        createdAt: now.subtract(const Duration(days: 4)),
      );
      expect(n5.waktuDinamis, equals('4 hari lalu'));
    });

    test('kelompokWaktuDinamis mengelompokkan timeline dengan benar', () {
      final now = DateTime.now();

      final todayItem = NotifikasiItem(
        id: 'n_today',
        judul: 'Uji Hari Ini',
        pesan: 'Pesan',
        waktu: 'Baru saja',
        tipe: TipeNotifikasi.tagihanBaru,
        createdAt: now,
      );
      expect(todayItem.kelompokWaktuDinamis, equals('Hari ini'));

      final yesterdayItem = NotifikasiItem(
        id: 'n_yesterday',
        judul: 'Uji Kemarin',
        pesan: 'Pesan',
        waktu: 'Baru saja',
        tipe: TipeNotifikasi.tagihanBaru,
        createdAt: now.subtract(const Duration(days: 1)),
      );
      expect(yesterdayItem.kelompokWaktuDinamis, equals('Kemarin'));
    });

    test('NotifikasiItem copyWith preserves new fields', () {
      final now = DateTime.now();
      final n = NotifikasiItem(
        id: 'n_test',
        judul: 'Judul',
        pesan: 'Pesan',
        waktu: 'Baru saja',
        tipe: TipeNotifikasi.buktiPembayaran,
        createdAt: now,
        pengirimUid: 'uid_123',
        isDibaca: false,
      );

      final dibaca = n.copyWith(isDibaca: true);
      expect(dibaca.isDibaca, isTrue);
      expect(dibaca.pengirimUid, equals('uid_123'));
      expect(dibaca.createdAt, equals(now));
    });
  });
}
