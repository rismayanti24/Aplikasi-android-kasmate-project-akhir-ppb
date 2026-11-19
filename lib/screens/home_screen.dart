import 'package:flutter/material.dart';
import '../utils/input_validation.dart';
import '../widgets/dialog_setoran.dart';
import '../data/kas_store.dart';
import '../data/profil_store.dart';
import 'buat_grup_screen.dart';
import 'gabung_grup_screen.dart';
import 'bayar_tagihan_screen.dart';
import 'konfirmasi_pembayaran_screen.dart';
import 'riwayat_screen.dart';
import 'detail_grup_screen.dart';
import 'qr_grup_screen.dart';
import 'buat_tagihan_screen.dart';
import '../widgets/animated_counter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _primaryGreen = Color(0xFF074E3B);
  static const Color _emerald = Color(0xFF10B981);
  static const Color _darkBg = Color(0xFF0F172A);

  bool _sembunyikanSaldo = false;

  void _bukaDialogTambahAnggota(BuildContext context) {
    final namaCtrl = TextEditingController();
    final waCtrl = TextEditingController();
    final waKey = GlobalKey<FormFieldState<String>>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: _primaryGreen),
            SizedBox(width: 8),
            Text(
              'Tambah Anggota Grup',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nama anggota',
                hintText: 'Contoh: Budi Santoso',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: waKey,
              controller: waCtrl,
              keyboardType: TextInputType.phone,
              validator: validasiNomorWhatsApp,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Nomor WhatsApp (opsional)',
                hintText: '081234567890 / +6281234567890',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (namaCtrl.text.trim().isEmpty) return;
              if (!waKey.currentState!.validate()) return;
              kasStore.tambahAnggota(
                nama: namaCtrl.text,
                noWa: waCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${namaCtrl.text.trim()} berhasil ditambahkan!'),
                  backgroundColor: _primaryGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _bukaModalPilihGrup(BuildContext context, KasRootState rootState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grup Kas Saya',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _darkBg),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: rootState.daftarGrup.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final g = rootState.daftarGrup[idx];
                  final isAktif = g.id == rootState.aktifGrupId;
                  return Container(
                    decoration: BoxDecoration(
                      color: isAktif ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isAktif ? _emerald : const Color(0xFFE2E8F0),
                        width: isAktif ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isAktif ? _primaryGreen : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          g.tipeGrup == 'kasResmi' ? Icons.account_balance_rounded : Icons.splitscreen_rounded,
                          color: isAktif ? Colors.white : const Color(0xFF64748B),
                          size: 18,
                        ),
                      ),
                      title: Text(
                        g.namaGrup,
                        style: TextStyle(
                          fontWeight: isAktif ? FontWeight.w800 : FontWeight.w600,
                          color: isAktif ? _primaryGreen : _darkBg,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        '${g.kodeUndangan} • ${g.tipeGrup == 'kasResmi' ? 'Kas Resmi' : 'Patungan'} • ${g.anggota.length} anggota',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      trailing: isAktif
                          ? const Icon(Icons.check_circle_rounded, color: _primaryGreen)
                          : const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                      onTap: () {
                        kasStore.pilihGrupAktif(g.id);
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BuatGrupScreen()));
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Buat Grup'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryGreen,
                      side: const BorderSide(color: _primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GabungGrupScreen()));
                    },
                    icon: const Icon(Icons.group_add_rounded, size: 18),
                    label: const Text('Gabung'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _bukaSheetTagihWhatsApp(BuildContext context, GrupKas state) {
    final belumLunas = state.anggota
        .where((a) => a.status == StatusBayar.belum || a.status == StatusBayar.menunggu)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.chat_outlined, color: _primaryGreen, size: 22),
                SizedBox(width: 8),
                Text(
                  'Kirim Pengingat WhatsApp',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _darkBg),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih anggota yang memiliki tagihan belum lunas',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            if (belumLunas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Semua anggota sudah menyelesaikan tagihan.',
                    style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                  ),
                ),
              )
            else
              ...belumLunas.map(
                (anggota) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: anggota.avatarColor,
                    child: Text(
                      anggota.nama.isNotEmpty ? anggota.nama[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                  ),
                  title: Text(
                    anggota.nama,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: _darkBg),
                  ),
                  subtitle: Text(
                    'Tagihan: ${formatRupiah(anggota.tagihan)}',
                    style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w500),
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final berhasil = await kasStore.kirimTagihanWhatsApp(anggota);
                      if (!berhasil && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal membuka WhatsApp/Browser. Cek koneksi di perangkat.'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 14),
                    label: const Text('Ingatkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _tampilkanDialogIngatkanAnggota(BuildContext context, AnggotaKas a) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: a.avatarColor,
                  child: Text(
                    a.nama.isNotEmpty ? a.nama[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.nama,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkBg),
                      ),
                      Text(
                        'Total tagihan: ${formatRupiah(a.tagihan)}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Ingatkan via WhatsApp', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final berhasil = await kasStore.kirimTagihanWhatsApp(a);
                  if (!berhasil && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal membuka WhatsApp. Cek koneksi di perangkat.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
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
        if (!rootState.adaGrup) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _primaryGreen.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 64,
                          color: _primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Selamat Datang di KasMate',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _darkBg),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Kelola kas kelompok dan split bill bersama teman dengan mudah, rapi, dan transparan.',
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Buat Grup Baru', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuatGrupScreen())),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryGreen,
                            side: const BorderSide(color: _primaryGreen, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('Gabung Grup via Kode / QR', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GabungGrupScreen())),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final state = rootState.grupAktif;
        final profil = profilNotifier.value;
        final namaUser = profil.nama.isNotEmpty ? profil.nama : 'Teman';
        final namaPanggilan = namaUser.split(' ').first;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================== TOP BAR: PROFIL & AKSI ====================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Greeting & Switch Group Pill
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_primaryGreen, _emerald],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryGreen.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  namaPanggilan.isNotEmpty ? namaPanggilan[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Hi, $namaPanggilan',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: _darkBg,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  InkWell(
                                    onTap: () => _bukaModalPilihGrup(context, rootState),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            state.tipeGrup == 'kasResmi'
                                                ? Icons.account_balance_rounded
                                                : Icons.splitscreen_rounded,
                                            size: 13,
                                            color: _primaryGreen,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              state.namaGrup,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: _darkBg,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF64748B)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Quick Top Actions
                      Row(
                        children: [
                          _buildTopCircleButton(
                            icon: Icons.qr_code_2_rounded,
                            tooltip: 'QR Undangan Grup',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QrGrupScreen(grup: state))),
                          ),
                          const SizedBox(width: 8),
                          _buildTopCircleButton(
                            icon: Icons.history_rounded,
                            tooltip: 'Riwayat Transaksi',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatScreen())),
                          ),
                          Builder(
                            builder: (context) {
                              final antreanVerifikasi = state.daftarKonfirmasi
                                  .where((k) => kasStore.bisaVerifikasiKonfirmasi(k))
                                  .toList();
                              if (antreanVerifikasi.isEmpty) return const SizedBox.shrink();

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 8),
                                  _buildTopCircleButton(
                                    icon: Icons.verified_user_rounded,
                                    tooltip: 'Verifikasi Pembayaran (${antreanVerifikasi.length})',
                                    iconColor: const Color(0xFFB45309),
                                    bgColor: const Color(0xFFFEF3C7),
                                    badgeCount: antreanVerifikasi.length,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const KonfirmasiPembayaranScreen()),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ==================== MAIN FINTECH BALANCE CARD ====================
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
                          color: const Color(0xFF064E3B).withValues(alpha: 0.35),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF34D399),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    state.tipeGrup == 'kasResmi' ? 'Kas Resmi' : 'Patungan',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                _sembunyikanSaldo ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 20,
                              ),
                              onPressed: () => setState(() => _sembunyikanSaldo = !_sembunyikanSaldo),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          state.tipeGrup == 'kasResmi' ? 'Total Saldo Kas' : 'Total Pengeluaran Patungan',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: _sembunyikanSaldo
                                  ? const Text(
                                      'Rp ••••••••',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    )
                                  : AnimatedCounterRupiah(
                                      targetValue: state.tipeGrup == 'kasResmi' ? state.saldo : state.pengeluaran,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                            ),
                            if (state.tipeGrup == 'kasResmi' && kasStore.isBendahara(state))
                              InkWell(
                                onTap: () => tampilkanDialogSetoran(context, state),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, size: 16, color: _primaryGreen),
                                      SizedBox(width: 4),
                                      Text(
                                        'Setor Kas',
                                        style: TextStyle(color: _primaryGreen, fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Sub-metrics capsules
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCapsule(
                                icon: Icons.trending_up_rounded,
                                iconColor: const Color(0xFF34D399),
                                label: 'Pemasukan',
                                value: _sembunyikanSaldo ? '••••••' : formatRupiah(state.pemasukan),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricCapsule(
                                icon: Icons.trending_down_rounded,
                                iconColor: const Color(0xFFF87171),
                                label: 'Pengeluaran',
                                value: _sembunyikanSaldo ? '••••••' : formatRupiah(state.pengeluaran),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================== QUICK ACTIONS CIRCULAR ROW ====================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickActionCircle(
                        icon: Icons.receipt_long_rounded,
                        label: 'Catat',
                        bgColor: _primaryGreen,
                        iconColor: Colors.white,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuatTagihanScreen())),
                      ),
                      if (kasStore.isBendahara(state))
                        _buildQuickActionCircle(
                          icon: Icons.add_card_rounded,
                          label: 'Setor Kas',
                          bgColor: const Color(0xFFDCFCE7),
                          iconColor: _primaryGreen,
                          onTap: () => tampilkanDialogSetoran(context, state),
                        )
                      else
                        _buildQuickActionCircle(
                          icon: Icons.payment_rounded,
                          label: 'Bayar',
                          bgColor: const Color(0xFFDCFCE7),
                          iconColor: _primaryGreen,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BayarTagihanScreen(),
                            ),
                          ),
                        ),
                      _buildQuickActionCircle(
                        icon: Icons.qr_code_2_rounded,
                        label: 'Kode / QR',
                        bgColor: const Color(0xFFE0E7FF),
                        iconColor: const Color(0xFF4338CA),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QrGrupScreen(grup: state))),
                      ),
                      _buildQuickActionCircle(
                        icon: Icons.history_rounded,
                        label: 'Riwayat',
                        bgColor: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFB45309),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatScreen())),
                      ),
                      _buildQuickActionCircle(
                        icon: Icons.tune_rounded,
                        label: 'Kelola',
                        bgColor: const Color(0xFFF1F5F9),
                        iconColor: const Color(0xFF475569),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DetailGrupScreen())),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // ==================== ANGGOTA GRUP (STORY AVATARS) ====================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Anggota Grup',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _darkBg),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${state.anggota.length}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => _bukaDialogTambahAnggota(context),
                        style: TextButton.styleFrom(
                          foregroundColor: _primaryGreen,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Tambah', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 94,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.anggota.length + 1,
                      itemBuilder: (context, idx) {
                        if (idx == 0) {
                          // Tombol Tambah Anggota Circle
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: InkWell(
                              onTap: () => _bukaDialogTambahAnggota(context),
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                                    ),
                                    child: const Icon(Icons.person_add_outlined, color: _primaryGreen, size: 22),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text('Tambah', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          );
                        }

                        final a = state.anggota[idx - 1];
                        final isLunas = a.status == StatusBayar.lunas;
                        final isMenunggu = a.status == StatusBayar.menunggu;
                        final isBelum = a.status == StatusBayar.belum || a.tagihan > 0;
                        final isBebas = !isLunas && !isMenunggu && !isBelum;
                        final namaSingkat = a.nama.split(' ').first;

                        return Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: InkWell(
                            onTap: () {
                              final isUserSendiri = kasStore.isCurrentUser(a);
                              if (isUserSendiri) {
                                if (a.tagihan > 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Kamu memiliki tagihan sebesar ${formatRupiah(a.tagihan)}.'),
                                      behavior: SnackBarBehavior.floating,
                                      action: SnackBarAction(
                                        label: 'Bayar Sekarang',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const BayarTagihanScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Ini akun kamu (${a.nama}). Kamu tidak memiliki tagihan.'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } else if (a.tagihan > 0) {
                                _tampilkanDialogIngatkanAnggota(context, a);
                              } else if (isLunas) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${a.nama} telah melunasi semua tagihan.'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${a.nama} bebas tagihan (tidak ada kewajiban kas).'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: a.avatarColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      a.nama.isNotEmpty ? a.nama[0].toUpperCase() : '?',
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: _darkBg, fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 56,
                                  child: Text(
                                    namaSingkat,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _darkBg),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                SizedBox(
                                  width: 58,
                                  child: Text(
                                    isLunas
                                        ? 'Lunas'
                                        : (isMenunggu
                                            ? 'Menunggu'
                                            : (isBelum ? formatRupiah(a.tagihan) : 'Bebas')),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: isLunas
                                          ? const Color(0xFF16A34A)
                                          : (isMenunggu
                                              ? const Color(0xFFD97706)
                                              : (isBelum
                                                  ? const Color(0xFFDC2626)
                                                  : const Color(0xFF64748B))),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================== SECTION 1: TAGIHAN SAYA ====================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFFDC2626)),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Tagihan Saya',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _darkBg),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kasStore.tagihanSaya().isEmpty ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${kasStore.tagihanSaya().length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: kasStore.tagihanSaya().isEmpty ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (kasStore.tagihanSaya().any((item) => item.status == StatusBayar.belum))
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BayarTagihanScreen())),
                          child: const Text(
                            'Bayar sekarang',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (kasStore.tagihanSaya().isEmpty)
                    _buildModernEmptyCard(
                      icon: Icons.check_circle_rounded,
                      iconColor: const Color(0xFF16A34A),
                      iconBg: const Color(0xFFDCFCE7),
                      title: 'Semua Tagihan Kamu Selesai',
                      description: 'Tidak ada tanggungan tagihan yang perlu kamu bayar saat ini.',
                    )
                  else
                    ...kasStore.tagihanSaya().map((item) => _buildTagihanSayaCard(context, item)),

                  const SizedBox(height: 24),

                  // ==================== SECTION 2: MENUNGGU DIBAYAR ====================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFFD97706)),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Menunggu Pembayaran',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _darkBg),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kasStore.menungguDibayar().isEmpty ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${kasStore.menungguDibayar().length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: kasStore.menungguDibayar().isEmpty ? const Color(0xFF15803D) : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (kasStore.menungguDibayar().isNotEmpty)
                        GestureDetector(
                          onTap: () => _bukaSheetTagihWhatsApp(context, state),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF15803D)),
                                SizedBox(width: 4),
                                Text(
                                  'Ingatkan',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (kasStore.menungguDibayar().isEmpty)
                    _buildModernEmptyCard(
                      icon: Icons.verified_user_rounded,
                      iconColor: const Color(0xFF0284C7),
                      iconBg: const Color(0xFFE0F2FE),
                      title: 'Tidak Ada Pembayaran Tertunda',
                      description: 'Semua anggota grup telah melunasi kewajibannya.',
                    )
                  else
                    ...kasStore.menungguDibayar().map((item) => _buildMenungguDibayarCard(context, item)),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? iconColor,
    Color? bgColor,
    int? badgeCount,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            tooltip: tooltip,
            padding: EdgeInsets.zero,
            icon: Icon(icon, size: 20, color: iconColor ?? const Color(0xFF334155)),
            onPressed: onTap,
          ),
        ),
        if (badgeCount != null && badgeCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetricCapsule({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCircle({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _darkBg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernEmptyCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _darkBg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagihanSayaCard(BuildContext context, TagihanDetailItem item) {
    final isMenunggu = item.status == StatusBayar.menunggu;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMenunggu ? const Color(0xFFFDE68A) : const Color(0xFFFECACA),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.judul,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _darkBg,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isMenunggu ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isMenunggu ? 'Menunggu verifikasi' : 'Belum bayar',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isMenunggu ? const Color(0xFFB45309) : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatRupiah(item.nominal),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _darkBg,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                item.sumberDana == 'Kas grup' ? Icons.account_balance_rounded : Icons.person_rounded,
                size: 15,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.sumberDana == 'Kas grup' ? 'Dari Kas Grup' : 'Ditalangi oleh ${item.namaPenerima}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (item.bankPenerima.isNotEmpty || item.rekPenerima.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Tujuan: ${item.bankPenerima} ${item.rekPenerima} a.n. ${item.namaPenerima}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (isMenunggu)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFFB45309)),
                  SizedBox(width: 8),
                  Text(
                    'Menunggu Verifikasi Penerima',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BayarTagihanScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text(
                  'Bayar Sekarang',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenungguDibayarCard(BuildContext context, TagihanDetailItem item) {
    final isMenunggu = item.status == StatusBayar.menunggu;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMenunggu ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
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
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: item.avatarColor,
            child: Text(
              item.namaPembayar.isNotEmpty ? item.namaPembayar[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.w800, color: _darkBg),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaPembayar,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _darkBg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.judul} • ${formatRupiah(item.nominal)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          if (isMenunggu) ...[
            Builder(
              builder: (context) {
                final state = kasStore.grupAktif;
                final myUid = kasStore.currentUserUid;
                final isMeBendahara = state.bendahara.toLowerCase() == kasStore.currentUserNama.toLowerCase() ||
                    (myUid.isNotEmpty && state.bendaharaUid == myUid);
                final me = kasStore.currentAnggota;
                final isPenerima = item.pembayarId != me?.id && (item.penerimaId == me?.id || isMeBendahara);

                if (isPenerima) {
                  return ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const KonfirmasiPembayaranScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF3C7),
                      foregroundColor: const Color(0xFFB45309),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Verifikasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  );
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Menunggu',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                  ),
                );
              },
            ),
          ]
          else
            OutlinedButton.icon(
              onPressed: () {
                final anggotaTarget = kasStore.grupAktif.anggota.firstWhere(
                  (a) => a.id == item.pembayarId,
                  orElse: () => kasStore.grupAktif.anggota.first,
                );
                kasStore.kirimTagihanWhatsApp(anggotaTarget);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF15803D),
                side: const BorderSide(color: Color(0xFF86EFAC)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.send_rounded, size: 13),
              label: const Text('Ingatkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
