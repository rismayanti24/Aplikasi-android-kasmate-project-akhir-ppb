import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppb1/data/kas_store.dart';
import 'package:ppb1/data/profil_store.dart';
import 'package:ppb1/models/pengguna.dart';

void main() {
  group('Filter Tagihan yang Sudah Lunas di Tagihan Saya', () {
    test('Tagihan yang sudah berstatus Lunas tidak boleh muncul kembali di tagihanSaya() saat ada tagihan baru', () {
      final tJajanAicha = TagihanKas(
        id: 't_jajan',
        judul: 'jajan aicha',
        total: 25000,
        subtotal: 25000,
        pajak: 0,
        tanggal: '2026-11-19',
        jatuhTempo: DateTime(2026, 11, 25),
        sumberDana: 'Dana pribadi',
        porsiPerOrang: 25000,
        penerimaId: 'u_sasa',
        namaPenerima: 'Sasa',
        items: const [],
      );

      final tAir = TagihanKas(
        id: 't_air',
        judul: 'air',
        total: 70000,
        subtotal: 70000,
        pajak: 0,
        tanggal: '2026-11-20',
        jatuhTempo: DateTime(2026, 11, 26),
        sumberDana: 'Dana pribadi',
        porsiPerOrang: 23333,
        penerimaId: 'u_sasa',
        namaPenerima: 'Sasa',
        items: const [],
      );

      final anggotaRisma = AnggotaKas(
        id: 'u_risma',
        nama: 'Risma',
        noWa: '081234567890',
        tagihan: 23333, // Hanya tersisa tagihan air
        status: StatusBayar.belum,
        avatarColor: const Color(0xFFDBEAFE),
      );

      final anggotaSasa = AnggotaKas(
        id: 'u_sasa',
        nama: 'Sasa',
        noWa: '089876543210',
        tagihan: 0,
        status: StatusBayar.tidakAdaTagihan,
        avatarColor: const Color(0xFFDCFCE7),
      );

      final riwayatLunasJajan = RiwayatPembayaranItem(
        id: 'rp_jajan_1',
        namaAnggota: 'Risma',
        judulTagihan: 'jajan aicha',
        nominal: 25000,
        waktu: '2026-11-19 14:00',
        status: 'Lunas',
        buktiPath: 'u_risma_bukti.jpg',
      );

      final grup = GrupKas(
        id: 'g_kost',
        namaGrup: 'Kost Berkah',
        kodeUndangan: 'KB01',
        tipeGrup: 'patungan',
        bendahara: 'Sasa',
        saldo: 0,
        pemasukan: 0,
        pengeluaran: 95000,
        anggota: [anggotaRisma, anggotaSasa],
        daftarTagihan: [tAir, tJajanAicha],
        daftarKonfirmasi: const [],
        daftarRiwayatPembayaran: [riwayatLunasJajan],
      );

      // Set user yang login adalah Risma
      profilNotifier.value = const Pengguna(id: 'u_risma', nama: 'Risma', noWa: '081234567890', bank: 'DANA', noRekening: '081234567890');
      kasStore.value = KasRootState(aktifGrupId: grup.id, daftarGrup: [grup]);

      // 1. Verifikasi deteksi lunas
      expect(kasStore.isTagihanLunasUntukAnggota(tJajanAicha, anggotaRisma, grup), isTrue);
      expect(kasStore.isTagihanLunasUntukAnggota(tAir, anggotaRisma, grup), isFalse);

      // 2. tagihanSaya() HANYA berisi tagihan 'air', dan 'jajan aicha' TIDAK MUNCUL
      final tagihanSayaList = kasStore.tagihanSaya();
      expect(tagihanSayaList.length, 1);
      expect(tagihanSayaList.first.judul, 'air');
      expect(tagihanSayaList.first.nominal, 23333);
      expect(tagihanSayaList.any((item) => item.judul == 'jajan aicha'), isFalse);
    });
  });
}
