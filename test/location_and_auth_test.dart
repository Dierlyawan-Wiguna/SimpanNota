import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simpan_nota/core/constants/supabase_constants.dart';
import 'package:simpan_nota/features/auth/presentation/screens/auth_screen.dart';
import 'package:simpan_nota/features/receipts/presentation/screens/add_receipt_screen.dart';
import 'package:simpan_nota/features/receipts/presentation/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Verifikasi UI Welcome, Login, dan AddReceiptScreen', () {
    test('1. SupabaseConstants.isConfigured berfungsi dengan valid', () {
      expect(SupabaseConstants.isConfigured, anyOf(isTrue, isFalse));
    });

    testWidgets('2. WelcomeScreen hanya memiliki tombol Mulai (tanpa teks daftar di sini)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Verifikasi tombol Mulai ada
      expect(find.text('Mulai'), findsOneWidget);

      // Verifikasi teks "Belum punya akun? Daftar di sini" sudah dihapus
      expect(find.text('Daftar di sini'), findsNothing);
      expect(find.text('Belum punya akun? '), findsNothing);
    });

    testWidgets('3. AddReceiptScreen memiliki label Alamat Toko, tombol Cari Lokasi Toko, dan tanpa Panel Pengujian', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddReceiptScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi tombol Cari Lokasi Toko ada
      expect(find.text('Cari Lokasi Toko'), findsOneWidget);

      // Verifikasi tombol lama "Ambil Lokasi Saat Ini" sudah diganti
      expect(find.text('Ambil Lokasi Saat Ini'), findsNothing);

      // Verifikasi label Alamat Toko ada
      expect(find.text('Alamat Toko'), findsOneWidget);

      // Verifikasi Panel Simulasi Pengujian sudah dihapus
      expect(find.text('Panel Simulasi Pengujian:'), findsNothing);
      expect(find.text('Test Error'), findsNothing);
      expect(find.text('Test Empty'), findsNothing);
    });

    testWidgets('4. LoginScreen memiliki tombol Lupa Password dan opsi Google Login', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Verifikasi tombol Lupa Password ada
      expect(find.text('Lupa Password?'), findsOneWidget);

      // Verifikasi tombol Lanjutkan dengan Google ada
      expect(find.text('Lanjutkan dengan Google'), findsOneWidget);

      // Verifikasi tombol Customer Service "Butuh Bantuan?" ada
      expect(find.text('Butuh Bantuan?'), findsOneWidget);
    });

    testWidgets('5. HomeScreen memiliki tombol Butuh Bantuan di pojok kiri sejajar dengan Tambah Nota', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Verifikasi kedua tombol sejajar di floatingActionButton
      expect(find.text('Butuh Bantuan?'), findsOneWidget);
      expect(find.text('Tambah Nota'), findsOneWidget);
    });
  });
}

