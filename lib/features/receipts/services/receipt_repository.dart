import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/category.dart';
import '../domain/receipt.dart';
import '../../../../core/local/database_helper.dart';

// Provider untuk menginjeksi ReceiptRepository ke layer Notifier/Controller
final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepository(DatabaseHelper.instance);
});

class ReceiptRepository {
  final DatabaseHelper _dbHelper;

  ReceiptRepository(this._dbHelper);

  /// Mengambil daftar kategori statis (opsional, jika Anda ingin menyimpannya di DB juga, bisa diubah)
  Future<List<Category>> fetchCategories({
    bool simulateError = false,
    bool simulateEmpty = false,
  }) async {
    // Simulasi loading
    await Future.delayed(const Duration(seconds: 1));

    if (simulateError) {
      throw Exception('Gagal mengambil daftar kategori.');
    }

    if (simulateEmpty) {
      return [];
    }

    return Category.values;
  }

  /// Mengambil daftar nota dari SQLite
  Future<List<Receipt>> getReceipts() async {
    return await _dbHelper.getReceipts();
  }

  /// Menyimpan nota baru ke SQLite
  Future<Receipt> saveReceipt({
    required String namaBarang,
    required Category kategori,
    required String namaToko,
    required DateTime tanggalBeli,
    required int durasiGaransiBulan,
    required String fotoPath,
  }) async {
    final receipt = Receipt(
      productName: namaBarang,
      category: kategori,
      storeName: namaToko,
      purchaseDate: tanggalBeli,
      warrantyMonths: durasiGaransiBulan,
      imagePath: fotoPath,
    );
    
    return await _dbHelper.insertReceipt(receipt);
  }

  /// Mengubah nota yang ada di SQLite
  Future<int> updateReceipt({
    required int id,
    required String namaBarang,
    required Category kategori,
    required String namaToko,
    required DateTime tanggalBeli,
    required int durasiGaransiBulan,
    required String fotoPath,
  }) async {
    final receipt = Receipt(
      id: id,
      productName: namaBarang,
      category: kategori,
      storeName: namaToko,
      purchaseDate: tanggalBeli,
      warrantyMonths: durasiGaransiBulan,
      imagePath: fotoPath,
    );
    
    return await _dbHelper.updateReceipt(receipt);
  }

  /// Menghapus nota dari SQLite berdasarkan ID
  Future<int> deleteReceipt(int id) async {
    return await _dbHelper.deleteReceipt(id);
  }
}
