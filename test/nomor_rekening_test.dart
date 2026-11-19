import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppb1/data/profil_store.dart';
import 'package:ppb1/models/pengguna.dart';
import 'package:ppb1/utils/input_validation.dart';

void main() {
  group('Validasi nomor rekening', () {
    test('rekening opsional dan digit dengan nol di depan diterima', () {
      for (final nomor in [
        null,
        '',
        '0',
        '001234567890',
        '12345678901234567890'
      ]) {
        expect(validasiNomorRekening(nomor), isNull);
      }
    });

    test('huruf, spasi, tanda baca, dan digit non-ASCII ditolak', () {
      for (final nomor in [
        'abc',
        '123abc',
        '123 456',
        '123.456',
        '+123',
        '１２３'
      ]) {
        expect(
          validasiNomorRekening(nomor),
          'Nomor rekening hanya boleh berisi angka',
        );
      }
    });

    test('penyimpanan menolak rekening invalid tanpa mengubah profil', () {
      final profilSebelumnya = profilNotifier.value;
      expect(
        () => simpanProfil(
          const Pengguna(
            id: 'user-test',
            nama: 'Pengguna',
            noWa: '',
            bank: '',
            noRekening: '123abc',
          ),
        ),
        throwsArgumentError,
      );
      expect(profilNotifier.value, same(profilSebelumnya));
    });
  });

  testWidgets(
      'input hanya angka, mempertahankan nol, dan memvalidasi data lama', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'rekening-lama-invalid');
    addTearDown(controller.dispose);
    final formKey = GlobalKey<FormState>();
    var tersimpan = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: validasiNomorRekening,
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    tersimpan = true;
                  },
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Simpan'));
    await tester.pump();
    expect(tersimpan, isFalse);
    expect(
        find.text('Nomor rekening hanya boleh berisi angka'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'abc');
    expect(controller.text, '');
    await tester.enterText(find.byType(TextFormField), '00ab123 456');
    expect(controller.text, '00123456');
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    expect(tersimpan, isTrue);
    expect(find.text('Nomor rekening hanya boleh berisi angka'), findsNothing);
  });
}
