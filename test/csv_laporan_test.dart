import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppb1/data/kas_store.dart';

void main() {
  group('generateLaporanCsv (Poin 39)', () {
    setUp(() {
      kasStore.value = KasRootState(
        aktifGrupId: 'grp_csv',
        daftarGrup: [
          GrupKas(
            id: 'grp_csv',
            namaGrup: 'Grup Test CSV',
            kodeUndangan: 'CSV001',
            saldo: 500000,
            pengeluaran: 150000,
            pemasukan: 650000,
            bendahara: 'Bendahara A',
            anggota: const [
              AnggotaKas(
                id: 'u1',
                nama: 'Anggota Satu',
                noWa: '08123456789',
                tagihan: 50000,
                status: StatusBayar.belum,
                avatarColor: Colors.blue,
                bank: 'BCA',
                noRekening: '1234567890',
              ),
              AnggotaKas(
                id: 'u2',
                nama: 'Anggota Dua',
                noWa: '+6281234567890',
                tagihan: 0,
                status: StatusBayar.lunas,
                avatarColor: Colors.green,
              ),
            ],
            daftarTagihan: const [],
            daftarKonfirmasi: const [],
            daftarRiwayatPembayaran: const [],
            daftarNotifikasi: const [],
          ),
        ],
      );
    });

    test('nomor WhatsApp dibungkus ="\'..." agar tidak jadi notasi ilmiah di Excel', () {
      final csv = kasStore.generateLaporanCsv();
      // Nomor lokal harus dibungkus ="'..."
      expect(csv, contains('="\'08123456789"'));
      // Nomor internasional juga dibungkus
      expect(csv, contains('="\'${'+6281234567890'}"'));
    });

    test('delimiter kolom anggota menggunakan titik koma (;)', () {
      final csv = kasStore.generateLaporanCsv();
      // Baris data anggota harus menggunakan ; sebagai separator
      expect(csv, contains('Anggota Satu;'));
    });

    test('nominal rupiah diformat sebagai teks "Rp ..."', () {
      final csv = kasStore.generateLaporanCsv();
      expect(csv, contains('Rp 500000'));
      expect(csv, contains('Rp 150000'));
    });

    test('CSV berisi semua header section', () {
      final csv = kasStore.generateLaporanCsv();
      expect(csv, contains('LAPORAN KEUANGAN KASMATE'));
      expect(csv, contains('STATUS ANGGOTA'));
      expect(csv, contains('RIWAYAT PENGELUARAN'));
      expect(csv, contains('RIWAYAT PEMBAYARAN'));
    });
  });
}
