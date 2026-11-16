import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/kas_store.dart';
import '../widgets/dialog_setoran.dart';
import 'qr_grup_screen.dart';
import 'buat_tagihan_screen.dart';

class DetailGrupScreen extends StatelessWidget {
  const DetailGrupScreen({super.key});

  static const Color _primaryGreen = Color(0xFF074E3B);
  static const Color _emerald = Color(0xFF10B981);
  static const Color _darkBg = Color(0xFF0F172A);

  void _salinKodeUndangan(BuildContext context, String kode) {
    Clipboard.setData(ClipboardData(text: kode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kode undangan "$kode" berhasil disalin ke clipboard!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: _primaryGreen,
      ),
    );
  }

  void _dialogEditNama(BuildContext context, GrupKas grup) {
    final ctrl = TextEditingController(text: grup.namaGrup);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: _primaryGreen),
            SizedBox(width: 8),
            Text(
              'Edit Nama Grup',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nama Grup',
            hintText: 'Contoh: Kas Kos 2B',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final baru = ctrl.text.trim();
              if (baru.isEmpty) return;
              kasStore.editNamaGrup(grup.id, baru);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Nama grup diubah menjadi "$baru"'),
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

  void _dialogTambahAnggota(BuildContext context) {
    final namaCtrl = TextEditingController();
    final waCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: _primaryGreen),
            SizedBox(width: 8),
            Text(
              'Tambah Anggota Baru',
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
                labelText: 'Nama Anggota',
                hintText: 'Contoh: Ahmad Budi',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: waCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Nomor WhatsApp',
                hintText: '0812xxxxxxxx',
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
              final nama = namaCtrl.text.trim();
              if (nama.isEmpty) return;
              kasStore.tambahAnggota(
                nama: nama,
                noWa: waCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$nama berhasil ditambahkan ke grup'),
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
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _dialogHapusAnggota(
      BuildContext context, AnggotaKas anggota, String grupNama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.person_remove_rounded, color: Color(0xFFB91C1C)),
            SizedBox(width: 8),
            Text('Hapus Anggota?', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Yakin ingin mengeluarkan "${anggota.nama}" dari grup $grupNama?',
          style: const TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              kasStore.hapusAnggota(anggota.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${anggota.nama} dikeluarkan dari grup'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _dialogHapusGrup(BuildContext context, GrupKas grup) {
    if (kasStore.daftarGrup.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa menghapus satu-satunya grup yang kamu miliki!'),
          backgroundColor: Color(0xFFB91C1C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C)),
            SizedBox(width: 8),
            Text('Hapus Grup?'),
          ],
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus grup "${grup.namaGrup}"?\n\nSemua data kas, catatan tagihan, dan riwayat di grup ini akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final ok = kasStore.hapusGrup(grup.id);
              Navigator.pop(ctx);
              if (ok) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Grup "${grup.namaGrup}" berhasil dihapus'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }

  void _dialogKeluarGrup(BuildContext context, GrupKas grup) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFB91C1C)),
            SizedBox(width: 8),
            Text('Keluar dari Grup?'),
          ],
        ),
        content: Text(
          'Apakah kamu yakin ingin keluar dari "${grup.namaGrup}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              kasStore.keluarDariGrup(grup.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kamu telah keluar dari ${grup.namaGrup}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar'),
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
        final grup = rootState.grupAktif;
        final isBendahara = grup.bendahara.toLowerCase() ==
            kasStore.currentUserNama.toLowerCase();
        final isKasResmi = grup.tipeGrup == 'kasResmi';

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8FAFC),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () => Navigator.pop(context),
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
            ),
            title: const Text(
              'Detail Grup',
              style: TextStyle(
                color: _darkBg,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QrGrupScreen(grup: grup),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, size: 20, color: _darkBg),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================== HEADER CARD (FINTECH STYLE) ====================
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isKasResmi ? Icons.account_balance_rounded : Icons.splitscreen_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isKasResmi ? 'Kas Resmi' : 'Patungan Santai',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => _salinKodeUndangan(context, grup.kodeUndangan),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.key_rounded, size: 12, color: Colors.white70),
                                  const SizedBox(width: 4),
                                  Text(
                                    grup.kodeUndangan,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.copy_rounded, size: 12, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        grup.namaGrup,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isKasResmi ? 'Total Saldo Kas Grup' : 'Total Tagihan Patungan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatRupiah(isKasResmi ? grup.saldo : grup.pengeluaran),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFDE047)),
                                const SizedBox(width: 6),
                                Text(
                                  'Bendahara: ${grup.bendahara}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Text(
                              '${grup.anggota.length} Anggota',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==================== CIRCULAR QUICK ACTION ROW ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickActionCircle(
                      icon: Icons.copy_rounded,
                      label: 'Salin Kode',
                      onTap: () => _salinKodeUndangan(context, grup.kodeUndangan),
                    ),
                    _buildQuickActionCircle(
                      icon: Icons.qr_code_2_rounded,
                      label: 'Kode QR',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QrGrupScreen(grup: grup),
                          ),
                        );
                      },
                    ),
                    _buildQuickActionCircle(
                      icon: Icons.share_rounded,
                      label: 'Kirim WA',
                      onTap: () => kasStore.bagikanUndanganGrupWhatsApp(grup),
                    ),
                    if (isKasResmi)
                      _buildQuickActionCircle(
                        icon: Icons.add_card_rounded,
                        label: 'Setor Kas',
                        onTap: () => tampilkanDialogSetoran(context, grup),
                      )
                    else
                      _buildQuickActionCircle(
                        icon: Icons.receipt_long_rounded,
                        label: 'Split Bill',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BuatTagihanScreen()),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 26),

                // ==================== DAFTAR ANGGOTA (YOUR FRIENDS STYLE) ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.people_alt_rounded, size: 16, color: _primaryGreen),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Anggota Grup (${grup.anggota.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _darkBg,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _dialogTambahAnggota(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _primaryGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 16, color: _primaryGreen),
                            SizedBox(width: 4),
                            Text(
                              'Tambah',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Daftar Anggota Cards
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: grup.anggota.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final anggota = grup.anggota[index];
                    final isCurrent = anggota.nama.toLowerCase() ==
                        kasStore.currentUserNama.toLowerCase();
                    final isAnggotaBendahara = anggota.nama.toLowerCase() ==
                        grup.bendahara.toLowerCase();
                    final bool isLunas = anggota.status == StatusBayar.lunas || anggota.tagihan <= 0;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          // Avatar with ring & initials
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: anggota.avatarColor,
                                child: Text(
                                  anggota.nama.isNotEmpty ? anggota.nama[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isLunas ? _emerald : const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Nama & Badges
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        anggota.nama,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _darkBg,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isAnggotaBendahara) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.star_rounded, size: 10, color: Color(0xFFB45309)),
                                            SizedBox(width: 2),
                                            Text(
                                              'Bendahara',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFFB45309),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (isCurrent && !isAnggotaBendahara) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Kamu',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF15803D),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  anggota.noWa.isNotEmpty ? anggota.noWa : 'Tanpa nomor WhatsApp',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          // Status & Action
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isLunas ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isLunas ? 'Lunas' : formatRupiah(anggota.tagihan),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isLunas ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                  ),
                                ),
                              ),
                              if (!isLunas && anggota.noWa.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => kasStore.kirimTagihanWhatsApp(anggota),
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.chat_bubble_outline_rounded, size: 12, color: _primaryGreen),
                                        SizedBox(width: 3),
                                        Text(
                                          'Tagih WA',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _primaryGreen),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (isBendahara && !isAnggotaBendahara) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                              onPressed: () => _dialogHapusAnggota(context, anggota, grup.namaGrup),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ==================== PENGATURAN & AKSI GRUP ====================
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF475569)),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Pengaturan Grup',
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      if (isBendahara) ...[
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFFB45309)),
                          ),
                          title: const Text(
                            'Edit Nama Grup',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _darkBg),
                          ),
                          subtitle: const Text(
                            'Ubah nama grup yang ditampilkan ke anggota',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                          onTap: () => _dialogEditNama(context, grup),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.delete_forever_rounded, size: 18, color: Color(0xFFB91C1C)),
                          ),
                          title: const Text(
                            'Hapus Grup',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
                          ),
                          subtitle: const Text(
                            'Hapus permanen grup ini dan semua catatannya',
                            style: TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFEF4444)),
                          onTap: () => _dialogHapusGrup(context, grup),
                        ),
                      ],
                      if (!isBendahara) ...[
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFB91C1C)),
                          ),
                          title: const Text(
                            'Keluar dari Grup',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
                          ),
                          subtitle: const Text(
                            'Kamu tidak lagi menjadi anggota grup ini',
                            style: TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFEF4444)),
                          onTap: () => _dialogKeluarGrup(context, grup),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 36),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCircle({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: _primaryGreen, size: 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
