import 'package:flutter_test/flutter_test.dart';
import 'package:simpan_nota/core/constants/supabase_constants.dart';
import 'package:simpan_nota/features/receipts/domain/category.dart';
import 'package:simpan_nota/features/receipts/domain/receipt.dart';

void main() {
  group('Supabase Integration & Model Tests', () {
    test('1. toSupabaseMap mengubah model Dart ke snake_case PostgreSQL', () {
      final receipt = Receipt(
        id: 10,
        productName: 'Monitor LED 24 Inch',
        category: Category.elektronik,
        storeName: 'Official Store',
        purchaseDate: DateTime(2024, 5, 20),
        warrantyMonths: 24,
        imagePath: 'https://xyz.supabase.co/storage/v1/object/public/receipts/img.jpg',
      );

      final map = receipt.toSupabaseMap();

      expect(map['id'], 10);
      expect(map['product_name'], 'Monitor LED 24 Inch');
      expect(map['category'], 'elektronik');
      expect(map['store_name'], 'Official Store');
      expect(map['purchase_date'], '2024-05-20');
      expect(map['warranty_months'], 24);
      expect(map['image_path'], contains('https://xyz.supabase.co'));
    });

    test('2. fromJson berhasil mem-parsing snake_case dari Supabase PostgreSQL', () {
      final supabaseJson = {
        'id': 42,
        'product_name': 'Kulkas 2 Pintu',
        'category': 'elektronik',
        'store_name': 'Elektronik Maju',
        'purchase_date': '2024-01-15',
        'warranty_months': 36,
        'image_path': 'https://xyz.supabase.co/storage/v1/object/public/receipts/kulkas.jpg',
      };

      final receipt = Receipt.fromJson(supabaseJson);

      expect(receipt.id, 42);
      expect(receipt.productName, 'Kulkas 2 Pintu');
      expect(receipt.category, Category.elektronik);
      expect(receipt.storeName, 'Elektronik Maju');
      expect(receipt.warrantyMonths, 36);
      expect(receipt.imagePath, 'https://xyz.supabase.co/storage/v1/object/public/receipts/kulkas.jpg');
    });

    test('3. SupabaseConstants.isConfigured mendeteksi placeholder vs kredensial asli', () {
      // Saat ini masih berupa placeholder
      expect(SupabaseConstants.isConfigured, isFalse);
    });
  });
}
