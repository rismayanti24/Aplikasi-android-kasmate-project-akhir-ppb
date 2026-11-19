/// Rekening bersifat opsional; jika diisi hanya boleh mengandung digit ASCII.
String? validasiNomorRekening(String? value) {
  final nomor = value ?? '';
  if (nomor.isEmpty) return null;
  if (!RegExp(r'^[0-9]+$').hasMatch(nomor)) {
    return 'Nomor rekening hanya boleh berisi angka';
  }
  return null;
}
