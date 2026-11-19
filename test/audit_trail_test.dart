import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppb1/data/kas_store.dart';
import 'package:ppb1/data/profil_store.dart';
import 'package:ppb1/models/pengguna.dart';

void main() {
  group('Fase 6.6 (Poin 3) Audit Trail & Batalkan Transaksi', () {
    test('batalkanTagihan mencatat audit trail dan mengoreksi keuangan', () {
      final store = kasStore;
      profilNotifier.value = const Pengguna(
        id: 'a1',
        nama: 'Bendahara Utama',
        noWa: '081234567890',
        bank: 'BCA',
        noRekening: '12345678',
      );

      final g = GrupKas(
        id: 'g_test_audit',
        namaGrup: 'Grup Audit',
        kodeUndangan: 'AUD123',
        tipeGrup: 'kasResmi',
        bendahara: 'Bendahara Utama',
        bendaharaUid: 'a1',
        saldo: 100000,
        pemasukan: 100000,
        pengeluaran: 50000,
        daftarKonfirmasi: const [],
        daftarRiwayatPembayaran: const [],
        anggota: [
          const AnggotaKas(
            id: 'a1',
            nama: 'Bendahara Utama',
            noWa: '081234567890',
            tagihan: 25000,
            status: StatusBayar.belum,
            avatarColor: Colors.blue,
          ),
          const AnggotaKas(
            id: 'a2',
            nama: 'Anggota Biasa',
            noWa: '081234567891',
            tagihan: 25000,
            status: StatusBayar.belum,
            avatarColor: Colors.green,
          ),
        ],
        daftarTagihan: [
          const TagihanKas(
            id: 't_audit',
            judul: 'Konsumsi Rapat',
            tanggal: '19 Nov 2026',
            sumberDana: 'Kas grup',
            items: [
              ItemBelanja(id: 'i1', nama: 'Snack', harga: 50000),
            ],
            subtotal: 50000,
            pajak: 0,
            total: 50000,
            porsiPerOrang: 25000,
            porsiAnggota: {'a1': 25000, 'a2': 25000},
            penerimaId: 'a1',
            namaPenerima: 'Bendahara Utama',
            anggotaDitagihIds: ['a1', 'a2'],
          ),
        ],
      );

      store.value = KasRootState(aktifGrupId: g.id, daftarGrup: [g]);

      // Batalkan transaksi dengan alasan
      final berhasil = store.batalkanTagihan(
        't_audit',
        alasan: 'Nota belanja salah dari toko',
      );

      expect(berhasil, isTrue);

      final grupUpdate = store.grupAktif;
      // Saldo kas dikembalikan: 100000 + 50000 = 150000
      expect(grupUpdate.saldo, equals(150000));
      expect(grupUpdate.pengeluaran, equals(0));

      // Tagihan anggota terpotong
      final a1 = grupUpdate.anggota.firstWhere((a) => a.id == 'a1');
      final a2 = grupUpdate.anggota.firstWhere((a) => a.id == 'a2');
      expect(a1.tagihan, equals(0));
      expect(a2.tagihan, equals(0));

      // Tagihan terhapus dari daftarTagihan
      expect(grupUpdate.daftarTagihan.any((t) => t.id == 't_audit'), isFalse);

      // Tercatat di daftarRiwayatPembayaran dengan status Dibatalkan dan ada catatan
      final riwayatBatal = grupUpdate.daftarRiwayatPembayaran.firstWhere(
        (r) => r.status == 'Dibatalkan',
      );
      expect(riwayatBatal.catatan, equals('Nota belanja salah dari toko'));
      expect(riwayatBatal.nominal, equals(50000));

      // Tercatat di notifikasi
      expect(
        grupUpdate.daftarNotifikasi.any(
          (n) => n.judul == 'Transaksi Dibatalkan',
        ),
        isTrue,
      );
    });
  });
}
