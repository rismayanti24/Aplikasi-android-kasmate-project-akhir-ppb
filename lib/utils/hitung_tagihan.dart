/// Rincian rupiah bulat: diskon mengurangi dasar pajak; biaya layanan ditambah
/// sesudah pajak dan tidak dikenai pajak lagi.
class RincianTagihan {
  final int subtotal;
  final int diskon;
  final double pajakPersen;
  final int pajak;
  final int biayaLayanan;

  const RincianTagihan._({
    required this.subtotal,
    required this.diskon,
    required this.pajakPersen,
    required this.pajak,
    required this.biayaLayanan,
  });

  factory RincianTagihan.hitung({
    required int subtotal,
    double pajakPersen = 0,
    int diskon = 0,
    int biayaLayanan = 0,
  }) {
    if (subtotal < 0 || diskon < 0 || biayaLayanan < 0) {
      throw ArgumentError('Nominal tidak boleh negatif');
    }
    if (diskon > subtotal) {
      throw ArgumentError('Diskon tidak boleh melebihi subtotal');
    }
    if (!pajakPersen.isFinite || pajakPersen < 0 || pajakPersen > 100) {
      throw ArgumentError('Pajak harus antara 0 sampai 100 persen');
    }
    final basisPoin = (pajakPersen * 100).round();
    if ((pajakPersen * 100 - basisPoin).abs() > 0.0000001) {
      throw ArgumentError('Pajak maksimal dua angka desimal');
    }

    final dasarPajak = subtotal - diskon;
    final pajak = (dasarPajak * basisPoin + 5000) ~/ 10000;
    return RincianTagihan._(
      subtotal: subtotal,
      diskon: diskon,
      pajakPersen: pajakPersen,
      pajak: pajak,
      biayaLayanan: biayaLayanan,
    );
  }

  int get total => subtotal - diskon + pajak + biayaLayanan;
}

/// Koma dan titik diterima sebagai desimal persen, bukan pemisah ribuan.
double? parsePersenPajak(String text) {
  final nilai = text.trim();
  if (!RegExp(r'^[0-9]{1,3}(?:[.,][0-9]{1,2})?$').hasMatch(nilai)) {
    return null;
  }
  final persen = double.tryParse(nilai.replaceAll(',', '.'));
  return persen != null && persen >= 0 && persen <= 100 ? persen : null;
}

String formatPersenPajak(double persen) {
  return persen
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'\.?0+$'), '')
      .replaceAll('.', ',');
}
