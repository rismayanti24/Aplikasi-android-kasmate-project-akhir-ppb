import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../data/kas_store.dart';
import '../utils/format.dart'
    show CurrencyInputFormatter, formatRibuan, parseNominal;

class HasilScanStruk {
  final List<ItemBelanja> items;
  final String judulPrediksi;
  final int totalPrediksi;

  HasilScanStruk({
    required this.items,
    required this.judulPrediksi,
    required this.totalPrediksi,
  });
}

class ScanStrukScreen extends StatefulWidget {
  const ScanStrukScreen({super.key});

  @override
  State<ScanStrukScreen> createState() => _ScanStrukScreenState();
}

class _ScanStrukScreenState extends State<ScanStrukScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isProcessing = false;
  final List<TextEditingController> _namaControllers = [];
  final List<TextEditingController> _hargaControllers = [];
  String _namaTokoPrediksi = 'Belanjaan Struk';

  static const Color _primaryGreen = Color(0xFF074E3B);

  @override
  void initState() {
    super.initState();
    // Buka opsi kamera / galeri otomatis saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pilihSumberFoto();
    });
  }

  @override
  void dispose() {
    for (final c in _namaControllers) {
      c.dispose();
    }
    for (final c in _hargaControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _pilihSumberFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Ambil Foto Struk Belanja',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: _primaryGreen),
                ),
                title: const Text('Gunakan Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Foto struk fisik secara langsung'),
                onTap: () {
                  Navigator.pop(ctx);
                  _ambilGambar(ImageSource.camera);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Color(0xFF4338CA)),
                ),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Gunakan foto struk yang sudah ada di HP'),
                onTap: () {
                  Navigator.pop(ctx);
                  _ambilGambar(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ambilGambar(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 90,
      );

      if (picked == null) return;

      setState(() {
        _imageFile = File(picked.path);
        _isProcessing = true;
      });

      await _prosesOcr(_imageFile!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _prosesOcr(File file) async {
    final inputImage = InputImage.fromFile(file);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      _parseHasilOcr(recognizedText);
    } catch (e) {
      debugPrint('Error proses OCR: $e');
    } finally {
      await textRecognizer.close();
    }
  }

  void _parseHasilOcr(RecognizedText recognized) {
    // Bersihkan controller lama
    for (final c in _namaControllers) {
      c.dispose();
    }
    for (final c in _hargaControllers) {
      c.dispose();
    }
    _namaControllers.clear();
    _hargaControllers.clear();

    final List<Map<String, dynamic>> itemsDitemukan = [];
    int totalDitemukan = 0;

    // Ambil baris pertama sebagai kemungkinan nama toko/merchant
    if (recognized.blocks.isNotEmpty && recognized.blocks.first.lines.isNotEmpty) {
      final firstLine = recognized.blocks.first.lines.first.text.trim();
      if (firstLine.length > 2 && firstLine.length < 35) {
        _namaTokoPrediksi = firstLine;
      }
    }

    final priceRegex = RegExp(r'(\d{1,3}(?:[.,]\d{3})+|\d{4,7})');

    final kataKunciAbaikan = [
      'kembali',
      'kembalian',
      'change',
      'tunai',
      'cash',
      'debit',
      'kredit',
      'qris',
      'telp',
      'tanggal',
      'waktu',
      'kasir',
      'operator',
      'ppn',
      'pajak',
      'tax',
      'diskon',
      'discount',
      'promo',
      'terima kasih',
      'selamat',
    ];

    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        final lower = text.toLowerCase();

        // Cek total belanja
        if (lower.contains('total') || lower.contains('grand total') || lower.contains('jumlah')) {
          final matches = priceRegex.allMatches(text);
          if (matches.isNotEmpty) {
            final rawPrice = matches.last.group(0)!;
            final parsed = int.tryParse(rawPrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            if (parsed > 0) {
              totalDitemukan = parsed;
            }
          }
          continue;
        }

        // Abaikan baris pembayaran / kembalian / footer
        if (kataKunciAbaikan.any((k) => lower.contains(k))) {
          continue;
        }

        // Cari harga di baris item
        final match = priceRegex.firstMatch(text);
        if (match != null) {
          final rawPrice = match.group(0)!;
          final harga = int.tryParse(rawPrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

          if (harga >= 500 && harga <= 5000000) {
            // Ambil teks sebelum harga sebagai nama barang
            String nama = text.substring(0, match.start).trim();
            // Bersihkan simbol aneh
            nama = nama.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();

            if (nama.length < 2) {
              nama = 'Item ${itemsDitemukan.length + 1}';
            }

            itemsDitemukan.add({
              'nama': nama,
              'harga': harga,
            });
          }
        }
      }
    }

    // Jika tidak ada item yang terdeteksi tapi ada total, buat 1 item belanja utama
    if (itemsDitemukan.isEmpty && totalDitemukan > 0) {
      itemsDitemukan.add({
        'nama': _namaTokoPrediksi,
        'harga': totalDitemukan,
      });
    }

    // Jika masih kosong sama sekali, beri 1 item draft
    if (itemsDitemukan.isEmpty) {
      itemsDitemukan.add({
        'nama': 'Pengeluaran Struk',
        'harga': 0,
      });
    }

    // Buat controller untuk setiap item yang terdeteksi agar bisa diedit user
    for (final it in itemsDitemukan) {
      _namaControllers.add(TextEditingController(text: it['nama'].toString()));
      _hargaControllers.add(
        TextEditingController(
          text: formatRibuan(parseNominal(it['harga'].toString())),
        ),
      );
    }

    setState(() {});
  }

  void _tambahItemBaru() {
    setState(() {
      _namaControllers.add(TextEditingController(text: 'Item Baru'));
      _hargaControllers.add(TextEditingController(text: '0'));
    });
  }

  void _hapusItem(int index) {
    setState(() {
      _namaControllers[index].dispose();
      _hargaControllers[index].dispose();
      _namaControllers.removeAt(index);
      _hargaControllers.removeAt(index);
    });
  }

  int get _hitungTotalItems {
    int sum = 0;
    for (final c in _hargaControllers) {
      final val = parseNominal(c.text);
      sum += val;
    }
    return sum;
  }

  void _gunakanHasil() {
    final List<ItemBelanja> itemsFinal = [];

    for (int i = 0; i < _namaControllers.length; i++) {
      final nama = _namaControllers[i].text.trim();
      final harga = parseNominal(_hargaControllers[i].text);

      if (nama.isNotEmpty && harga > 0) {
        itemsFinal.add(
          ItemBelanja(
            id: 'scan_${DateTime.now().millisecondsSinceEpoch}_$i',
            nama: nama,
            harga: harga,
          ),
        );
      }
    }

    if (itemsFinal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 item dengan harga di atas 0')),
      );
      return;
    }

    final hasil = HasilScanStruk(
      items: itemsFinal,
      judulPrediksi: _namaTokoPrediksi,
      totalPrediksi: _hitungTotalItems,
    );

    Navigator.pop(context, hasil);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        title: const Text(
          'Pindai Struk Belanja (OCR)',
          style: TextStyle(color: Color(0xFF111827), fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Ambil Foto Lain',
            icon: const Icon(Icons.add_a_photo_outlined, color: _primaryGreen),
            onPressed: _pilihSumberFoto,
          ),
        ],
      ),
      body: SafeArea(
        child: _isProcessing
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _primaryGreen),
                    SizedBox(height: 16),
                    Text(
                      'Membaca teks struk dengan Google ML Kit...',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Mengekstrak nama item & nominal otomatis',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview Gambar Struk jika ada
                    if (_imageFile != null)
                      Container(
                        height: 140,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFFF3F4F6),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          image: DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          alignment: Alignment.bottomLeft,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Struk: $_namaTokoPrediksi',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _pilihSumberFoto,
                                icon: const Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                                label: const Text('Ganti', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Header Daftar Item
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Item Terdeteksi (${_namaControllers.length})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _tambahItemBaru,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Tambah Item', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: _primaryGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Daftar Item hasil scan
                    if (_namaControllers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.document_scanner_outlined, size: 48, color: Color(0xFF9CA3AF)),
                            SizedBox(height: 8),
                            Text('Belum ada foto struk yang dipindai', style: TextStyle(color: Color(0xFF6B7280))),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _namaControllers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: _namaControllers[index],
                                      decoration: const InputDecoration(
                                        hintText: 'Nama barang',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        border: UnderlineInputBorder(),
                                      ),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _hargaControllers[index],
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [CurrencyInputFormatter()],
                                      decoration: const InputDecoration(
                                        prefixText: 'Rp ',
                                        hintText: '0',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        border: UnderlineInputBorder(),
                                      ),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFEF4444)),
                                    onPressed: () => _hapusItem(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Total Ringkasan
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Belanja Struk',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _primaryGreen,
                            ),
                          ),
                          Text(
                            formatRupiah(_hitungTotalItems),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tombol Gunakan Hasil Scan
                    ElevatedButton.icon(
                      onPressed: _namaControllers.isEmpty ? null : _gunakanHasil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: const Text(
                        'Gunakan Hasil Scan ke Form',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
      ),
    );
  }
}
