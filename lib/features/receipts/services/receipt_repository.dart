import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/category.dart';
import '../domain/receipt.dart';
import '../../../../core/local/database_helper.dart';
import '../../../../core/constants/supabase_constants.dart';

// Provider untuk menginjeksi ReceiptRepository ke layer Notifier/Controller
final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepository(DatabaseHelper.instance);
});

class ReceiptRepository {
  final DatabaseHelper _dbHelper;
  final http.Client _client;
  final SupabaseClient? _customSupabaseClient;
  final String _baseUrl =
      'https://jsonplaceholder.typicode.com/posts'; // Mock API sementara

  ReceiptRepository(
    this._dbHelper, {
    http.Client? client,
    SupabaseClient? supabaseClient,
  })  : _client = client ?? http.Client(),
        _customSupabaseClient = supabaseClient;

  SupabaseClient? get _supabase {
    if (_customSupabaseClient != null) return _customSupabaseClient;
    if (SupabaseConstants.isConfigured) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

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

  /// Mengunggah foto nota ke Supabase Storage (bucket: 'receipts') jika Supabase aktif
  Future<String> uploadImageIfNeeded(String localPath) async {
    final sb = _supabase;
    if (sb == null) return localPath;
    if (localPath.startsWith('http://') || localPath.startsWith('https://')) {
      return localPath;
    }

    try {
      final file = File(localPath);
      if (!await file.exists()) return localPath;

      final extension = localPath.split('.').last;
      final fileName =
          'receipt_${DateTime.now().millisecondsSinceEpoch}_${localPath.hashCode.abs()}.$extension';

      await sb.storage.from('receipts').upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = sb.storage.from('receipts').getPublicUrl(fileName);
      return publicUrl;
    } catch (_) {
      // Fallback ke path lokal jika upload gagal agar proses simpan data tidak terhambat
      return localPath;
    }
  }

  /// GET: Mengambil daftar nota dari Supabase PostgreSQL (atau fallback REST API / SQLite)
  Future<List<Receipt>> getReceipts() async {
    final sb = _supabase;
    if (sb != null) {
      try {
        var query = sb.from('receipts').select();
        final currentUserId = sb.auth.currentUser?.id;
        if (currentUserId != null) {
          query = query.eq('user_id', currentUserId);
        }

        final List<dynamic> data =
            await query.order('purchase_date', ascending: false);
        return data
            .map((json) => Receipt.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        throw Exception('Gagal memuat data dari Supabase: $e');
      }
    }

    // Fallback ke REST API (Pertemuan 6) bila Supabase belum dikonfigurasi
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

  /// POST: Menyimpan nota baru ke Supabase PostgreSQL (atau fallback REST API)
  Future<Receipt> saveReceipt({
    required String namaBarang,
    required Category kategori,
    required String namaToko,
    required DateTime tanggalBeli,
    required int durasiGaransiBulan,
    required String fotoPath,
  }) async {
    final resolvedImagePath = await uploadImageIfNeeded(fotoPath);

    final receipt = Receipt(
      productName: namaBarang,
      category: kategori,
      storeName: namaToko,
      purchaseDate: tanggalBeli,
      warrantyMonths: durasiGaransiBulan,
      imagePath: resolvedImagePath,
    );

    final sb = _supabase;
    if (sb != null) {
      try {
        final map = receipt.toSupabaseMap();
        final currentUserId = sb.auth.currentUser?.id;
        if (currentUserId != null) {
          map['user_id'] = currentUserId;
        }

        final response = await sb
            .from('receipts')
            .insert(map)
            .select()
            .single();
        return Receipt.fromJson(response);
      } catch (e) {
        throw Exception('Gagal menyimpan nota ke Supabase: $e');
      }
    }

    // Fallback ke REST API (Pertemuan 6)
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

  /// UPDATE: Mengubah nota di Supabase PostgreSQL (atau fallback SQLite)
  Future<int> updateReceipt({
    required int id,
    required String namaBarang,
    required Category kategori,
    required String namaToko,
    required DateTime tanggalBeli,
    required int durasiGaransiBulan,
    required String fotoPath,
  }) async {
    final resolvedImagePath = await uploadImageIfNeeded(fotoPath);

    final receipt = Receipt(
      id: id,
      productName: namaBarang,
      category: kategori,
      storeName: namaToko,
      purchaseDate: tanggalBeli,
      warrantyMonths: durasiGaransiBulan,
      imagePath: resolvedImagePath,
    );

    final sb = _supabase;
    if (sb != null) {
      try {
        final map = receipt.toSupabaseMap();
        final currentUserId = sb.auth.currentUser?.id;
        if (currentUserId != null) {
          map['user_id'] = currentUserId;
        }

        await sb
            .from('receipts')
            .update(map)
            .eq('id', id);
        return 1;
      } catch (e) {
        throw Exception('Gagal memperbarui nota di Supabase: $e');
      }
    }

    // Fallback ke SQLite
    return await _dbHelper.updateReceipt(receipt);
  }

  /// DELETE: Menghapus nota dari Supabase PostgreSQL (atau fallback SQLite)
  Future<int> deleteReceipt(int id) async {
    final sb = _supabase;
    if (sb != null) {
      try {
        await sb.from('receipts').delete().eq('id', id);
        return 1;
      } catch (e) {
        throw Exception('Gagal menghapus nota di Supabase: $e');
      }
    }

    // Fallback ke SQLite
    return await _dbHelper.deleteReceipt(id);
  }
}
