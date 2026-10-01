import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/category.dart';

// Provider untuk menginjeksi ReceiptRepository ke layer Notifier/Controller
final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepository();
});

class ReceiptRepository {
  /// Mensimulasikan pengambilan data kategori dari server/database.
  /// Ini digunakan untuk memenuhi syarat: (1) Initial loading, (3) Empty state, dan (4) Error state.
  Future<List<Category>> fetchCategories({
    bool simulateError = false,
    bool simulateEmpty = false,
  }) async {
    // Simulasi loading dari jaringan selama 2 detik
    await Future.delayed(const Duration(seconds: 10));

    if (simulateError) {
      // Melemparkan error untuk mensimulasikan kegagalan jaringan/server
      throw Exception(
        'Gagal mengambil daftar kategori dari server. Periksa koneksi Anda.',
      );
    }

    if (simulateEmpty) {
      // Mengembalikan daftar kosong untuk mensimulasikan "Empty State"
      return [];
    }

    // Mengembalikan data kategori yang sukses dimuat (2. Data sukses dimuat)
    return Category.values;
  }

  /// Mensimulasikan proses penyimpanan data nota ke server/database.
  Future<void> saveReceipt(String namaBarang, Category kategori) async {
    // Simulasi loading penyimpanan data selama 2 detik
    await Future.delayed(const Duration(seconds: 2));

    // Di aplikasi nyata, proses ini akan memanggil API Supabase.
    // Misalnya: await supabase.from('receipts').insert({...});
  }
}
