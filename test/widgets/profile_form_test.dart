import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpan_nota/features/profile/presentation/widgets/profile_form.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileForm Widget Tests', () {
    testWidgets('1. Merender input nama, telepon, Telegram Chat ID, dan tautan bantuan', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileForm(
                initialName: 'Budi Santoso',
                initialPhone: '+6281234567890',
                initialTelegramChatId: '12345678',
                onSubmit: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nama Pengguna'), findsOneWidget);
      expect(find.text('Nomor Telepon'), findsOneWidget);
      expect(find.text('Telegram Chat ID (Opsional)'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Budi Santoso'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '12345678'), findsOneWidget);
      expect(find.text('Buka @userinfobot'), findsOneWidget);
      expect(find.text('Download Telegram'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
    });

    testWidgets('2. Validasi error lokal saat nama kosong', (tester) async {
      bool submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileForm(
                initialName: '',
                initialPhone: '',
                onSubmit: (_) async {
                  submitted = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tekan tombol simpan
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Memastikan error validasi muncul dan submit tidak dipanggil
      expect(find.text('Nama pengguna tidak boleh kosong.'), findsOneWidget);
      expect(submitted, isFalse);
    });

    testWidgets('3. Validasi error lokal saat Telegram Chat ID bukan angka', (tester) async {
      bool submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileForm(
                initialName: 'Budi Santoso',
                initialPhone: '08123456789',
                initialTelegramChatId: 'telegram_user',
                onSubmit: (_) async {
                  submitted = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tekan tombol simpan
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Memastikan error validasi Telegram Chat ID muncul
      expect(find.text('Telegram Chat ID hanya boleh berupa angka.'), findsOneWidget);
      expect(submitted, isFalse);
    });

    testWidgets('4. Submit berhasil memanggil callback onSubmit dengan format nomor dan telegramChatId yang benar', (tester) async {
      ProfileFormData? receivedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileForm(
                initialName: 'Ahmad Yani',
                initialPhone: '085712345678',
                initialTelegramChatId: '987654321',
                onSubmit: (data) async {
                  receivedData = data;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(receivedData, isNotNull);
      expect(receivedData!.name, 'Ahmad Yani');
      expect(receivedData!.phone, '+6285712345678');
      expect(receivedData!.telegramChatId, '987654321');
    });

    testWidgets('5. Loading state menonaktifkan tombol dan menampilkan spinner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileForm(
                initialName: 'Budi',
                initialPhone: '',
                isLoading: true,
                onSubmit: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Simpan'), findsNothing);
    });

    testWidgets('6. Tombol Batal memanggil callback onCancel', (tester) async {
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileForm(
                initialName: 'Budi',
                initialPhone: '',
                onCancel: () => cancelled = true,
                onSubmit: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(cancelled, isTrue);
    });
  });
}
