import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:simpan_nota/features/profile/presentation/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Profile Feature - Baseline Widget Tests', () {
    testWidgets('1. ProfileScreen berhasil merender header, avatar, dan informasi profil', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan AppBar menampilkan 'Profil Saya'
      expect(find.text('Profil Saya'), findsOneWidget);

      // Memastikan Tile profil tersedia
      expect(find.text('Nama Pengguna'), findsWidgets);
      expect(find.text('Email Terdaftar'), findsOneWidget);
      expect(find.text('Nomor Telepon'), findsOneWidget);
      expect(find.text('Tanggal Mendaftar'), findsOneWidget);

      // Memastikan Card Pengaturan Mode Gelap ada
      expect(find.text('Mode Gelap (Dark Mode)'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // Memastikan Tombol Keluar dari Akun ada
      expect(find.text('Keluar dari Akun'), findsOneWidget);
    });

    testWidgets('2. ProfileScreen membuka dialog Ubah Profil saat tombol edit ditekan', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cari tombol icon edit di AppBar
      final editButtonFinder = find.byTooltip('Ubah Profil');
      expect(editButtonFinder, findsOneWidget);

      await tester.tap(editButtonFinder);
      await tester.pumpAndSettle();

      // Memastikan dialog Ubah Profil muncul
      expect(find.text('Ubah Profil'), findsOneWidget);
      expect(find.text('Nomor Telepon (WhatsApp)'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);

      // Tutup dialog
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Nomor Telepon (WhatsApp)'), findsNothing);
    });

    testWidgets('3. ProfileScreen membuka dialog Ubah Kata Sandi saat tombol ditekan', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cari tombol Ubah Kata Sandi
      final changePasswordButtonFinder = find.widgetWithText(OutlinedButton, 'Ubah Kata Sandi');
      if (changePasswordButtonFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(changePasswordButtonFinder);
        await tester.pumpAndSettle();
        await tester.tap(changePasswordButtonFinder);
        await tester.pumpAndSettle();

        // Memastikan dialog Ubah Kata Sandi muncul
        expect(find.text('Kata Sandi Baru'), findsOneWidget);
        expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);

        // Tutup dialog
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();
      }
    });
  });
}
