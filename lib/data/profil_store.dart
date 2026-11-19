import 'package:flutter/foundation.dart';

import '../models/pengguna.dart';
import '../utils/input_validation.dart';
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
  final error = validasiNomorRekening(profil.noRekening);
  if (error != null) {
    throw ArgumentError.value(profil.noRekening, 'noRekening', error);
  }
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
