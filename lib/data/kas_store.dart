import 'dart:math';
import '../utils/input_validation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profil_store.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

String formatRupiah(int nominal) {
  final isNegatif = nominal < 0;
  final angka = nominal.abs().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < angka.length; i++) {
    final posisiDariKanan = angka.length - i;
    buffer.write(angka[i]);
    if (posisiDariKanan > 1 && posisiDariKanan % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${isNegatif ? '-Rp ' : 'Rp '}${buffer.toString()}';
}

enum StatusBayar { tidakAdaTagihan, lunas, menunggu, belum }

class AnggotaKas {
  final String id;
  final String nama;
  final String noWa;
  final int tagihan;
  final StatusBayar status;
  final Color avatarColor;

  const AnggotaKas({
    required this.id,
    required this.nama,
    required this.noWa,
    required this.tagihan,
    required this.status,
    required this.avatarColor,
  });

  AnggotaKas copyWith({
    String? nama,
    String? noWa,
    int? tagihan,
    StatusBayar? status,
  }) {
    return AnggotaKas(
      id: id,
      nama: nama ?? this.nama,
      noWa: noWa ?? this.noWa,
      tagihan: tagihan ?? this.tagihan,
      status: status ?? this.status,
      avatarColor: avatarColor,
    );
  }
}

class ItemBelanja {
  final String id;
  final String nama;
  final int harga;

  const ItemBelanja({
    required this.id,
    required this.nama,
    required this.harga,
  });
}

class TagihanKas {
  final String id;
  final String judul;
  final String tanggal;
  final String sumberDana;
  final List<ItemBelanja> items;
  final int subtotal;
  final int pajak;
  final int total;
  final int porsiPerOrang;

  // Info penerima transfer (siapa yang nalangin / harus menerima uang)
  final String penerimaId;
  final String namaPenerima;
  final String bankPenerima;
  final String rekPenerima;

  const TagihanKas({
    required this.id,
    required this.judul,
    required this.tanggal,
    required this.sumberDana,
    required this.items,
    required this.subtotal,
    required this.pajak,
    required this.total,
    required this.porsiPerOrang,
    required this.penerimaId,
    required this.namaPenerima,
    this.bankPenerima = '',
    this.rekPenerima = '',
  });
}

class KonfirmasiItem {
  final String id;
  final String anggotaId;
  final String namaAnggota;
  final String judulTagihan;
  final int nominal;
  final String namaFileBukti;
  final String buktiPath;
  final String waktuUnggah;

  const KonfirmasiItem({
    required this.id,
    required this.anggotaId,
    required this.namaAnggota,
    required this.judulTagihan,
    required this.nominal,
    required this.namaFileBukti,
    required this.buktiPath,
    required this.waktuUnggah,
  });
}

class RiwayatPembayaranItem {
  final String id;
  final String namaAnggota;
  final String judulTagihan;
  final int nominal;
  final String waktu;
  final String status; // 'Lunas' atau 'Ditolak'
  final String buktiPath;

  const RiwayatPembayaranItem({
    required this.id,
    required this.namaAnggota,
    required this.judulTagihan,
    required this.nominal,
    required this.waktu,
    required this.status,
    required this.buktiPath,
  });
}

class TagihanDetailItem {
  final String id;
  final String tagihanId;
  final String judul;
  final int nominal;
  final StatusBayar status;
  final String namaPenerima;
  final String bankPenerima;
  final String rekPenerima;
  final String namaPembayar;
  final String pembayarId;
  final String noWaPembayar;
  final Color avatarColor;
  final String sumberDana;
  final String tanggal;

  const TagihanDetailItem({
    required this.id,
    required this.tagihanId,
    required this.judul,
    required this.nominal,
    required this.status,
    required this.namaPenerima,
    this.bankPenerima = '',
    this.rekPenerima = '',
    required this.namaPembayar,
    required this.pembayarId,
    this.noWaPembayar = '',
    this.avatarColor = const Color(0xFFDBEAFE),
    this.sumberDana = '',
    this.tanggal = '',
  });
}

enum TipeNotifikasi {
  tagihanBaru,
  buktiPembayaran,
  konfirmasiLunas,
  konfirmasiTolak,
  anggotaBaru,
  pengingatWa,
}

class NotifikasiItem {
  final String id;
  final String judul;
  final String pesan;
  final String waktu;
  final String kelompokWaktu; // 'Hari ini', 'Kemarin', 'Minggu lalu'
  final TipeNotifikasi tipe;
  final bool isDibaca;
  final int? nominal;
  final String? terkaitId;

  const NotifikasiItem({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.waktu,
    this.kelompokWaktu = 'Hari ini',
    required this.tipe,
    this.isDibaca = false,
    this.nominal,
    this.terkaitId,
  });

  NotifikasiItem copyWith({
    bool? isDibaca,
  }) {
    return NotifikasiItem(
      id: id,
      judul: judul,
      pesan: pesan,
      waktu: waktu,
      kelompokWaktu: kelompokWaktu,
      tipe: tipe,
      isDibaca: isDibaca ?? this.isDibaca,
      nominal: nominal,
      terkaitId: terkaitId,
    );
  }
}

class GrupKas {
  final String id;
  final String namaGrup;
  final String kodeUndangan;
  final String tipeGrup; // 'kasResmi' (ada saldo kas) atau 'patungan' (murni split bill)
  final String bendahara;
  final int saldo;
  final int pemasukan;
  final int pengeluaran;
  final List<AnggotaKas> anggota;
  final List<TagihanKas> daftarTagihan;
  final List<KonfirmasiItem> daftarKonfirmasi;
  final List<RiwayatPembayaranItem> daftarRiwayatPembayaran;
  final List<NotifikasiItem> daftarNotifikasi;

  const GrupKas({
    required this.id,
    required this.namaGrup,
    required this.kodeUndangan,
    this.tipeGrup = 'kasResmi',
    required this.bendahara,
    required this.saldo,
    required this.pemasukan,
    required this.pengeluaran,
    required this.anggota,
    required this.daftarTagihan,
    required this.daftarKonfirmasi,
    required this.daftarRiwayatPembayaran,
    this.daftarNotifikasi = const [],
  });

  String get linkUndangan => 'https://kasmate.app/join/$kodeUndangan';

  GrupKas copyWith({
    String? namaGrup,
    String? kodeUndangan,
    String? tipeGrup,
    String? bendahara,
    int? saldo,
    int? pemasukan,
    int? pengeluaran,
    List<AnggotaKas>? anggota,
    List<TagihanKas>? daftarTagihan,
    List<KonfirmasiItem>? daftarKonfirmasi,
    List<RiwayatPembayaranItem>? daftarRiwayatPembayaran,
    List<NotifikasiItem>? daftarNotifikasi,
  }) {
    return GrupKas(
      id: id,
      namaGrup: namaGrup ?? this.namaGrup,
      kodeUndangan: kodeUndangan ?? this.kodeUndangan,
      tipeGrup: tipeGrup ?? this.tipeGrup,
      bendahara: bendahara ?? this.bendahara,
      saldo: saldo ?? this.saldo,
      pemasukan: pemasukan ?? this.pemasukan,
      pengeluaran: pengeluaran ?? this.pengeluaran,
      anggota: anggota ?? this.anggota,
      daftarTagihan: daftarTagihan ?? this.daftarTagihan,
      daftarKonfirmasi: daftarKonfirmasi ?? this.daftarKonfirmasi,
      daftarRiwayatPembayaran:
          daftarRiwayatPembayaran ?? this.daftarRiwayatPembayaran,
      daftarNotifikasi: daftarNotifikasi ?? this.daftarNotifikasi,
    );
  }
}

const _grupKosong = GrupKas(
  id: '',
  namaGrup: 'Belum Ada Grup',
  kodeUndangan: '-',
  tipeGrup: 'kasResmi',
  bendahara: '',
  saldo: 0,
  pemasukan: 0,
  pengeluaran: 0,
  anggota: [],
  daftarTagihan: [],
  daftarKonfirmasi: [],
  daftarRiwayatPembayaran: [],
  daftarNotifikasi: [],
);

class KasRootState {
  final String aktifGrupId;
  final List<GrupKas> daftarGrup;

  const KasRootState({
    required this.aktifGrupId,
    required this.daftarGrup,
  });

  bool get adaGrup => daftarGrup.isNotEmpty;

  GrupKas get grupAktif => daftarGrup.firstWhere(
        (g) => g.id == aktifGrupId,
        orElse: () =>
            daftarGrup.isNotEmpty ? daftarGrup.first : _grupKosong,
      );
}

class KasStore extends ValueNotifier<KasRootState> {
  KasStore()
      : super(
          const KasRootState(
            aktifGrupId: '',
            daftarGrup: [],
          ),
        );
  static const List<Color> _palette = [
    Color(0xFFDBEAFE),
    Color(0xFFFCE7F3),
    Color(0xFFFEF3C7),
    Color(0xFFE0E7FF),
  ];

  GrupKas get grupAktif => value.grupAktif;
  List<GrupKas> get daftarGrup => value.daftarGrup;

  String get currentUserNama {
    final nama = profilNotifier.value.nama.trim();
    return nama.isEmpty ? grupAktif.bendahara : nama;
  }

  AnggotaKas? get currentAnggota {
    final nama = currentUserNama.toLowerCase();
    for (final a in grupAktif.anggota) {
      if (a.nama.toLowerCase() == nama) return a;
    }
    return grupAktif.anggota.isNotEmpty ? grupAktif.anggota.first : null;
  }

  /// Tagihan yang HARUS DIBAYAR oleh user yang sedang login ke orang lain
  List<TagihanDetailItem> tagihanSaya([String? userId]) {
    final me = currentAnggota;
    if (me == null) return [];

    final result = <TagihanDetailItem>[];
    final targetId = userId ?? me.id;

    if (me.id == targetId && me.status != StatusBayar.lunas && me.status != StatusBayar.tidakAdaTagihan && me.tagihan > 0) {
      if (grupAktif.daftarTagihan.isNotEmpty) {
        for (final t in grupAktif.daftarTagihan) {
          if (t.penerimaId != me.id) {
            result.add(
              TagihanDetailItem(
                id: 'ts_${t.id}_${me.id}',
                tagihanId: t.id,
                judul: t.judul,
                nominal: t.porsiPerOrang > 0 ? t.porsiPerOrang : me.tagihan,
                status: me.status,
                namaPenerima: t.namaPenerima,
                bankPenerima: t.bankPenerima,
                rekPenerima: t.rekPenerima,
                namaPembayar: me.nama,
                pembayarId: me.id,
                noWaPembayar: me.noWa,
                avatarColor: me.avatarColor,
                sumberDana: t.sumberDana,
                tanggal: t.tanggal,
              ),
            );
          }
        }
      }

      if (result.isEmpty) {
        String bankBendahara = '';
        String rekBendahara = '';
        final isMeBendahara = me.nama.toLowerCase() == grupAktif.bendahara.toLowerCase();
        if (isMeBendahara) {
          bankBendahara = profilNotifier.value.bank;
          rekBendahara = profilNotifier.value.noRekening;
        } else {
          for (final t in grupAktif.daftarTagihan) {
            if (t.namaPenerima.toLowerCase() == grupAktif.bendahara.toLowerCase() && t.rekPenerima.isNotEmpty) {
              bankBendahara = t.bankPenerima;
              rekBendahara = t.rekPenerima;
              break;
            }
          }
          if (bankBendahara.isEmpty) bankBendahara = 'Bank Bendahara';
          if (rekBendahara.isEmpty) rekBendahara = '-';
        }

        result.add(
          TagihanDetailItem(
            id: 'ts_default_${me.id}',
            tagihanId: 'default',
            judul: 'Iuran / Tagihan grup',
            nominal: me.tagihan,
            status: me.status,
            namaPenerima: grupAktif.bendahara,
            bankPenerima: bankBendahara,
            rekPenerima: rekBendahara,
            namaPembayar: me.nama,
            pembayarId: me.id,
            noWaPembayar: me.noWa,
            avatarColor: me.avatarColor,
            sumberDana: grupAktif.tipeGrup == 'kasResmi'
                ? 'Kas grup'
                : 'Dana pribadi',
            tanggal: 'Bulan ini',
          ),
        );
      }
    }

    return result;
  }

  /// Tagihan dari anggota lain yang HARUS DIBAYAR KE USER yang sedang login
  List<TagihanDetailItem> menungguDibayar([String? userId]) {
    final me = currentAnggota;
    if (me == null) return [];

    final targetId = userId ?? me.id;
    final isBendahara =
        grupAktif.bendahara.toLowerCase() == currentUserNama.toLowerCase();
    final result = <TagihanDetailItem>[];

    final judulAktif = grupAktif.daftarTagihan.isNotEmpty
        ? grupAktif.daftarTagihan.first.judul
        : 'Iuran grup';
    final sumberAktif = grupAktif.daftarTagihan.isNotEmpty
        ? grupAktif.daftarTagihan.first.sumberDana
        : (grupAktif.tipeGrup == 'kasResmi' ? 'Kas grup' : 'Dana pribadi');

    for (final a in grupAktif.anggota) {
      if (a.id != targetId && a.status != StatusBayar.lunas && a.status != StatusBayar.tidakAdaTagihan && a.tagihan > 0) {
        final sayaPenerima = isBendahara ||
            grupAktif.daftarTagihan.any((t) => t.penerimaId == targetId);

        if (sayaPenerima) {
          result.add(
            TagihanDetailItem(
              id: 'md_${a.id}',
              tagihanId: grupAktif.daftarTagihan.isNotEmpty
                  ? grupAktif.daftarTagihan.first.id
                  : 'default',
              judul: judulAktif,
              nominal: a.tagihan,
              status: a.status,
              namaPenerima: me.nama,
              bankPenerima: profilNotifier.value.bank,
              rekPenerima: profilNotifier.value.noRekening,
              namaPembayar: a.nama,
              pembayarId: a.id,
              noWaPembayar: a.noWa,
              avatarColor: a.avatarColor,
              sumberDana: sumberAktif,
              tanggal: 'Bulan ini',
            ),
          );
        }
      }
    }

    return result;
  }

  int get totalHarusBayar {
    return tagihanSaya().fold<int>(0, (sum, item) => sum + item.nominal);
  }

  int get totalAkanDiterima {
    return menungguDibayar().fold<int>(0, (sum, item) => sum + item.nominal);
  }

  int get jumlahNotifikasiBelumDibaca =>
      grupAktif.daftarNotifikasi.where((n) => !n.isDibaca).length;

  void tambahNotifikasi({
    required String judul,
    required String pesan,
    required TipeNotifikasi tipe,
    int? nominal,
    String? terkaitId,
    String kelompokWaktu = 'Hari ini',
  }) {
    final g = grupAktif;
    final baru = NotifikasiItem(
      id: 'n_${DateTime.now().millisecondsSinceEpoch}',
      judul: judul,
      pesan: pesan,
      waktu: 'Baru saja',
      kelompokWaktu: kelompokWaktu,
      tipe: tipe,
      nominal: nominal,
      terkaitId: terkaitId,
      isDibaca: false,
    );
    _updateGrupAktif(
      g.copyWith(daftarNotifikasi: [baru, ...g.daftarNotifikasi]),
    );
  }

  void tandaiSemuaNotifikasiDibaca() {
    final g = grupAktif;
    final listBaru =
        g.daftarNotifikasi.map((n) => n.copyWith(isDibaca: true)).toList();
    _updateGrupAktif(g.copyWith(daftarNotifikasi: listBaru));
  }

  void _updateGrupAktif(GrupKas updated) {
    final listBaru =
        value.daftarGrup.map((g) => g.id == updated.id ? updated : g).toList();
    value = KasRootState(aktifGrupId: updated.id, daftarGrup: listBaru);
    // Sinkronkan ke Cloud Firestore di latar belakang
    firestoreService.simpanGrup(updated).catchError((err) {
      debugPrint('Firestore update note: $err');
    });
  }

  /// Reset state memori saat logout agar tidak bocor ke user lain
  void resetState() {
    value = const KasRootState(aktifGrupId: '', daftarGrup: []);
    _semuaGrupFirestore = [];
  }

  List<GrupKas> _semuaGrupFirestore = [];

  /// Memfilter grup agar hanya menampilkan grup di mana user terdaftar sebagai bendahara/anggota
  void _filterDanTerapkanGrup() {
    final myNama = profilNotifier.value.nama.trim().toLowerCase();
    final myWa = _formatNomorWa(profilNotifier.value.noWa);
    final fbUser = authService.currentUser;
    final myFbName = (fbUser?.displayName ?? '').trim().toLowerCase();

    // Jika belum ada user yang login atau nama masih kosong, kosongkan daftar
    if (myNama.isEmpty && myFbName.isEmpty && fbUser == null) {
      value = const KasRootState(aktifGrupId: '', daftarGrup: []);
      return;
    }

    final listUser = _semuaGrupFirestore.where((g) {
      // 1. Cek apakah pembuat/bendahara grup
      final isBendahara = (myNama.isNotEmpty && g.bendahara.toLowerCase() == myNama) ||
          (myFbName.isNotEmpty && g.bendahara.toLowerCase() == myFbName);
      if (isBendahara) return true;

      // 2. Cek apakah ada di daftar anggota (nama atau WA sama)
      final isAnggota = g.anggota.any((a) {
        final matchNama = (myNama.isNotEmpty && a.nama.toLowerCase() == myNama) ||
            (myFbName.isNotEmpty && a.nama.toLowerCase() == myFbName);
        final matchWa = myWa.isNotEmpty && a.noWa.isNotEmpty && _formatNomorWa(a.noWa) == myWa;
        return matchNama || matchWa;
      });

      return isAnggota;
    }).toList();

    if (listUser.isNotEmpty) {
      final currentId = value.aktifGrupId;
      final ada = listUser.any((g) => g.id == currentId);
      final newId = ada ? currentId : listUser.first.id;
      value = KasRootState(aktifGrupId: newId, daftarGrup: listUser);
    } else {
      value = const KasRootState(aktifGrupId: '', daftarGrup: []);
    }
  }

  void inisialisasiFirestoreSync() {
    // Dengarkan perubahan profil pengguna agar otomatis re-filter saat login / load profil
    profilNotifier.addListener(_filterDanTerapkanGrup);

    firestoreService.streamDaftarGrup().listen(
      (listGrup) {
        // Hapus data dummy bawaan (g1 / g2) jika ada di Firestore
        for (final g in listGrup) {
          if (g.id == 'g1' || g.id == 'g2') {
            firestoreService.hapusGrup(g.id).catchError((_) {});
          }
        }
        _semuaGrupFirestore =
            listGrup.where((g) => g.id != 'g1' && g.id != 'g2').toList();
        _filterDanTerapkanGrup();
      },
      onError: (err) {
        debugPrint('Firestore sync notice (offline mode active): $err');
      },
    );
  }
  String _formatNomorWa(String raw) {
    final bersih = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (bersih.startsWith('0')) {
      return '62${bersih.substring(1)}';
    }
    if (!bersih.startsWith('62') && bersih.isNotEmpty) {
      return '62$bersih';
    }
    return bersih;
  }

  String _waktuSekarangLengkap() {
    final now = DateTime.now();
    const bulan = [
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
      'Des'
    ];
    final jam =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return '${now.day} ${bulan[now.month - 1]} ${now.year}, $jam';
  }

  String _tanggalSekarang() {
    final now = DateTime.now();
    const bulan = [
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
      'Des'
    ];
    return '${now.day} ${bulan[now.month - 1]} ${now.year}';
  }

  // ==================== GRUP & UNDANGAN ====================

  Future<GrupKas> buatGrupBaru(String namaGrup, String kodeUndangan, [String tipeGrup = 'kasResmi']) async {
    final namaUser = profilNotifier.value.nama.isEmpty
        ? 'Bendahara Utama'
        : profilNotifier.value.nama;
    final waUser = profilNotifier.value.noWa.isEmpty
        ? ''
        : _formatNomorWa(profilNotifier.value.noWa);

    final grupBaru = GrupKas(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
      namaGrup: namaGrup.trim(),
      kodeUndangan: kodeUndangan.trim().toUpperCase(),
      tipeGrup: tipeGrup,
      bendahara: namaUser,
      saldo: 0,
      pemasukan: 0,
      pengeluaran: 0,
      anggota: [
        AnggotaKas(
          id: 'a_${DateTime.now().millisecondsSinceEpoch}',
          nama: namaUser,
          noWa: waUser,
          tagihan: 0,
          status: StatusBayar.tidakAdaTagihan,
          avatarColor: const Color(0xFFDBEAFE),
        ),
      ],
      daftarTagihan: const [],
      daftarKonfirmasi: const [],
      daftarRiwayatPembayaran: const [],
    );

    value = KasRootState(
      aktifGrupId: grupBaru.id,
      daftarGrup: [grupBaru, ...value.daftarGrup],
    );

    try {
      await firestoreService.simpanGrup(grupBaru);
      debugPrint('Berhasil simpan grup baru ke Firestore: ${grupBaru.namaGrup}');
    } catch (e) {
      debugPrint('Catatan Firestore saat buatGrupBaru: $e');
    }

    return grupBaru;
  }

  GrupKas? cariGrupByKode(String kode) {
    final target = kode.trim().toUpperCase();
    if (target.isEmpty) return null;
    for (final g in value.daftarGrup) {
      if (g.kodeUndangan.toUpperCase() == target) {
        return g;
      }
    }
    return null;
  }

  /// Mencari grup dari memori lokal atau langsung query ke Cloud Firestore
  Future<GrupKas?> cariGrupByKodeAsync(String kode) async {
    final target = kode.trim().toUpperCase();
    if (target.isEmpty) return null;

    // Cek memori lokal terlebih dahulu
    for (final g in value.daftarGrup) {
      if (g.kodeUndangan.toUpperCase() == target) {
        return g;
      }
    }

    // Jika belum ada di memori lokal, cari langsung ke Cloud Firestore
    return await firestoreService.cariGrupByKodeFirestore(target);
  }

  bool gabungGrup(String kode) {
    final ditemukan = cariGrupByKode(kode);
    if (ditemukan == null) return false;

    final namaUser = profilNotifier.value.nama.isEmpty
        ? 'Anggota Baru'
        : profilNotifier.value.nama;
    final waUser = _formatNomorWa(profilNotifier.value.noWa);

    final sudahAda = ditemukan.anggota.any(
      (a) => a.nama.toLowerCase() == namaUser.toLowerCase(),
    );

    final daftarAnggotaBaru = List<AnggotaKas>.from(ditemukan.anggota);
    if (!sudahAda) {
      daftarAnggotaBaru.add(
        AnggotaKas(
          id: 'a_${DateTime.now().millisecondsSinceEpoch}',
          nama: namaUser,
          noWa: waUser,
          tagihan: 0,
          status: StatusBayar.tidakAdaTagihan,
          avatarColor: _palette[daftarAnggotaBaru.length % _palette.length],
        ),
      );
    }

    final grupTerupdate = ditemukan.copyWith(anggota: daftarAnggotaBaru);
    _updateGrupAktif(grupTerupdate);
    return true;
  }

  /// Bergabung ke grup dengan sinkronisasi Cloud Firestore
  Future<bool> gabungGrupAsync(String kode) async {
    final target = kode.trim().toUpperCase();
    if (target.isEmpty) return false;

    // Cari grup dari Cloud Firestore atau lokal
    final ditemukan = await cariGrupByKodeAsync(target);
    if (ditemukan == null) return false;

    final namaUser = profilNotifier.value.nama.isEmpty
        ? 'Anggota Baru'
        : profilNotifier.value.nama;
    final waUser = _formatNomorWa(profilNotifier.value.noWa);

    final sudahAda = ditemukan.anggota.any(
      (a) => a.nama.toLowerCase() == namaUser.toLowerCase(),
    );

    final daftarAnggotaBaru = List<AnggotaKas>.from(ditemukan.anggota);
    if (!sudahAda) {
      daftarAnggotaBaru.add(
        AnggotaKas(
          id: 'a_${DateTime.now().millisecondsSinceEpoch}',
          nama: namaUser,
          noWa: waUser,
          tagihan: 0,
          status: StatusBayar.tidakAdaTagihan,
          avatarColor: _palette[daftarAnggotaBaru.length % _palette.length],
        ),
      );
    }

    final notif = NotifikasiItem(
      id: 'n_${DateTime.now().millisecondsSinceEpoch}',
      judul: 'Anggota Baru Bergabung',
      pesan: '$namaUser telah bergabung ke grup',
      waktu: 'Baru saja',
      kelompokWaktu: 'Hari ini',
      tipe: TipeNotifikasi.anggotaBaru,
    );

    final grupTerupdate = ditemukan.copyWith(
      anggota: daftarAnggotaBaru,
      daftarNotifikasi: [notif, ...ditemukan.daftarNotifikasi],
    );

    // Tambahkan atau update grup di lokal state
    final indexLokal = value.daftarGrup.indexWhere((g) => g.id == grupTerupdate.id);
    final List<GrupKas> listBaru;
    if (indexLokal != -1) {
      listBaru = value.daftarGrup.map((g) => g.id == grupTerupdate.id ? grupTerupdate : g).toList();
    } else {
      listBaru = [grupTerupdate, ...value.daftarGrup];
    }
    value = KasRootState(aktifGrupId: grupTerupdate.id, daftarGrup: listBaru);

    // Sinkronisasi pembaruan ke Cloud Firestore
    try {
      await firestoreService.simpanGrup(grupTerupdate);
      debugPrint('Berhasil sinkronisasi gabung grup ke Cloud: ${grupTerupdate.namaGrup}');
    } catch (e) {
      debugPrint('Catatan Firestore saat gabung grup: $e');
    }

    return true;
  }

  void pilihGrupAktif(String grupId) {
    value = KasRootState(
      aktifGrupId: grupId,
      daftarGrup: value.daftarGrup,
    );
  }

  // ==================== CREATE ====================

  void tambahAnggota({required String nama, required String noWa}) {
    final error = validasiNomorWhatsApp(noWa);
    if (error != null) {
      throw ArgumentError.value(noWa, 'noWa', error);
    }
    final g = grupAktif;
    final baru = AnggotaKas(
      id: 'a_${DateTime.now().millisecondsSinceEpoch}',
      nama: nama.trim(),
      noWa: _formatNomorWa(noWa),
      tagihan: 0,
      status: StatusBayar.tidakAdaTagihan,
      avatarColor: _palette[g.anggota.length % _palette.length],
    );
    final notif = NotifikasiItem(
      id: 'n_${DateTime.now().millisecondsSinceEpoch}',
      judul: 'Anggota Baru Ditambahkan',
      pesan: '${nama.trim()} telah bergabung ke grup',
      waktu: 'Baru saja',
      kelompokWaktu: 'Hari ini',
      tipe: TipeNotifikasi.anggotaBaru,
    );
    _updateGrupAktif(
      g.copyWith(
        anggota: [...g.anggota, baru],
        daftarNotifikasi: [notif, ...g.daftarNotifikasi],
      ),
    );
  }

  /// Mencatat setoran kas masuk (menambah saldo dan pemasukan kas bersama)
  void catatSetoranKas({
    required int nominal,
    required String penyetorNama,
    String? keterangan,
  }) {
    final g = grupAktif;
    if (nominal <= 0) return;

    final ket = (keterangan != null && keterangan.trim().isNotEmpty)
        ? keterangan.trim()
        : 'Setoran kas dari $penyetorNama';

    final saldoBaru = g.saldo + nominal;
    final pemasukanBaru = g.pemasukan + nominal;

    final notif = NotifikasiItem(
      id: 'n_${DateTime.now().millisecondsSinceEpoch}',
      judul: 'Setoran Kas Masuk',
      pesan: '$penyetorNama menyetor ${formatRupiah(nominal)} ($ket)',
      waktu: 'Baru saja',
      kelompokWaktu: 'Hari ini',
      tipe: TipeNotifikasi.konfirmasiLunas,
      nominal: nominal,
    );

    final riwayat = RiwayatPembayaranItem(
      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
      namaAnggota: penyetorNama,
      judulTagihan: ket,
      nominal: nominal,
      waktu: _waktuSekarangLengkap(),
      status: 'Lunas',
      buktiPath: '',
    );

    // Kurangi tagihan anggota jika penyetor punya tagihan belum bayar
    final anggotaBaru = g.anggota.map((a) {
      if (a.nama.toLowerCase() == penyetorNama.toLowerCase()) {
        final sisaTagihan = max(0, a.tagihan - nominal);
        final statusBaru = sisaTagihan == 0
            ? (a.tagihan > 0 ? StatusBayar.lunas : a.status)
            : a.status;
        return a.copyWith(tagihan: sisaTagihan, status: statusBaru);
      }
      return a;
    }).toList();

    final grupTerupdate = g.copyWith(
      saldo: saldoBaru,
      pemasukan: pemasukanBaru,
      anggota: anggotaBaru,
      daftarNotifikasi: [notif, ...g.daftarNotifikasi],
      daftarRiwayatPembayaran: [riwayat, ...g.daftarRiwayatPembayaran],
    );

    _updateGrupAktif(grupTerupdate);
  }

  void tambahTagihan({
    required String judul,
    required String sumberDana,
    required List<ItemBelanja> items,
    required List<String> idAnggotaDitagih,
    String? penerimaIdOverride,
    bool pakaiPajak = false,
  }) {
    final g = grupAktif;
    final subtotal = items.fold<int>(0, (sum, item) => sum + item.harga);
    final pajak = pakaiPajak ? (subtotal * 0.1).round() : 0;
    final total = subtotal + pajak;

    final targetIds = idAnggotaDitagih.isEmpty
        ? g.anggota.map((e) => e.id).toList()
        : idAnggotaDitagih;

    final porsi = targetIds.isEmpty ? total : (total / targetIds.length).ceil();

    // Tentukan siapa penerima transfer:
    // - Kalau ada override (dari UI "Siapa yang nalangin?") → pakai itu
    // - Kalau sumber dana "Kas grup" → penerima = bendahara
    // - Kalau "Dana pribadi" / default → penerima = user yang login (currentAnggota)
    final profil = profilNotifier.value;
    final AnggotaKas penerima;
    if (sumberDana == 'Kas grup') {
      penerima = g.anggota.firstWhere(
        (a) => a.nama.toLowerCase() == g.bendahara.toLowerCase(),
        orElse: () => g.anggota.first,
      );
    } else {
      final pId = penerimaIdOverride ?? (currentAnggota?.id ?? g.anggota.first.id);
      penerima = g.anggota.firstWhere(
        (a) => a.id == pId,
        orElse: () => g.anggota.first,
      );
    }

    final isMe = penerima.nama.toLowerCase() == currentUserNama.toLowerCase();
    final bank = isMe ? profil.bank : (penerima.nama.toLowerCase() == g.bendahara.toLowerCase() ? profil.bank : '');
    final rek = isMe ? profil.noRekening : (penerima.nama.toLowerCase() == g.bendahara.toLowerCase() ? profil.noRekening : '');

    final tagihanBaru = TagihanKas(
      id: 't_${DateTime.now().millisecondsSinceEpoch}',
      judul: judul.trim().isEmpty ? 'Pengeluaran Baru' : judul.trim(),
      tanggal: _tanggalSekarang(),
      sumberDana: sumberDana,
      items: List<ItemBelanja>.from(items),
      subtotal: subtotal,
      pajak: pajak,
      total: total,
      porsiPerOrang: porsi,
      penerimaId: penerima.id,
      namaPenerima: penerima.nama,
      bankPenerima: bank,
      rekPenerima: rek,
    );

    final anggotaTerupdate = g.anggota.map((anggota) {
      if (targetIds.contains(anggota.id)) {
        if (sumberDana == 'Dana pribadi' && anggota.id == penerima.id) {
          // Yang nalangin sudah bayar porsi pengeluarannya sendiri di awal
          return anggota;
        }
        return anggota.copyWith(
          tagihan: anggota.tagihan + porsi,
          status: StatusBayar.belum,
        );
      }
      return anggota;
    }).toList();

    final kurangiKas = sumberDana == 'Kas grup';

    final notifTagihan = NotifikasiItem(
      id: 'n_${DateTime.now().millisecondsSinceEpoch}',
      judul: 'Tagihan Baru Dibuat',
      pesan: 'Tagihan "${tagihanBaru.judul}" (${formatRupiah(total)}) dibagi ke ${targetIds.length} orang',
      waktu: 'Baru saja',
      kelompokWaktu: 'Hari ini',
      tipe: TipeNotifikasi.tagihanBaru,
      nominal: total,
    );

    _updateGrupAktif(
      g.copyWith(
        saldo: kurangiKas ? g.saldo - total : g.saldo,
        pengeluaran: g.pengeluaran + total,
        anggota: anggotaTerupdate,
        daftarTagihan: [tagihanBaru, ...g.daftarTagihan],
        daftarNotifikasi: [notifTagihan, ...g.daftarNotifikasi],
      ),
    );
    notificationService.tampilkanNotifikasi(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Tagihan Baru: ${tagihanBaru.judul}',
      body: 'Tagihan ${formatRupiah(total)} dibuat untuk ${targetIds.length} anggota di ${g.namaGrup}',
      payload: 'tagihan_baru',
    );
  }

  // ==================== UPDATE ====================

  void ajukanPembayaran({
    required String anggotaId,
    required String namaFileBukti,
    required String buktiPath,
    String? judulTagihan,
    int? nominal,
  }) {
    final g = grupAktif;
    final target = g.anggota.firstWhere((a) => a.id == anggotaId);
    final judulFinal = judulTagihan ??
        (g.daftarTagihan.isNotEmpty ? g.daftarTagihan.first.judul : 'Iuran Kas');
    final nominalFinal =
        nominal ?? (target.tagihan > 0 ? target.tagihan : 0);

    final konfirmasiBaru = KonfirmasiItem(
      id: 'k_${DateTime.now().millisecondsSinceEpoch}',
      anggotaId: target.id,
      namaAnggota: target.nama,
      judulTagihan: judulFinal,
      nominal: nominalFinal,
      namaFileBukti: namaFileBukti,
      buktiPath: buktiPath,
      waktuUnggah: _waktuSekarangLengkap(),
    );

    final anggotaTerupdate = g.anggota.map((a) {
      if (a.id == anggotaId) {
        return a.copyWith(status: StatusBayar.menunggu);
      }
      return a;
    }).toList();

    final konfirmasiBersih =
        g.daftarKonfirmasi.where((k) => k.anggotaId != anggotaId).toList();

    final notifBukti = NotifikasiItem(
      id: 'n_${DateTime.now().millisecondsSinceEpoch}',
      judul: 'Bukti Pembayaran Diunggah',
      pesan: '${target.nama} mengunggah bukti bayar "$judulFinal" — ${formatRupiah(nominalFinal)}',
      waktu: 'Baru saja',
      kelompokWaktu: 'Hari ini',
      tipe: TipeNotifikasi.buktiPembayaran,
      nominal: nominalFinal,
      terkaitId: konfirmasiBaru.id,
    );

    _updateGrupAktif(
      g.copyWith(
        anggota: anggotaTerupdate,
        daftarKonfirmasi: [konfirmasiBaru, ...konfirmasiBersih],
        daftarNotifikasi: [notifBukti, ...g.daftarNotifikasi],
      ),
    );
    notificationService.tampilkanNotifikasiBuktiMasuk(
      namaPengirim: target.nama,
      judulTagihan: judulFinal,
      nominal: nominalFinal,
    );
  }

  void verifikasiPembayaran(String konfirmasiId, {required bool diterima}) {
    final g = grupAktif;
    final item = g.daftarKonfirmasi.firstWhere((k) => k.id == konfirmasiId);

    final anggotaTerupdate = g.anggota.map((a) {
      if (a.id == item.anggotaId) {
        return a.copyWith(
          status: diterima ? StatusBayar.lunas : StatusBayar.belum,
          tagihan: diterima ? 0 : a.tagihan,
        );
      }
      return a;
    }).toList();

    final sisaKonfirmasi =
        g.daftarKonfirmasi.where((k) => k.id != konfirmasiId).toList();

    final riwayatBaru = RiwayatPembayaranItem(
      id: 'rp_${DateTime.now().millisecondsSinceEpoch}',
      namaAnggota: item.namaAnggota,
      judulTagihan: item.judulTagihan,
      nominal: item.nominal,
      waktu: _waktuSekarangLengkap(),
      status: diterima ? 'Lunas' : 'Ditolak',
      buktiPath: item.buktiPath,
    );

    final notifVerif = NotifikasiItem(
      id: 'n_${DateTime.now().millisecondsSinceEpoch}',
      judul: diterima ? 'Pembayaran Dikonfirmasi' : 'Pembayaran Ditolak',
      pesan: diterima
          ? 'Pembayaran ${item.namaAnggota} untuk "${item.judulTagihan}" telah lunas (${formatRupiah(item.nominal)})'
          : 'Bukti pembayaran ${item.namaAnggota} untuk "${item.judulTagihan}" ditolak',
      waktu: 'Baru saja',
      kelompokWaktu: 'Hari ini',
      tipe: diterima ? TipeNotifikasi.konfirmasiLunas : TipeNotifikasi.konfirmasiTolak,
      nominal: item.nominal,
    );

    _updateGrupAktif(
      g.copyWith(
        saldo: diterima ? g.saldo + item.nominal : g.saldo,
        pemasukan: diterima ? g.pemasukan + item.nominal : g.pemasukan,
        anggota: anggotaTerupdate,
        daftarKonfirmasi: sisaKonfirmasi,
        daftarRiwayatPembayaran: [riwayatBaru, ...g.daftarRiwayatPembayaran],
        daftarNotifikasi: [notifVerif, ...g.daftarNotifikasi],
      ),
    );
    notificationService.tampilkanNotifikasiVerifikasi(
      namaAnggota: item.namaAnggota,
      judulTagihan: item.judulTagihan,
      nominal: item.nominal,
      diterima: diterima,
    );
  }

  // ==================== DELETE ====================

  void hapusTagihan(String tagihanId) {
    final g = grupAktif;
    final target = g.daftarTagihan.firstWhere((t) => t.id == tagihanId);
    final kembalikanKas = target.sumberDana == 'Kas grup';

    final anggotaTerupdate = g.anggota.map((a) {
      if (target.sumberDana == 'Dana pribadi' && a.id == target.penerimaId) {
        return a;
      }
      final sisa = max(0, a.tagihan - target.porsiPerOrang);
      final statusBaru = sisa == 0
          ? StatusBayar.tidakAdaTagihan
          : (a.status == StatusBayar.lunas ? StatusBayar.lunas : StatusBayar.belum);
      return a.copyWith(
        tagihan: sisa,
        status: statusBaru,
      );
    }).toList();

    _updateGrupAktif(
      g.copyWith(
        saldo: kembalikanKas ? g.saldo + target.total : g.saldo,
        pengeluaran: max(0, g.pengeluaran - target.total),
        anggota: anggotaTerupdate,
        daftarTagihan: g.daftarTagihan.where((t) => t.id != tagihanId).toList(),
      ),
    );
  }

  void hapusAnggota(String anggotaId) {
    final g = grupAktif;
    _updateGrupAktif(
      g.copyWith(
        anggota: g.anggota.where((a) => a.id != anggotaId).toList(),
        daftarKonfirmasi:
            g.daftarKonfirmasi.where((k) => k.anggotaId != anggotaId).toList(),
      ),
    );
  }

  void editNamaGrup(String grupId, String namaBaru) {
    final listBaru = value.daftarGrup.map((g) {
      if (g.id == grupId) {
        final updated = g.copyWith(namaGrup: namaBaru.trim());
        firestoreService.simpanGrup(updated).catchError((_) {});
        return updated;
      }
      return g;
    }).toList();
    value = KasRootState(aktifGrupId: value.aktifGrupId, daftarGrup: listBaru);
  }

  bool hapusGrup(String grupId) {
    if (value.daftarGrup.length <= 1) {
      return false;
    }
    final sisaGrup = value.daftarGrup.where((g) => g.id != grupId).toList();
    final newAktifId =
        value.aktifGrupId == grupId ? sisaGrup.first.id : value.aktifGrupId;
    value = KasRootState(aktifGrupId: newAktifId, daftarGrup: sisaGrup);
    firestoreService.hapusGrup(grupId).catchError((_) {});
    return true;
  }

  void keluarDariGrup(String grupId) {
    final me = currentAnggota;
    if (me != null) {
      final g = value.daftarGrup.firstWhere((x) => x.id == grupId);
      final sisaAnggota = g.anggota.where((a) => a.id != me.id).toList();
      _updateGrupAktif(g.copyWith(anggota: sisaAnggota));
    }
  }

  // ==================== WHATSAPP LAUNCHER ====================

  Future<bool> _bukaUrlWhatsApp(Uri uri) async {
    try {
      final dibukaExternal = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (dibukaExternal) return true;
    } catch (_) {}

    try {
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      return false;
    }
  }

  Future<bool> kirimTagihanWhatsApp(AnggotaKas anggota) async {
    final g = grupAktif;
    final profil = profilNotifier.value;
    final bank = profil.bank.isEmpty ? 'Bank' : profil.bank;
    final rekening =
        profil.noRekening.isEmpty ? '-' : profil.noRekening;
    final penerima = profil.nama.isEmpty ? g.bendahara : profil.nama;
    final judulTagihan =
        g.daftarTagihan.isNotEmpty ? g.daftarTagihan.first.judul : 'Iuran Kas';
    final nominalText = formatRupiah(anggota.tagihan);

    final pesan = 'Halo ${anggota.nama},\n'
        'Pengingat tagihan *${g.namaGrup}* untuk *$judulTagihan* sebesar *$nominalText*.\n\n'
        'Silakan transfer ke:\n'
        '$bank $rekening a.n. $penerima\n\n'
        'Jika sudah transfer, mohon unggah bukti bayar di aplikasi *KasMate*. Terima kasih!';

    final nomorTujuan = _formatNomorWa(anggota.noWa);
    final url = Uri.parse(
      'https://wa.me/$nomorTujuan?text=${Uri.encodeComponent(pesan)}',
    );
    tambahNotifikasi(
      judul: 'Pengingat WhatsApp Terkirim',
      pesan: 'Pengingat tagihan "$judulTagihan" dikirim ke ${anggota.nama}',
      tipe: TipeNotifikasi.pengingatWa,
      nominal: anggota.tagihan,
    );
    return _bukaUrlWhatsApp(url);
  }

  Future<bool> bagikanUndanganGrupWhatsApp([GrupKas? targetGrup]) async {
    final g = targetGrup ?? grupAktif;
    final pesan = 'Halo teman-teman!\n'
        'Yuk gabung ke grup kas *${g.namaGrup}* di aplikasi *KasMate*.\n\n'
        'Kode Undangan: *${g.kodeUndangan}*\n'
        'Link Undangan: ${g.linkUndangan}\n\n'
        'Buka aplikasi KasMate -> pilih *Gabung ke grup* -> masukkan kode *${g.kodeUndangan}*.';

    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(pesan)}');
    return _bukaUrlWhatsApp(url);
  }

  // ==================== EKSPOR LAPORAN ====================

  String generateLaporanCsv() {
    final g = grupAktif;
    final sb = StringBuffer();
    sb.writeln('LAPORAN KEUANGAN KASMATE');
    sb.writeln('Nama Grup,${g.namaGrup}');
    sb.writeln('Kode Undangan,${g.kodeUndangan}');
    sb.writeln('Bendahara,${g.bendahara}');
    sb.writeln('Saldo Kas,${g.saldo}');
    sb.writeln('Total Pemasukan,${g.pemasukan}');
    sb.writeln('Total Pengeluaran,${g.pengeluaran}');
    sb.writeln('');
    sb.writeln('STATUS ANGGOTA');
    sb.writeln('Nama Anggota,No WhatsApp,Sisa Tagihan,Status');
    for (final a in g.anggota) {
      final st = a.status == StatusBayar.lunas
          ? 'Lunas'
          : a.status == StatusBayar.menunggu
              ? 'Menunggu'
              : a.status == StatusBayar.tidakAdaTagihan
                  ? 'Tidak Ada Tagihan'
                  : 'Belum Bayar';
      sb.writeln('${a.nama},${a.noWa},${a.tagihan},$st');
    }
    sb.writeln('');
    sb.writeln('RIWAYAT PENGELUARAN');
    sb.writeln('Judul,Tanggal,Sumber Dana,Total');
    for (final t in g.daftarTagihan) {
      sb.writeln('${t.judul},${t.tanggal},${t.sumberDana},${t.total}');
    }
    sb.writeln('');
    sb.writeln('RIWAYAT PEMBAYARAN');
    sb.writeln('Nama Pembayar,Tagihan,Nominal,Waktu,Status');
    for (final r in g.daftarRiwayatPembayaran) {
      sb.writeln(
          '${r.namaAnggota},${r.judulTagihan},${r.nominal},"${r.waktu}",${r.status}');
    }
    return sb.toString();
  }
}

final KasStore kasStore = KasStore();
