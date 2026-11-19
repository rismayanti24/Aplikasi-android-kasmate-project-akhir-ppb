import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppb1/data/kas_store.dart';
import 'package:ppb1/screens/register_screen.dart';
import 'package:ppb1/utils/input_validation.dart';

void main() {
  group('Validasi nomor WhatsApp Indonesia', () {
    test('kolom tetap opsional', () {
      expect(validasiNomorWhatsApp(null), isNull);
      expect(validasiNomorWhatsApp(''), isNull);
      expect(validasiNomorWhatsApp('   '), isNull);
    });

    test('menerima format lokal, internasional, dan format simpan aplikasi',
        () {
      for (final nomor in [
        '0812345678',
        '0812345678901',
        '089123456789',
        '+62812345678',
        '+62812345678901',
        '62812345678',
        '62812345678901',
        ' 081234567890 ',
      ]) {
        expect(validasiNomorWhatsApp(nomor), isNull, reason: nomor);
      }
    });

    test('menolak nomor terlalu pendek atau panjang di semua format', () {
      for (final nomor in [
        '081234567',
        '08123456789012',
        '+6281234567',
        '+628123456789012',
        '6281234567',
        '628123456789012',
      ]) {
        expect(validasiNomorWhatsApp(nomor), isNotNull, reason: nomor);
      }
    });

    test('menolak huruf, tanda baca, kode negara lain, dan awalan salah', () {
      for (final nomor in [
        'abcdefghijk',
        '0812abc567890',
        '0812-3456-7890',
        '0812 3456 7890',
        '0812\n34567890',
        '０８１２３４５６７８９０',
        '021234567890',
        '080123456789',
        '81234567890',
        '+601234567890',
        '006281234567890',
        '+62081234567890',
        '++6281234567890',
        '628123+4567890',
      ]) {
        expect(validasiNomorWhatsApp(nomor), isNotNull, reason: nomor);
      }
    });

    test('tambah anggota menolak nomor invalid sebelum mengubah data', () {
      final sebelumnya = kasStore.value;
      expect(
        () => kasStore.tambahAnggota(nama: 'Anggota', noWa: '0812abc'),
        throwsArgumentError,
      );
      expect(kasStore.value, same(sebelumnya));
    });
  });

  testWidgets('pendaftaran diblokir sebelum menghubungi Auth jika WA invalid', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.enterText(find.byType(TextField).at(0), 'Pengguna');
    await tester.enterText(
        find.byType(TextField).at(1), 'pengguna@example.com');
    await tester.enterText(find.byType(TextField).at(3), 'password-test');

    for (final nomor in ['0812abc567890', '0812']) {
      await tester.enterText(find.byType(TextFormField), nomor);
      await tester.ensureVisible(find.text('Daftar Sekarang'));
      await tester.tap(find.text('Daftar Sekarang'));
      await tester.pumpAndSettle();
      expect(find.text(validasiNomorWhatsApp(nomor)!), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    }

    await tester.enterText(find.byType(TextFormField), '+6281234567890');
    await tester.pumpAndSettle();
    expect(
      find.text('Gunakan 08…, +628…, atau 628… (10–13 digit lokal)'),
      findsNothing,
    );
  });
}
