import 'package:flutter/foundation.dart';

import '../models/pengguna.dart';
import '../services/firestore_service.dart';

final ValueNotifier<Pengguna> profilNotifier = ValueNotifier<Pengguna>(
  const Pengguna(
    id: '',
    nama: '',
    noWa: '',
    bank: '',
    noRekening: '',
  ),
);

void simpanProfil(Pengguna profil) {
  profilNotifier.value = profil;
  firestoreService.simpanProfilUser(profil).catchError((_) {});
}

void resetProfil() {
  profilNotifier.value = const Pengguna(
    id: '',
    nama: '',
    noWa: '',
    bank: '',
    noRekening: '',
  );
}
