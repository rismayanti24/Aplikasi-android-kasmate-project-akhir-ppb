import 'dart:convert';

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/kas_store.dart';

import '../models/pengguna.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final FirestoreService _instance = FirestoreService._internal();

  factory FirestoreService() => _instance;

  FirestoreService._internal();

  // Koleksi References

  CollectionReference get _usersCol => _db.collection('users');

  CollectionReference get _groupsCol => _db.collection('groups');

  // ==================== USER PROFIL ====================

  /// Simpan atau perbarui data profil pengguna

  Future<void> simpanProfilUser(Pengguna pengguna) async {
    try {
      await _usersCol.doc(pengguna.id).set({
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
      await _usersCol.doc(uid).delete();
    } catch (e) {
      debugPrint('Error hapusProfilUser: $e');
    }
  }

  /// Ambil profil pengguna sekali (Future)

  Future<Pengguna?> getProfilUser(String uid) async {
    try {
      final doc = await _usersCol.doc(uid).get();

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
    return _usersCol.doc(uid).snapshots().map((doc) {
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
    return _groupsCol.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return _mapDocToGrupKas(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Simpan grup kas (buat baru atau perbarui seluruh grup)

  Future<void> simpanGrup(GrupKas grup) async {
    try {
      await _groupsCol
          .doc(grup.id)
          .set(_mapGrupKasToMap(grup), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error simpanGrup: $e');

      rethrow;
    }
  }

  /// Hapus grup kas

  Future<void> hapusGrup(String grupId) async {
    try {
      await _groupsCol.doc(grupId).delete();
    } catch (e) {
      debugPrint('Error hapusGrup: $e');

      rethrow;
    }
  }

  /// Mencari grup di Cloud Firestore berdasarkan kode undangan

  Future<GrupKas?> cariGrupByKodeFirestore(String kode) async {
    final target = kode.trim().toUpperCase();

    if (target.isEmpty) return null;

    try {
      final query = await _groupsCol
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

  // ==================== UTILS FOTO BUKTI (BASE64) ====================

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
    return {
      'namaGrup': g.namaGrup,
      'kodeUndangan': g.kodeUndangan,
      'tipeGrup': g.tipeGrup,
      'bendahara': g.bendahara,
      'saldo': g.saldo,
      'pemasukan': g.pemasukan,
      'pengeluaran': g.pengeluaran,
      'anggota': g.anggota
          .map((a) => {
                'id': a.id,
                'nama': a.nama,
                'noWa': a.noWa,
                'tagihan': a.tagihan,
                'status': a.status.name,
                'avatarColor': a.avatarColor.toARGB32(),
              })
          .toList(),
      'daftarTagihan': g.daftarTagihan
          .map((t) => {
                'id': t.id,
                'judul': t.judul,
                'tanggal': t.tanggal,
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

      return AnggotaKas(
        id: map['id'] ?? '',
        nama: map['nama'] ?? '',
        noWa: map['noWa'] ?? '',
        tagihan: map['tagihan'] ?? 0,
        status: status,
        avatarColor: Color(colorVal),
      );
    }).toList();

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

      return TagihanKas(
        id: map['id'] ?? '',
        judul: map['judul'] ?? '',
        tanggal: map['tanggal'] ?? '',
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
      );
    }).toList();

    return GrupKas(
      id: id,
      namaGrup: data['namaGrup'] ?? '',
      kodeUndangan: data['kodeUndangan'] ?? '',
      tipeGrup: data['tipeGrup'] ?? 'kasResmi',
      bendahara: data['bendahara'] ?? '',
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
