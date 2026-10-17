import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/category.dart';
import '../domain/receipt.dart';
import '../../../../core/local/database_helper.dart';

// Provider untuk menginjeksi ReceiptRepository ke layer Notifier/Controller
final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  // DatabaseHelper dipertahankan untuk referensi, tapi kita akan pakai HTTP
  return ReceiptRepository(DatabaseHelper.instance);
});

class ReceiptRepository {
  final DatabaseHelper _dbHelper;
  final http.Client _client;
  final String _baseUrl =
      'https://jsonplaceholder.typicode.com/posts'; // Mock API sementara

  ReceiptRepository(this._dbHelper, {http.Client? client})
    : _client = client ?? http.Client();

  /// Mengambil daftar kategori statis
  Future<List<Category>> fetchCategories({
    bool simulateError = false,
    bool simulateEmpty = false,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    if (simulateError) throw Exception('Gagal mengambil daftar kategori.');
    if (simulateEmpty) return [];
    return Category.values;
  }

  /// GET: Mengambil daftar nota dari REST API
  Future<List<Receipt>> getReceipts() async {
    try {
      final response = await _client.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Receipt.fromJson(json)).toList();
      } else {
        throw Exception(
          'Gagal memuat data dari server (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Format JSON rusak: $e');
      }
      throw Exception('Terjadi kesalahan jaringan atau server: $e');
    }
  }

  /// POST: Menyimpan nota baru ke REST API
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

    try {
      final response = await _client.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(receipt.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Receipt.fromJson(responseData);
      } else {
        throw Exception(
          'Gagal menyimpan nota ke server (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengirim data ke server: $e');
    }
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
