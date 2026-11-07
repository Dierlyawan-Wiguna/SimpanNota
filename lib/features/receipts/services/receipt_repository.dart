import 'dart:io';

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
  final SupabaseClient? _customSupabaseClient;

  ReceiptRepository(
    this._dbHelper, {
    Object? client,
    SupabaseClient? supabaseClient,
  }) : _customSupabaseClient = supabaseClient;

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

  /// GET: Mengambil daftar nota dari Supabase PostgreSQL (atau fallback SQLite lokal)
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
        // Jika tabel Supabase belum ada atau koneksi bermasalah, fallback ke SQLite
        try {
          return await _dbHelper.getReceipts();
        } catch (_) {
          throw Exception('Gagal memuat data dari Supabase: $e');
        }
      }
    }

    // Fallback SQLite lokal jika Supabase tidak aktif
    try {
      return await _dbHelper.getReceipts();
    } catch (_) {
      return [];
    }
  }

  /// POST: Menyimpan nota baru ke Supabase PostgreSQL (atau fallback SQLite lokal)
  Future<Receipt> saveReceipt({
    required String namaBarang,
    required Category kategori,
    required String namaToko,
    required DateTime tanggalBeli,
    required int durasiGaransiBulan,
    int durasiGaransiHari = 0,
    required String fotoPath,
  }) async {
    final resolvedImagePath = await uploadImageIfNeeded(fotoPath);

    final receipt = Receipt(
      productName: namaBarang,
      category: kategori,
      storeName: namaToko,
      purchaseDate: tanggalBeli,
      warrantyMonths: durasiGaransiBulan,
      warrantyDays: durasiGaransiHari,
      imagePath: resolvedImagePath,
    );

    final sb = _supabase;
    if (sb != null) {
      try {
        final currentUserId = sb.auth.currentUser?.id;
        final map = receipt.toSupabaseMap(includeDays: true);
        if (currentUserId != null) {
          map['user_id'] = currentUserId;
        }

        try {
          final response = await sb
              .from('receipts')
              .insert(map)
              .select()
              .single();
          return Receipt.fromJson(response);
        } catch (_) {
          // Fallback jika tabel remote Supabase belum ada kolom warranty_days
          final fallbackMap = receipt.toSupabaseMap(includeDays: false);
          if (currentUserId != null) {
            fallbackMap['user_id'] = currentUserId;
          }
          final response = await sb
              .from('receipts')
              .insert(fallbackMap)
              .select()
              .single();
          return Receipt.fromJson(response);
        }
      } catch (e) {
        // Jika Supabase gagal, simpan ke database lokal agar data user tidak hilang
        try {
          return await _dbHelper.insertReceipt(receipt);
        } catch (_) {}
        throw Exception('Gagal menyimpan nota ke Supabase: $e');
      }
    }

    // Fallback ke SQLite lokal
    return await _dbHelper.insertReceipt(receipt);
  }

  /// UPDATE: Mengubah nota di Supabase PostgreSQL (atau fallback SQLite)
  Future<int> updateReceipt({
    required int id,
    required String namaBarang,
    required Category kategori,
    required String namaToko,
    required DateTime tanggalBeli,
    required int durasiGaransiBulan,
    int durasiGaransiHari = 0,
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
      warrantyDays: durasiGaransiHari,
      imagePath: resolvedImagePath,
    );

    final sb = _supabase;
    if (sb != null) {
      try {
        final currentUserId = sb.auth.currentUser?.id;
        final map = receipt.toSupabaseMap(includeDays: true);
        if (currentUserId != null) {
          map['user_id'] = currentUserId;
        }

        try {
          await sb
              .from('receipts')
              .update(map)
              .eq('id', id);
          return 1;
        } catch (_) {
          // Fallback jika remote Supabase belum ada kolom warranty_days
          final fallbackMap = receipt.toSupabaseMap(includeDays: false);
          if (currentUserId != null) {
            fallbackMap['user_id'] = currentUserId;
          }
          await sb
              .from('receipts')
              .update(fallbackMap)
              .eq('id', id);
          return 1;
        }
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
