import 'package:flutter/material.dart';
import '../data/kas_store.dart';
import 'konfirmasi_pembayaran_screen.dart';
import 'bayar_tagihan_screen.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  static const Color _primaryGreen = Color(0xFF074E3B);
  int _selectedFilter = 0; // 0: Semua, 1: Tagihan, 2: Pembayaran, 3: Anggota

  List<NotifikasiItem> _filterNotifikasi(List<NotifikasiItem> items) {
    if (_selectedFilter == 1) {
      return items.where((n) => n.tipe == TipeNotifikasi.tagihanBaru).toList();
    } else if (_selectedFilter == 2) {
      return items
          .where(
            (n) =>
                n.tipe == TipeNotifikasi.buktiPembayaran ||
                n.tipe == TipeNotifikasi.konfirmasiLunas ||
                n.tipe == TipeNotifikasi.konfirmasiTolak,
          )
          .toList();
    } else if (_selectedFilter == 3) {
      return items
          .where(
            (n) =>
                n.tipe == TipeNotifikasi.anggotaBaru ||
                n.tipe == TipeNotifikasi.pengingatWa,
          )
          .toList();
    }
    return items;
  }

  Map<String, List<NotifikasiItem>> _groupByTimeline(
      List<NotifikasiItem> items) {
    final Map<String, List<NotifikasiItem>> groups = {};
    for (final item in items) {
      final key = item.kelompokWaktu.isNotEmpty ? item.kelompokWaktu : 'Lainnya';
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<KasRootState>(
      valueListenable: kasStore,
      builder: (context, rootState, _) {
        final g = rootState.grupAktif;
        final semuaNotifikasi = g.daftarNotifikasi;
        final filteredList = _filterNotifikasi(semuaNotifikasi);
        final grouped = _groupByTimeline(filteredList);
        final unreadCount = kasStore.jumlahNotifikasiBelumDibaca;

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFAFAFA),
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Row(
              children: [
                const Text(
                  'Pusat Notifikasi',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount baru',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _primaryGreen,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: () {
                    kasStore.tandaiSemuaNotifikasiDibaca();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Semua notifikasi ditandai dibaca'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text(
                    'Baca semua',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: _primaryGreen,
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      _buildFilterChip('Semua', 0, semuaNotifikasi.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Tagihan',
                        1,
                        semuaNotifikasi
                            .where((n) => n.tipe == TipeNotifikasi.tagihanBaru)
                            .length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Pembayaran',
                        2,
                        semuaNotifikasi
                            .where(
                              (n) =>
                                  n.tipe == TipeNotifikasi.buktiPembayaran ||
                                  n.tipe == TipeNotifikasi.konfirmasiLunas ||
                                  n.tipe == TipeNotifikasi.konfirmasiTolak,
                            )
                            .length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Anggota & WA',
                        3,
                        semuaNotifikasi
                            .where(
                              (n) =>
                                  n.tipe == TipeNotifikasi.anggotaBaru ||
                                  n.tipe == TipeNotifikasi.pengingatWa,
                            )
                            .length,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Daftar Notifikasi / Empty State
                Expanded(
                  child: filteredList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          itemCount: grouped.keys.length,
                          itemBuilder: (context, groupIndex) {
                            final timelineKey =
                                grouped.keys.elementAt(groupIndex);
                            final notifItems = grouped[timelineKey]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 12, bottom: 8, left: 4),
                                  child: Text(
                                    timelineKey,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6B7280),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                ...notifItems.map(
                                  (item) => _buildNotifikasiCard(context, item),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, int index, int count) {
    final isSelected = _selectedFilter == index;
    return ChoiceChip(
      label: Text(count > 0 ? '$label ($count)' : label),
      selected: isSelected,
      selectedColor: const Color(0xFFDCFCE7),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? _primaryGreen : const Color(0xFF4B5563),
      ),
      side: BorderSide(
        color: isSelected ? _primaryGreen : const Color(0xFFE5E7EB),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) {
        setState(() => _selectedFilter = index);
      },
    );
  }

  Widget _buildNotifikasiCard(BuildContext context, NotifikasiItem item) {
    final iconData = _getIconForType(item.tipe);
    final iconColor = _getColorForType(item.tipe);
    final iconBg = _getBgColorForType(item.tipe);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isDibaca ? Colors.white : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isDibaca
              ? const Color(0xFFE5E7EB)
              : const Color(0xFF86EFAC),
          width: item.isDibaca ? 1 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        item.judul,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: item.isDibaca
                              ? FontWeight.w600
                              : FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!item.isDibaca)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.pesan,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF4B5563),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),

                // Footer: Timestamp + Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.waktu,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    if (item.tipe == TipeNotifikasi.buktiPembayaran)
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const KonfirmasiPembayaranScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                'Periksa',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryGreen,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: _primaryGreen,
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (item.tipe == TipeNotifikasi.tagihanBaru)
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BayarTagihanScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                'Bayar',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryGreen,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: _primaryGreen,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada notifikasi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Semua aktivitas grup kamu akan muncul di sini.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(TipeNotifikasi tipe) {
    switch (tipe) {
      case TipeNotifikasi.buktiPembayaran:
        return Icons.hourglass_top_rounded;
      case TipeNotifikasi.konfirmasiLunas:
        return Icons.check_circle_rounded;
      case TipeNotifikasi.konfirmasiTolak:
        return Icons.cancel_rounded;
      case TipeNotifikasi.tagihanBaru:
        return Icons.receipt_long_rounded;
      case TipeNotifikasi.anggotaBaru:
        return Icons.person_add_rounded;
      case TipeNotifikasi.pengingatWa:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  Color _getColorForType(TipeNotifikasi tipe) {
    switch (tipe) {
      case TipeNotifikasi.buktiPembayaran:
        return const Color(0xFFB45309);
      case TipeNotifikasi.konfirmasiLunas:
        return const Color(0xFF15803D);
      case TipeNotifikasi.konfirmasiTolak:
        return const Color(0xFFB91C1C);
      case TipeNotifikasi.tagihanBaru:
        return const Color(0xFF074E3B);
      case TipeNotifikasi.anggotaBaru:
        return const Color(0xFF1D4ED8);
      case TipeNotifikasi.pengingatWa:
        return const Color(0xFF047857);
    }
  }

  Color _getBgColorForType(TipeNotifikasi tipe) {
    switch (tipe) {
      case TipeNotifikasi.buktiPembayaran:
        return const Color(0xFFFEF3C7);
      case TipeNotifikasi.konfirmasiLunas:
        return const Color(0xFFDCFCE7);
      case TipeNotifikasi.konfirmasiTolak:
        return const Color(0xFFFEE2E2);
      case TipeNotifikasi.tagihanBaru:
        return const Color(0xFFE6F4EA);
      case TipeNotifikasi.anggotaBaru:
        return const Color(0xFFDBEAFE);
      case TipeNotifikasi.pengingatWa:
        return const Color(0xFFD1FAE5);
    }
  }
}
