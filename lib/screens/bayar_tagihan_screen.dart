import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/hitung_tagihan.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../data/kas_store.dart';
import '../services/firestore_service.dart';
import '../widgets/success_dialog.dart';

class BayarTagihanScreen extends StatefulWidget {
  final bool showBackButton;
  const BayarTagihanScreen({super.key, this.showBackButton = true});

  @override
  State<BayarTagihanScreen> createState() => _BayarTagihanScreenState();
}

class _BayarTagihanScreenState extends State<BayarTagihanScreen> {
  String? _selectedTagihanId;
  XFile? _buktiFoto;
  final ImagePicker _picker = ImagePicker();

  static const Color _primaryGreen = Color(0xFF074E3B);

  Future<void> _pilihSumberFoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unggah bukti transfer',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih foto struk/screenshot transfer dari perangkat kamu',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: _primaryGreen),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 800,
                  imageQuality: 50,
                );
                if (file != null && mounted) {
                  setState(() => _buktiFoto = file);
                }
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt_outlined, color: _primaryGreen),
              title: const Text('Ambil Foto Kamera'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 800,
                  imageQuality: 50,
                );
                if (file != null && mounted) {
                  setState(() => _buktiFoto = file);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<KasRootState>(
      valueListenable: kasStore,
      builder: (context, rootState, _) {
        final state = rootState.grupAktif;
        // Kunci pembayaran hanya untuk anggota yang sedang login (Poin 35 & 41)
        final me = kasStore.currentAnggota;
        final AnggotaKas? aktif = me != null &&
                (me.status == StatusBayar.belum || me.status == StatusBayar.menunggu) &&
                me.tagihan > 0
            ? me
            : null;

        final tagihanUntukSaya = me == null
            ? <TagihanKas>[]
            : state.daftarTagihan.where((t) =>
                t.porsiUntuk(me.id) > 0 &&
                !(t.sumberDana == 'Dana pribadi' && t.penerimaId == me.id) &&
                !kasStore.isTagihanLunasUntukAnggota(t, me),
              ).toList();
        final TagihanKas? tagihanAktif = tagihanUntukSaya.isEmpty
            ? null
            : tagihanUntukSaya.firstWhere(
                (t) => t.id == _selectedTagihanId,
                orElse: () => tagihanUntukSaya.first,
              );

        final totalTagihan = tagihanAktif != null && me != null
            ? tagihanAktif.porsiUntuk(me.id)
            : (aktif?.tagihan ?? 0);
        final adaPajak = tagihanAktif != null &&
            tagihanAktif.pajak > 0 &&
            tagihanAktif.total > 0;
        final bagianPajak = adaPajak
            ? (totalTagihan * (tagihanAktif.pajak / tagihanAktif.total)).round()
            : 0;
        final bagianDiskon = tagihanAktif != null && tagihanAktif.total > 0
            ? (totalTagihan * tagihanAktif.diskon / tagihanAktif.total).round()
            : 0;
        final bagianLayanan = tagihanAktif != null && tagihanAktif.total > 0
            ? (totalTagihan * tagihanAktif.biayaLayanan / tagihanAktif.total).round()
            : 0;
        final bagianItem = totalTagihan - bagianPajak - bagianLayanan + bagianDiskon;
        final labelPajak = adaPajak && tagihanAktif.pajakPersen > 0
            ? 'Bagian pajak (${formatPersenPajak(tagihanAktif.pajakPersen)}%)'
            : 'Bagian pajak';

        // Info transfer dinamis sesuai penerima tagihan / pihak yang menalangi
        final namaPenerima = (tagihanAktif != null && tagihanAktif.namaPenerima.isNotEmpty)
            ? tagihanAktif.namaPenerima
            : state.bendahara;
        final AnggotaKas? penerimaAnggota = state.anggota.cast<AnggotaKas?>().firstWhere(
          (a) => a != null && (
            (tagihanAktif != null && tagihanAktif.penerimaId.isNotEmpty && (a.id == tagihanAktif.penerimaId || a.uid == tagihanAktif.penerimaId)) ||
            (tagihanAktif != null && tagihanAktif.namaPenerima.isNotEmpty && a.nama.toLowerCase() == tagihanAktif.namaPenerima.toLowerCase()) ||
            a.nama.toLowerCase() == state.bendahara.toLowerCase()
          ),
          orElse: () => null,
        );

        final bankTujuan = (tagihanAktif != null && tagihanAktif.bankPenerima.isNotEmpty)
            ? tagihanAktif.bankPenerima
            : (penerimaAnggota != null && penerimaAnggota.bank.isNotEmpty
                ? penerimaAnggota.bank
                : 'Bank Belum Diatur');
        final rekTujuan = (tagihanAktif != null && tagihanAktif.rekPenerima.isNotEmpty)
            ? tagihanAktif.rekPenerima
            : (penerimaAnggota != null && penerimaAnggota.noRekening.isNotEmpty
                ? penerimaAnggota.noRekening
                : '-');

        final bool sudahAdaBuktiMenunggu = aktif != null &&
            state.daftarKonfirmasi.any((k) =>
                k.anggotaId == aktif.id &&
                (tagihanAktif == null ||
                    k.judulTagihan.toLowerCase() ==
                        tagihanAktif.judul.toLowerCase()));

        final bisaKirim = aktif != null && _buktiFoto != null;

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFAFAFA),
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: widget.showBackButton,
            iconTheme: const IconThemeData(color: Color(0xFF111827)),
            title: const Text(
              'Tagihan saya',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (aktif != null) ...[
                    Row(
                      children: [
                        const Text(
                          'Pembayar: ',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            aktif.nama,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (tagihanUntukSaya.length > 1) ...[
                    const Text(
                      'Pilih tagihan yang ingin dibayar:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: tagihanUntukSaya.map((t) {
                          final selected = (tagihanAktif?.id == t.id);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                '${t.judul} (${formatRupiah(t.porsiUntuk(me!.id))})',
                              ),
                              selected: selected,
                              selectedColor: const Color(0xFFDCFCE7),
                              onSelected: (_) {
                                setState(() {
                                  _selectedTagihanId = t.id;
                                  _buktiFoto = null;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (aktif == null) ...[
                    const SizedBox(height: 60),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 56, color: Color(0xFF10B981)),
                          const SizedBox(height: 12),
                          const Text(
                            'Tidak ada tagihan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Kamu tidak memiliki tagihan yang perlu dibayar saat ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                  if (sudahAdaBuktiMenunggu) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: Color(0xFFB45309)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bukti untuk tagihan ini sudah diunggah dan sedang menunggu verifikasi oleh $namaPenerima.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9A3412),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tagihanAktif?.judul ?? 'Tidak ada tagihan',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tagihanAktif?.tanggal ?? 'Semua sudah lunas',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: aktif.status == StatusBayar.menunggu
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                aktif.status == StatusBayar.menunggu
                                    ? 'Menunggu'
                                    : 'Belum bayar',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: aktif.status == StatusBayar.menunggu
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          formatRupiah(totalTagihan),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const Divider(color: Color(0xFFE5E7EB), height: 28),
                        _buildDetailRow(
                          'Bagian item belanja',
                          formatRupiah(bagianItem),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          adaPajak ? labelPajak : 'Pajak',
                          adaPajak ? formatRupiah(bagianPajak) : 'Tidak ada (Rp 0)',
                        ),
                        if (bagianDiskon > 0) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow('Bagian diskon', '-${formatRupiah(bagianDiskon)}'),
                        ],
                        if (bagianLayanan > 0) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow('Bagian biaya layanan', formatRupiah(bagianLayanan)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance_rounded,
                                    size: 14,
                                    color: _primaryGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tagihanAktif?.sumberDana == 'Kas grup'
                                        ? 'Transfer ke Kas Grup'
                                        : 'Transfer ke yang menalangi:',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$bankTujuan $rekTujuan',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'a.n. $namaPenerima',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.copy_outlined,
                            size: 20,
                            color: Color(0xFF6B7280),
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: rekTujuan));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nomor rekening disalin'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pilihSumberFoto,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _buktiFoto != null
                            ? const Color(0xFFECFDF5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _buktiFoto != null
                              ? _primaryGreen
                              : const Color(0xFFE5E7EB),
                          width: _buktiFoto != null ? 1.5 : 1,
                        ),
                      ),
                      child: _buktiFoto == null
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 28,
                                    color: _primaryGreen,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Unggah foto bukti transfer (Wajib)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Ketuk untuk memilih dari Galeri atau Kamera',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Maks. 5MB • Format JPG/PNG (otomatis dikompres)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: kIsWeb
                                      ? Image.network(
                                          _buktiFoto!.path,
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(_buktiFoto!.path),
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: _primaryGreen,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _buktiFoto!.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _primaryGreen,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _pilihSumberFoto,
                                      child: const Text('Ganti foto'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: ElevatedButton(
                      onPressed: () async {
                              final foto = _buktiFoto;
                              if (foto == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Wajib unggah foto bukti transfer terlebih dahulu!',
                                    ),
                                  ),
                                );
                                return;
                              }

                              // Konversi ke Base64 dan simpan ke subkoleksi bukti_transfer Firestore
                              final base64String =
                                  await firestoreService.fileToBase64(foto.path);
                              final buktiId =
                                  'bkt_${DateTime.now().millisecondsSinceEpoch}_${aktif.id}';
                              if (base64String.isNotEmpty) {
                                await firestoreService.simpanBuktiTransfer(
                                  grupId: state.id,
                                  buktiId: buktiId,
                                  base64Data: base64String,
                                  namaFile: foto.name,
                                );
                              }
                              final pathFinal = base64String.isNotEmpty
                                  ? buktiId
                                  : foto.path;

                              kasStore.ajukanPembayaran(
                                anggotaId: aktif.id,
                                namaFileBukti: foto.name,
                                buktiPath: pathFinal,
                                judulTagihan: tagihanAktif?.judul,
                                nominal: totalTagihan,
                                penerimaId: tagihanAktif?.penerimaId,
                                namaPenerima: tagihanAktif?.namaPenerima,
                                sumberDana: tagihanAktif?.sumberDana,
                              );
                              if (mounted) {
                                setState(() => _buktiFoto = null);
                              }
                              if (context.mounted) {
                                KasSuccessDialog.show(
                                  context,
                                  title: 'Bukti Terkirim!',
                                  message:
                                      'Bukti transfer ${aktif.nama} telah dikirim ke bendahara dan sedang menunggu verifikasi.',
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            bisaKirim ? _primaryGreen : const Color(0xFF9CA3AF),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        bisaKirim
                            ? (sudahAdaBuktiMenunggu
                                ? 'Ganti bukti & kirim ulang'
                                : 'Tandai sudah bayar')
                            : (sudahAdaBuktiMenunggu
                                ? 'Bukti sudah terkirim (Menunggu verifikasi)'
                                : 'Unggah bukti dulu untuk mengirim'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  ], // end else aktif != null
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
