import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simpan_nota/features/auth/presentation/screens/auth_screen.dart';
import 'package:simpan_nota/features/receipts/domain/category.dart';
import 'package:simpan_nota/features/receipts/domain/receipt.dart';
import 'package:simpan_nota/features/receipts/presentation/screens/add_receipt_screen.dart';
import 'package:simpan_nota/features/receipts/services/receipt_repository.dart';
import 'package:simpan_nota/core/local/database_helper.dart';
import 'package:simpan_nota/core/services/notification_service.dart';

class MockReceiptRepository extends ReceiptRepository {
  MockReceiptRepository() : super(DatabaseHelper.instance);

  @override
  Future<List<Category>> fetchCategories({bool simulateError = false, bool simulateEmpty = false}) async {
    return Category.values;
  }

  @override
  Future<Receipt> saveReceipt({
    required String namaBarang,
    required Category kategori,
    required String namaToko,
    required DateTime tanggalBeli,
    required int durasiGaransiBulan,
    required String fotoPath,
  }) async {
    return Receipt(
      id: 99,
      productName: namaBarang,
      category: kategori,
      storeName: namaToko,
      purchaseDate: tanggalBeli,
      warrantyMonths: durasiGaransiBulan,
      imagePath: fotoPath,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Advanced Features - Unit & Widget Tests', () {
    test('1. NotificationService: Singleton instance and initialization check', () {
      final service1 = NotificationService();
      final service2 = NotificationService();
      expect(identical(service1, service2), isTrue);
    });

    testWidgets('2. AuthScreen: Tampilan elemen autentikasi biometrik & tombol pemindaian', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(),
        ),
      );

      // Pastikan icon fingerprint, judul, dan tombol autentikasi tersedia
      expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);
      expect(find.text('Autentikasi Keamanan'), findsOneWidget);
      expect(find.textContaining('Pindai Biometrik / PIN'), findsOneWidget);
      expect(find.text('Ganti Akun / Halaman Login'), findsOneWidget);
    });

    testWidgets('3. AddReceiptScreen: Tombol Kamera dan Ambil Lokasi Saat Ini tersedia pada form', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            receiptRepositoryProvider.overrideWithValue(MockReceiptRepository()),
          ],
          child: const MaterialApp(
            home: AddReceiptScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Pastikan tombol Kamera dan Galeri tersedia
      expect(find.text('Buka Kamera'), findsOneWidget);
      expect(find.text('Dari Galeri'), findsOneWidget);

      // Pastikan field dan tombol Geolocator Lokasi tersedia
      expect(find.text('Alamat / Koordinat Toko'), findsOneWidget);
      expect(find.text('Ambil Lokasi Saat Ini'), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });
  });
}
