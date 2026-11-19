import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import '../data/kas_store.dart';

class StatistikScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const StatistikScreen({super.key, this.onBack});

  @override
  State<StatistikScreen> createState() => _StatistikScreenState();
}

class _StatistikScreenState extends State<StatistikScreen> {
  static const Color _primaryGreen = Color(0xFF074E3B);
  static const Color _darkBg = Color(0xFF0F172A);

  String _selectedPeriode = 'Bulan Ini';
  int _touchedPieIndex = -1;

  final List<String> _periodeList = const [
    'Bulan Ini',
    'Bulan Lalu',
    '6 Bulan Terakhir',
  ];

  static const List<String> _namaBulanSingkat = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  List<String> _getBulanLabels() {
    final now = DateTime.now();
    final labels = <String>[];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      labels.add(_namaBulanSingkat[d.month - 1]);
    }
    return labels;
  }

  DateTime? _parseTanggal(TagihanKas t) {
    if (t.jatuhTempo != null) return t.jatuhTempo;
    final s = t.tanggal.trim();
    if (s.isEmpty) return null;

    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    final lower = s.toLowerCase();
    if (lower.contains('bulan ini') || lower.contains('hari ini')) {
      return DateTime.now();
    }
    if (lower.contains('kemarin')) {
      return DateTime.now().subtract(const Duration(days: 1));
    }

    final parts = s.split(' ');
    if (parts.length >= 3) {
      final day = int.tryParse(parts[0]);
      final year = int.tryParse(parts[2].replaceAll(',', ''));
      final monthStr = parts[1].toLowerCase();

      int? month;
      const monthMap = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'mei': 5,
        'may': 5,
        'jun': 6,
        'juni': 6,
        'jul': 7,
        'agu': 8,
        'ags': 8,
        'agt': 8,
        'sep': 9,
        'okt': 10,
        'oct': 10,
        'nov': 11,
        'des': 12,
        'dec': 12,
      };

      for (final entry in monthMap.entries) {
        if (monthStr.startsWith(entry.key)) {
          month = entry.value;
          break;
        }
      }

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  List<TagihanKas> _filterTagihanPeriode(List<TagihanKas> list) {
    final now = DateTime.now();
    if (_selectedPeriode == 'Bulan Ini') {
      return list.where((t) {
        final dt = _parseTanggal(t);
        if (dt == null) return true;
        return dt.year == now.year && dt.month == now.month;
      }).toList();
    } else if (_selectedPeriode == 'Bulan Lalu') {
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      return list.where((t) {
        final dt = _parseTanggal(t);
        if (dt == null) return false;
        return dt.year == lastMonth.year && dt.month == lastMonth.month;
      }).toList();
    } else {
      // 6 Bulan Terakhir
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
      return list.where((t) {
        final dt = _parseTanggal(t);
        if (dt == null) return true;
        return dt.isAfter(sixMonthsAgo) || dt.isAtSameMomentAs(sixMonthsAgo);
      }).toList();
    }
  }

  int _hitungTotalPengeluaranPeriode(GrupKas g, List<TagihanKas> filteredTagihan) {
    final sumFiltered = filteredTagihan.fold<int>(0, (sum, t) => sum + t.total);
    if (_selectedPeriode == 'Bulan Ini' || _selectedPeriode == '6 Bulan Terakhir') {
      return sumFiltered > 0 ? sumFiltered : g.pengeluaran;
    }
    return sumFiltered;
  }

  int _hitungTotalPemasukanPeriode(GrupKas g) {
    final lunasList = g.daftarRiwayatPembayaran.where((r) => r.status.toLowerCase() == 'lunas');
    final sumLunas = lunasList.fold<int>(0, (sum, r) => sum + r.nominal);
    return sumLunas > 0 ? sumLunas : g.pemasukan;
  }

  // Data kategori riil dengan validasi fallback data transaksi riil (Poin 42) & perluasan kamus kata kunci (Poin 52)
  List<_KategoriData> _hitungKategori(
    GrupKas grup,
    List<TagihanKas> tagihanList,
    int totalPengeluaran,
  ) {
    int utilitas = 0;
    int belanja = 0;
    int makanan = 0;
    int lainnya = 0;

    const kataKunciUtilitas = [
      'wifi', 'wi-fi', 'internet', 'indihome', 'biznet', 'firstmedia',
      'listrik', 'pln', 'token', 'air', 'pdam', 'kas bulanan', 'iuran',
      'kebersihan', 'keamanan', 'satpam', 'kos', 'kontrakan', 'sewa',
      'maintenance', 'servis', 'service',
    ];

    const kataKunciBelanja = [
      'belanja', 'dapur', 'galon', 'aqua', 'le minerale', 'sembako', 'beras',
      'minyak', 'telur', 'sabun', 'shampoo', 'deterjen', 'odol', 'tisu', 'tissue',
      'sapu', 'pel', 'supermarket', 'minimarket', 'indomaret', 'alfamart',
      'hypermart', 'transmart', 'alat', 'atk', 'print', 'fotokopi', 'modul',
      'buku', 'kertas',
    ];

    const kataKunciMakanan = [
      'makan', 'minum', 'kopi', 'coffee', 'cafe', 'kafe', 'snack', 'cemilan',
      'sarapan', 'lunch', 'dinner', 'bukber', 'nasi', 'mie', 'bakso', 'sate',
      'ayam', 'bebek', 'daging', 'sapi', 'kambing', 'ikan', 'seafood', 'udang',
      'cumi', 'martabak', 'gorengan', 'roti', 'kue', 'boba', 'teh', 'jus',
      'juice', 'es ', 'burger', 'pizza', 'resto', 'restaurant', 'warung',
      'warkop', 'geprek', 'pecel', 'soto', 'rawon', 'gudeg', 'rendang',
      'padang', 'katering', 'catering', 'gofood', 'grabfood', 'shopeefood',
    ];

    bool cocokKataKunci(TagihanKas t, List<String> kataKunci) {
      final j = t.judul.toLowerCase();
      if (kataKunci.any((k) => j.contains(k))) return true;
      for (final item in t.items) {
        final itemNama = item.nama.toLowerCase();
        if (kataKunci.any((k) => itemNama.contains(k))) return true;
      }
      return false;
    }

    for (final t in tagihanList) {
      if (cocokKataKunci(t, kataKunciUtilitas)) {
        utilitas += t.total;
      } else if (cocokKataKunci(t, kataKunciBelanja)) {
        belanja += t.total;
      } else if (cocokKataKunci(t, kataKunciMakanan)) {
        makanan += t.total;
      } else {
        lainnya += t.total;
      }
    }

    // Fallback stabilitas data: jika rincian tagihan belum sinkron tapi ada catatan pengeluaran kas
    if (tagihanList.isEmpty && totalPengeluaran > 0) {
      lainnya = totalPengeluaran;
    }

    final total = utilitas + belanja + makanan + lainnya;

    return [
      _KategoriData(
        nama: 'Utilitas & Tagihan',
        nominal: utilitas,
        persentase: total > 0 ? (utilitas / total * 100) : 0,
        color: const Color(0xFF0D9488),
        icon: Icons.bolt_rounded,
      ),
      _KategoriData(
        nama: 'Belanja Kebutuhan',
        nominal: belanja,
        persentase: total > 0 ? (belanja / total * 100) : 0,
        color: const Color(0xFF10B981),
        icon: Icons.shopping_bag_outlined,
      ),
      _KategoriData(
        nama: 'Makanan & Konsumsi',
        nominal: makanan,
        persentase: total > 0 ? (makanan / total * 100) : 0,
        color: const Color(0xFFF59E0B),
        icon: Icons.restaurant_rounded,
      ),
      _KategoriData(
        nama: 'Lain-lain & Opsional',
        nominal: lainnya,
        persentase: total > 0 ? (lainnya / total * 100) : 0,
        color: const Color(0xFF6366F1),
        icon: Icons.category_outlined,
      ),
    ];
  }

  // Tren pengeluaran 6 bulan terakhir dinamis dari data transaksi riil
  List<double> _getMonthlySpending(GrupKas grup) {
    final now = DateTime.now();
    final values = <double>[];
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthName = _namaBulanSingkat[monthDate.month - 1].toLowerCase();
      final yearStr = monthDate.year.toString();

      int monthTotal = 0;
      for (final t in grup.daftarTagihan) {
        final dt = _parseTanggal(t);
        if (dt != null) {
          if (dt.year == monthDate.year && dt.month == monthDate.month) {
            monthTotal += t.total;
          }
        } else {
          final tgl = t.tanggal.toLowerCase();
          if (tgl.contains(monthName) &&
              (tgl.contains(yearStr) || tgl.contains(yearStr.substring(2)))) {
            monthTotal += t.total;
          }
        }
      }

      if (i == 0 && monthTotal == 0 && grup.pengeluaran > 0) {
        monthTotal = grup.pengeluaran;
      }

      values.add((monthTotal / 1000).toDouble());
    }
    return values;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<KasRootState>(
      valueListenable: kasStore,
      builder: (context, rootState, _) {
        final g = rootState.grupAktif;
        final filteredTagihan = _filterTagihanPeriode(g.daftarTagihan);
        final totalPengeluaranPeriode = _hitungTotalPengeluaranPeriode(g, filteredTagihan);
        final totalPemasukanPeriode = _hitungTotalPemasukanPeriode(g);
        final kategoriList = _hitungKategori(g, filteredTagihan, totalPengeluaranPeriode);
        final monthlySpending = _getMonthlySpending(g);
        final bulanLabels = _getBulanLabels();
        final totalKategori =
            kategoriList.fold<int>(0, (sum, k) => sum + k.nominal);
        final kategoriTerbesar = totalKategori > 0
            ? kategoriList.reduce(
                (curr, next) => curr.persentase > next.persentase ? curr : next,
              )
            : null;

        final sumSpending = monthlySpending.reduce((a, b) => a + b);
        final rataRata = monthlySpending.isNotEmpty
            ? (sumSpending / monthlySpending.length * 1000).round()
            : 0;

        final maxSpending =
            monthlySpending.isEmpty ? 100.0 : monthlySpending.reduce(max);
        final chartMaxY = maxSpending > 0
            ? (maxSpending * 1.3).ceilToDouble()
            : 100.0;
        final gridInterval = (chartMaxY / 4).clamp(10.0, double.infinity).ceilToDouble();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8FAFC),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            leading: (widget.onBack != null || Navigator.canPop(context))
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: _darkBg, size: 20),
                      ),
                    ),
                  )
                : null,
            title: const Text(
              'Statistik Pengeluaran',
              style: TextStyle(
                color: _darkBg,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriode,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: _primaryGreen),
                    style: const TextStyle(
                      color: _darkBg,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    items: _periodeList.map((String p) {
                      return DropdownMenuItem<String>(
                        value: p,
                        child: Text(p),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPeriode = val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================== MAIN ANALYTICS CARD (FINTECH STYLE) ====================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF0F766E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF064E3B).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.query_stats_rounded, size: 16, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Pelacak Pengeluaran',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _selectedPeriode,
                                style: const TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          formatRupiah(totalPengeluaranPeriode),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total pengeluaran (${_selectedPeriode.toLowerCase()}) di ${g.namaGrup}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sub Metric Badges: Row 1 (Pemasukan Kas & Saldo Kas)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF6EE7B7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.arrow_downward_rounded, size: 14, color: _primaryGreen),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Pemasukan Kas',
                                            style: TextStyle(fontSize: 10, color: Colors.white70),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            formatRupiah(totalPemasukanPeriode),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF93C5FD),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.account_balance_wallet_outlined, size: 14, color: Color(0xFF1E3A8A)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Saldo Kas Grup',
                                            style: TextStyle(fontSize: 10, color: Colors.white70),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            formatRupiah(g.saldo),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Sub Metric Badges: Row 2 (Rata-rata/Bln & Top Kategori)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF34D399),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.show_chart_rounded, size: 14, color: _primaryGreen),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Rata-rata/Bln',
                                            style: TextStyle(fontSize: 10, color: Colors.white70),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            formatRupiah(rataRata),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFDE047),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.pie_chart_rounded, size: 14, color: Color(0xFF854D0E)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Top Kategori',
                                            style: TextStyle(fontSize: 10, color: Colors.white70),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            kategoriTerbesar != null
                                                ? '${kategoriTerbesar.nama.split(' ').first} (${kategoriTerbesar.persentase.toStringAsFixed(0)}%)'
                                                : 'Belum ada',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
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

                  const SizedBox(height: 24),

                  // ==================== BAR CHART TREN BULANAN ====================
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bar_chart_rounded, size: 16, color: _primaryGreen),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tren Pengeluaran 6 Bulan Terakhir',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _darkBg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 22, 20, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 190,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: chartMaxY,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => const Color(0xFF0F172A),
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final bln = bulanLabels[group.x];
                                    final val = formatRupiah((rod.toY * 1000).toInt());
                                    return BarTooltipItem(
                                      '$bln\n$val',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 42,
                                    getTitlesWidget: (value, meta) {
                                      if (value > 0 && (value % gridInterval).abs() < 1) {
                                        return Text(
                                          '${value.toInt()}k',
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx >= 0 && idx < bulanLabels.length) {
                                        final isCurrent = idx == bulanLabels.length - 1;
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            bulanLabels[idx],
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                                              color: isCurrent ? _primaryGreen : const Color(0xFF64748B),
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: gridInterval,
                                getDrawingHorizontalLine: (value) => const FlLine(
                                  color: Color(0xFFF1F5F9),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(
                                monthlySpending.length,
                                (i) {
                                  final isCurrent = i == monthlySpending.length - 1;
                                  return BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: monthlySpending[i],
                                        color: isCurrent ? _primaryGreen : const Color(0xFF6EE7B7),
                                        width: 16,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            '* Ketuk batang grafik untuk melihat rincian nominal',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================== PIE CHART KATEGORI ====================
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.pie_chart_rounded, size: 16, color: Color(0xFFB45309)),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Proporsi Pengeluaran per Kategori',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _darkBg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (totalKategori == 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(Icons.pie_chart_outline_rounded, size: 44, color: Color(0xFFCBD5E1)),
                                SizedBox(height: 8),
                                Text(
                                  'Belum ada transaksi pengeluaran tercatat',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          SizedBox(
                            height: 190,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedPieIndex = -1;
                                        return;
                                      }
                                      _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 3,
                                centerSpaceRadius: 40,
                                sections: List.generate(
                                  kategoriList.length,
                                  (i) {
                                    final isTouched = i == _touchedPieIndex;
                                    final k = kategoriList[i];
                                    final double fontSize = isTouched ? 13 : 11;
                                    final double radius = isTouched ? 58 : 50;

                                    if (k.nominal == 0) {
                                      return PieChartSectionData(
                                        color: Colors.transparent,
                                        value: 0,
                                        showTitle: false,
                                      );
                                    }

                                    return PieChartSectionData(
                                      color: k.color,
                                      value: k.persentase,
                                      title: '${k.persentase.toStringAsFixed(0)}%',
                                      radius: radius,
                                      titleStyle: TextStyle(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Breakdown Items
                        Column(
                          children: kategoriList.map((k) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: k.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(k.icon, size: 16, color: k.color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      k.nama,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _darkBg,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatRupiah(k.nominal),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _darkBg,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${k.persentase.toStringAsFixed(0)}%)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================== BREAKDOWN ANGGOTA ====================
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.people_outline_rounded, size: 16, color: Color(0xFF4338CA)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Status Iuran Anggota (${g.anggota.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _darkBg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: g.anggota.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final a = g.anggota[index];
                        final isTidakAda = a.status == StatusBayar.tidakAdaTagihan;
                        final isLunas = a.status == StatusBayar.lunas;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: a.avatarColor,
                            child: Text(
                              a.nama.isNotEmpty ? a.nama[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          title: Text(
                            a.nama,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _darkBg,
                            ),
                          ),
                          subtitle: Text(
                            isTidakAda
                                ? 'Tidak ada tanggungan'
                                : isLunas
                                    ? 'Semua tagihan lunas'
                                    : 'Tanggungan: ${formatRupiah(a.tagihan)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isTidakAda
                                  ? const Color(0xFF64748B)
                                  : isLunas
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB45309),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isTidakAda
                                  ? const Color(0xFFF1F5F9)
                                  : isLunas
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isTidakAda ? 'Bebas' : (isLunas ? 'Lunas' : 'Belum'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isTidakAda
                                    ? const Color(0xFF64748B)
                                    : isLunas
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _KategoriData {
  final String nama;
  final int nominal;
  final double persentase;
  final Color color;
  final IconData icon;

  const _KategoriData({
    required this.nama,
    required this.nominal,
    required this.persentase,
    required this.color,
    required this.icon,
  });
}
