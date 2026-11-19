import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:ppb1/utils/format.dart';

void main() {
  final formatter = CurrencyInputFormatter();

  TextEditingValue edit(String text, {int? cursor}) {
    return formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: cursor ?? text.length),
      ),
    );
  }

  group('CurrencyInputFormatter', () {
    test('memformat ribuan saat mengetik bertahap', () {
      var value = TextEditingValue.empty;
      const expected = [
        '1',
        '10',
        '100',
        '1.000',
        '10.000',
        '100.000',
        '1.000.000'
      ];

      for (var i = 0; i < expected.length; i++) {
        final text = '${value.text}${i == 0 ? '1' : '0'}';
        value = formatter.formatEditUpdate(
          value,
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        );
        expect(value.text, expected[i]);
        expect(value.selection.baseOffset, value.text.length);
      }
    });

    test('membersihkan hasil tempel tanpa menambahkan prefix Rp', () {
      final value = edit('Rp 1.234.567');
      expect(value.text, '1.234.567');
      expect(parseNominal(value.text), 1234567);
    });

    test('menangani input kosong, nonangka, dan nol di depan', () {
      for (final text in ['', 'abc', '.']) {
        final value = edit(text);
        expect(value.text, '');
        expect(value.selection.baseOffset, 0);
      }
      expect(edit('000').text, '0');
      expect(edit('0001000').text, '1.000');
      expect(edit('0001000').selection.baseOffset, 5);
    });

    test('mempertahankan kursor di awal dan tengah nominal', () {
      expect(edit('1234567', cursor: 0).selection.baseOffset, 0);
      final middle = edit('192.345', cursor: 2);
      expect(middle.text, '192.345');
      expect(middle.selection.baseOffset, 2);
    });

    test('mempertahankan rentang seleksi setelah format', () {
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1234567',
          selection: TextSelection(baseOffset: 1, extentOffset: 4),
        ),
      );
      expect(value.text, '1.234.567');
      expect(
          value.selection, const TextSelection(baseOffset: 1, extentOffset: 5));
    });

    test('menghapus digit dan menghitung ulang pemisah ribuan', () {
      final value = formatter.formatEditUpdate(
        edit('1000'),
        const TextEditingValue(
          text: '1.00',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(value.text, '100');
      expect(value.selection.baseOffset, 3);
    });

    test('menolak nominal di luar kapasitas integer tanpa menjadi nol', () {
      final oldValue = edit('1000');
      final value = formatter.formatEditUpdate(
        oldValue,
        const TextEditingValue(
          text: '999999999999999999999999999999999',
          selection: TextSelection.collapsed(offset: 33),
        ),
      );
      expect(value, oldValue);
    });

    test('menunggu sampai keyboard menyelesaikan composing text', () {
      const composingValue = TextEditingValue(
        text: '1000',
        selection: TextSelection.collapsed(offset: 4),
        composing: TextRange(start: 0, end: 4),
      );
      expect(
        formatter.formatEditUpdate(TextEditingValue.empty, composingValue),
        composingValue,
      );
    });
  });

  testWidgets('field nominal menampilkan titik dan tetap menyimpan angka utuh',
      (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '1000000');
    expect(controller.text, '1.000.000');
    expect(parseNominal(controller.text), 1000000);

    await tester.enterText(find.byType(TextField), '');
    expect(controller.text, '');
    expect(parseNominal(controller.text), 0);
  });
}
