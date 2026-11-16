class Pengguna {
  final String id;
  final String nama;
  final String noWa;
  final String bank;
  final String noRekening;

  const Pengguna({
    required this.id,
    required this.nama,
    required this.noWa,
    required this.bank,
    required this.noRekening,
  });

  Pengguna copyWith({
    String? id,
    String? nama,
    String? noWa,
    String? bank,
    String? noRekening,
  }) {
    return Pengguna(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      noWa: noWa ?? this.noWa,
      bank: bank ?? this.bank,
      noRekening: noRekening ?? this.noRekening,
    );
  }
}
