class ReceiptModel {
  final String id;
  final String userId;
  final String namaBarang;
  final String namaToko;
  final DateTime tanggalBeli;
  final int durasiGaransiBulan;
  final String? fotoUrl;
  final String kategori;
  final DateTime createdAt;

  ReceiptModel({
    required this.id,
    required this.userId,
    required this.namaBarang,
    required this.namaToko,
    required this.tanggalBeli,
    required this.durasiGaransiBulan,
    this.fotoUrl,
    required this.kategori,
    required this.createdAt,
  });

  ReceiptModel copyWith({
    String? id,
    String? userId,
    String? namaBarang,
    String? namaToko,
    DateTime? tanggalBeli,
    int? durasiGaransiBulan,
    String? fotoUrl,
    String? kategori,
    DateTime? createdAt,
  }) {
    return ReceiptModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      namaBarang: namaBarang ?? this.namaBarang,
      namaToko: namaToko ?? this.namaToko,
      tanggalBeli: tanggalBeli ?? this.tanggalBeli,
      durasiGaransiBulan: durasiGaransiBulan ?? this.durasiGaransiBulan,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      kategori: kategori ?? this.kategori,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'nama_barang': namaBarang,
      'nama_toko': namaToko,
      'tanggal_beli': tanggalBeli.toIso8601String(),
      'durasi_garansi_bulan': durasiGaransiBulan,
      'foto_url': fotoUrl,
      'kategori': kategori,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReceiptModel.fromMap(Map<String, dynamic> map) {
    return ReceiptModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      namaBarang: map['nama_barang'] ?? '',
      namaToko: map['nama_toko'] ?? '',
      tanggalBeli: DateTime.parse(map['tanggal_beli']),
      durasiGaransiBulan: map['durasi_garansi_bulan']?.toInt() ?? 0,
      fotoUrl: map['foto_url'],
      kategori: map['kategori'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
