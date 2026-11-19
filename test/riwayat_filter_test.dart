import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppb1/data/kas_store.dart';
import 'package:ppb1/screens/riwayat_screen.dart';

void main() {
  group('Fase 8.5 (Poin 22) Search & Filter Chip di Riwayat', () {
    setUp(() {
      kasStore.value = KasRootState(
        aktifGrupId: 'grp_test_riwayat',
        daftarGrup: [
          GrupKas(
            id: 'grp_test_riwayat',
            namaGrup: 'Grup Uji Riwayat',
            kodeUndangan: 'KM26-RWYT',
            saldo: 500000,
            pengeluaran: 250000,
            pemasukan: 750000,
            bendahara: 'Bendahara',
            anggota: const [
              AnggotaKas(
                id: 'u1',
                nama: 'Alice Wijaya',
                noWa: '08123456789',
                tagihan: 0,
                status: StatusBayar.lunas,
                avatarColor: Colors.blue,
              ),
              AnggotaKas(
                id: 'u2',
                nama: 'Bob Santoso',
                noWa: '08123456788',
                tagihan: 50000,
                status: StatusBayar.belum,
                avatarColor: Colors.orange,
              ),
            ],
            daftarTagihan: const [
              TagihanKas(
                id: 't1',
                judul: 'Makan Siang Bareng',
                subtotal: 100000,
                pajak: 0,
                total: 100000,
                porsiPerOrang: 50000,
                tanggal: '20 Nov 2026',
                penerimaId: 'u1',
                namaPenerima: 'Alice Wijaya',
                sumberDana: 'Dana pribadi',
                items: [ItemBelanja(id: 'i1', nama: 'Ayam Bakar', harga: 100000)],
              ),
              TagihanKas(
                id: 't2',
                judul: 'Beli Galon Aqua',
                subtotal: 20000,
                pajak: 0,
                total: 20000,
                porsiPerOrang: 10000,
                tanggal: '21 Nov 2026',
                penerimaId: 'bendahara',
                namaPenerima: 'Kas grup',
                sumberDana: 'Kas grup',
                items: [ItemBelanja(id: 'i2', nama: 'Aqua Galon', harga: 20000)],
              ),
            ],
            daftarKonfirmasi: const [
              KonfirmasiItem(
                id: 'k1',
                anggotaId: 'u2',
                namaAnggota: 'Bob Santoso',
                nominal: 50000,
                namaFileBukti: 'transfer_bob.jpg',
                buktiPath: 'path/bob.jpg',
                waktuUnggah: '10:00',
                judulTagihan: 'Makan Siang Bareng',
              ),
            ],
            daftarRiwayatPembayaran: const [
              RiwayatPembayaranItem(
                id: 'r1',
                namaAnggota: 'Alice Wijaya',
                nominal: 50000,
                waktu: '19 Nov 2026',
                status: 'Lunas',
                buktiPath: 'bukti_r1.jpg',
                judulTagihan: 'Uang Kas Mingguan',
              ),
            ],
            daftarNotifikasi: const [],
          ),
        ],
      );
    });

    testWidgets('menampilkan kolom pencarian dan filter chip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RiwayatScreen(initialTab: 0),
        ),
      );
      await tester.pumpAndSettle();

      // Cek ada search field
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cari nama anggota, tagihan, nominal...'), findsOneWidget);

      // Cek filter chip untuk tab pembayaran
      expect(find.widgetWithText(ChoiceChip, 'Semua'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Lunas'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Menunggu'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Dibatalkan'), findsOneWidget);

      // Cek item riwayat lunas tampil
      expect(find.text('Alice Wijaya'), findsOneWidget);
      expect(find.text('Uang Kas Mingguan • 19 Nov 2026'), findsOneWidget);
    });

    testWidgets('filter chip Menunggu menampilkan antrean konfirmasi', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RiwayatScreen(initialTab: 0),
        ),
      );
      await tester.pumpAndSettle();

      // Tap filter chip 'Menunggu'
      await tester.tap(find.widgetWithText(ChoiceChip, 'Menunggu'));
      await tester.pumpAndSettle();

      // Bob Santoso dari daftarKonfirmasi harus tampil dengan badge Menunggu
      expect(find.text('Bob Santoso'), findsOneWidget);
      expect(find.text('Menunggu'), findsNWidgets(2));
    });

    testWidgets('pencarian memfilter item sesuai query', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RiwayatScreen(initialTab: 0),
        ),
      );
      await tester.pumpAndSettle();

      // Cari kata yang tidak ada
      await tester.enterText(find.byType(TextField), 'TidakAdaNamaIni');
      await tester.pumpAndSettle();

      // Harus menampilkan empty state pencarian
      expect(find.text('Tidak ada riwayat pembayaran yang cocok'), findsOneWidget);

      // Clear search
      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.pumpAndSettle();
      expect(find.text('Alice Wijaya'), findsOneWidget);
    });

    testWidgets('tab Pengeluaran menampilkan filter Kas grup dan Talangan', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RiwayatScreen(initialTab: 1),
        ),
      );
      await tester.pumpAndSettle();

      // Cek filter chip untuk tab pengeluaran
      expect(find.widgetWithText(ChoiceChip, 'Semua'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Kas grup'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Talangan'), findsOneWidget);

      // Kedua pengeluaran harus tampil saat 'Semua'
      expect(find.text('Makan Siang Bareng'), findsOneWidget);
      expect(find.text('Beli Galon Aqua'), findsOneWidget);

      // Filter hanya Kas grup
      await tester.tap(find.widgetWithText(ChoiceChip, 'Kas grup'));
      await tester.pumpAndSettle();

      expect(find.text('Beli Galon Aqua'), findsOneWidget);
      expect(find.text('Makan Siang Bareng'), findsNothing);
    });
  });
}
