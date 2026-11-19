import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/input_validation.dart';
import '../theme/theme_controller.dart';
import '../data/profil_store.dart';
import '../data/kas_store.dart';
import '../services/firestore_service.dart';
import '../models/pengguna.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  static const Color _primaryGreen = Color(0xFF074E3B);

  late bool _pengingatTagihan;
  String _ingatkanSebelum = '1 hari';

  @override
  void initState() {
    super.initState();
    _pengingatTagihan = notificationService.aktifNotifier.value;
  }

  final List<String> _opsiIngatkan = const [
    '1 hari',
    '2 hari',
    '3 hari',
    '1 minggu',
  ];

  void _bukaFormEditProfil(BuildContext context) {
    final profil = profilNotifier.value;
    final namaCtrl = TextEditingController(text: profil.nama);
    final waCtrl = TextEditingController(text: profil.noWa);
    final bankCtrl = TextEditingController(text: profil.bank);
    final rekCtrl = TextEditingController(text: profil.noRekening);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profil & Rekening',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: namaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama lengkap',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: waCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'No WhatsApp',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bankCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bank',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rekCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: validasiNomorRekening,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'No Rekening',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  simpanProfil(
                    Pengguna(
                      id: profil.id,
                      nama: namaCtrl.text.trim(),
                      noWa: waCtrl.text.trim(),
                      bank: bankCtrl.text.trim(),
                      noRekening: rekCtrl.text.trim(),
                    ),
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil & rekening berhasil diperbarui!'),
                      backgroundColor: _primaryGreen,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _dialogKeluarAkun(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFF074E3B)),
            SizedBox(width: 8),
            Text('Keluar Akun?'),
          ],
        ),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun KasMate di perangkat ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authService.logout();
              kasStore.resetState();
              resetProfil();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _dialogHapusAkun(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C)),
            SizedBox(width: 8),
            Text('Hapus Akun?'),
          ],
        ),
        content: const Text(
          'Akun kamu akan dihapus secara permanen dari sistem KasMate.\n\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final uid = authService.currentUser?.uid;
                if (uid != null) {
                  await firestoreService.hapusProfilUser(uid);
                }
                await authService.hapusAkun();
                kasStore.resetState();
                resetProfil();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Akun kamu berhasil dihapus permanen.'),
                      backgroundColor: Color(0xFFB91C1C),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: const Color(0xFFB91C1C),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Hapus Akun'),
          ),
        ],
      ),
    );
  }

  void _dialogTentangAplikasi(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: _primaryGreen,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'KasMate',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Versi 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aplikasi Manajemen Kas & Split Bill Kelompok.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Project Akhir Praktikum Pemrograman Bergerak (PPB)\nSemester 5 — Teknik Informatika\n© 2026 KasMate Team',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  void _dialogLisensi(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Lisensi Open Source',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'MIT License\n\n'
            'Copyright (c) 2026 KasMate Team\n\n'
            'Permission is hereby granted, free of charge, to any person obtaining a copy '
            'of this software and associated documentation files (the "Software"), to deal '
            'in the Software without restriction, including without limitation the rights '
            'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell '
            'copies of the Software.\n\n'
            'Packages Digunakan:\n'
            '• flutter & flutter_lints\n'
            '• cupertino_icons\n'
            '• font_awesome_flutter\n'
            '• url_launcher\n'
            '• image_picker\n'
            '• share_plus\n'
            '• qr_flutter\n'
            '• mobile_scanner\n'
            '• fl_chart\n'
            '• firebase_core & firebase_auth\n'
            '• cloud_firestore\n'
            '• flutter_local_notifications\n'
            '• shimmer\n'
            '• animations\n'
            '• lottie',
            style: TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.4),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        title: const Text(
          'Pengaturan',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== TAMPILAN ====================
              _buildSectionTitle('Tampilan'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeModeNotifier,
                  builder: (context, themeMode, _) {
                    final isDark = themeMode == ThemeMode.dark;
                    return SwitchListTile(
                      activeThumbColor: _primaryGreen,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          size: 20,
                          color: isDark ? Colors.amber : const Color(0xFF4B5563),
                        ),
                      ),
                      title: const Text(
                        'Mode Gelap (Dark Mode)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isDark ? 'Tema gelap aktif' : 'Tema terang aktif',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: isDark,
                      onChanged: (_) => toggleThemeMode(),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ==================== NOTIFIKASI ====================
              _buildSectionTitle('Notifikasi'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: _primaryGreen,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          size: 20,
                          color: _primaryGreen,
                        ),
                      ),
                      title: const Text(
                        'Pengingat Tagihan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Dapatkan pemberitahuan tagihan yang mendekati tempo',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _pengingatTagihan,
                      onChanged: (val) {
                        setState(() => _pengingatTagihan = val);
                        notificationService.aktifNotifier.value = val;
                        if (!val) {
                          notificationService.batalkanSemua();
                        }
                      },
                    ),
                    if (_pengingatTagihan) ...[
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.alarm_rounded,
                            size: 20,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        title: const Text(
                          'Waktu Pengingat',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Kapan pengingat harus dikirim sebelum tempo',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _ingatkanSebelum,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _primaryGreen,
                            ),
                            icon: const Icon(
                              Icons.arrow_drop_down_rounded,
                              color: _primaryGreen,
                            ),
                            items: _opsiIngatkan.map((String opt) {
                              return DropdownMenuItem<String>(
                                value: opt,
                                child: Text('H-$opt'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _ingatkanSebelum = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================== AKUN ====================
              _buildSectionTitle('Akun'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                          color: Color(0xFF4338CA),
                        ),
                      ),
                      title: const Text(
                        'Edit profil & rekening',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Ubah nama, no WhatsApp, dan no rekening bank',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF9CA3AF),
                      ),
                      onTap: () => _bukaFormEditProfil(context),
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          size: 20,
                          color: _primaryGreen,
                        ),
                      ),
                      title: const Text(
                        'Keluar akun (Logout)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      subtitle: const Text(
                        'Keluar dari sesi akun saat ini di perangkat ini',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF9CA3AF),
                      ),
                      onTap: () => _dialogKeluarAkun(context),
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          size: 20,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                      title: const Text(
                        'Hapus akun',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                      subtitle: const Text(
                        'Hapus seluruh data akun secara permanen',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFEF4444),
                      ),
                      onTap: () => _dialogHapusAkun(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================== TENTANG ====================
              _buildSectionTitle('Tentang'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      title: const Text(
                        'Tentang KasMate',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Versi 1.0.0 • Project Akhir PPB Semester 5',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF9CA3AF),
                      ),
                      onTap: () => _dialogTentangAplikasi(context),
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          size: 20,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      title: const Text(
                        'Lisensi open source',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Daftar lisensi pustaka pihak ketiga',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF9CA3AF),
                      ),
                      onTap: () => _dialogLisensi(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}
