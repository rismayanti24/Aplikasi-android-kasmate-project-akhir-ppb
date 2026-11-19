import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppb1/data/kas_store.dart';
import 'package:ppb1/data/profil_store.dart';
import 'package:ppb1/models/pengguna.dart';

void main() {
  group('Sinkronisasi Pengeluaran Patungan & Proteksi Reminder WA', () {
    test('Grup patungan menghitung total pengeluaran dinamis dari daftarTagihan jika pengeluaran disimpan 0', () {
      final tagihan1 = TagihanKas(
        id: 't1',
        judul: 'Dapur',
        total: 25000,
        subtotal: 25000,
        pajak: 0,
        tanggal: '2026-11-20',
        jatuhTempo: DateTime(2026, 11, 25),
        sumberDana: 'Dana pribadi',
        porsiPerOrang: 25000,
        penerimaId: 'p1',
        namaPenerima: 'Penerima',
        items: const [],
      );

      final grup = GrupKas(
        id: 'g_patungan_1',
        namaGrup: 'Patungan Makan',
        kodeUndangan: 'PTG1',
        tipeGrup: 'patungan',
        bendahara: 'Risma',
        saldo: 0,
        pemasukan: 0,
        pengeluaran: 0, // Nilai default 0 dari Firestore lama
        anggota: const [],
        daftarTagihan: [tagihan1],
        daftarKonfirmasi: const [],
        daftarRiwayatPembayaran: const [],
      );

      // Getter pengeluaran otomatis mengembalikan total tagihan (25.000)
      expect(grup.pengeluaran, 25000);
    });

    test('isCurrentUser mendeteksi profil pengguna yang sedang login', () {
      final anggotaSaya = AnggotaKas(
        id: 'a1',
        nama: 'Risma',
        noWa: '081234567890',
        tagihan: 25000,
        status: StatusBayar.belum,
        avatarColor: const Color(0xFFDBEAFE),
      );

      final anggotaLain = AnggotaKas(
        id: 'a2',
        nama: 'Sasa',
        noWa: '089876543210',
        tagihan: 0,
        status: StatusBayar.tidakAdaTagihan,
        avatarColor: const Color(0xFFDBEAFE),
      );

      profilNotifier.value = const Pengguna(id: 'u1', nama: 'Risma', noWa: '081234567890', bank: 'BCA', noRekening: '123456');

      expect(kasStore.isCurrentUser(anggotaSaya), isTrue);
      expect(kasStore.isCurrentUser(anggotaLain), isFalse);
    });

    test('kirimTagihanWhatsApp mengembalikan false jika target adalah diri sendiri', () async {
      profilNotifier.value = const Pengguna(id: 'u1', nama: 'Risma', noWa: '081234567890', bank: 'BCA', noRekening: '123456');
      final anggotaSaya = AnggotaKas(
        id: 'a1',
        nama: 'Risma',
        noWa: '081234567890',
        tagihan: 25000,
        status: StatusBayar.belum,
        avatarColor: const Color(0xFFDBEAFE),
      );

      final berhasil = await kasStore.kirimTagihanWhatsApp(anggotaSaya);
      expect(berhasil, isFalse);
    });
  });
}
