import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/kas_store.dart';

class BuatGrupScreen extends StatefulWidget {
  const BuatGrupScreen({super.key});

  @override
  State<BuatGrupScreen> createState() => _BuatGrupScreenState();
}

class _BuatGrupScreenState extends State<BuatGrupScreen> {
  final TextEditingController _namaGrupController = TextEditingController();
  late final String _inviteCode;
  String _tipeGrup = 'kasResmi';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    final acak =
        List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    _inviteCode = 'KM26-$acak';
  }

  @override
  void dispose() {
    _namaGrupController.dispose();
    super.dispose();
  }

  Future<void> _simpanDanBagikanWa({required bool bukaWa}) async {
    if (_namaGrupController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama grup terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final grup = await kasStore.buatGrupBaru(_namaGrupController.text, _inviteCode, _tipeGrup);

      if (bukaWa) {
        await kasStore.bagikanUndanganGrupWhatsApp(grup);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Grup "${grup.namaGrup}" (${grup.kodeUndangan}) berhasil dibuat!',
            ),
            backgroundColor: const Color(0xFF074E3B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat grup: $e'),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'Buat grup baru',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Jadi bendahara & bagikan link undangan ke anggota',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nama grup',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _namaGrupController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Kas Kos 3A',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF074E3B),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Tipe grup',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tipeGrup = 'kasResmi'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _tipeGrup == 'kasResmi' ? const Color(0xFFDCFCE7) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _tipeGrup == 'kasResmi' ? const Color(0xFF074E3B) : const Color(0xFFE5E7EB),
                            width: _tipeGrup == 'kasResmi' ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_rounded,
                                  size: 15,
                                  color: _tipeGrup == 'kasResmi' ? const Color(0xFF074E3B) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Kas Resmi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: _tipeGrup == 'kasResmi' ? const Color(0xFF074E3B) : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Ada saldo kas bersama & iuran rutin.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tipeGrup = 'patungan'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _tipeGrup == 'patungan' ? const Color(0xFFDCFCE7) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _tipeGrup == 'patungan' ? const Color(0xFF074E3B) : const Color(0xFFE5E7EB),
                            width: _tipeGrup == 'patungan' ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.splitscreen_rounded,
                                  size: 15,
                                  color: _tipeGrup == 'patungan' ? const Color(0xFF074E3B) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Patungan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: _tipeGrup == 'patungan' ? const Color(0xFF074E3B) : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Murni bagi tagihan / split bill kegiatan.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kode undangan grup',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _inviteCode,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: Color(0xFF074E3B),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.copy_outlined,
                            color: Color(0xFF6B7280),
                          ),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _inviteCode),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Kode undangan "$_inviteCode" disalin'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFE5E7EB)),
                    const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF074E3B)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bagikan kode di atas ke teman untuk bergabung melalui menu "Gabung Grup".',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _simpanDanBagikanWa(bukaWa: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF074E3B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.share_outlined, size: 19),
                label: Text(
                  _isLoading
                      ? 'Menyimpan ke Cloud...'
                      : 'Buat grup & Bagikan ke WhatsApp',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => _simpanDanBagikanWa(bukaWa: false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    foregroundColor: const Color(0xFF111827),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Buat grup saja',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
