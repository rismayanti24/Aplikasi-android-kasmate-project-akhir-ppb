import 'dart:convert';

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/kas_store.dart';

import '../models/pengguna.dart';

class FirestoreService {
  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static final FirestoreService _instance = FirestoreService._internal();

  factory FirestoreService() => _instance;

  FirestoreService._internal();

  // Koleksi References
  CollectionReference? get _usersCol {
    try {
      return _db?.collection('users');
    } catch (_) {
      return null;
    }
  }

  CollectionReference? get _groupsCol {
    try {
      return _db?.collection('groups');
    } catch (_) {
      return null;
    }
  }

  // ==================== USER PROFIL ====================

  /// Simpan atau perbarui data profil pengguna
  Future<void> simpanProfilUser(Pengguna pengguna) async {
    try {
      final col = _usersCol;
      if (col == null) return;
      await col.doc(pengguna.id).set({
        'nama': pengguna.nama,
        'noWa': pengguna.noWa,
        'bank': pengguna.bank,
        'noRekening': pengguna.noRekening,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error simpanProfilUser: $e');
    }
  }

  /// Hapus data profil pengguna dari Firestore
  Future<void> hapusProfilUser(String uid) async {
    try {
      final col = _usersCol;
      if (col == null) return;
      await col.doc(uid).delete();
    } catch (e) {
      debugPrint('Error hapusProfilUser: $e');
    }
  }

  /// Ambil profil pengguna sekali (Future)
  Future<Pengguna?> getProfilUser(String uid) async {
    try {
      final col = _usersCol;
      if (col == null) return null;
      final doc = await col.doc(uid).get();

      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data() as Map<String, dynamic>;

      return Pengguna(
        id: uid,
        nama: data['nama'] ?? '',
        noWa: data['noWa'] ?? '',
        bank: data['bank'] ?? '',
        noRekening: data['noRekening'] ?? '',
      );
    } catch (e) {
      debugPrint('Error getProfilUser: $e');
      return null;
    }
  }

  /// Stream profil pengguna realtime
  Stream<Pengguna?> streamProfilUser(String uid) {
    final col = _usersCol;
    if (col == null) return const Stream.empty();
    return col.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data() as Map<String, dynamic>;

      return Pengguna(
        id: uid,
        nama: data['nama'] ?? '',
        noWa: data['noWa'] ?? '',
        bank: data['bank'] ?? '',
        noRekening: data['noRekening'] ?? '',
      );
    });
  }

  // ==================== GRUP KAS ====================

  /// Stream semua grup kas realtime
  Stream<List<GrupKas>> streamDaftarGrup() {
    final col = _groupsCol;
    if (col == null) return const Stream.empty();
    return col.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return _mapDocToGrupKas(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Ambil semua grup kas sekali (Future)
  Future<List<GrupKas>> getDaftarGrupSekali() async {
    try {
      final col = _groupsCol;
      if (col == null) return [];
      final snapshot = await col.get();
      return snapshot.docs.map((doc) {
        return _mapDocToGrupKas(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Error getDaftarGrupSekali: $e');
      return [];
    }
  }

  /// Simpan grup kas (buat baru atau perbarui seluruh grup)
  Future<void> simpanGrup(GrupKas grup) async {
    try {
      final col = _groupsCol;
      if (col == null) return;
      await col
          .doc(grup.id)
          .set(_mapGrupKasToMap(grup), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error simpanGrup: $e');
    }
  }

  /// Hapus grup kas
  Future<void> hapusGrup(String grupId) async {
    try {
      final col = _groupsCol;
      if (col == null) return;
      await col.doc(grupId).delete();
    } catch (e) {
      debugPrint('Error hapusGrup: $e');
    }
  }

  /// Mencari grup di Cloud Firestore berdasarkan kode undangan
  Future<GrupKas?> cariGrupByKodeFirestore(String kode) async {
    final target = kode.trim().toUpperCase();
    if (target.isEmpty) return null;

    try {
      final col = _groupsCol;
      if (col == null) return null;
      final query = await col
          .where('kodeUndangan', isEqualTo: target)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final doc = query.docs.first;
      return _mapDocToGrupKas(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error cariGrupByKodeFirestore: $e');
      return null;
    }
  }

  // ==================== UTILS FOTO BUKTI (BASE64 & SUBKOLEKSI) ====================

  // Cache in-memory foto bukti agar tidak download berulang kali
  final Map<String, String> _buktiCache = {};

  /// Mengambil cache foto bukti jika ada
  String? getBuktiFromCache(String grupId, String buktiId) =>
      _buktiCache['${grupId}_$buktiId'];

  /// Menyimpan foto bukti ke cache lokal
  void cacheBuktiLokal(String grupId, String buktiId, String base64Data) {
    if (base64Data.isNotEmpty) {
      _buktiCache['${grupId}_$buktiId'] = base64Data;
    }
  }

  /// Simpan foto bukti pembayaran ke subkoleksi `bukti_transfer` di bawah grup terkait (Poin 2 & 49)
  Future<void> simpanBuktiTransfer({
    required String grupId,
    required String buktiId,
    required String base64Data,
    required String namaFile,
  }) async {
    if (base64Data.isEmpty) return;
    try {
      cacheBuktiLokal(grupId, buktiId, base64Data);
      final col = _groupsCol;
      if (col == null) return;
      await col
          .doc(grupId)
          .collection('bukti_transfer')
          .doc(buktiId)
          .set({
        'id': buktiId,
        'base64': base64Data,
        'namaFile': namaFile,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error simpanBuktiTransfer: $e');
    }
  }

  /// Ambil data foto bukti transfer dari subkoleksi (Poin 2 & 49)
  Future<String?> getBuktiTransfer({
    required String grupId,
    required String buktiId,
  }) async {
    final cached = getBuktiFromCache(grupId, buktiId);
    if (cached != null) return cached;

    try {
      final col = _groupsCol;
      if (col == null) return null;
      final doc = await col
          .doc(grupId)
          .collection('bukti_transfer')
          .doc(buktiId)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final b64 = data['base64'] as String?;
        if (b64 != null && b64.isNotEmpty) {
          cacheBuktiLokal(grupId, buktiId, b64);
          return b64;
        }
      }
    } catch (e) {
      debugPrint('Error getBuktiTransfer: $e');
    }
    return null;
  }

  /// Simpan notifikasi ke subkoleksi `notifikasi` di bawah grup terkait (Poin 46)
  Future<void> simpanNotifikasiSubkoleksi({
    required String grupId,
    required NotifikasiItem notifikasi,
  }) async {
    if (grupId.isEmpty || notifikasi.id.isEmpty) return;
    try {
      final col = _groupsCol;
      if (col == null) return;
      final ms = notifikasi.createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch;
      await col
          .doc(grupId)
          .collection('notifikasi')
          .doc(notifikasi.id)
          .set({
        'id': notifikasi.id,
        'judul': notifikasi.judul,
        'pesan': notifikasi.pesan,
        'waktu': notifikasi.waktu,
        'kelompokWaktu': notifikasi.kelompokWaktu,
        'tipe': notifikasi.tipe.name,
        'isDibaca': notifikasi.isDibaca,
        'nominal': notifikasi.nominal,
        'terkaitId': notifikasi.terkaitId,
        'timestamp': ms,
        'createdAt': FieldValue.serverTimestamp(),
        'pengirimUid': notifikasi.pengirimUid,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error simpanNotifikasiSubkoleksi: $e');
    }
  }

  /// Stream notifikasi realtime dari subkoleksi grup (Poin 46)
  Stream<List<NotifikasiItem>> streamNotifikasiGrup(String grupId) {
    if (grupId.isEmpty) return const Stream.empty();
    final col = _groupsCol;
    if (col == null) return const Stream.empty();
    return col
        .doc(grupId)
        .collection('notifikasi')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        final rawTipe = data['tipe'] as String? ?? 'tagihanBaru';
        final tipe = TipeNotifikasi.values.firstWhere(
          (t) => t.name == rawTipe,
          orElse: () => TipeNotifikasi.tagihanBaru,
        );
        DateTime? createdAt;
        final rawCreatedAt = data['createdAt'] ?? data['timestamp'];
        if (rawCreatedAt is Timestamp) {
          createdAt = rawCreatedAt.toDate();
        } else if (rawCreatedAt is int) {
          createdAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
        } else if (doc.id.startsWith('n_')) {
          final ms = int.tryParse(doc.id.substring(2));
          if (ms != null) createdAt = DateTime.fromMillisecondsSinceEpoch(ms);
        }
        return NotifikasiItem(
          id: doc.id,
          judul: data['judul'] ?? '',
          pesan: data['pesan'] ?? '',
          waktu: data['waktu'] ?? '',
          kelompokWaktu: data['kelompokWaktu'] ?? 'Hari ini',
          tipe: tipe,
          isDibaca: data['isDibaca'] ?? false,
          nominal: data['nominal'] as int?,
          terkaitId: data['terkaitId'] as String?,
          createdAt: createdAt,
          pengirimUid: data['pengirimUid'] as String?,
        );
      }).toList();

      list.sort((a, b) {
        final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Tandai notifikasi dibaca di subkoleksi (Poin 10)
  Future<void> tandaiNotifikasiDibacaSubkoleksi({
    required String grupId,
    required String notifId,
    required bool isDibaca,
  }) async {
    if (grupId.isEmpty || notifId.isEmpty) return;
    try {
      final col = _groupsCol;
      if (col == null) return;
      await col
          .doc(grupId)
          .collection('notifikasi')
          .doc(notifId)
          .set({'isDibaca': isDibaca}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error tandaiNotifikasiDibacaSubkoleksi: $e');
    }
  }

  /// Tandai semua notifikasi dibaca di subkoleksi
  Future<void> tandaiSemuaNotifikasiDibacaSubkoleksi(String grupId) async {
    if (grupId.isEmpty) return;
    try {
      final col = _groupsCol;
      if (col == null) return;
      final snap = await col.doc(grupId).collection('notifikasi').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isDibaca': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error tandaiSemuaNotifikasiDibacaSubkoleksi: $e');
    }
  }

  /// Mengubah foto lokal menjadi Base64 string agar bisa disimpan di Firestore tanpa Firebase Storage berbayar

  Future<String> fileToBase64(String filePath) async {
    if (filePath.isEmpty) return '';

    try {
      final file = File(filePath);

      if (await file.exists()) {
        final bytes = await file.readAsBytes();

        return base64Encode(bytes);
      }
    } catch (e) {
      debugPrint('Error fileToBase64: $e');
    }

    return '';
  }

  // ==================== MAPPERS ====================

  Map<String, dynamic> _mapGrupKasToMap(GrupKas g) {
    final uids = <String>{};
    if (g.bendaharaUid != null && g.bendaharaUid!.isNotEmpty) {
      uids.add(g.bendaharaUid!);
    }
    for (final a in g.anggota) {
      if (a.uid != null && a.uid!.isNotEmpty) {
        uids.add(a.uid!);
      } else if (a.id.isNotEmpty && !a.id.startsWith('a_')) {
        uids.add(a.id);
      }
    }
    for (final u in g.anggotaUids) {
      if (u.isNotEmpty && !g.blacklistUids.contains(u)) uids.add(u);
    }

    return {
      'namaGrup': g.namaGrup,
      'kodeUndangan': g.kodeUndangan,
      'tipeGrup': g.tipeGrup,
      'bendahara': g.bendahara,
      'bendaharaUid': g.bendaharaUid ?? '',
      'anggotaUids': uids.toList(),
      'blacklistUids': g.blacklistUids,
      'saldo': g.saldo,
      'pemasukan': g.pemasukan,
      'pengeluaran': g.pengeluaran,
      'anggota': g.anggota
          .map((a) => {
                'id': a.id,
                'uid': a.uid ?? (a.id.startsWith('a_') ? '' : a.id),
                'nama': a.nama,
                'noWa': a.noWa,
                'tagihan': a.tagihan,
                'status': a.status.name,
                'avatarColor': a.avatarColor.toARGB32(),
                'bank': a.bank,
                'noRekening': a.noRekening,
              })
          .toList(),
      'daftarTagihan': g.daftarTagihan
          .map((t) => {
                'id': t.id,
                'judul': t.judul,
                'tanggal': t.tanggal,
                'jatuhTempo': t.jatuhTempo?.millisecondsSinceEpoch,
                'sumberDana': t.sumberDana,
                'subtotal': t.subtotal,
                'pajakPersen': t.pajakPersen,
                'diskon': t.diskon,
                'biayaLayanan': t.biayaLayanan,
                'pajak': t.pajak,
                'total': t.total,
                'porsiPerOrang': t.porsiPerOrang,
                'porsiAnggota': t.porsiAnggota,
                'penerimaId': t.penerimaId,
                'namaPenerima': t.namaPenerima,
                'bankPenerima': t.bankPenerima,
                'rekPenerima': t.rekPenerima,
                'anggotaDitagihIds': t.anggotaDitagihIds,
                'items': t.items
                    .map((i) => {
                          'id': i.id,
                          'nama': i.nama,
                          'harga': i.harga,
                        })
                    .toList(),
              })
          .toList(),
      'daftarKonfirmasi': g.daftarKonfirmasi
          .map((k) => {
                'id': k.id,
                'anggotaId': k.anggotaId,
                'namaAnggota': k.namaAnggota,
                'judulTagihan': k.judulTagihan,
                'nominal': k.nominal,
                'namaFileBukti': k.namaFileBukti,
                'buktiPath': k.buktiPath,
                'waktuUnggah': k.waktuUnggah,
                'penerimaId': k.penerimaId ?? '',
                'namaPenerima': k.namaPenerima ?? '',
                'sumberDana': k.sumberDana ?? 'Kas grup',
              })
          .toList(),
      'daftarRiwayatPembayaran': g.daftarRiwayatPembayaran
          .map((r) => {
                'id': r.id,
                'namaAnggota': r.namaAnggota,
                'judulTagihan': r.judulTagihan,
                'nominal': r.nominal,
                'waktu': r.waktu,
                'status': r.status,
                'buktiPath': r.buktiPath,
                'catatan': r.catatan,
              })
          .toList(),
      'daftarNotifikasi': g.daftarNotifikasi
          .map((n) => {
                'id': n.id,
                'judul': n.judul,
                'pesan': n.pesan,
                'waktu': n.waktu,
                'kelompokWaktu': n.kelompokWaktu,
                'tipe': n.tipe.name,
                'isDibaca': n.isDibaca,
                'nominal': n.nominal,
                'terkaitId': n.terkaitId,
                'createdAt': n.createdAt?.millisecondsSinceEpoch,
                'pengirimUid': n.pengirimUid,
              })
          .toList(),
    };
  }

  GrupKas _mapDocToGrupKas(String id, Map<String, dynamic> data) {
    // Anggota
    final rawAnggota = (data['anggota'] as List<dynamic>?) ?? [];
    final anggotaList = rawAnggota.map((a) {
      final map = a as Map<String, dynamic>;
      final statusStr = map['status'] ?? 'tidakAdaTagihan';
      final status = StatusBayar.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => StatusBayar.tidakAdaTagihan,
      );

      final colorVal =
          map['avatarColor'] is int ? map['avatarColor'] as int : 0xFFDBEAFE;

      final uid = map['uid'] as String? ??
          (map['id'] != null && !map['id'].toString().startsWith('a_')
              ? map['id'].toString()
              : null);

      return AnggotaKas(
        id: map['id'] ?? '',
        uid: uid,
        nama: map['nama'] ?? '',
        noWa: map['noWa'] ?? '',
        tagihan: map['tagihan'] ?? 0,
        status: status,
        avatarColor: Color(colorVal),
        bank: map['bank'] ?? '',
        noRekening: map['noRekening'] ?? '',
      );
    }).toList();

    final rawUids = (data['anggotaUids'] as List<dynamic>?) ?? [];
    final anggotaUids = rawUids.map((e) => e.toString()).toList();
    final rawBlacklist = (data['blacklistUids'] as List<dynamic>?) ?? [];
    final blacklistUids = rawBlacklist.map((e) => e.toString()).toList();
    final bendaharaUid = data['bendaharaUid'] as String? ?? '';

    // Tagihan

    final rawTagihan = (data['daftarTagihan'] as List<dynamic>?) ?? [];

    final tagihanList = rawTagihan.map((t) {
      final map = t as Map<String, dynamic>;

      final rawItems = (map['items'] as List<dynamic>?) ?? [];

      final items = rawItems.map((i) {
        final imap = i as Map<String, dynamic>;

        return ItemBelanja(
          id: imap['id'] ?? '',
          nama: imap['nama'] ?? '',
          harga: imap['harga'] ?? 0,
        );
      }).toList();

      DateTime? jatuhTempo;
      final rawJatuhTempo = map['jatuhTempo'];
      if (rawJatuhTempo is Timestamp) {
        jatuhTempo = rawJatuhTempo.toDate();
      } else if (rawJatuhTempo is int) {
        jatuhTempo = DateTime.fromMillisecondsSinceEpoch(rawJatuhTempo);
      }

      return TagihanKas(
        id: map['id'] ?? '',
        judul: map['judul'] ?? '',
        tanggal: map['tanggal'] ?? '',
        jatuhTempo: jatuhTempo,
        sumberDana: map['sumberDana'] ?? 'Dana pribadi',
        items: items,
        subtotal: map['subtotal'] ?? 0,
        pajakPersen: (map['pajakPersen'] as num?)?.toDouble() ??
            ((map['pajak'] ?? 0) > 0 ? 10 : 0),
        diskon: map['diskon'] ?? 0,
        biayaLayanan: map['biayaLayanan'] ?? 0,
        pajak: map['pajak'] ?? 0,
        total: map['total'] ?? 0,
        porsiPerOrang: map['porsiPerOrang'] ?? 0,
        porsiAnggota: ((map['porsiAnggota'] as Map<String, dynamic>?) ?? {})
            .map((id, nominal) => MapEntry(id, (nominal as num).toInt())),
        penerimaId: map['penerimaId'] ?? '',
        namaPenerima: map['namaPenerima'] ?? '',
        bankPenerima: map['bankPenerima'] ?? '',
        rekPenerima: map['rekPenerima'] ?? '',
        anggotaDitagihIds: ((map['anggotaDitagihIds'] as List<dynamic>?) ?? [])
            .map((e) => e.toString())
            .toList(),
      );
    }).toList();

    // Konfirmasi

    final rawKonfirmasi = (data['daftarKonfirmasi'] as List<dynamic>?) ?? [];

    final konfirmasiList = rawKonfirmasi.map((k) {
      final map = k as Map<String, dynamic>;

      return KonfirmasiItem(
        id: map['id'] ?? '',
        anggotaId: map['anggotaId'] ?? '',
        namaAnggota: map['namaAnggota'] ?? '',
        judulTagihan: map['judulTagihan'] ?? '',
        nominal: map['nominal'] ?? 0,
        namaFileBukti: map['namaFileBukti'] ?? '',
        buktiPath: map['buktiPath'] ?? '',
        waktuUnggah: map['waktuUnggah'] ?? '',
        penerimaId: map['penerimaId'] as String?,
        namaPenerima: map['namaPenerima'] as String?,
        sumberDana: map['sumberDana'] as String?,
      );
    }).toList();

    // Riwayat

    final rawRiwayat =
        (data['daftarRiwayatPembayaran'] as List<dynamic>?) ?? [];

    final riwayatList = rawRiwayat.map((r) {
      final map = r as Map<String, dynamic>;

      return RiwayatPembayaranItem(
        id: map['id'] ?? '',
        namaAnggota: map['namaAnggota'] ?? '',
        judulTagihan: map['judulTagihan'] ?? '',
        nominal: map['nominal'] ?? 0,
        waktu: map['waktu'] ?? '',
        status: map['status'] ?? 'Lunas',
        buktiPath: map['buktiPath'] ?? '',
        catatan: map['catatan'] as String?,
      );
    }).toList();

    // Notifikasi

    final rawNotif = (data['daftarNotifikasi'] as List<dynamic>?) ?? [];

    final notifikasiList = rawNotif.map((n) {
      final map = n as Map<String, dynamic>;

      final tipeStr = map['tipe'] ?? 'tagihanBaru';

      final tipe = TipeNotifikasi.values.firstWhere(
        (t) => t.name == tipeStr,
        orElse: () => TipeNotifikasi.tagihanBaru,
      );

      DateTime? createdAt;
      final rawCreatedAt = map['createdAt'] ?? map['timestamp'];
      if (rawCreatedAt is Timestamp) {
        createdAt = rawCreatedAt.toDate();
      } else if (rawCreatedAt is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
      } else if (map['id'] is String && (map['id'] as String).startsWith('n_')) {
        final ms = int.tryParse((map['id'] as String).substring(2));
        if (ms != null) createdAt = DateTime.fromMillisecondsSinceEpoch(ms);
      }

      return NotifikasiItem(
        id: map['id'] ?? '',
        judul: map['judul'] ?? '',
        pesan: map['pesan'] ?? '',
        waktu: map['waktu'] ?? '',
        kelompokWaktu: map['kelompokWaktu'] ?? 'Hari ini',
        tipe: tipe,
        isDibaca: map['isDibaca'] ?? false,
        nominal: map['nominal'],
        terkaitId: map['terkaitId'],
        createdAt: createdAt,
        pengirimUid: map['pengirimUid'] as String?,
      );
    }).toList();

    return GrupKas(
      id: id,
      namaGrup: data['namaGrup'] ?? '',
      kodeUndangan: data['kodeUndangan'] ?? '',
      tipeGrup: data['tipeGrup'] ?? 'kasResmi',
      bendahara: data['bendahara'] ?? '',
      bendaharaUid: bendaharaUid.isNotEmpty ? bendaharaUid : null,
      anggotaUids: anggotaUids,
      blacklistUids: blacklistUids,
      saldo: data['saldo'] ?? 0,
      pemasukan: data['pemasukan'] ?? 0,
      pengeluaran: data['pengeluaran'] ?? 0,
      anggota: anggotaList,
      daftarTagihan: tagihanList,
      daftarKonfirmasi: konfirmasiList,
      daftarRiwayatPembayaran: riwayatList,
      daftarNotifikasi: notifikasiList,
    );
  }
}

// Instance global

final firestoreService = FirestoreService();
