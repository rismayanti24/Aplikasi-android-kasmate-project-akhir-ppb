import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppb1/data/kas_store.dart';
import 'package:ppb1/data/profil_store.dart';
import 'package:ppb1/models/pengguna.dart';
import 'package:ppb1/screens/bayar_tagihan_screen.dart';
import 'package:ppb1/screens/buat_tagihan_screen.dart';
import 'package:ppb1/utils/hitung_tagihan.dart';

AnggotaKas anggota(String id, {int tagihan = 0}) => AnggotaKas(
      id: id,
      nama: id.toUpperCase(),
      noWa: '',
      tagihan: tagihan,
      status: tagihan > 0 ? StatusBayar.belum : StatusBayar.lunas,
      avatarColor: Colors.green,
    );

TagihanKas tagihan({
  String id = 'tagihan',
  int total = 100000,
  int porsiLama = 33333,
  Map<String, int> porsi = const {'a': 33334, 'b': 33333, 'c': 33333},
  List<String> target = const [],
}) =>
    TagihanKas(
      id: id,
      judul: id,
      tanggal: '20 Nov 2026',
      sumberDana: 'Kas grup',
      items: const [],
      subtotal: total,
      pajak: 0,
      total: total,
      porsiPerOrang: porsiLama,
      porsiAnggota: porsi,
      anggotaDitagihIds: target,
      penerimaId: 'c',
      namaPenerima: 'C',
    );

GrupKas grup(List<AnggotaKas> anggotaList,
        {List<TagihanKas> tagihanList = const []}) =>
    GrupKas(
      id: 'grup-test',
      namaGrup: 'Grup Test',
      kodeUndangan: 'TEST',
      bendahara: 'C',
      saldo: 1000000,
      pemasukan: 1000000,
      pengeluaran: 0,
      anggota: anggotaList,
      daftarTagihan: tagihanList,
      daftarKonfirmasi: const [],
      daftarRiwayatPembayaran: const [],
    );

void main() {
  group('Pembagian rupiah tanpa kelebihan total', () {
    test('100000 dibagi tiga tepat 33334 + 33333 + 33333', () {
      expect(bagiRataTagihan(100000, ['a', 'b', 'c']), {
        'a': 33334,
        'b': 33333,
        'c': 33333,
      });
    });

    test('seluruh sisa masuk penalang jika ikut pembagian', () {
      final porsi =
          bagiRataTagihan(100001, ['a', 'b', 'c'], penanggungSisaId: 'b');
      expect(porsi, {'a': 33333, 'b': 33335, 'c': 33333});
      expect(porsi['a']! + porsi['c']! + porsi['b']!, 100001);
    });

    test('penalang tidak ditagih: sisa jatuh ke anggota pertama', () {
      expect(
          bagiRataTagihan(100001, ['a', 'b', 'c'], penanggungSisaId: 'luar'), {
        'a': 33335,
        'b': 33333,
        'c': 33333,
      });
    });

    test('nilai kecil, nol, pembagian habis, dan satu anggota', () {
      expect(bagiRataTagihan(2, ['a', 'b', 'c']), {'a': 2, 'b': 0, 'c': 0});
      expect(bagiRataTagihan(0, ['a', 'b']), {'a': 0, 'b': 0});
      expect(bagiRataTagihan(100000, ['a', 'b']), {'a': 50000, 'b': 50000});
      expect(bagiRataTagihan(100001, ['a']), {'a': 100001});
    });

    test('total selalu terjaga untuk berbagai nominal dan jumlah anggota', () {
      for (var jumlah = 1; jumlah <= 20; jumlah++) {
        final ids = List.generate(jumlah, (i) => 'anggota-$i');
        for (final total in [0, 1, 2, 17, 100, 100000, 105351]) {
          final porsi = bagiRataTagihan(total, ids, penanggungSisaId: ids.last);
          expect(porsi.values.fold<int>(0, (sum, n) => sum + n), total);
          expect(porsi.values.every((n) => n >= 0), isTrue);
          expect(porsi.length, jumlah);
        }
      }
    });

    test('map tidak bisa diubah, input negatif/kosong/duplikat ditolak', () {
      final porsi = bagiRataTagihan(100000, ['a', 'b', 'c']);
      expect(() => porsi['a'] = 0, throwsUnsupportedError);
      for (final hitung in <Map<String, int> Function()>[
        () => bagiRataTagihan(-1, ['a']),
        () => bagiRataTagihan(100, []),
        () => bagiRataTagihan(100, ['']),
        () => bagiRataTagihan(100, ['a', 'a']),
      ]) {
        expect(hitung, throwsArgumentError);
      }
    });
  });

  group('Nominal tagihan per anggota', () {
    test('map bagian menjadi sumber nominal, bukan porsi rata-rata', () {
      final item = tagihan();
      expect(item.porsiUntuk('a'), 33334);
      expect(item.porsiUntuk('b'), 33333);
      expect(item.porsiUntuk('luar'), 0);
      expect(tagihan(total: 2, porsi: {'a': 2, 'b': 0}).porsiUntuk('b'), 0);
    });

    test(
        'tagihan lama tidak dihitung ulang; daftar target lama tetap dihormati',
        () {
      final lama = tagihan(porsi: {}, porsiLama: 33334);
      expect(lama.porsiUntuk('a'), 33334);
      expect(lama.porsiUntuk('b'), 33334);
      expect(tagihan(porsi: {}, target: ['a']).porsiUntuk('b'), 0);
    });

    test('tagihanSaya menggunakan bagian masing-masing tanpa salah pembulatan',
        () {
      final profilAwal = profilNotifier.value;
      addTearDown(() => profilNotifier.value = profilAwal);
      profilNotifier.value = const Pengguna(
        id: 'a',
        nama: 'A',
        noWa: '',
        bank: '',
        noRekening: '',
      );
      final store = KasStore();
      addTearDown(store.dispose);
      final g = grup([anggota('a', tagihan: 33334), anggota('b'), anggota('c')],
          tagihanList: [tagihan()]);
      store.value = KasRootState(aktifGrupId: g.id, daftarGrup: [g]);
      expect(store.tagihanSaya().single.nominal, 33334);
      expect(store.totalHarusBayar, 33334);
    });

    test('anggota pembagian yang tidak valid ditolak sebelum data berubah', () {
      final store = KasStore();
      addTearDown(store.dispose);
      final g = grup([anggota('a')]);
      store.value = KasRootState(aktifGrupId: g.id, daftarGrup: [g]);
      final awal = store.value;
      expect(
        () => store.tambahTagihan(
          judul: 'Belanja',
          sumberDana: 'Kas grup',
          items: const [
            ItemBelanja(id: 'item', nama: 'Belanja', harga: 100000)
          ],
          idAnggotaDitagih: ['bukan-anggota'],
        ),
        throwsArgumentError,
      );
      expect(store.value, same(awal));
    });
  });

  void siapkanLayar(WidgetTester tester, GrupKas g, {String akun = 'a'}) {
    final stateAwal = kasStore.value;
    final profilAwal = profilNotifier.value;
    addTearDown(() {
      kasStore.value = stateAwal;
      profilNotifier.value = profilAwal;
    });
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    profilNotifier.value = Pengguna(
      id: akun,
      nama: akun.toUpperCase(),
      noWa: '',
      bank: '',
      noRekening: '',
    );
    kasStore.value = KasRootState(aktifGrupId: g.id, daftarGrup: [g]);
  }

  testWidgets('form menampilkan pembagian tepat dan penanggung sisa',
      (tester) async {
    siapkanLayar(tester, grup([anggota('a'), anggota('b'), anggota('c')]));
    await tester.pumpWidget(const MaterialApp(home: BuatTagihanScreen()));
    final harga = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        (widget.decoration?.labelText?.startsWith('Nominal') ?? false));
    await tester.ensureVisible(harga);
    await tester.enterText(harga, '100000');
    await tester.pumpAndSettle();
    expect(find.text('Rincian pembagian'), findsOneWidget);
    expect(find.text('Rp 33.334'), findsOneWidget);
    expect(find.text('Rp 33.333'), findsNWidgets(2));
    expect(
        find.text('Sisa pembulatan Rp 1 masuk ke bagian A.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'bagian anggota kedua mengikuti akun login, bukan anggota pertama',
      (tester) async {
    siapkanLayar(
        tester,
        grup(
          [
            anggota('a', tagihan: 33334),
            anggota('b', tagihan: 33333),
            anggota('c')
          ],
          tagihanList: [tagihan()],
        ),
        akun: 'b');
    await tester.pumpWidget(const MaterialApp(home: BayarTagihanScreen()));
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    expect(find.text('Bayar sebagai anggota:'), findsNothing);
    expect(find.text('Rp 33.333'), findsWidgets);
    expect(find.text('Rp 33.334'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'layar Bayar memakai bagian akun aktif dan tidak menawarkan tagihan orang lain',
      (tester) async {
    siapkanLayar(
        tester,
        grup(
          [anggota('a', tagihan: 33334), anggota('b'), anggota('c')],
          tagihanList: [
            tagihan(id: 'Khusus B', porsi: {'b': 50000}, total: 50000),
            tagihan(id: 'Tagihan Bersama'),
          ],
        ));
    await tester.pumpWidget(const MaterialApp(home: BayarTagihanScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Rp 33.334'), findsWidgets);
    expect(find.textContaining('Khusus B'), findsNothing);
    expect(find.text('Rp 33.333'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
