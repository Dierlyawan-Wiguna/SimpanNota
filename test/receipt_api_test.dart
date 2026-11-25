import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:simpan_nota/features/receipts/domain/category.dart';
import 'package:simpan_nota/features/receipts/domain/receipt.dart';
import 'package:simpan_nota/features/receipts/services/receipt_repository.dart';
import 'package:simpan_nota/core/local/database_helper.dart';
import 'dart:convert';

void main() {
  group('Model Receipt Tests', () {
    test('1. Model valid: fromJson berhasil mem-parsing JSON yang benar', () {
      final json = {
        'id': 1,
        'productName': 'Laptop Gaming',
        'category': 'elektronik',
        'storeName': 'Toko Komputer',
        'purchaseDate': '2023-10-01T10:00:00.000Z',
        'warrantyMonths': 12,
        'imagePath': '/path/to/image.jpg'
      };
      
      final receipt = Receipt.fromJson(json);
      
      expect(receipt.id, 1);
      expect(receipt.productName, 'Laptop Gaming');
      expect(receipt.category, Category.elektronik);
      expect(receipt.storeName, 'Toko Komputer');
      expect(receipt.warrantyMonths, 12);
      expect(receipt.imagePath, '/path/to/image.jpg');
    });

    test('2. Model invalid: fromJson memberikan nilai default aman pada JSON yang salah/hilang', () {
      final json = {
        'id': 'abc', // Invalid id
        // productName missing
        'category': 'tidak_ada', // Invalid enum
        // storeName missing
        'purchaseDate': 'bukan_tanggal', // Invalid date
        'warrantyMonths': 'dua belas', // Invalid number
        // imagePath missing
      };
      
      final receipt = Receipt.fromJson(json);
      
      expect(receipt.id, null);
      // Memastikan kode kita tidak crash dan memberikan default yang aman
      expect(receipt.productName, 'Unknown Product'); 
      expect(receipt.category, Category.elektronik); 
      expect(receipt.storeName, 'Unknown Store');
      expect(receipt.warrantyMonths, 0);
      expect(receipt.imagePath, '');
    });
  });

  group('API Repository Tests', () {
    late DatabaseHelper dbHelper; 
    
    setUp(() {
      dbHelper = DatabaseHelper.instance; 
    });

    test('3. API sukses: getReceipts mengembalikan List saat status 200', () async {
      // MockClient memungkinkan kita mencegat HTTP request 
      // dan mengembalikan respon palsu tanpa harus butuh koneksi internet
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'productName': 'Item 1',
              'category': 'makanan',
              'storeName': 'Toko A',
              'purchaseDate': '2023-01-01T00:00:00.000Z',
              'warrantyMonths': 0,
              'imagePath': ''
            }
          ]),
          200, // Status code 200 Sukses
        );
      });
      
      final repo = ReceiptRepository(dbHelper, client: mockClient);
      final receipts = await repo.getReceipts();
      
      expect(receipts, isA<List<Receipt>>());
      expect(receipts.length, 1);
      expect(receipts.first.productName, 'Item 1');
    });

    test('4. Data kosong: getReceipts mengembalikan list kosong []', () async {
      final mockClient = MockClient((request) async {
        return http.Response('[]', 200); // Mengembalikan array kosong
      });
      
      final repo = ReceiptRepository(dbHelper, client: mockClient);
      final receipts = await repo.getReceipts();
      
      // Memastikan bahwa list benar-benar kosong
      expect(receipts, isEmpty);
    });

    test('5. HTTP gagal: melempar Exception jika status 404 atau 500', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500); // HTTP 500
      });
      
      final repo = ReceiptRepository(dbHelper, client: mockClient);
      
      // Memastikan fungsi throwsException melempar Exception Server 
      expect(() => repo.getReceipts(), throwsException);
    });

    test('6. JSON rusak: melempar Exception saat JSON cacat (malformed)', () async {
      final mockClient = MockClient((request) async {
        // String JSON ini kehilangan penutup kurung dan tanda kutip (Cacat)
        return http.Response('[{id: 1, productName: "Laptop"', 200); 
      });
      
      final repo = ReceiptRepository(dbHelper, client: mockClient);
      
      // Karena JSON.decode akan gagal, kode try-catch di Repository kita 
      // seharusnya mengubah FormatException menjadi Server Exception 
      expect(() => repo.getReceipts(), throwsException);
    });

    test('7. toSupabaseMap mengabaikan warranty_card_path jika includeWarrantyCard bernilai false', () {
      final receipt = Receipt(
        id: 5,
        productName: 'Monitor Dell',
        category: Category.elektronik,
        storeName: 'Dell Store',
        purchaseDate: DateTime(2026, 2, 1),
        warrantyMonths: 36,
        warrantyDays: 10,
        imagePath: '/img/dell.png',
        warrantyCardPath: '/img/card.png',
      );

      final map = receipt.toSupabaseMap(includeWarrantyCard: false);
      expect(map.containsKey('warranty_card_path'), isFalse);
    });

    test('8. toSupabaseMap menyertakan warranty_card_path jika includeWarrantyCard bernilai true', () {
      final receipt = Receipt(
        id: 5,
        productName: 'Monitor Dell',
        category: Category.elektronik,
        storeName: 'Dell Store',
        purchaseDate: DateTime(2026, 2, 1),
        warrantyMonths: 36,
        warrantyDays: 10,
        imagePath: '/img/dell.png',
        warrantyCardPath: '/img/card.png',
      );

      final map = receipt.toSupabaseMap(includeWarrantyCard: true);
      expect(map['warranty_card_path'], '/img/card.png');
    });

    test('9. toSupabaseMap mengatur warranty_months minimal 1 saat input bernilai 0', () {
      final receipt = Receipt(
        id: 6,
        productName: 'Kabel Audio',
        category: Category.lainnya,
        storeName: 'Toko Kabel',
        purchaseDate: DateTime(2026, 3, 1),
        warrantyMonths: 0,
        warrantyDays: 7,
        imagePath: '/img/cable.png',
      );

      final map = receipt.toSupabaseMap();
      expect(map['warranty_months'], 1);
    });

    test('10. toSupabaseMap tanpa includeDays tidak menyertakan key warranty_days', () {
      final receipt = Receipt(
        id: 7,
        productName: 'Mouse Pad',
        category: Category.lainnya,
        storeName: 'Gaming Shop',
        purchaseDate: DateTime(2026, 4, 1),
        warrantyMonths: 6,
        warrantyDays: 5,
        imagePath: '/img/pad.png',
      );

      final map = receipt.toSupabaseMap(includeDays: false);
      expect(map.containsKey('warranty_days'), isFalse);
    });
  });
}
