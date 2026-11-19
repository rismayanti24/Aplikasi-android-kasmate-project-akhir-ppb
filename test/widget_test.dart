import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppb1/widgets/status_badge.dart';
import 'package:ppb1/widgets/empty_state.dart';

void main() {
  group('KasMate Widget Tests', () {
    testWidgets('StatusBadge menampilkan label dan warna yang sesuai', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(status: 'lunas'),
                StatusBadge(status: 'menunggu'),
                StatusBadge(status: 'belum'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Lunas'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Belum Bayar'), findsOneWidget);
    });

    testWidgets('KasEmptyState menampilkan judul, deskripsi, dan tombol aksi', (WidgetTester tester) async {
      bool actionClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KasEmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Belum Ada Tagihan',
              subtitle: 'Kamu tidak memiliki kewajiban kas saat ini.',
              action: ElevatedButton(
                onPressed: () => actionClicked = true,
                child: const Text('Buat Tagihan'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Belum Ada Tagihan'), findsOneWidget);
      expect(find.text('Kamu tidak memiliki kewajiban kas saat ini.'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
      expect(find.text('Buat Tagihan'), findsOneWidget);

      await tester.tap(find.text('Buat Tagihan'));
      expect(actionClicked, isTrue);
    });
  });
}
