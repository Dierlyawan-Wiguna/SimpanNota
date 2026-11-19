import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpan_nota/core/services/app_logger.dart';
import 'package:simpan_nota/features/profile/presentation/screens/system_log_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await AppLogger.clearLogs();
  });

  tearDown(() async {
    await AppLogger.clearLogs();
  });

  group('1. AppLogger Unit Tests', () {
    test('1.1 LogLevel parsing dan label sesuai standar', () {
      expect(LogLevel.info.label, 'INFO');
      expect(LogLevel.warning.label, 'WARNING');
      expect(LogLevel.error.label, 'ERROR');
      expect(LogLevel.fatal.label, 'FATAL');

      expect(LogLevel.fromString('INFO'), LogLevel.info);
      expect(LogLevel.fromString('warning'), LogLevel.warning);
      expect(LogLevel.fromString('WARN'), LogLevel.warning);
      expect(LogLevel.fromString('error'), LogLevel.error);
      expect(LogLevel.fromString('fatal'), LogLevel.fatal);
      expect(LogLevel.fromString('unknown'), LogLevel.info);
    });

    test('1.2 AppLogger.sanitize menyamarkan password, token, dan apiKey sensitif', () {
      const sensitive1 = 'Login attempt password=mySecretPassword123 with user';
      expect(AppLogger.sanitize(sensitive1), contains('password=[REDACTED]'));
      expect(AppLogger.sanitize(sensitive1), isNot(contains('mySecretPassword123')));

      const sensitive2 = 'API call token: "eyJhGciOi..."';
      expect(AppLogger.sanitize(sensitive2), contains('token=[REDACTED]'));
      expect(AppLogger.sanitize(sensitive2), isNot(contains('eyJhGciOi...')));

      const sensitive3 = 'Supabase apiKey: sb_publishable_secretKey';
      expect(AppLogger.sanitize(sensitive3), contains('apiKey=[REDACTED]'));
      expect(AppLogger.sanitize(sensitive3), isNot(contains('sb_publishable_secretKey')));
    });

    test('1.3 Log info, warning, error, dan fatal tercatat di buffer in-memory', () {
      AppLogger.info('TEST_TAG', 'Pesan informasi');
      AppLogger.warning('TEST_TAG', 'Pesan peringatan');
      AppLogger.error('TEST_TAG', 'Pesan error');
      AppLogger.fatal('TEST_TAG', 'Pesan fatal crash');

      final logs = AppLogger.inMemoryLogs;
      expect(logs.length, 4);

      expect(logs[0].level, LogLevel.fatal);
      expect(logs[0].message, 'Pesan fatal crash');
      expect(logs[1].level, LogLevel.error);
      expect(logs[2].level, LogLevel.warning);
      expect(logs[3].level, LogLevel.info);
    });

    test('1.4 Rotasi log in-memory dibatasi maksimal 500 entri', () {
      for (int i = 0; i < 520; i++) {
        AppLogger.info('ROTATION', 'Log ke-$i');
      }

      final logs = AppLogger.inMemoryLogs;
      expect(logs.length, AppLogger.maxInMemoryLogs);
      expect(logs.first.message, 'Log ke-519');
    });

    test('1.5 exportLogsAsText menghasilkan teks terstruktur dengan header', () {
      AppLogger.info('APP', 'Aplikasi dimulai');
      final text = AppLogger.exportLogsAsText();

      expect(text, contains('=== SIMPANNOTA RUNTIME SYSTEM LOGS ==='));
      expect(text, contains('[INFO] [APP] Aplikasi dimulai'));
      expect(text, contains('Total Log: 1'));
    });

    test('1.6 clearLogs membersihkan seluruh riwayat log', () async {
      AppLogger.info('TAG', 'Log 1');
      AppLogger.error('TAG', 'Log 2');
      expect(AppLogger.inMemoryLogs.length, 2);

      await AppLogger.clearLogs();
      expect(AppLogger.inMemoryLogs.isEmpty, isTrue);
      expect(AppLogger.logsNotifier.value.isEmpty, isTrue);
    });
  });

  group('2. SystemLogScreen Widget Tests', () {
    testWidgets('2.1 Menampilkan App Bar, Chip Filter, dan State Kosong saat belum ada log',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SystemLogScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('System Logs & Tracing'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('INFO'), findsOneWidget);
      expect(find.text('WARNING'), findsOneWidget);
      expect(find.text('ERROR'), findsOneWidget);
      expect(find.text('FATAL'), findsOneWidget);
      expect(find.text('Belum Ada Log Tercatat'), findsOneWidget);
    });

    testWidgets('2.2 Menampilkan daftar log dan merespons filter level', (tester) async {
      AppLogger.info('AUTH', 'Login berhasil');
      AppLogger.error('NETWORK', 'Koneksi timeout');

      await tester.pumpWidget(
        const MaterialApp(
          home: SystemLogScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Secara default (filter ALL) kedua log tampil
      expect(find.text('Login berhasil'), findsOneWidget);
      expect(find.text('Koneksi timeout'), findsOneWidget);

      // Tap filter ERROR pada ChoiceChip
      await tester.tap(find.widgetWithText(ChoiceChip, 'ERROR'));
      await tester.pumpAndSettle();

      expect(find.text('Koneksi timeout'), findsOneWidget);
      expect(find.text('Login berhasil'), findsNothing);

      // Tap filter INFO pada ChoiceChip
      await tester.tap(find.widgetWithText(ChoiceChip, 'INFO'));
      await tester.pumpAndSettle();

      expect(find.text('Login berhasil'), findsOneWidget);
      expect(find.text('Koneksi timeout'), findsNothing);
    });

    testWidgets('2.3 Memiliki accessibility Semantics pada tombol salin dan hapus',
        (tester) async {
      AppLogger.info('APP', 'Test Semantics');

      await tester.pumpWidget(
        const MaterialApp(
          home: SystemLogScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Salin Seluruh Log'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Bersihkan Riwayat Log'),
        findsOneWidget,
      );
    });
  });
}
