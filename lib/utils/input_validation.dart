/// Memeriksa format HP Indonesia, bukan status aktif atau akun WhatsApp.
/// Panjang 10–13 digit dihitung dalam bentuk lokal 08..., bukan kode negara.
String? validasiNomorWhatsApp(String? value) {
  final nomor = value?.trim() ?? '';
  if (nomor.isEmpty) return null;

  final formatIndonesia = RegExp(
    r'^(?:08[1-9][0-9]{7,10}|\+?628[1-9][0-9]{7,10})$',
  );
  if (RegExp(r'[^0-9+]').hasMatch(nomor) || !formatIndonesia.hasMatch(nomor)) {
    return 'Gunakan 08…, +628…, atau 628… (10–13 digit lokal)';
  }
  return null;
}

/// Rekening bersifat opsional; jika diisi hanya boleh mengandung digit ASCII.
String? validasiNomorRekening(String? value) {
  final nomor = value ?? '';
  if (nomor.isEmpty) return null;
  if (!RegExp(r'^[0-9]+$').hasMatch(nomor)) {
    return 'Nomor rekening hanya boleh berisi angka';
  }
  return null;
}
