import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:simpan_nota/features/auth/presentation/screens/auth_screen.dart';
import 'package:simpan_nota/features/receipts/domain/category.dart';
import 'package:simpan_nota/features/receipts/domain/receipt.dart';
import 'package:simpan_nota/features/receipts/presentation/screens/receipt_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/url_launcher');

  bool canLaunchReturnValue = false;
  String? lastLaunchedUrl;

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    canLaunchReturnValue = false;
    lastLaunchedUrl = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'canLaunch') {
        return canLaunchReturnValue;
      }
      if (methodCall.method == 'launch') {
        lastLaunchedUrl = methodCall.arguments['url'] as String?;
        return true;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('Telegram Reminder Feature Tests', () {
    testWidgets('1. WelcomeScreen menampilkan info fitur pengingat Telegram dengan Semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pengingat Garansi via Telegram'), findsOneWidget);
      expect(
        find.textContaining('Pengingat Garansi Otomatis Gratis via Telegram (H-30 & H-7)'),
        findsOneWidget,
      );
    });

    testWidgets('2. LoginScreen menampilkan banner informasi pengingat Telegram', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Pengingat Garansi Otomatis Gratis via Telegram (H-30 & H-7)'),
        findsOneWidget,
      );
    });

    testWidgets('3. ReceiptDetailScreen menampilkan tombol Kirim Pengingat ke Telegram', (tester) async {
      final dummyReceipt = Receipt(
        id: 1,
        productName: 'Laptop Asus ROG',
        category: Category.elektronik,
        storeName: 'Asus Store Official',
        purchaseDate: DateTime(2025, 1, 1),
        warrantyMonths: 24,
        imagePath: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ReceiptDetailScreen(receipt: dummyReceipt),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pengingat Garansi Telegram'), findsOneWidget);
      expect(find.text('Kirim Pengingat ke Telegram'), findsOneWidget);
    });

    testWidgets('4. Muncul dialog "Telegram Belum Terpasang" saat Telegram belum ada di perangkat', (tester) async {
      canLaunchReturnValue = false;

      final dummyReceipt = Receipt(
        id: 2,
        productName: 'Monitor Xiaomi 27 Inch',
        category: Category.elektronik,
        storeName: 'Mi Store',
        purchaseDate: DateTime(2025, 2, 1),
        warrantyMonths: 12,
        imagePath: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ReceiptDetailScreen(receipt: dummyReceipt),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll ke bagian bawah agar tombol Telegram terlihat di viewport
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Ketuk tombol Kirim Pengingat ke Telegram
      final button = find.widgetWithText(ElevatedButton, 'Kirim Pengingat ke Telegram');
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Verifikasi AlertDialog Telegram Belum Terpasang muncul
      expect(find.text('Telegram Belum Terpasang'), findsOneWidget);
      expect(
        find.textContaining('Aplikasi Telegram dibutuhkan untuk mengirim dan menerima pengingat garansi secara otomatis'),
        findsOneWidget,
      );
      expect(find.text('Download Telegram'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      // Verifikasi tombol Batal menutup dialog
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Telegram Belum Terpasang'), findsNothing);
    });

    testWidgets('5. Saat Telegram sudah terpasang, mengarahkan ke link Telegram tg://msg', (tester) async {
      canLaunchReturnValue = true;

      final dummyReceipt = Receipt(
        id: 3,
        productName: 'Kamera Sony A7',
        category: Category.elektronik,
        storeName: 'Sony Center',
        purchaseDate: DateTime(2025, 3, 1),
        warrantyMonths: 12,
        imagePath: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ReceiptDetailScreen(receipt: dummyReceipt),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      final button = find.widgetWithText(ElevatedButton, 'Kirim Pengingat ke Telegram');
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(lastLaunchedUrl, startsWith('tg://msg?text='));
    });
  });
}
