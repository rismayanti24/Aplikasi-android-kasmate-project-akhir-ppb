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
}
