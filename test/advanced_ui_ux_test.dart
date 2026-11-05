import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simpan_nota/features/auth/presentation/screens/auth_screen.dart';
import 'package:simpan_nota/features/receipts/domain/category.dart';
import 'package:simpan_nota/features/receipts/domain/receipt.dart';
import 'package:simpan_nota/features/receipts/presentation/controllers/receipt_list_notifier.dart';
import 'package:simpan_nota/features/receipts/presentation/screens/home_screen.dart';
import 'package:simpan_nota/features/receipts/presentation/widgets/receipt_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyReceipts = [
    Receipt(
      id: 1,
      productName: 'Laptop Asus ROG',
      category: Category.elektronik,
      storeName: 'Asus Official Store',
      purchaseDate: DateTime(2024, 1, 15),
      warrantyMonths: 24,
      imagePath: '/path/to/laptop.jpg',
    ),
    Receipt(
      id: 2,
      productName: 'Kulkas Sharp 2 Pintu',
      category: Category.elektronik,
      storeName: 'Elektronik City',
      purchaseDate: DateTime(2024, 3, 10),
      warrantyMonths: 36,
      imagePath: '/path/to/kulkas.jpg',
    ),
  ];

  group('4 Kriteria UI/UX Lanjutan - Unit & Widget Tests', () {
    testWidgets('1. Layout Adaptif: HomeScreen menampilkan Grid di layar lebar dan List di layar HP', (tester) async {
      // Skenario A: Layar Lebar (Tablet / Landscape - 800x600)
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filteredReceiptListProvider.overrideWithValue(AsyncValue.data(dummyReceipts)),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Finder untuk ListView vertikal (daftar nota)
      final verticalReceiptListFinder = find.byWidgetPredicate(
        (widget) => widget is ListView && widget.scrollDirection == Axis.vertical,
      );

      // Di layar lebar (lebar >= 600), harus merender GridView dan tidak merender vertical ListView
      expect(find.byType(GridView), findsOneWidget);
      expect(verticalReceiptListFinder, findsNothing);

      // Skenario B: Layar Kecil (HP / Portrait - 400x800)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filteredReceiptListProvider.overrideWithValue(AsyncValue.data(dummyReceipts)),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Di layar kecil (lebar < 600), harus merender ListView vertikal biasa
      expect(verticalReceiptListFinder, findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('2. Accessibility Dasar: Semantics widget aktif pada ReceiptCard dan Tombol', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptCard(
              receipt: dummyReceipts.first,
              onTap: () {},
            ),
          ),
        ),
      );

      // Cek apakah Semantics dengan label deskriptif tersedia
      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label != null && widget.properties.label!.contains('Laptop Asus ROG'),
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('3. Keyboard-Safe UI: Form login dan register dibungkus SingleChildScrollView', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Verifikasi SingleChildScrollView aktif pada form login
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      // Verifikasi SingleChildScrollView aktif pada form register
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
