import 'package:flutter/material.dart';
import '../data/kas_store.dart';

class RiwayatScreen extends StatefulWidget {
  final int initialTab;
  const RiwayatScreen({super.key, this.initialTab = 0});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterPembayaran = 'Semua'; // 'Semua', 'Lunas', 'Menunggu', 'Dibatalkan'
  String _filterPengeluaran = 'Semua'; // 'Semua', 'Kas grup', 'Talangan'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      initialIndex: widget.initialTab,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

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

        // Filter list Pembayaran
        final List<dynamic> listPembayaran;
        if (_filterPembayaran == 'Menunggu') {
          listPembayaran = state.daftarKonfirmasi.where((k) {
            if (_searchQuery.isEmpty) return true;
            return k.namaAnggota.toLowerCase().contains(_searchQuery) ||
                k.judulTagihan.toLowerCase().contains(_searchQuery) ||
                k.nominal.toString().contains(_searchQuery);
          }).toList();
        } else {
          listPembayaran = state.daftarRiwayatPembayaran.where((item) {
            if (_filterPembayaran == 'Lunas' && item.status != 'Lunas') {
              return false;
            }
            if (_filterPembayaran == 'Dibatalkan' && item.status != 'Dibatalkan') {
              return false;
            }
            if (_searchQuery.isEmpty) return true;
            return item.namaAnggota.toLowerCase().contains(_searchQuery) ||
                item.judulTagihan.toLowerCase().contains(_searchQuery) ||
                item.nominal.toString().contains(_searchQuery);
          }).toList();
        }

        // Filter list Pengeluaran
        final listPengeluaran = state.daftarTagihan.where((t) {
          if (_filterPengeluaran == 'Kas grup' && t.sumberDana != 'Kas grup') {
            return false;
          }
          if (_filterPengeluaran == 'Talangan' && t.sumberDana == 'Kas grup') {
            return false;
          }
          if (_searchQuery.isEmpty) return true;
          return t.judul.toLowerCase().contains(_searchQuery) ||
              t.namaPenerima.toLowerCase().contains(_searchQuery) ||
              t.total.toString().contains(_searchQuery) ||
              t.items.any((i) => i.nama.toLowerCase().contains(_searchQuery));
        }).toList();

        final filterOptions = _tabController.index == 0
            ? const ['Semua', 'Lunas', 'Menunggu', 'Dibatalkan']
            : const ['Semua', 'Kas grup', 'Talangan'];

        final currentFilter =
            _tabController.index == 0 ? _filterPembayaran : _filterPengeluaran;

        return Scaffold(
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
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF074E3B),
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: const Color(0xFF074E3B),
              tabs: const [
                Tab(text: 'Pembayaran'),
                Tab(text: 'Pengeluaran'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Search field & filter chips (Poin 22)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: _tabController.index == 0
                            ? 'Cari nama anggota, tagihan, nominal...'
                            : 'Cari pengeluaran, barang, nominal...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
                    const SizedBox(height: 10),
                    // Filter Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filterOptions.map((opt) {
                          final selected = currentFilter == opt;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                opt,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? const Color(0xFF074E3B)
                                      : const Color(0xFF475569),
                                ),
                              ),
                              selected: selected,
                              selectedColor: const Color(0xFFDCFCE7),
                              backgroundColor: const Color(0xFFF1F5F9),
                              side: BorderSide(
                                color: selected
                                    ? const Color(0xFF074E3B)
                                    : const Color(0xFFE2E8F0),
                                width: selected ? 1.2 : 1,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  if (_tabController.index == 0) {
                                    _filterPembayaran = opt;
                                  } else {
                                    _filterPengeluaran = opt;
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // Content TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 0: Pembayaran
                    listPembayaran.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _searchQuery.isNotEmpty ||
                                            _filterPembayaran != 'Semua'
                                        ? Icons.search_off_rounded
                                        : Icons.receipt_long_outlined,
                                    size: 48,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isNotEmpty ||
                                            _filterPembayaran != 'Semua'
                                        ? 'Tidak ada riwayat pembayaran yang cocok'
                                        : 'Belum ada riwayat pembayaran terverifikasi.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty ||
                                      _filterPembayaran != 'Semua') ...[
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Coba ubah kata kunci atau ganti filter chip di atas',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: listPembayaran.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final raw = listPembayaran[index];

                              // Jika item dari antrean konfirmasi (Menunggu)
                              if (raw is KonfirmasiItem) {
                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFFED7AA),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Color(0xFFFEF3C7),
                                        child: Icon(
                                          Icons.hourglass_top_rounded,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              raw.namaAnggota,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${raw.judulTagihan} • ${raw.waktuUnggah}',
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
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            formatRupiah(raw.nominal),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                          const Text(
                                            'Menunggu',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFD97706),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // Item RiwayatPembayaran biasa
                              final item = raw as RiwayatPembayaranItem;
                              final isLunas = item.status == 'Lunas';
                              final isBatal = item.status == 'Dibatalkan';
                              final isAnggotaAktif = state.anggota.any(
                                (a) =>
                                    a.nama.toLowerCase() ==
                                    item.namaAnggota.toLowerCase(),
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
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF1F5F9),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color:
                                                          const Color(0xFFCBD5E1),
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
                                    const SizedBox(width: 8),
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

                    // Tab 1: Pengeluaran
                    listPengeluaran.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _searchQuery.isNotEmpty ||
                                            _filterPengeluaran != 'Semua'
                                        ? Icons.search_off_rounded
                                        : Icons.receipt_long_outlined,
                                    size: 48,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isNotEmpty ||
                                            _filterPengeluaran != 'Semua'
                                        ? 'Tidak ada catatan pengeluaran yang cocok'
                                        : 'Belum ada catatan pengeluaran.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty ||
                                      _filterPengeluaran != 'Semua') ...[
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Coba ubah kata kunci atau ganti filter chip di atas',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: listPengeluaran.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final t = listPengeluaran[index];
                              final isTalangan = t.sumberDana != 'Kas grup' &&
                                  t.namaPenerima.isNotEmpty;
                              final isPenerimaAktif = !isTalangan ||
                                  state.anggota.any(
                                    (a) =>
                                        (t.penerimaId.isNotEmpty &&
                                            (a.uid == t.penerimaId ||
                                                a.id == t.penerimaId)) ||
                                        a.nama.toLowerCase() ==
                                            t.namaPenerima.toLowerCase(),
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
                                    const SizedBox(width: 8),
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
                                        onTap: () =>
                                            _tampilkanDialogBatal(context, t),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF2F2),
                                            borderRadius:
                                                BorderRadius.circular(8),
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
            ],
          ),
        );
      },
    );
  }
}
