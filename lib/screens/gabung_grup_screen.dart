import 'dart:async';
import 'package:flutter/material.dart';
import '../data/kas_store.dart';
import 'scan_qr_screen.dart';

class GabungGrupScreen extends StatefulWidget {
  const GabungGrupScreen({super.key});

  @override
  State<GabungGrupScreen> createState() => _GabungGrupScreenState();
}

class _GabungGrupScreenState extends State<GabungGrupScreen> {
  final TextEditingController _kodeController = TextEditingController();
  GrupKas? _grupDitemukan;
  bool _sedangMencari = false;
  bool _sedangGabung = false;
  Timer? _debounceTimer;

  static const Color _primaryGreen = Color(0xFF074E3B);

  @override
  void initState() {
    super.initState();
    _kodeController.addListener(_onKodeChanged);
  }

  void _onKodeChanged() {
    _debounceTimer?.cancel();
    final text = _kodeController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _grupDitemukan = null;
        _sedangMencari = false;
      });
      return;
    }

    // Debounce 450ms agar tidak spam Firestore saat mengetik
    _debounceTimer = Timer(const Duration(milliseconds: 450), () {
      _cariGrup(text);
    });
  }

  Future<void> _cariGrup(String kode) async {
    final target = kode.trim().toUpperCase();
    if (target.isEmpty) return;

    setState(() {
      _sedangMencari = true;
    });

    final hasil = await kasStore.cariGrupByKodeAsync(target);

    if (mounted) {
      setState(() {
        _grupDitemukan = hasil;
        _sedangMencari = false;
      });
    }
  }

  Future<void> _bukaScanner() async {
    final hasil = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanQrScreen()),
    );
    if (hasil != null && hasil.isNotEmpty) {
      _kodeController.text = hasil;
      _cariGrup(hasil);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kode QR "$hasil" berhasil dipindai!'),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _prosesGabung() async {
    final kode = _kodeController.text.trim();
    if (kode.isEmpty || _grupDitemukan == null) return;

    setState(() => _sedangGabung = true);

    try {
      final sukses = await kasStore.gabungGrupAsync(kode);
      if (sukses && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil bergabung ke ${_grupDitemukan!.namaGrup}!',
            ),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal bergabung ke grup. Silakan coba lagi.'),
            backgroundColor: Color(0xFFB91C1C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final pesan = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pesan),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sedangGabung = false);
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _kodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kodeInput = _kodeController.text.trim();
    final myUid = kasStore.currentUserUid;
    final isBlacklisted = _grupDitemukan != null &&
        myUid.isNotEmpty &&
        _grupDitemukan!.blacklistUids.contains(myUid);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Gabung ke grup',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Masukkan kode undangan valid dari bendahara untuk sinkronisasi',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Kode undangan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _kodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Contoh: KM26-ABCD atau KS2B-7X4Q',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Pindai QR Code',
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: _primaryGreen,
                    ),
                    onPressed: _bukaScanner,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _primaryGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _bukaScanner,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text(
                  'Pindai QR Code Undangan',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryGreen,
                  side: const BorderSide(color: _primaryGreen),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Kartu Status Validasi Real-time Cloud
              _buildStatusCard(kodeInput, isBlacklisted: isBlacklisted),

              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton(
                  onPressed: (_grupDitemukan == null || _sedangGabung || _sedangMencari || isBlacklisted)
                      ? null
                      : _prosesGabung,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _sedangGabung
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Gabung grup',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String kodeInput, {bool isBlacklisted = false}) {
    if (_sedangMencari) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Mencari grup di Cloud Firestore...',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    if (kodeInput.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF6B7280)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ketik kode grup atau pindai QR Code di atas',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      );
    }

    if (isBlacklisted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.block_rounded, size: 18, color: Color(0xFFB91C1C)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Akses ditolak: Kamu telah dikeluarkan dari grup ini dan tidak dapat bergabung kembali tanpa izin bendahara.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final cocok = _grupDitemukan != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cocok ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cocok ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                cocok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                size: 18,
                color: cocok ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cocok
                      ? '${_grupDitemukan!.namaGrup} • ${_grupDitemukan!.anggota.length} anggota'
                      : 'Kode grup tidak ditemukan di Cloud Firestore',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cocok ? _primaryGreen : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ),
          if (cocok) ...[
            const SizedBox(height: 4),
            Text(
              'Bendahara: ${_grupDitemukan!.bendahara}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF065F46),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
