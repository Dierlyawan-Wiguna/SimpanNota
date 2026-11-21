import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:simpan_nota/core/services/telegram_service.dart';
import 'package:simpan_nota/features/receipts/domain/receipt.dart';
import 'package:simpan_nota/features/receipts/domain/category.dart';

class MockHttpClient extends http.BaseClient {
  final int statusCode;
  final String body;

  MockHttpClient({required this.statusCode, required this.body});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final byteStream = http.ByteStream.fromBytes(utf8.encode(body));
    return http.StreamedResponse(
      byteStream,
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }
}

class ThrowingHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw Exception('Connection failed');
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  final testReceipt = Receipt(
    id: 1,
    productName: 'Extension ESP32 S3',
    storeName: 'Shopee Official',
    category: Category.elektronik,
    purchaseDate: DateTime(2026, 1, 1),
    warrantyMonths: 12,
    imagePath: 'receipt_1.jpg',
  );

  group('TelegramService - formatWarrantyReminderMessage', () {
    test('menghasilkan format markdown pengingat garansi dengan benar', () {
      final msg = TelegramService.formatWarrantyReminderMessage(
        receipt: testReceipt,
        userName: 'Dierlyawan',
      );

      expect(msg, contains('PENGINGAT MASA GARANSI SIMPANNOTA'));
      expect(msg, contains('Dierlyawan'));
      expect(msg, contains('Extension ESP32 S3'));
      expect(msg, contains('Shopee Official'));
      expect(msg, contains('Elektronik'));
      expect(msg, contains('12 Bulan'));
    });
  });

  group('TelegramService - sendAutomatedMessage', () {
    test('mengembalikan noToken jika bot token kosong', () async {
      final result = await TelegramService.sendAutomatedMessage(
        chatId: '1227447571',
        message: 'Tes pengingat',
        botToken: '',
      );

      expect(result.status, TelegramSendStatus.noToken);
      expect(result.isSuccess, isFalse);
    });

    test('mengembalikan chatNotFound jika chatId kosong', () async {
      final result = await TelegramService.sendAutomatedMessage(
        chatId: '   ',
        message: 'Tes pengingat',
        botToken: '123456:ABC-DEF',
      );

      expect(result.status, TelegramSendStatus.chatNotFound);
      expect(result.isSuccess, isFalse);
    });

    test('mengembalikan success jika API Telegram menjawab 200 OK', () async {
      TelegramService.client = MockHttpClient(
        statusCode: 200,
        body: '{"ok": true, "result": {"message_id": 99}}',
      );

      final result = await TelegramService.sendAutomatedMessage(
        chatId: '1227447571',
        message: 'Pengingat garansi aktif',
        botToken: '123456:VALID_TOKEN',
      );

      expect(result.status, TelegramSendStatus.success);
      expect(result.isSuccess, isTrue);
      expect(result.statusCode, 200);
    });

    test('mengembalikan userNotStarted jika API Telegram menjawab 403 Forbidden', () async {
      TelegramService.client = MockHttpClient(
        statusCode: 403,
        body: '{"ok": false, "error_code": 403, "description": "Forbidden: bot was blocked by the user"}',
      );

      final result = await TelegramService.sendAutomatedMessage(
        chatId: '1227447571',
        message: 'Pengingat garansi aktif',
        botToken: '123456:VALID_TOKEN',
      );

      expect(result.status, TelegramSendStatus.userNotStarted);
      expect(result.isSuccess, isFalse);
      expect(result.statusCode, 403);
    });

    test('mengembalikan invalidToken jika API Telegram menjawab 401 Unauthorized', () async {
      TelegramService.client = MockHttpClient(
        statusCode: 401,
        body: '{"ok": false, "error_code": 401, "description": "Unauthorized"}',
      );

      final result = await TelegramService.sendAutomatedMessage(
        chatId: '1227447571',
        message: 'Pengingat garansi aktif',
        botToken: '123456:INVALID_TOKEN',
      );

      expect(result.status, TelegramSendStatus.invalidToken);
      expect(result.isSuccess, isFalse);
    });

    test('mengembalikan networkError jika koneksi HTTP gagal', () async {
      TelegramService.client = ThrowingHttpClient();

      final result = await TelegramService.sendAutomatedMessage(
        chatId: '1227447571',
        message: 'Pengingat garansi aktif',
        botToken: '123456:VALID_TOKEN',
      );

      expect(result.status, TelegramSendStatus.networkError);
      expect(result.isSuccess, isFalse);
    });
  });
}
