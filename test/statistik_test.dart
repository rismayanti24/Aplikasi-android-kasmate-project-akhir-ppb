import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppb1/data/kas_store.dart';
import 'package:ppb1/screens/statistik_screen.dart';

void main() {
  testWidgets('StatistikScreen stabil dan menampilkan data fallback saat tagihan kosong',
      (WidgetTester tester) async {
    // Setup state grup dengan pengeluaran dan saldo, tetapi daftarTagihan kosong
    kasStore.value = KasRootState(
      aktifGrupId: 'grp_test',
      daftarGrup: [
        const GrupKas(
          id: 'grp_test',
          namaGrup: 'Grup Uji Statistik',
          kodeUndangan: 'TEST1234',
          saldo: 250000,
          pengeluaran: 150000,
          pemasukan: 400000,
          bendahara: 'Bendahara Uji',
          anggota: [
            AnggotaKas(
              id: 'u1',
              nama: 'User 1',
              noWa: '08123456789',
              status: StatusBayar.lunas,
              tagihan: 0,
              avatarColor: Colors.blue,
            ),
          ],
          daftarTagihan: [],
          daftarKonfirmasi: [],
          daftarRiwayatPembayaran: [],
          daftarNotifikasi: [],
        ),
      ],
    );

    // Render StatistikScreen
    await tester.pumpWidget(
      const MaterialApp(
        home: StatistikScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi bahwa layar tidak crash, menampilkan nominal pengeluaran dan fallback kategori
    expect(find.text('Statistik Pengeluaran'), findsOneWidget);
    expect(find.text('Rp 150.000'), findsWidgets);
    expect(find.text('Pemasukan Kas'), findsOneWidget);
    expect(find.text('Saldo Kas Grup'), findsOneWidget);
    // Kategori fallback mengalokasikan ke Lain-lain & Opsional sehingga tidak kosong mendadak
    expect(find.text('Lain-lain & Opsional'), findsOneWidget);
  });

  testWidgets('StatistikScreen mengelompokkan kategori konsumsi dan olahan makanan dengan benar (Poin 52)',
      (WidgetTester tester) async {
    kasStore.value = KasRootState(
      aktifGrupId: 'grp_kuliner',
      daftarGrup: [
        GrupKas(
          id: 'grp_kuliner',
          namaGrup: 'Grup Kuliner',
          kodeUndangan: 'MAKAN123',
          saldo: 500000,
          pengeluaran: 120000,
          pemasukan: 620000,
          bendahara: 'Bendahara',
          anggota: const [
            AnggotaKas(
              id: 'u1',
              nama: 'User 1',
              noWa: '08123456789',
              status: StatusBayar.lunas,
              tagihan: 0,
              avatarColor: Colors.green,
            ),
          ],
          daftarTagihan: [
            TagihanKas(
              id: 't_sate',
              judul: 'Sate Padang & Martabak Telor',
              tanggal: 'Bulan ini',
              sumberDana: 'Kas grup',
              items: const [
                ItemBelanja(id: 'i1', nama: 'Sate Padang Daging Sapi', harga: 50000),
                ItemBelanja(id: 'i2', nama: 'Martabak Telur Spesial', harga: 70000),
              ],
              subtotal: 120000,
              pajak: 0,
              total: 120000,
              porsiPerOrang: 120000,
              penerimaId: 'u1',
              namaPenerima: 'User 1',
            ),
          ],
          daftarKonfirmasi: const [],
          daftarRiwayatPembayaran: const [],
          daftarNotifikasi: const [],
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: StatistikScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi bahwa Sate & Martabak masuk ke Makanan & Konsumsi (bukan Lain-lain)
    expect(find.text('Makanan & Konsumsi'), findsOneWidget);
    expect(find.text('Rp 120.000'), findsWidgets);
    expect(find.text('(100%)'), findsWidgets);
  });
}
