import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppb1/data/kas_store.dart';
import 'package:ppb1/data/profil_store.dart';
import 'package:ppb1/models/pengguna.dart';
import 'package:ppb1/screens/buat_tagihan_screen.dart';
import 'package:ppb1/utils/hitung_tagihan.dart';

void main() {
  group('Perhitungan penyesuaian tagihan', () {
    test('tanpa penyesuaian, total tetap sama dengan subtotal', () {
      final rincian = RincianTagihan.hitung(subtotal: 100000);
      expect(rincian.total, 100000);
      expect(rincian.pajak, 0);
    });

    test('pajak default lama 10 persen tetap menghasilkan nominal yang sama',
        () {
      final rincian = RincianTagihan.hitung(subtotal: 100000, pajakPersen: 10);
      expect(rincian.pajak, 10000);
      expect(rincian.total, 110000);
    });

    test('diskon mengurangi dasar pajak, layanan ditambah setelah pajak', () {
      final rincian = RincianTagihan.hitung(
        subtotal: 100000,
        diskon: 10000,
        pajakPersen: 11.5,
        biayaLayanan: 5000,
      );
      expect(rincian.pajak, 10350);
      expect(rincian.total, 105350);
    });

    test('pajak nol tidak menghitung pajak dua kali pada struk', () {
      final rincian = RincianTagihan.hitung(
        subtotal: 110000,
        pajakPersen: 0,
        diskon: 10000,
        biayaLayanan: 5000,
      );
      expect(rincian.pajak, 0);
      expect(rincian.total, 105000);
    });

    test('persentase dua desimal dan pembulatan rupiah setengah ke atas', () {
      expect(
        RincianTagihan.hitung(subtotal: 100000, pajakPersen: 7.25).pajak,
        7250,
      );
      expect(RincianTagihan.hitung(subtotal: 1, pajakPersen: 50).pajak, 1);
      expect(RincianTagihan.hitung(subtotal: 1, pajakPersen: 49.99).pajak, 0);
    });

    test('diskon penuh, layanan, dan pajak batas maksimum ditangani', () {
      final diskonPenuh = RincianTagihan.hitung(
        subtotal: 100000,
        diskon: 100000,
        pajakPersen: 10,
        biayaLayanan: 5000,
      );
      expect(diskonPenuh.pajak, 0);
      expect(diskonPenuh.total, 5000);
      expect(RincianTagihan.hitung(subtotal: 100, pajakPersen: 100).total, 200);
    });

    test('menolak diskon berlebih dan semua nominal negatif', () {
      for (final hitung in <RincianTagihan Function()>[
        () => RincianTagihan.hitung(subtotal: -1),
        () => RincianTagihan.hitung(subtotal: 100, diskon: -1),
        () => RincianTagihan.hitung(subtotal: 100, biayaLayanan: -1),
        () => RincianTagihan.hitung(subtotal: 100, diskon: 101),
      ]) {
        expect(hitung, throwsArgumentError);
      }
    });

    test(
        'menolak persen negatif, lebih dari 100, nonfinite, dan presisi berlebih',
        () {
      for (final persen in [
        -1.0,
        100.01,
        double.nan,
        double.infinity,
        10.123
      ]) {
        expect(
          () => RincianTagihan.hitung(subtotal: 100000, pajakPersen: persen),
          throwsArgumentError,
        );
      }
    });

    test('input persen menerima titik/koma dan menolak input tidak valid', () {
      expect(parsePersenPajak('11,5'), 11.5);
      expect(parsePersenPajak('7.25'), 7.25);
      expect(parsePersenPajak(' 10 '), 10);
      expect(parsePersenPajak('0'), 0);
      expect(parsePersenPajak('100,00'), 100);
      for (final input in [
        '',
        'abc',
        '-1',
        '101',
        '1,234',
        'NaN',
        '1e2',
        '10%'
      ]) {
        expect(parsePersenPajak(input), isNull, reason: input);
      }
      expect(formatPersenPajak(0), '0');
      expect(formatPersenPajak(10), '10');
      expect(formatPersenPajak(11.5), '11,5');
      expect(formatPersenPajak(7.25), '7,25');
      expect(formatPersenPajak(100), '100');
    });
  });

  group('Validasi KasStore sebelum mengubah saldo', () {
    const items = [ItemBelanja(id: 'item', nama: 'Belanja', harga: 100000)];
    late KasStore store;

    setUp(() => store = KasStore());
    tearDown(() => store.dispose());

    test('diskon tidak valid tidak mengubah state', () {
      final awal = store.value;
      expect(
        () => store.tambahTagihan(
          judul: 'Belanja',
          sumberDana: 'Kas grup',
          items: items,
          idAnggotaDitagih: [],
          diskon: 100001,
        ),
        throwsArgumentError,
      );
      expect(store.value, same(awal));
    });

    test('total nol tidak dapat dicatat sebagai pengeluaran', () {
      expect(
        () => store.tambahTagihan(
          judul: 'Belanja',
          sumberDana: 'Kas grup',
          items: items,
          idAnggotaDitagih: [],
          diskon: 100000,
        ),
        throwsArgumentError,
      );
    });

    test('pengecekan saldo menggunakan total termasuk biaya layanan', () {
      final grup = store.grupAktif.copyWith(saldo: 110000);
      store.value = KasRootState(aktifGrupId: grup.id, daftarGrup: [grup]);
      final awal = store.value;
      final berhasil = store.tambahTagihan(
        judul: 'Belanja',
        sumberDana: 'Kas grup',
        items: items,
        idAnggotaDitagih: [],
        pakaiPajak: true,
        pajakPersen: 10,
        biayaLayanan: 1000,
      );
      expect(berhasil, isFalse);
      expect(store.value, same(awal));
    });
  });

  testWidgets(
      'form memperbarui pajak, diskon, layanan dan menolak diskon berlebih', (
    tester,
  ) async {
    final stateAwal = kasStore.value;
    final profilAwal = profilNotifier.value;
    addTearDown(() {
      kasStore.value = stateAwal;
      profilNotifier.value = profilAwal;
    });
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    profilNotifier.value = const Pengguna(
      id: 'anggota-test',
      nama: 'Pengguna',
      noWa: '',
      bank: '',
      noRekening: '',
    );
    final anggota = AnggotaKas(
      id: 'anggota-test',
      nama: 'Pengguna',
      noWa: '',
      tagihan: 0,
      status: StatusBayar.lunas,
      avatarColor: Colors.green,
    );
    final grup = kasStore.grupAktif.copyWith(
      saldo: 1000000,
      bendahara: 'Pengguna',
      anggota: [anggota],
    );
    kasStore.value = KasRootState(aktifGrupId: grup.id, daftarGrup: [grup]);
    await tester.pumpWidget(const MaterialApp(home: BuatTagihanScreen()));

    final harga = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        (widget.decoration?.labelText?.startsWith('Nominal') ?? false));
    await tester.ensureVisible(harga);
    await tester.enterText(harga, '100000');
    await tester.ensureVisible(find.text('Tambahkan pajak'));
    await tester.tap(find.text('Tambahkan pajak'));
    await tester.pumpAndSettle();
    expect(find.text('Pajak 10%'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '11,5');
    await tester.enterText(find.byType(TextFormField).at(1), '10000');
    await tester.enterText(find.byType(TextFormField).at(2), '5000');
    await tester.pumpAndSettle();
    expect(find.text('Pajak 11,5%'), findsOneWidget);
    expect(find.text('Rp 10.350'), findsOneWidget);
    final totalRow =
        find.ancestor(of: find.text('Total'), matching: find.byType(Row));
    expect(
      find.descendant(of: totalRow, matching: find.text('Rp 105.350')),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Tambahkan pajak'));
    await tester.tap(find.text('Tambahkan pajak'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: totalRow, matching: find.text('Rp 95.000')),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField).at(0), '200000');
    await tester.pumpAndSettle();
    expect(find.text('Diskon tidak boleh melebihi subtotal'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    final sebelumSimpan = kasStore.value;
    await tester.ensureVisible(find.text('Simpan tagihan'));
    await tester.tap(find.text('Simpan tagihan'));
    await tester.pumpAndSettle();
    expect(kasStore.value, same(sebelumSimpan));
    expect(find.byType(BuatTagihanScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
