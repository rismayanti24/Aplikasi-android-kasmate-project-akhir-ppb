import 'package:flutter/services.dart';

String formatRupiah(int number) {
  String result = number.toString();
  String formatted = '';
  int count = 0;
  for (int i = result.length - 1; i >= 0; i--) {
    formatted = result[i] + formatted;
    count++;
    if (count % 3 == 0 && i != 0) {
      formatted = '.$formatted';
    }
  }
  return 'Rp $formatted';
}

/// Memformat integer menjadi angka dengan pemisah ribuan titik saja (misal: 10000 -> "10.000")
String formatRibuan(int number) {
  final isNegatif = number < 0;
  final str = number.abs().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    final posDariKanan = str.length - i;
    buffer.write(str[i]);
    if (posDariKanan > 1 && posDariKanan % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${isNegatif ? "-" : ""}${buffer.toString()}';
}

/// Mengubah string input berformat ribuan menjadi integer bersih
int parseNominal(String text) {
  final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(clean) ?? 0;
}

/// Formatter otomatis pemisah ribuan saat user mengetik nominal uang (Poin 48)
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return newValue;
    }

    final nonDigit = RegExp(r'[^0-9]');
    final digitsOnly = newValue.text.replaceAll(nonDigit, '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final normalized = digitsOnly.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final nominal = int.tryParse(normalized);
    // Jangan mengubah nominal yang melampaui kapasitas integer menjadi nol.
    if (nominal == null) return oldValue;

    final formatted = formatRibuan(nominal);
    final removedZeros = digitsOnly.length - normalized.length;

    int mapOffset(int offset) {
      if (offset < 0) return formatted.length;
      final digitsBeforeCursor = newValue.text
          .substring(0, offset.clamp(0, newValue.text.length))
          .replaceAll(nonDigit, '')
          .length;
      final target = (digitsBeforeCursor - removedZeros).clamp(
        0,
        normalized.length,
      );
      if (target == 0) return 0;

      var digitCount = 0;
      for (var i = 0; i < formatted.length; i++) {
        if (formatted[i] != '.') digitCount++;
        if (digitCount == target) return i + 1;
      }
      return formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection(
        baseOffset: mapOffset(newValue.selection.baseOffset),
        extentOffset: mapOffset(newValue.selection.extentOffset),
        affinity: newValue.selection.affinity,
        isDirectional: newValue.selection.isDirectional,
      ),
    );
  }
}
