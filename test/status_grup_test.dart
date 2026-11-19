import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppb1/data/kas_store.dart';

void main() {
  group('Fase 8.4 (Poin 9 & 12) Tipe Grup & Status Tagihan', () {
    test('GrupKas membedakan tipeGrup kasResmi dan patungan', () {
      final grupKas = GrupKas(
        id: 'g1',
        namaGrup: 'Kas Kos 3A',
        kodeUndangan: 'KM26-TEST',
        tipeGrup: 'kasResmi',
        saldo: 100000,
        pengeluaran: 0,
        pemasukan: 100000,
        bendahara: 'Bendahara',
        anggota: const [],
        daftarTagihan: const [],
        daftarKonfirmasi: const [],
        daftarRiwayatPembayaran: const [],
        daftarNotifikasi: const [],
      );
      expect(grupKas.tipeGrup, equals('kasResmi'));

      final grupPatungan = grupKas.copyWith(tipeGrup: 'patungan');
      expect(grupPatungan.tipeGrup, equals('patungan'));
    });

    test('AnggotaKas memiliki StatusBayar.tidakAdaTagihan untuk anggota tanpa utang', () {
      const anggotaBebas = AnggotaKas(
        id: 'u1',
        nama: 'Budi',
        noWa: '08123456789',
        tagihan: 0,
        status: StatusBayar.tidakAdaTagihan,
        avatarColor: Colors.blue,
      );

      const anggotaLunas = AnggotaKas(
        id: 'u2',
        nama: 'Siti',
        noWa: '08123456780',
        tagihan: 0,
        status: StatusBayar.lunas,
        avatarColor: Colors.green,
      );

      expect(anggotaBebas.status, equals(StatusBayar.tidakAdaTagihan));
      expect(anggotaLunas.status, equals(StatusBayar.lunas));
      expect(anggotaBebas.status != anggotaLunas.status, isTrue);
    });

    test('kasStore.buatGrupBaru menyimpan tipeGrup sesuai pilihan (kasResmi / patungan)', () async {
      final grup = await kasStore.buatGrupBaru('Grup Liburan', 'KM26-HOLI', 'patungan');
      expect(grup.tipeGrup, equals('patungan'));
      expect(grup.namaGrup, equals('Grup Liburan'));
    });
  });
}
