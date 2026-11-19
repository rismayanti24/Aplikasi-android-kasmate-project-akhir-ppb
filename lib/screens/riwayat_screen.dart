import 'package:flutter/material.dart';
import '../data/kas_store.dart';

class RiwayatScreen extends StatelessWidget {
  final int initialTab;
  const RiwayatScreen({super.key, this.initialTab = 0});

  void _tampilkanDialogBatal(BuildContext context, TagihanKas t) {
    final alasanController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Batalkan Transaksi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin membatalkan pengeluaran "${t.judul}" (${formatRupiah(t.total)})?',
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tindakan ini akan mengembalikan saldo, mengoreksi tanggungan anggota, dan dicatat pada audit trail riwayat.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: alasanController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Alasan pembatalan (wajib)',
                  hintText: 'Contoh: Salah input nominal / nota batal',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF074E3B)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Alasan pembatalan wajib diisi';
                  }
                  if (val.trim().length < 3) {
                    return 'Alasan terlalu singkat (min. 3 karakter)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final alasan = alasanController.text.trim();
                Navigator.pop(dialogCtx);
                final sukses = kasStore.batalkanTagihan(t.id, alasan: alasan);
                if (sukses) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pengeluaran "${t.judul}" berhasil dibatalkan'),
                      backgroundColor: const Color(0xFF074E3B),
                    ),
                  );
                }
              }
            },
            child: const Text('Konfirmasi Pembatalan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<KasRootState>(
      valueListenable: kasStore,
      builder: (context, rootState, _) {
        final state = rootState.grupAktif;
        final isBendahara = kasStore.isBendahara(state);

        return DefaultTabController(
          length: 2,
          initialIndex: initialTab,
          child: Scaffold(
            backgroundColor: const Color(0xFFFAFAFA),
            appBar: AppBar(
              backgroundColor: const Color(0xFFFAFAFA),
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF111827)),
              title: const Text(
                'Riwayat transaksi',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              bottom: const TabBar(
                labelColor: Color(0xFF074E3B),
                unselectedLabelColor: Color(0xFF6B7280),
                indicatorColor: Color(0xFF074E3B),
                tabs: [
                  Tab(text: 'Pembayaran'),
                  Tab(text: 'Pengeluaran'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                state.daftarRiwayatPembayaran.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada riwayat pembayaran terverifikasi.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: state.daftarRiwayatPembayaran.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = state.daftarRiwayatPembayaran[index];
                          final isLunas = item.status == 'Lunas';
                          final isBatal = item.status == 'Dibatalkan';
                          final isAnggotaAktif = state.anggota.any(
                            (a) => a.nama.toLowerCase() == item.namaAnggota.toLowerCase(),
                          );

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isBatal
                                    ? const Color(0xFFFECACA)
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isLunas
                                      ? const Color(0xFFDCFCE7)
                                      : (isBatal
                                          ? const Color(0xFFFEF2F2)
                                          : const Color(0xFFFEE2E2)),
                                  child: Icon(
                                    isLunas
                                        ? Icons.check_rounded
                                        : (isBatal
                                            ? Icons.block_rounded
                                            : Icons.close_rounded),
                                    color: isLunas
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              item.namaAnggota,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (!isAnggotaAktif) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: const Color(0xFFCBD5E1),
                                                ),
                                              ),
                                              child: const Text(
                                                'Keluar',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        '${item.judulTagihan} • ${item.waktu}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      if (item.catatan != null &&
                                          item.catatan!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Alasan: ${item.catatan}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: Color(0xFFDC2626),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formatRupiah(item.nominal),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        decoration: isBatal
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: isBatal
                                            ? const Color(0xFF9CA3AF)
                                            : const Color(0xFF111827),
                                      ),
                                    ),
                                    Text(
                                      item.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isLunas
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                state.daftarTagihan.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada catatan pengeluaran.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: state.daftarTagihan.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final t = state.daftarTagihan[index];
                          final isTalangan = t.sumberDana != 'Kas grup' && t.namaPenerima.isNotEmpty;
                          final isPenerimaAktif = !isTalangan ||
                              state.anggota.any(
                                (a) =>
                                    (t.penerimaId.isNotEmpty &&
                                        (a.uid == t.penerimaId || a.id == t.penerimaId)) ||
                                    a.nama.toLowerCase() == t.namaPenerima.toLowerCase(),
                              );

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.judul,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${t.tanggal} • ${t.sumberDana}${isTalangan ? " (${t.namaPenerima}${isPenerimaAktif ? "" : " - Keluar"})" : ""} • ${t.items.length} item',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatRupiah(t.total),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                // Tombol Batalkan Transaksi khusus Bendahara (Poin 3)
                                if (isBendahara) ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _tampilkanDialogBatal(context, t),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFFECACA),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.cancel_outlined,
                                            size: 13,
                                            color: Color(0xFFDC2626),
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'Batalkan',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFDC2626),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
