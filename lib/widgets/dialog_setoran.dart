import 'package:flutter/material.dart';
import '../data/kas_store.dart';
import '../utils/format.dart' show CurrencyInputFormatter, parseNominal;

void tampilkanDialogSetoran(BuildContext context, GrupKas grup) {
  if (!kasStore.isBendahara(grup)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hanya bendahara yang berhak mencatat setoran kas'),
        backgroundColor: Color(0xFFDC2626),
      ),
    );
    return;
  }

  final nominalCtrl = TextEditingController();
  final ketCtrl = TextEditingController();
  String namaPenyetor = grup.bendahara;

  final anggotaList = <String>[];
  if (!anggotaList.contains(grup.bendahara)) {
    anggotaList.add(grup.bendahara);
  }
  for (final a in grup.anggota) {
    if (!anggotaList.contains(a.nama)) {
      anggotaList.add(a.nama);
    }
  }
  if (!anggotaList.contains('Kas Awal / Modal')) {
    anggotaList.insert(0, 'Kas Awal / Modal');
  }

  const primaryGreen = Color(0xFF074E3B);

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_card_rounded, color: primaryGreen),
            SizedBox(width: 8),
            Text(
              'Catat Setoran Kas',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Uang masuk yang langsung menambah saldo kas bersama',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Penyetor / Sumber',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: namaPenyetor,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                items: anggotaList.map((nama) {
                  return DropdownMenuItem(
                    value: nama,
                    child: Text(nama, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => namaPenyetor = val);
                },
              ),
              const SizedBox(height: 14),
              const Text(
                'Nominal Setoran (Rp)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nominalCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '50.000',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Keterangan (Opsional)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: ketCtrl,
                decoration: InputDecoration(
                  hintText: 'Contoh: Iuran kas bulan ini / Saldo awal',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final nominal = parseNominal(nominalCtrl.text);
              if (nominal <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Masukkan nominal setoran valid')),
                );
                return;
              }
              kasStore.catatSetoranKas(
                nominal: nominal,
                penyetorNama: namaPenyetor,
                keterangan: ketCtrl.text.trim().isEmpty ? null : ketCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Setoran ${formatRupiah(nominal)} berhasil ditambahkan ke saldo kas!',
                  ),
                  backgroundColor: primaryGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan Setoran'),
          ),
        ],
      ),
    ),
  );
}
