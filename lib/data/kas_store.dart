import 'dart:async';
import 'dart:math';
import '../utils/hitung_tagihan.dart';
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
  final String? uid;
  final String nama;
  final String noWa;
  final int tagihan;
  final StatusBayar status;
  final Color avatarColor;
  final String bank;
  final String noRekening;

  const AnggotaKas({
    required this.id,
    this.uid,
    required this.nama,
    required this.noWa,
    required this.tagihan,
    required this.status,
    required this.avatarColor,
    this.bank = '',
    this.noRekening = '',
  });

  AnggotaKas copyWith({
    String? uid,
    String? nama,
    String? noWa,
    int? tagihan,
    StatusBayar? status,
    String? bank,
    String? noRekening,
  }) {
    return AnggotaKas(
      id: id,
      uid: uid ?? this.uid,
      nama: nama ?? this.nama,
      noWa: noWa ?? this.noWa,
      tagihan: tagihan ?? this.tagihan,
      status: status ?? this.status,
      avatarColor: avatarColor,
      bank: bank ?? this.bank,
      noRekening: noRekening ?? this.noRekening,
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
  final DateTime? jatuhTempo;
  final String sumberDana;
  final List<ItemBelanja> items;
  final int subtotal;
  final double pajakPersen;
  final int diskon;
  final int biayaLayanan;
  final int pajak;
  final int total;
  final int porsiPerOrang;
  final Map<String, int> porsiAnggota;

  // Info penerima transfer (siapa yang nalangin / harus menerima uang)
  final String penerimaId;
  final String namaPenerima;
  final String bankPenerima;
  final String rekPenerima;
  final List<String> anggotaDitagihIds;

  const TagihanKas({
    required this.id,
    required this.judul,
    required this.tanggal,
    this.jatuhTempo,
    required this.sumberDana,
    required this.items,
    required this.subtotal,
    this.pajakPersen = 0,
    this.diskon = 0,
    this.biayaLayanan = 0,
    required this.pajak,
    required this.total,
    required this.porsiPerOrang,
    this.porsiAnggota = const {},
    required this.penerimaId,
    required this.namaPenerima,
    this.bankPenerima = '',
    this.rekPenerima = '',
    this.anggotaDitagihIds = const [],
  });

  int porsiUntuk(String anggotaId) {
    if (porsiAnggota.isNotEmpty) return porsiAnggota[anggotaId] ?? 0;
    // Data lama tidak dihitung ulang supaya utang historis tidak ikut berubah.
    if (anggotaDitagihIds.isNotEmpty && !anggotaDitagihIds.contains(anggotaId)) {
      return 0;
    }
    return porsiPerOrang;
  }
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
  final String? penerimaId;
  final String? namaPenerima;
  final String? sumberDana;

  const KonfirmasiItem({
    required this.id,
    required this.anggotaId,
    required this.namaAnggota,
    required this.judulTagihan,
    required this.nominal,
    required this.namaFileBukti,
    required this.buktiPath,
    required this.waktuUnggah,
    this.penerimaId,
    this.namaPenerima,
    this.sumberDana,
  });
}

class RiwayatPembayaranItem {
  final String id;
  final String namaAnggota;
  final String judulTagihan;
  final int nominal;
  final String waktu;
  final String status; // 'Lunas', 'Ditolak', atau 'Dibatalkan'
  final String buktiPath;
  final String? catatan;

  const RiwayatPembayaranItem({
    required this.id,
    required this.namaAnggota,
    required this.judulTagihan,
    required this.nominal,
    required this.waktu,
    required this.status,
    required this.buktiPath,
    this.catatan,
  });

  RiwayatPembayaranItem copyWith({
    String? status,
    String? catatan,
  }) {
    return RiwayatPembayaranItem(
      id: id,
      namaAnggota: namaAnggota,
      judulTagihan: judulTagihan,
      nominal: nominal,
      waktu: waktu,
      status: status ?? this.status,
      buktiPath: buktiPath,
      catatan: catatan ?? this.catatan,
    );
  }
}

class TagihanDetailItem {
  final String id;
  final String tagihanId;
  final String judul;
  final int nominal;
  final StatusBayar status;
  final String namaPenerima;
  final String penerimaId;
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
    this.penerimaId = '',
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
  final DateTime? createdAt;
  final String? pengirimUid;

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
    this.createdAt,
    this.pengirimUid,
  });

  NotifikasiItem copyWith({
    bool? isDibaca,
    String? waktu,
    String? kelompokWaktu,
    DateTime? createdAt,
    String? pengirimUid,
  }) {
    return NotifikasiItem(
      id: id,
      judul: judul,
      pesan: pesan,
      waktu: waktu ?? this.waktu,
      kelompokWaktu: kelompokWaktu ?? this.kelompokWaktu,
      tipe: tipe,
      isDibaca: isDibaca ?? this.isDibaca,
      nominal: nominal,
      terkaitId: terkaitId,
      createdAt: createdAt ?? this.createdAt,
      pengirimUid: pengirimUid ?? this.pengirimUid,
    );
  }

  /// Waktu relatif dinamis (Poin 25)
  String get waktuDinamis {
    final t = createdAt;
    if (t == null) return waktu.isNotEmpty ? waktu : 'Baru saja';
    final now = DateTime.now();
    final diff = now.difference(t);

    if (diff.isNegative || diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else if (diff.inDays < 30) {
      final minggu = (diff.inDays / 7).floor();
      return '$minggu minggu lalu';
    } else {
      return '${t.day}/${t.month}/${t.year}';
    }
  }

  /// Kelompok timeline relatif dinamis (Poin 25)
  String get kelompokWaktuDinamis {
    final t = createdAt;
    if (t == null) return kelompokWaktu.isNotEmpty ? kelompokWaktu : 'Hari ini';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notifDate = DateTime(t.year, t.month, t.day);
    final diffDays = today.difference(notifDate).inDays;

    if (diffDays <= 0) {
      return 'Hari ini';
    } else if (diffDays == 1) {
      return 'Kemarin';
    } else if (diffDays < 7) {
      return 'Minggu ini';
    } else if (diffDays < 30) {
      return 'Bulan ini';
    } else {
      return 'Lebih lama';
    }
  }
}

class GrupKas {
  final String id;
  final String namaGrup;
  final String kodeUndangan;
  final String tipeGrup; // 'kasResmi' (ada saldo kas) atau 'patungan' (murni split bill)
  final String bendahara;
  final String? bendaharaUid;
  final List<String> anggotaUids;
  final List<String> blacklistUids;
  final int saldo;
  final int pemasukan;
  final int _pengeluaran;

  /// Total pengeluaran kas (untuk kasResmi) atau akumulasi tagihan patungan (untuk patungan)
  int get pengeluaran {
    if (tipeGrup == 'patungan') {
      final totalDariTagihan =
          daftarTagihan.fold<int>(0, (prev, t) => prev + t.total);
      return totalDariTagihan > _pengeluaran ? totalDariTagihan : _pengeluaran;
    }
    return _pengeluaran;
  }

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
    this.bendaharaUid,
    this.anggotaUids = const [],
    this.blacklistUids = const [],
    required this.saldo,
    required this.pemasukan,
    required int pengeluaran,
    required this.anggota,
    required this.daftarTagihan,
    required this.daftarKonfirmasi,
    required this.daftarRiwayatPembayaran,
    this.daftarNotifikasi = const [],
  }) : _pengeluaran = pengeluaran;

  String get linkUndangan => kodeUndangan;

  GrupKas copyWith({
    String? namaGrup,
    String? kodeUndangan,
    String? tipeGrup,
    String? bendahara,
    String? bendaharaUid,
    List<String>? anggotaUids,
    List<String>? blacklistUids,
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
      bendaharaUid: bendaharaUid ?? this.bendaharaUid,
      anggotaUids: anggotaUids ?? this.anggotaUids,
      blacklistUids: blacklistUids ?? this.blacklistUids,
      saldo: saldo ?? this.saldo,
      pemasukan: pemasukan ?? this.pemasukan,
      pengeluaran: pengeluaran ?? _pengeluaran,
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

  String get currentUserUid {
    final uid = profilNotifier.value.id.trim();
    if (uid.isNotEmpty) return uid;
    try {
      return authService.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  String get currentUserNama {
    final nama = profilNotifier.value.nama.trim();
    if (nama.isNotEmpty) return nama;
    try {
      final fbName = authService.currentUser?.displayName?.trim() ?? '';
      if (fbName.isNotEmpty) return fbName;
    } catch (_) {}
    return 'Pengguna';
  }

  AnggotaKas? get currentAnggota {
    final myUid = currentUserUid;
    if (myUid.isNotEmpty) {
      for (final a in grupAktif.anggota) {
        if (a.uid == myUid || a.id == myUid) return a;
      }
    }
    final myNama = currentUserNama.toLowerCase();
    if (myNama.isNotEmpty && myNama != 'pengguna') {
      for (final a in grupAktif.anggota) {
        if (a.nama.toLowerCase() == myNama) return a;
      }
    }
    final myWa = _formatNomorWa(profilNotifier.value.noWa);
    if (myWa.isNotEmpty) {
      for (final a in grupAktif.anggota) {
        if (a.noWa.isNotEmpty && _formatNomorWa(a.noWa) == myWa) return a;
      }
    }
    return null;
  }

  /// Mengecek apakah user yang sedang login berhak menerima / menolak konfirmasi pembayaran
  bool bisaVerifikasiKonfirmasi(KonfirmasiItem item) {
    final myUid = currentUserUid;
    final myNama = currentUserNama.toLowerCase();
    final g = grupAktif;

    // Pembayar TIDAK BISA memverifikasi pembayaran miliknya sendiri
    if (item.anggotaId == currentAnggota?.id ||
        (myUid.isNotEmpty && currentAnggota?.uid == myUid && item.anggotaId == currentAnggota?.id) ||
        (myNama.isNotEmpty && myNama != 'pengguna' && item.namaAnggota.toLowerCase() == myNama)) {
      return false;
    }

    // 1. Cek apakah ada penerimaId spesifik (orang yang menalangi)
    if (item.penerimaId != null && item.penerimaId!.isNotEmpty) {
      if (myUid.isNotEmpty && item.penerimaId == myUid) return true;
      final me = currentAnggota;
      if (me != null && (item.penerimaId == me.id || (me.uid != null && item.penerimaId == me.uid))) {
        return true;
      }
    }

    // 2. Cek apakah ada namaPenerima spesifik
    if (item.namaPenerima != null && item.namaPenerima!.isNotEmpty) {
      if (item.namaPenerima!.toLowerCase() == myNama) return true;
    }

    // 3. Jika untuk kas grup atau penerima default: Bendahara berhak memverifikasi
    return isBendahara(g);
  }

  /// Cek apakah user saat ini adalah bendahara dari grup tertentu
  bool isBendahara(GrupKas g) {
    final myUid = currentUserUid;
    final myNama = currentUserNama.toLowerCase();
    if (myUid.isNotEmpty && g.bendaharaUid != null && g.bendaharaUid!.isNotEmpty) {
      return g.bendaharaUid == myUid;
    }
    return myNama.isNotEmpty && myNama != 'pengguna' && g.bendahara.toLowerCase() == myNama;
  }

  /// Cek apakah suatu anggota merupakan user yang sedang login saat ini
  bool isCurrentUser(AnggotaKas a) {
    final me = currentAnggota;
    if (me != null && (me.id == a.id || (me.uid != null && me.uid == a.uid))) {
      return true;
    }
    final myUid = currentUserUid;
    if (myUid.isNotEmpty && (a.uid == myUid || a.id == myUid)) return true;
    final myNama = currentUserNama.toLowerCase();
    if (myNama.isNotEmpty && myNama != 'pengguna' && a.nama.toLowerCase() == myNama) return true;
    final myWa = _formatNomorWa(profilNotifier.value.noWa);
    if (myWa.isNotEmpty && a.noWa.isNotEmpty && _formatNomorWa(a.noWa) == myWa) return true;
    return false;
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
          if (t.penerimaId != me.id && t.porsiUntuk(me.id) > 0) {
            result.add(
              TagihanDetailItem(
                id: 'ts_${t.id}_${me.id}',
                tagihanId: t.id,
                judul: t.judul,
                nominal: t.porsiUntuk(me.id),
                status: me.status,
                namaPenerima: t.namaPenerima,
                penerimaId: t.penerimaId,
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
          final bendaharaAnggota = grupAktif.anggota.cast<AnggotaKas?>().firstWhere(
            (a) => a != null && (
              a.nama.toLowerCase() == grupAktif.bendahara.toLowerCase() ||
              (grupAktif.bendaharaUid != null && a.uid == grupAktif.bendaharaUid)
            ),
            orElse: () => null,
          );
          if (bendaharaAnggota != null && bendaharaAnggota.bank.isNotEmpty) {
            bankBendahara = bendaharaAnggota.bank;
            rekBendahara = bendaharaAnggota.noRekening;
          }
          if (bankBendahara.isEmpty) {
            for (final t in grupAktif.daftarTagihan) {
              if (t.namaPenerima.toLowerCase() == grupAktif.bendahara.toLowerCase() && t.rekPenerima.isNotEmpty) {
                bankBendahara = t.bankPenerima;
                rekBendahara = t.rekPenerima;
                break;
              }
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
            penerimaId: grupAktif.bendaharaUid ?? '',
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
              penerimaId: me.uid ?? me.id,
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

  StreamSubscription<List<NotifikasiItem>>? _notifSub;
  String _currentNotifGrupId = '';
  final Set<String> _notifikasiDitampilkanIds = {};

  void tambahNotifikasi({
    required String judul,
    required String pesan,
    required TipeNotifikasi tipe,
    int? nominal,
    String? terkaitId,
    String kelompokWaktu = 'Hari ini',
    DateTime? createdAt,
    String? pengirimUid,
  }) {
    final g = grupAktif;
    final wNow = createdAt ?? DateTime.now();
    final pUid = pengirimUid ?? currentUserUid;
    final baru = NotifikasiItem(
      id: 'n_${wNow.millisecondsSinceEpoch}',
      judul: judul,
      pesan: pesan,
      waktu: 'Baru saja',
      kelompokWaktu: kelompokWaktu,
      tipe: tipe,
      nominal: nominal,
      terkaitId: terkaitId,
      isDibaca: false,
      createdAt: wNow,
      pengirimUid: pUid,
    );
    _notifikasiDitampilkanIds.add(baru.id);
    _updateGrupAktif(
      g.copyWith(daftarNotifikasi: [baru, ...g.daftarNotifikasi]),
    );
  }

  /// Menandai satu notifikasi telah dibaca (Poin 10)
  void tandaiNotifikasiDibaca(String id) {
    final g = grupAktif;
    final listBaru = g.daftarNotifikasi.map((n) {
      if (n.id == id) {
        return n.copyWith(isDibaca: true);
      }
      return n;
    }).toList();
    _updateGrupAktif(g.copyWith(daftarNotifikasi: listBaru));
    firestoreService.tandaiNotifikasiDibacaSubkoleksi(
      grupId: g.id,
      notifId: id,
      isDibaca: true,
    ).catchError((err) {
      debugPrint('Firestore update notif dibaca note: $err');
    });
  }

  /// Menandai semua notifikasi telah dibaca
  void tandaiSemuaNotifikasiDibaca() {
    final g = grupAktif;
    final listBaru =
        g.daftarNotifikasi.map((n) => n.copyWith(isDibaca: true)).toList();
    _updateGrupAktif(g.copyWith(daftarNotifikasi: listBaru));
    firestoreService.tandaiSemuaNotifikasiDibacaSubkoleksi(g.id).catchError((err) {
      debugPrint('Firestore update all notif dibaca note: $err');
    });
  }

  void _updateGrupAktif(GrupKas updated) {
    final listBaru =
        value.daftarGrup.map((g) => g.id == updated.id ? updated : g).toList();
    value = KasRootState(aktifGrupId: updated.id, daftarGrup: listBaru);
    // Sinkronkan ke Cloud Firestore di latar belakang
    firestoreService.simpanGrup(updated).catchError((err) {
      debugPrint('Firestore update note: $err');
    });
    // Broadcast notifikasi terbaru ke subkoleksi grup Firestore (Poin 46)
    if (updated.daftarNotifikasi.isNotEmpty) {
      final notifTerbaru = updated.daftarNotifikasi.first;
      firestoreService.simpanNotifikasiSubkoleksi(
        grupId: updated.id,
        notifikasi: notifTerbaru,
      ).catchError((err) {
        debugPrint('Firestore broadcast subkoleksi note: $err');
      });
    }
  }

  /// Dengarkan subkoleksi notifikasi grup secara realtime (Poin 46)
  void _listenNotifikasiGrup(String grupId) {
    if (grupId.isEmpty) {
      _notifSub?.cancel();
      _notifSub = null;
      _currentNotifGrupId = '';
      return;
    }
    if (grupId == _currentNotifGrupId) return;
    _currentNotifGrupId = grupId;
    _notifSub?.cancel();
    _notifSub = firestoreService.streamNotifikasiGrup(grupId).listen(
      (daftarDariSubkoleksi) {
        if (daftarDariSubkoleksi.isEmpty) return;
        final g = grupAktif;
        if (g.id != grupId) return;

        final currentUid = currentUserUid;
        for (final item in daftarDariSubkoleksi) {
          if (!_notifikasiDitampilkanIds.contains(item.id)) {
            _notifikasiDitampilkanIds.add(item.id);
            final bukanPengirimSaya = item.pengirimUid != null &&
                item.pengirimUid!.isNotEmpty &&
                item.pengirimUid != currentUid;
            if (bukanPengirimSaya) {
              notificationService.tampilkanNotifikasi(
                id: item.id.hashCode,
                title: item.judul,
                body: item.pesan,
                payload: item.tipe.name,
              );
            }
          }
        }

        // Sinkronkan daftarNotifikasi lokal dengan data subkoleksi
        final mapNotif = <String, NotifikasiItem>{};
        for (final n in g.daftarNotifikasi) {
          mapNotif[n.id] = n;
        }
        for (final n in daftarDariSubkoleksi) {
          mapNotif[n.id] = n;
        }
        final listGabungan = mapNotif.values.toList()
          ..sort((a, b) {
            final aTime = a.createdAt?.millisecondsSinceEpoch ??
                (int.tryParse(a.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0);
            final bTime = b.createdAt?.millisecondsSinceEpoch ??
                (int.tryParse(b.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0);
            return bTime.compareTo(aTime);
          });

        final updated = g.copyWith(daftarNotifikasi: listGabungan);
        final listBaru = value.daftarGrup
            .map((itemG) => itemG.id == updated.id ? updated : itemG)
            .toList();
        value = KasRootState(aktifGrupId: updated.id, daftarGrup: listBaru);
      },
      onError: (err) {
        debugPrint('Error streaming notifikasi subkoleksi: $err');
      },
    );
  }

  /// Reset state memori saat logout agar tidak bocor ke user lain
  void resetState() {
    _notifSub?.cancel();
    _notifSub = null;
    _currentNotifGrupId = '';
    _notifikasiDitampilkanIds.clear();
    value = const KasRootState(aktifGrupId: '', daftarGrup: []);
    _semuaGrupFirestore = [];
  }

  List<GrupKas> _semuaGrupFirestore = [];

  /// Muat ulang seluruh grup pengguna dari Firestore (dipanggil saat login / inisialisasi)
  Future<void> muatUlangGrupDariFirestore([String? targetUid]) async {
    try {
      final daftar = await firestoreService.getDaftarGrupSekali();
      _semuaGrupFirestore = daftar.where((g) => g.id != 'g1' && g.id != 'g2').toList();
      _filterDanTerapkanGrup();
    } catch (e) {
      debugPrint('Error muatUlangGrupDariFirestore: $e');
    }
  }

  /// Memfilter grup agar hanya menampilkan grup di mana user terdaftar sebagai bendahara/anggota
  void _filterDanTerapkanGrup() {
    final myUid = currentUserUid;
    final myNama = profilNotifier.value.nama.trim().toLowerCase();
    final myWa = _formatNomorWa(profilNotifier.value.noWa);
    final fbUser = authService.currentUser;
    final myFbName = (fbUser?.displayName ?? '').trim().toLowerCase();

    // Jika belum ada user yang login atau nama masih kosong, kosongkan daftar
    if (myUid.isEmpty && myNama.isEmpty && myFbName.isEmpty && fbUser == null) {
      value = const KasRootState(aktifGrupId: '', daftarGrup: []);
      return;
    }

    final listUser = _semuaGrupFirestore.where((g) {
      // Step 4.2 (Poin 29 & 30): Jika user ada di daftar blacklist grup ini, sembunyikan dari dashboard
      if (myUid.isNotEmpty && g.blacklistUids.contains(myUid)) {
        return false;
      }

      // 1. Cek apakah user adalah bendahara berdasarkan UID atau nama
      if (myUid.isNotEmpty && g.bendaharaUid != null && g.bendaharaUid == myUid) {
        return true;
      }
      final isBendaharaNama = (myNama.isNotEmpty && g.bendahara.toLowerCase() == myNama) ||
          (myFbName.isNotEmpty && g.bendahara.toLowerCase() == myFbName);
      if (isBendaharaNama) return true;

      // 2. Cek apakah UID user terdaftar di anggotaUids grup
      if (myUid.isNotEmpty && g.anggotaUids.contains(myUid)) {
        return true;
      }

      // 3. Cek apakah ada di daftar anggota (UID, nama, atau WA sama)
      final isAnggota = g.anggota.any((a) {
        final matchUid = myUid.isNotEmpty && ((a.uid != null && a.uid == myUid) || a.id == myUid);
        final matchNama = (myNama.isNotEmpty && a.nama.toLowerCase() == myNama) ||
            (myFbName.isNotEmpty && a.nama.toLowerCase() == myFbName);
        final matchWa = myWa.isNotEmpty && a.noWa.isNotEmpty && _formatNomorWa(a.noWa) == myWa;
        return matchUid || matchNama || matchWa;
      });

      return isAnggota;
    }).toList();

    if (listUser.isNotEmpty) {
      final currentId = value.aktifGrupId;
      final ada = listUser.any((g) => g.id == currentId);
      final newId = ada ? currentId : listUser.first.id;
      value = KasRootState(aktifGrupId: newId, daftarGrup: listUser);
      _listenNotifikasiGrup(newId);
      // Periksa pengingat jatuh tempo tagihan (Poin 24 & 37)
      final gAktif = listUser.firstWhere((g) => g.id == newId, orElse: () => listUser.first);
      if (gAktif.daftarTagihan.isNotEmpty) {
        notificationService.periksaJatuhTempoTagihan(
          daftarTagihan: gAktif.daftarTagihan,
          myNama: myNama,
          myId: currentAnggota?.id,
          myUid: myUid,
        );
      }
    } else {
      value = const KasRootState(aktifGrupId: '', daftarGrup: []);
      _listenNotifikasiGrup('');
    }
  }

  /// Sinkronisasi edit profil user (nama, no WA, bank, rekening) ke semua grup di Firestore
  Future<void> perbaruiProfilAnggotaDiSemuaGrup({
    required String uid,
    required String namaBaru,
    required String noWaBaru,
    String? bankBaru,
    String? noRekeningBaru,
  }) async {
    final targetUid = uid.isNotEmpty ? uid : currentUserUid;
    final myCurrentNama = currentUserNama.toLowerCase();

    final updatedDaftarGrup = <GrupKas>[];
    for (final g in value.daftarGrup) {
      bool grupDiubah = false;
      String bendaharaBaru = g.bendahara;
      if ((targetUid.isNotEmpty && g.bendaharaUid == targetUid) ||
          (g.bendahara.toLowerCase() == myCurrentNama)) {
        bendaharaBaru = namaBaru;
        grupDiubah = true;
      }

      final anggotaBaru = g.anggota.map((a) {
        final match = (targetUid.isNotEmpty && ((a.uid != null && a.uid == targetUid) || a.id == targetUid)) ||
            (a.nama.toLowerCase() == myCurrentNama);
        if (match) {
          grupDiubah = true;
          return a.copyWith(
            uid: targetUid.isNotEmpty ? targetUid : a.uid,
            nama: namaBaru,
            noWa: noWaBaru,
            bank: bankBaru ?? a.bank,
            noRekening: noRekeningBaru ?? a.noRekening,
          );
        }
        return a;
      }).toList();

      if (grupDiubah) {
        final gBaru = g.copyWith(
          bendahara: bendaharaBaru,
          bendaharaUid: (targetUid.isNotEmpty && g.bendaharaUid == targetUid) ? targetUid : g.bendaharaUid,
          anggota: anggotaBaru,
        );
        updatedDaftarGrup.add(gBaru);
        await firestoreService.simpanGrup(gBaru).catchError((_) {});
      } else {
        updatedDaftarGrup.add(g);
      }
    }

    if (updatedDaftarGrup.isNotEmpty) {
      value = KasRootState(
        aktifGrupId: value.aktifGrupId,
        daftarGrup: updatedDaftarGrup,
      );
    }
  }

  /// Bersihkan referensi user dari semua grup di Firestore saat user menghapus akun
  Future<void> bersihkanUserDariSemuaGrup(String uid) async {
    try {
      final semua = await firestoreService.getDaftarGrupSekali();
      for (final g in semua) {
        final ada = g.anggotaUids.contains(uid) ||
            g.bendaharaUid == uid ||
            g.anggota.any((a) => a.uid == uid || a.id == uid);
        if (ada) {
          final sisaAnggota = g.anggota.where((a) => a.uid != uid && a.id != uid).toList();
          final sisaUids = g.anggotaUids.where((u) => u != uid).toList();
          if (sisaAnggota.isEmpty) {
            await firestoreService.hapusGrup(g.id);
          } else {
            final updated = g.copyWith(
              bendaharaUid: g.bendaharaUid == uid ? (sisaAnggota.isNotEmpty ? sisaAnggota.first.uid : null) : g.bendaharaUid,
              bendahara: g.bendaharaUid == uid ? (sisaAnggota.isNotEmpty ? sisaAnggota.first.nama : g.bendahara) : g.bendahara,
              anggota: sisaAnggota,
              anggotaUids: sisaUids,
            );
            await firestoreService.simpanGrup(updated);
          }
        }
      }
    } catch (e) {
      debugPrint('Error bersihkanUserDariSemuaGrup: $e');
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
    final currentUid = currentUserUid;
    final namaUser = profilNotifier.value.nama.isEmpty
        ? 'Bendahara Utama'
        : profilNotifier.value.nama;
    final waUser = profilNotifier.value.noWa.isEmpty
        ? ''
        : _formatNomorWa(profilNotifier.value.noWa);

    final anggotaId = currentUid.isNotEmpty ? currentUid : 'a_${DateTime.now().millisecondsSinceEpoch}';

    final grupBaru = GrupKas(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
      namaGrup: namaGrup.trim(),
      kodeUndangan: kodeUndangan.trim().toUpperCase(),
      tipeGrup: tipeGrup,
      bendahara: namaUser,
      bendaharaUid: currentUid.isNotEmpty ? currentUid : null,
      anggotaUids: currentUid.isNotEmpty ? [currentUid] : [],
      saldo: 0,
      pemasukan: 0,
      pengeluaran: 0,
      anggota: [
        AnggotaKas(
          id: anggotaId,
          uid: currentUid.isNotEmpty ? currentUid : null,
          nama: namaUser,
          noWa: waUser,
          tagihan: 0,
          status: StatusBayar.tidakAdaTagihan,
          avatarColor: const Color(0xFFDBEAFE),
          bank: profilNotifier.value.bank,
          noRekening: profilNotifier.value.noRekening,
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

    // Step 4.2 (Poin 29 & 30): Cek blacklist
    final currentUid = currentUserUid;
    if (currentUid.isNotEmpty && ditemukan.blacklistUids.contains(currentUid)) {
      return false;
    }

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

    final currentUid = currentUserUid;
    // Step 4.2 (Poin 29 & 30): Cek blacklist
    if (currentUid.isNotEmpty && ditemukan.blacklistUids.contains(currentUid)) {
      throw Exception('Kamu telah dikeluarkan dari grup ini dan tidak dapat bergabung kembali tanpa izin bendahara.');
    }
    final namaUser = profilNotifier.value.nama.isEmpty
        ? 'Anggota Baru'
        : profilNotifier.value.nama;
    final waUser = _formatNomorWa(profilNotifier.value.noWa);

    final daftarAnggotaBaru = List<AnggotaKas>.from(ditemukan.anggota);
    final anggotaUidsBaru = Set<String>.from(ditemukan.anggotaUids);

    final indexExisting = daftarAnggotaBaru.indexWhere((a) {
      if (currentUid.isNotEmpty && ((a.uid != null && a.uid == currentUid) || a.id == currentUid)) return true;
      if (waUser.isNotEmpty && a.noWa.isNotEmpty && _formatNomorWa(a.noWa) == waUser) return true;
      return a.nama.toLowerCase() == namaUser.toLowerCase();
    });

    if (indexExisting >= 0) {
      final existing = daftarAnggotaBaru[indexExisting];
      daftarAnggotaBaru[indexExisting] = existing.copyWith(
        uid: currentUid.isNotEmpty ? currentUid : existing.uid,
        noWa: waUser.isNotEmpty ? waUser : existing.noWa,
        bank: profilNotifier.value.bank.isNotEmpty ? profilNotifier.value.bank : existing.bank,
        noRekening: profilNotifier.value.noRekening.isNotEmpty ? profilNotifier.value.noRekening : existing.noRekening,
      );
    } else {
      final anggotaId = currentUid.isNotEmpty ? currentUid : 'a_${DateTime.now().millisecondsSinceEpoch}';
      daftarAnggotaBaru.add(
        AnggotaKas(
          id: anggotaId,
          uid: currentUid.isNotEmpty ? currentUid : null,
          nama: namaUser,
          noWa: waUser,
          tagihan: 0,
          status: StatusBayar.tidakAdaTagihan,
          avatarColor: _palette[daftarAnggotaBaru.length % _palette.length],
          bank: profilNotifier.value.bank,
          noRekening: profilNotifier.value.noRekening,
        ),
      );
    }

    if (currentUid.isNotEmpty) {
      anggotaUidsBaru.add(currentUid);
    }

    final wNow = DateTime.now();
    final notif = NotifikasiItem(
      id: 'n_${wNow.millisecondsSinceEpoch}',
      judul: 'Anggota Baru Bergabung',
      pesan: '$namaUser telah bergabung ke grup',
      waktu: 'Baru saja',
      kelompokWaktu: 'Hari ini',
      tipe: TipeNotifikasi.anggotaBaru,
      createdAt: wNow,
      pengirimUid: currentUid,
    );

    final grupTerupdate = ditemukan.copyWith(
      anggota: daftarAnggotaBaru,
      anggotaUids: anggotaUidsBaru.toList(),
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
      firestoreService.simpanNotifikasiSubkoleksi(
        grupId: grupTerupdate.id,
        notifikasi: notif,
      ).catchError((_) {});
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
    _listenNotifikasiGrup(grupId);
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
    final wNow = DateTime.now();
    final notif = NotifikasiItem(
      id: 'n_${wNow.millisecondsSinceEpoch}',
      judul: 'Anggota Baru Ditambahkan',
      pesan: '${nama.trim()} telah bergabung ke grup',
      waktu: 'Baru saja',
      kelompokWaktu: 'Hari ini',
      tipe: TipeNotifikasi.anggotaBaru,
      createdAt: wNow,
      pengirimUid: currentUserUid,
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
    if (!isBendahara(g)) return;
    if (nominal <= 0) return;

    final ket = (keterangan != null && keterangan.trim().isNotEmpty)
        ? keterangan.trim()
        : 'Setoran kas dari $penyetorNama';

    final saldoBaru = g.saldo + nominal;
    final pemasukanBaru = g.pemasukan + nominal;

    final wNow = DateTime.now();
    final notif = NotifikasiItem(
      id: 'n_${wNow.millisecondsSinceEpoch}',
      judul: 'Setoran Kas Masuk',
      pesan: '$penyetorNama menyetor ${formatRupiah(nominal)} ($ket)',
      waktu: 'Baru saja',
      kelompokWaktu: 'Hari ini',
      tipe: TipeNotifikasi.konfirmasiLunas,
      nominal: nominal,
      createdAt: wNow,
      pengirimUid: currentUserUid,
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

  bool tambahTagihan({
    required String judul,
    required String sumberDana,
    required List<ItemBelanja> items,
    required List<String> idAnggotaDitagih,
    String? penerimaIdOverride,
    bool pakaiPajak = false,
    double pajakPersen = 10,
    int diskon = 0,
    int biayaLayanan = 0,
    DateTime? jatuhTempo,
  }) {
    final g = grupAktif;
    if (items.isEmpty || items.any((item) => item.harga < 0)) {
      throw ArgumentError('Item pengeluaran tidak valid');
    }
    final subtotal = items.fold<int>(0, (sum, item) => sum + item.harga);
    final rincian = RincianTagihan.hitung(
      subtotal: subtotal,
      pajakPersen: pakaiPajak ? pajakPersen : 0,
      diskon: diskon,
      biayaLayanan: biayaLayanan,
    );
    final pajak = rincian.pajak;
    final total = rincian.total;
    if (total <= 0) {
      throw ArgumentError('Total pengeluaran harus lebih dari nol');
    }

    // Cegah saldo kas minus jika pengeluaran dibebankan ke Kas grup
    if (sumberDana == 'Kas grup' && total > g.saldo) {
      return false;
    }

    final targetIds = (idAnggotaDitagih.isEmpty
        ? g.anggota.map((e) => e.id)
        : idAnggotaDitagih).toSet().toList();
    final anggotaIds = g.anggota.map((a) => a.id).toSet();
    if (targetIds.isEmpty || targetIds.any((id) => !anggotaIds.contains(id))) {
      throw ArgumentError('Pilih anggota grup yang valid untuk pembagian');
    }
    final porsi = total ~/ targetIds.length;

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

    final porsiAnggota = bagiRataTagihan(
      total,
      targetIds,
      penanggungSisaId: sumberDana == 'Dana pribadi' ? penerima.id : null,
    );

    final isMe = penerima.nama.toLowerCase() == currentUserNama.toLowerCase();
    String bank = penerima.bank;
    String rek = penerima.noRekening;

    if (isMe) {
      if (profil.bank.isNotEmpty) bank = profil.bank;
      if (profil.noRekening.isNotEmpty) rek = profil.noRekening;
    } else if (penerima.nama.toLowerCase() == g.bendahara.toLowerCase()) {
      if (bank.isEmpty && currentUserNama.toLowerCase() == g.bendahara.toLowerCase() && profil.bank.isNotEmpty) {
        bank = profil.bank;
        rek = profil.noRekening;
      }
    }

    final tagihanBaru = TagihanKas(
      id: 't_${DateTime.now().millisecondsSinceEpoch}',
      judul: judul.trim().isEmpty ? 'Pengeluaran Baru' : judul.trim(),
      tanggal: _tanggalSekarang(),
      jatuhTempo: jatuhTempo,
      sumberDana: sumberDana,
      items: List<ItemBelanja>.from(items),
      subtotal: subtotal,
      pajakPersen: rincian.pajakPersen,
      diskon: rincian.diskon,
      biayaLayanan: rincian.biayaLayanan,
      pajak: pajak,
      total: total,
      porsiPerOrang: porsi,
      porsiAnggota: porsiAnggota,
      penerimaId: penerima.id,
      namaPenerima: penerima.nama,
      bankPenerima: bank,
      rekPenerima: rek,
      anggotaDitagihIds: List<String>.from(targetIds),
    );

    final anggotaTerupdate = g.anggota.map((anggota) {
      if (targetIds.contains(anggota.id)) {
        if (sumberDana == 'Dana pribadi' && anggota.id == penerima.id) {
          // Yang nalangin sudah bayar porsi pengeluarannya sendiri di awal
          return anggota;
        }
        final bagian = porsiAnggota[anggota.id] ?? 0;
        if (bagian == 0) return anggota;
        return anggota.copyWith(
          tagihan: anggota.tagihan + bagian,
          status: StatusBayar.belum,
        );
      }
      return anggota;
    }).toList();

    final kurangiKas = sumberDana == 'Kas grup';
    final tambahPengeluaran = kurangiKas || g.tipeGrup == 'patungan';

    final wNow = DateTime.now();
    final notifTagihan = NotifikasiItem(
      id: 'n_${wNow.millisecondsSinceEpoch}',
      judul: 'Tagihan Baru Dibuat',
      pesan: 'Tagihan "${tagihanBaru.judul}" (${formatRupiah(total)}) dibagi ke ${targetIds.length} orang',
      waktu: 'Baru saja',
      kelompokWaktu: 'Hari ini',
      tipe: TipeNotifikasi.tagihanBaru,
      nominal: total,
      createdAt: wNow,
      pengirimUid: currentUserUid,
    );

    _updateGrupAktif(
      g.copyWith(
        saldo: kurangiKas ? g.saldo - total : g.saldo,
        pengeluaran: tambahPengeluaran ? g.pengeluaran + total : g.pengeluaran,
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
    return true;
  }

  // ==================== UPDATE ====================

  void ajukanPembayaran({
    required String anggotaId,
    required String namaFileBukti,
    required String buktiPath,
    String? judulTagihan,
    int? nominal,
    String? penerimaId,
    String? namaPenerima,
    String? sumberDana,
  }) {
    final g = grupAktif;
    final target = g.anggota.firstWhere((a) => a.id == anggotaId);
    final judulFinal = judulTagihan ??
        (g.daftarTagihan.isNotEmpty ? g.daftarTagihan.first.judul : 'Iuran Kas');
    final nominalFinal =
        nominal ?? (target.tagihan > 0 ? target.tagihan : 0);

    // Cari tagihan terkait untuk mengetahui siapa penerima transfer yang berhak verifikasi
    String finalPenerimaId = penerimaId ?? '';
    String finalNamaPenerima = namaPenerima ?? '';
    String finalSumberDana = sumberDana ?? '';
    if (finalPenerimaId.isEmpty || finalSumberDana.isEmpty) {
      for (final t in g.daftarTagihan) {
        if (t.judul.toLowerCase() == judulFinal.toLowerCase() || t.porsiUntuk(anggotaId) == nominalFinal) {
          if (finalPenerimaId.isEmpty) {
            finalPenerimaId = t.penerimaId;
            finalNamaPenerima = t.namaPenerima;
          }
          if (finalSumberDana.isEmpty) {
            finalSumberDana = t.sumberDana;
          }
          break;
        }
      }
      if (finalPenerimaId.isEmpty) {
        finalPenerimaId = g.bendaharaUid ?? '';
        finalNamaPenerima = g.bendahara;
      }
      if (finalSumberDana.isEmpty) {
        finalSumberDana = 'Kas grup';
      }
    }

    final konfirmasiBaru = KonfirmasiItem(
      id: 'k_${DateTime.now().millisecondsSinceEpoch}',
      anggotaId: target.id,
      namaAnggota: target.nama,
      judulTagihan: judulFinal,
      nominal: nominalFinal,
      namaFileBukti: namaFileBukti,
      buktiPath: buktiPath,
      waktuUnggah: _waktuSekarangLengkap(),
      penerimaId: finalPenerimaId,
      namaPenerima: finalNamaPenerima,
      sumberDana: finalSumberDana,
    );

    final anggotaTerupdate = g.anggota.map((a) {
      if (a.id == anggotaId) {
        return a.copyWith(status: StatusBayar.menunggu);
      }
      return a;
    }).toList();

    // Hanya timpa bukti jika untuk anggota dan judul tagihan yang sama (Poin 6)
    final konfirmasiBersih = g.daftarKonfirmasi
        .where((k) => !(k.anggotaId == anggotaId &&
            k.judulTagihan.toLowerCase() == judulFinal.toLowerCase()))
        .toList();

    final wNow = DateTime.now();
    final notifBukti = NotifikasiItem(
      id: 'n_${wNow.millisecondsSinceEpoch}',
      judul: 'Bukti Pembayaran Diunggah',
      pesan: '${target.nama} mengunggah bukti bayar "$judulFinal" — ${formatRupiah(nominalFinal)}',
      waktu: 'Baru saja',
      kelompokWaktu: 'Hari ini',
      tipe: TipeNotifikasi.buktiPembayaran,
      nominal: nominalFinal,
      terkaitId: konfirmasiBaru.id,
      createdAt: wNow,
      pengirimUid: currentUserUid,
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

    final sisaKonfirmasi =
        g.daftarKonfirmasi.where((k) => k.id != konfirmasiId).toList();

    // Kurangi tagihan sebesar nominal pembayaran yang disetujui (Poin 6)
    final anggotaTerupdate = g.anggota.map((a) {
      if (a.id == item.anggotaId) {
        final sisa = diterima ? max(0, a.tagihan - item.nominal) : a.tagihan;
        final adaKonfirmasiLain = sisaKonfirmasi.any((k) => k.anggotaId == a.id);
        final statusBaru = sisa == 0
            ? StatusBayar.lunas
            : (adaKonfirmasiLain ? StatusBayar.menunggu : StatusBayar.belum);
        return a.copyWith(
          status: statusBaru,
          tagihan: sisa,
        );
      }
      return a;
    }).toList();

    final riwayatBaru = RiwayatPembayaranItem(
      id: 'rp_${DateTime.now().millisecondsSinceEpoch}',
      namaAnggota: item.namaAnggota,
      judulTagihan: item.judulTagihan,
      nominal: item.nominal,
      waktu: _waktuSekarangLengkap(),
      status: diterima ? 'Lunas' : 'Ditolak',
      buktiPath: item.buktiPath,
    );

    final wNow = DateTime.now();
    final notifVerif = NotifikasiItem(
      id: 'n_${wNow.millisecondsSinceEpoch}',
      judul: diterima ? 'Pembayaran Dikonfirmasi' : 'Pembayaran Ditolak',
      pesan: diterima
          ? 'Pembayaran ${item.namaAnggota} untuk "${item.judulTagihan}" telah lunas (${formatRupiah(item.nominal)})'
          : 'Bukti pembayaran ${item.namaAnggota} untuk "${item.judulTagihan}" ditolak',
      waktu: 'Baru saja',
      kelompokWaktu: 'Hari ini',
      tipe: diterima ? TipeNotifikasi.konfirmasiLunas : TipeNotifikasi.konfirmasiTolak,
      nominal: item.nominal,
      createdAt: wNow,
      pengirimUid: currentUserUid,
    );

    final masukKas = item.sumberDana == null || item.sumberDana == 'Kas grup';

    _updateGrupAktif(
      g.copyWith(
        saldo: (diterima && masukKas) ? g.saldo + item.nominal : g.saldo,
        pemasukan: (diterima && masukKas) ? g.pemasukan + item.nominal : g.pemasukan,
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

  // ==================== DELETE / BATALKAN TRANSAKSI ====================

  /// Batalkan transaksi pengeluaran khusus bendahara dengan alasan pembatalan (Poin 3)
  bool batalkanTagihan(String tagihanId, {required String alasan}) {
    final g = grupAktif;
    if (!isBendahara(g)) return false;
    final alasanBersih = alasan.trim();
    if (alasanBersih.isEmpty) return false;

    final targetIndex = g.daftarTagihan.indexWhere((t) => t.id == tagihanId);
    if (targetIndex == -1) return false;
    final target = g.daftarTagihan[targetIndex];
    final kembalikanKas = target.sumberDana == 'Kas grup';
    final kurangiPengeluaran = kembalikanKas || g.tipeGrup == 'patungan';

    // Kurangi tagihan dari anggota yang memang ikut ditagih (Poin 7)
    final anggotaTerupdate = g.anggota.map((a) {
      final isAnggotaDitagih = target.porsiAnggota.isNotEmpty
          ? target.porsiAnggota.containsKey(a.id)
          : (target.anggotaDitagihIds.isEmpty ||
              target.anggotaDitagihIds.contains(a.id));

      if (!isAnggotaDitagih || target.porsiUntuk(a.id) <= 0) {
        return a;
      }

      if (target.sumberDana == 'Dana pribadi' && a.id == target.penerimaId) {
        return a;
      }
      final sisa = max(0, a.tagihan - target.porsiUntuk(a.id));
      final statusBaru = sisa == 0
          ? StatusBayar.tidakAdaTagihan
          : (a.status == StatusBayar.lunas ? StatusBayar.lunas : StatusBayar.belum);
      return a.copyWith(
        tagihan: sisa,
        status: statusBaru,
      );
    }).toList();

    // Hapus juga konfirmasi tertunda yang terkait dengan tagihan ini
    final konfirmasiSisa = g.daftarKonfirmasi
        .where((k) => k.judulTagihan.toLowerCase() != target.judul.toLowerCase())
        .toList();

    // Catat ke Audit Trail riwayat transaksi dengan status Dibatalkan (Poin 3)
    final namaPembatal = currentUserNama.isNotEmpty ? currentUserNama : g.bendahara;
    final riwayatBatal = RiwayatPembayaranItem(
      id: 'rb_${DateTime.now().millisecondsSinceEpoch}',
      namaAnggota: '$namaPembatal (Bendahara)',
      judulTagihan: '${target.judul} [Dibatalkan]',
      nominal: target.total,
      waktu: _waktuSekarangLengkap(),
      status: 'Dibatalkan',
      buktiPath: '',
      catatan: alasanBersih,
    );

    // Kirim notifikasi audit trail ke grup
    final notifBatal = NotifikasiItem(
      id: 'n_${DateTime.now().millisecondsSinceEpoch}',
      judul: 'Transaksi Dibatalkan',
      pesan: 'Pengeluaran "${target.judul}" (${formatRupiah(target.total)}) dibatalkan oleh $namaPembatal. Alasan: $alasanBersih',
      waktu: 'Baru saja',
      kelompokWaktu: 'Hari ini',
      tipe: TipeNotifikasi.konfirmasiTolak,
      nominal: target.total,
      createdAt: DateTime.now(),
      pengirimUid: currentUserUid,
    );

    _updateGrupAktif(
      g.copyWith(
        saldo: kembalikanKas ? g.saldo + target.total : g.saldo,
        pengeluaran: kurangiPengeluaran ? max(0, g.pengeluaran - target.total) : g.pengeluaran,
        anggota: anggotaTerupdate,
        daftarTagihan: g.daftarTagihan.where((t) => t.id != tagihanId).toList(),
        daftarKonfirmasi: konfirmasiSisa,
        daftarRiwayatPembayaran: [riwayatBatal, ...g.daftarRiwayatPembayaran],
        daftarNotifikasi: [notifBatal, ...g.daftarNotifikasi],
      ),
    );

    return true;
  }

  void hapusTagihan(String tagihanId, {String alasan = 'Dihapus oleh bendahara'}) {
    batalkanTagihan(tagihanId, alasan: alasan);
  }

  /// Menyerahkan peran bendahara kepada anggota lain (Poin 11)
  bool gantiBendahara(String targetAnggotaId) {
    final g = grupAktif;
    if (!isBendahara(g)) return false;

    final target = g.anggota.firstWhere(
      (a) => a.id == targetAnggotaId,
      orElse: () => g.anggota.first,
    );

    final targetUid = target.uid ?? (target.id.startsWith('a_') ? null : target.id);
    final updated = g.copyWith(
      bendahara: target.nama,
      bendaharaUid: targetUid,
    );

    _updateGrupAktif(updated);
    return true;
  }

  bool hapusAnggota(String anggotaId, {bool paksa = false}) {
    final g = grupAktif;
    if (!isBendahara(g)) return false;

    // Bendahara tidak bisa mengeluarkan dirinya sendiri lewat aksi ini
    final me = currentAnggota;
    if (me != null && me.id == anggotaId) return false;

    // Cek tunggakan sebelum mengeluarkan anggota (Poin 28)
    AnggotaKas? target;
    for (final a in g.anggota) {
      if (a.id == anggotaId) {
        target = a;
        break;
      }
    }
    if (target != null && target.tagihan > 0 && !paksa) {
      return false; // Ditolak: masih ada tunggakan dan bukan aksi paksa
    }

    // Step 4.2 (Poin 29 & 30): Blacklist & pencabutan akses anggota
    final targetUid = target?.uid ??
        (target != null && !target.id.startsWith('a_') ? target.id : '');
    final newBlacklist = Set<String>.from(g.blacklistUids);
    final newAnggotaUids = Set<String>.from(g.anggotaUids);

    if (targetUid.isNotEmpty) {
      newBlacklist.add(targetUid);
      newAnggotaUids.remove(targetUid);
    }

    final wNow = DateTime.now();
    final notifDikeluarkan = NotifikasiItem(
      id: 'n_${wNow.millisecondsSinceEpoch}',
      judul: 'Anggota Dikeluarkan',
      pesan:
          '${target?.nama ?? "Seorang anggota"} telah dikeluarkan dari grup ${g.namaGrup}',
      waktu: 'Baru saja',
      kelompokWaktu: 'Hari ini',
      tipe: TipeNotifikasi.konfirmasiTolak,
      createdAt: wNow,
      pengirimUid: currentUserUid,
    );

    _updateGrupAktif(
      g.copyWith(
        anggota: g.anggota.where((a) => a.id != anggotaId).toList(),
        anggotaUids: newAnggotaUids.toList(),
        blacklistUids: newBlacklist.toList(),
        daftarKonfirmasi:
            g.daftarKonfirmasi.where((k) => k.anggotaId != anggotaId).toList(),
        daftarNotifikasi: [notifDikeluarkan, ...g.daftarNotifikasi],
      ),
    );
    return true;
  }

  bool editNamaGrup(String grupId, String namaBaru) {
    final gIndex = value.daftarGrup.indexWhere((x) => x.id == grupId);
    if (gIndex < 0) return false;
    final g = value.daftarGrup[gIndex];
    if (!isBendahara(g)) return false;

    final listBaru = value.daftarGrup.map((item) {
      if (item.id == grupId) {
        final updated = item.copyWith(namaGrup: namaBaru.trim());
        firestoreService.simpanGrup(updated).catchError((_) {});
        return updated;
      }
      return item;
    }).toList();
    value = KasRootState(aktifGrupId: value.aktifGrupId, daftarGrup: listBaru);
    return true;
  }

  bool hapusGrup(String grupId) {
    final gIndex = value.daftarGrup.indexWhere((x) => x.id == grupId);
    if (gIndex < 0) return false;
    final g = value.daftarGrup[gIndex];
    if (!isBendahara(g)) return false;

    if (value.daftarGrup.length <= 1) {
      return false;
    }
    final sisaGrup = value.daftarGrup.where((item) => item.id != grupId).toList();
    final newAktifId =
        value.aktifGrupId == grupId ? sisaGrup.first.id : value.aktifGrupId;
    value = KasRootState(aktifGrupId: newAktifId, daftarGrup: sisaGrup);
    firestoreService.hapusGrup(grupId).catchError((_) {});
    return true;
  }

  Future<void> keluarDariGrup(String grupId) async {
    final myUid = currentUserUid;
    final myNama = currentUserNama.toLowerCase();
    final myWa = _formatNomorWa(profilNotifier.value.noWa);

    final gIndex = value.daftarGrup.indexWhere((x) => x.id == grupId);
    if (gIndex >= 0) {
      final g = value.daftarGrup[gIndex];
      // Bendahara tidak boleh keluar sebelum menyerahkan peran bendahara ke anggota lain (Poin 11 & 33)
      if (isBendahara(g) && g.anggota.length > 1) {
        throw Exception('Bendahara tidak boleh keluar sebelum menyerahkan peran bendahara ke anggota lain.');
      }
      final sisaAnggota = g.anggota.where((a) {
        if (myUid.isNotEmpty && ((a.uid != null && a.uid == myUid) || a.id == myUid)) return false;
        if (myNama.isNotEmpty && a.nama.toLowerCase() == myNama) return false;
        if (myWa.isNotEmpty && a.noWa.isNotEmpty && _formatNomorWa(a.noWa) == myWa) return false;
        return true;
      }).toList();

      final sisaUids = g.anggotaUids.where((u) => u != myUid).toList();
      final updatedGrup = g.copyWith(
        anggota: sisaAnggota,
        anggotaUids: sisaUids,
      );

      // Sinkronkan ke Firestore
      if (sisaAnggota.isEmpty) {
        await firestoreService.hapusGrup(grupId).catchError((_) {});
      } else {
        await firestoreService.simpanGrup(updatedGrup).catchError((_) {});
      }

      // Hapus dari state lokal user saat ini
      final sisaGrup = value.daftarGrup.where((x) => x.id != grupId).toList();
      final newAktifId = sisaGrup.isNotEmpty ? sisaGrup.first.id : '';
      value = KasRootState(aktifGrupId: newAktifId, daftarGrup: sisaGrup);
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
    // Cegah pengiriman pengingat tagihan ke diri sendiri
    if (isCurrentUser(anggota)) {
      debugPrint('Tidak dapat mengirim pengingat tagihan ke diri sendiri');
      return false;
    }
    final g = grupAktif;
    final profil = profilNotifier.value;
    String bank = profil.bank.isEmpty ? 'Bank' : profil.bank;
    String rekening =
        profil.noRekening.isEmpty ? '-' : profil.noRekening;
    String penerima = profil.nama.isEmpty ? g.bendahara : profil.nama;

    // Cari seluruh rincian tagihan tertunggak milik anggota terkait (Poin 14)
    final tagihanTerkait = g.daftarTagihan.where((t) {
      return t.anggotaDitagihIds.contains(anggota.id) ||
          t.porsiAnggota.containsKey(anggota.id) ||
          t.porsiAnggota.containsKey(anggota.nama) ||
          (anggota.uid != null && t.anggotaDitagihIds.contains(anggota.uid));
    }).toList();

    // Jika tagihan adalah talangan yang memiliki info rekening tujuan penerima
    if (tagihanTerkait.isNotEmpty) {
      final tPertama = tagihanTerkait.first;
      if (tPertama.rekPenerima.isNotEmpty && tPertama.rekPenerima != '-') {
        bank = tPertama.bankPenerima.isNotEmpty ? tPertama.bankPenerima : bank;
        rekening = tPertama.rekPenerima;
        penerima = tPertama.namaPenerima.isNotEmpty ? tPertama.namaPenerima : penerima;
      }
    }

    final totalTunggakanText = formatRupiah(anggota.tagihan);
    final sbRincian = StringBuffer();

    if (tagihanTerkait.isNotEmpty) {
      for (final t in tagihanTerkait) {
        final porsi = t.porsiAnggota[anggota.id] ??
            t.porsiAnggota[anggota.nama] ??
            (anggota.uid != null ? t.porsiAnggota[anggota.uid] : null) ??
            t.porsiPerOrang;
        sbRincian.writeln('• ${t.judul}: ${formatRupiah(porsi)}');
      }
    } else {
      sbRincian.writeln('• Iuran Kas: $totalTunggakanText');
    }

    final pesan = 'Halo ${anggota.nama},\n\n'
        'Pengingat tagihan *${g.namaGrup}*:\n'
        '${sbRincian.toString().trimRight()}\n'
        'Total Tagihan: *$totalTunggakanText*\n\n'
        'Silakan transfer ke:\n'
        '$bank $rekening a.n. $penerima\n\n'
        'Jika sudah transfer, mohon unggah bukti bayar di aplikasi *KasMate*. Terima kasih!';

    final nomorTujuan = _formatNomorWa(anggota.noWa);
    final url = Uri.parse(
      'https://wa.me/$nomorTujuan?text=${Uri.encodeComponent(pesan)}',
    );
    final judulSummary = tagihanTerkait.isNotEmpty
        ? tagihanTerkait.map((t) => t.judul).join(', ')
        : 'Iuran Kas';
    tambahNotifikasi(
      judul: 'Pengingat WhatsApp Terkirim',
      pesan: 'Pengingat tagihan "$judulSummary" dikirim ke ${anggota.nama}',
      tipe: TipeNotifikasi.pengingatWa,
      nominal: anggota.tagihan,
    );
    return _bukaUrlWhatsApp(url);
  }

  Future<bool> bagikanUndanganGrupWhatsApp([GrupKas? targetGrup]) async {
    final g = targetGrup ?? grupAktif;
    final tipeGrupLabel = g.tipeGrup == 'kasResmi' ? 'Kas Resmi' : 'Patungan';
    final pesan = 'Halo teman-teman!\n'
        'Yuk gabung ke grup *${g.namaGrup}* ($tipeGrupLabel) di aplikasi *KasMate*.\n\n'
        'Kode Undangan: *${g.kodeUndangan}*\n\n'
        'Cara bergabung:\n'
        '1. Buka aplikasi KasMate\n'
        '2. Pilih menu *Gabung Grup*\n'
        '3. Masukkan kode undangan: *${g.kodeUndangan}* atau scan QR grup.';

    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(pesan)}');
    return _bukaUrlWhatsApp(url);
  }

  // ==================== EKSPOR LAPORAN ====================

  /// Escape nilai CSV: bungkus dalam tanda kutip ganda jika mengandung koma, kutip, atau newline.
  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Format nomor WA agar tidak dikonversi ke notasi ilmiah oleh Excel (Poin 39).
  static String _csvNoWa(String noWa) {
    final bersih = noWa.trim();
    if (bersih.isEmpty) return '';
    // ="'08123456789" mencegah Excel menginterpretasi sebagai angka
    return '="\'$bersih"';
  }

  /// Format nominal rupiah sebagai teks agar tidak menjadi angka biasa di Excel.
  static String _csvNominal(int nominal) => 'Rp $nominal';

  String generateLaporanCsv() {
    final g = grupAktif;
    final sb = StringBuffer();

    // Header laporan
    sb.writeln('LAPORAN KEUANGAN KASMATE');
    sb.writeln('Nama Grup,${_csvEscape(g.namaGrup)}');
    sb.writeln('Kode Undangan,${g.kodeUndangan}');
    sb.writeln('Bendahara,${_csvEscape(g.bendahara)}');
    sb.writeln('Saldo Kas,${_csvNominal(g.saldo)}');
    sb.writeln('Total Pemasukan,${_csvNominal(g.pemasukan)}');
    sb.writeln('Total Pengeluaran,${_csvNominal(g.pengeluaran)}');
    sb.writeln('');

    // Status anggota
    sb.writeln('STATUS ANGGOTA');
    sb.writeln('Nama Anggota;No WhatsApp;Bank;No Rekening;Sisa Tagihan;Status');
    for (final a in g.anggota) {
      final st = a.status == StatusBayar.lunas
          ? 'Lunas'
          : a.status == StatusBayar.menunggu
              ? 'Menunggu Konfirmasi'
              : a.status == StatusBayar.tidakAdaTagihan
                  ? 'Tidak Ada Tagihan'
                  : 'Belum Bayar';
      final noWaCsv = _csvNoWa(a.noWa);
      sb.writeln(
        '${_csvEscape(a.nama)};$noWaCsv;${_csvEscape(a.bank)};${_csvEscape(a.noRekening)};${_csvNominal(a.tagihan)};$st',
      );
    }
    sb.writeln('');

    // Riwayat pengeluaran / tagihan
    sb.writeln('RIWAYAT PENGELUARAN');
    sb.writeln('Judul;Tanggal;Sumber Dana;Total;Penerima Transfer');
    for (final t in g.daftarTagihan) {
      sb.writeln(
        '${_csvEscape(t.judul)};${_csvEscape(t.tanggal)};${_csvEscape(t.sumberDana)};${_csvNominal(t.total)};${_csvEscape(t.namaPenerima)}',
      );
    }
    sb.writeln('');

    // Riwayat pembayaran
    sb.writeln('RIWAYAT PEMBAYARAN');
    sb.writeln('Nama Pembayar;Tagihan;Nominal;Waktu;Status;Catatan');
    for (final r in g.daftarRiwayatPembayaran) {
      final isAktif = g.anggota.any(
        (a) => a.nama.toLowerCase() == r.namaAnggota.toLowerCase(),
      );
      final namaLabel = isAktif ? r.namaAnggota : '${r.namaAnggota} (Keluar)';
      sb.writeln(
        '${_csvEscape(namaLabel)};${_csvEscape(r.judulTagihan)};${_csvNominal(r.nominal)};${_csvEscape(r.waktu)};${r.status};${_csvEscape(r.catatan ?? '')}',
      );
    }
    return sb.toString();
  }
}

final KasStore kasStore = KasStore();
