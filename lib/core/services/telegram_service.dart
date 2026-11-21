import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../constants/supabase_constants.dart';
import '../../features/receipts/domain/receipt.dart';
import 'app_logger.dart';

/// Status hasil pengiriman notifikasi Telegram
enum TelegramSendStatus {
  success,
  noToken,
  userNotStarted,
  chatNotFound,
  invalidToken,
  networkError,
  error,
}

/// Hasil eksekusi pengiriman pesan otomatis ke Telegram API
class TelegramSendResult {
  final TelegramSendStatus status;
  final String message;
  final int? statusCode;

  const TelegramSendResult({
    required this.status,
    required this.message,
    this.statusCode,
  });

  bool get isSuccess => status == TelegramSendStatus.success;
}

/// Layanan komunikasi langsung dengan Telegram Bot API
class TelegramService {
  TelegramService._();

  static http.Client client = http.Client();

  /// Menghasilkan format pesan pengingat garansi rapi untuk Telegram (Markdown)
  static String formatWarrantyReminderMessage({
    required Receipt receipt,
    required String userName,
  }) {
    final expiredDate = receipt.expirationDate;
    final daysLeft = expiredDate.difference(DateTime.now()).inDays;
    final formattedBuyDate =
        DateFormat('dd MMMM yyyy', 'id_ID').format(receipt.purchaseDate);
    final formattedExpDate =
        DateFormat('dd MMMM yyyy', 'id_ID').format(expiredDate);

    String statusText;
    if (daysLeft < 0) {
      statusText = '❌ KEDALUWARSA (Telah berakhir ${-daysLeft} hari lalu)';
    } else if (daysLeft <= 30) {
      statusText = '⚠️ SEGERA BERAKHIR ($daysLeft hari lagi tersisa!)';
    } else {
      statusText = '✅ AKTIF ($daysLeft hari lagi tersisa)';
    }

    return '''
🔔 *PENGINGAT MASA GARANSI SIMPANNOTA*

Halo *$userName*,
Berikut adalah pengingat otomatis status masa garansi barang Anda:

📦 *Barang:* ${receipt.productName}
🏪 *Toko:* ${receipt.storeName}
🏷️ *Kategori:* ${receipt.category.label}
📅 *Tanggal Beli:* $formattedBuyDate
⏳ *Durasi Garansi:* ${receipt.warrantyDurationLabel}
🛑 *Jatuh Tempo:* $formattedExpDate
📊 *Status Garansi:* $statusText

_Pesan ini dikirimkan otomatis oleh sistem SimpanNota langsung ke akun Telegram Anda._'''
        .trim();
  }

  /// Mengirim pesan secara otomatis melalui Telegram Bot API
  static Future<TelegramSendResult> sendAutomatedMessage({
    required String chatId,
    required String message,
    String? botToken,
  }) async {
    final token = (botToken != null && botToken.trim().isNotEmpty)
        ? botToken.trim()
        : SupabaseConstants.telegramBotToken.trim();

    if (token.isEmpty) {
      AppLogger.warning('TELEGRAM', 'Telegram Bot Token belum dikonfigurasi.');
      return const TelegramSendResult(
        status: TelegramSendStatus.noToken,
        message: 'Bot Token belum dikonfigurasi. Silakan masukkan Bot Token.',
      );
    }

    final trimmedChatId = chatId.trim();
    if (trimmedChatId.isEmpty) {
      AppLogger.warning('TELEGRAM', 'Chat ID Telegram kosong.');
      return const TelegramSendResult(
        status: TelegramSendStatus.chatNotFound,
        message: 'Telegram Chat ID kosong. Silakan atur Chat ID di profil.',
      );
    }

    final url = Uri.parse('https://api.telegram.org/bot$token/sendMessage');

    try {
      AppLogger.info('TELEGRAM', 'Mengirim pesan otomatis ke Telegram Chat ID: $trimmedChatId');

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': trimmedChatId,
          'text': message,
          'parse_mode': 'Markdown',
        }),
      );

      final statusCode = response.statusCode;
      final body = response.body;

      if (statusCode == 200) {
        AppLogger.info('TELEGRAM', 'Pesan pengingat berhasil terkirim ke Telegram ($trimmedChatId)');
        return const TelegramSendResult(
          status: TelegramSendStatus.success,
          message: 'Pesan pengingat berhasil dikirim langsung ke Telegram Anda!',
          statusCode: 200,
        );
      }

      AppLogger.warning('TELEGRAM', 'Gagal mengirim pesan Telegram ($statusCode): $body');

      if (statusCode == 403) {
        return const TelegramSendResult(
          status: TelegramSendStatus.userNotStarted,
          message:
              'Bot belum dapat mengirim pesan. Silakan buka bot Anda di Telegram dan ketuk "Mulai / Start" sekali, lalu coba lagi.',
          statusCode: 403,
        );
      } else if (statusCode == 400) {
        return TelegramSendResult(
          status: TelegramSendStatus.chatNotFound,
          message: 'Chat ID "$trimmedChatId" tidak ditemukan atau belum pernah berinteraksi dengan bot.',
          statusCode: 400,
        );
      } else if (statusCode == 401) {
        return const TelegramSendResult(
          status: TelegramSendStatus.invalidToken,
          message: 'Bot Token tidak valid. Periksa kembali token dari @BotFather.',
          statusCode: 401,
        );
      } else {
        return TelegramSendResult(
          status: TelegramSendStatus.error,
          message: 'Telegram API Error ($statusCode): $body',
          statusCode: statusCode,
        );
      }
    } catch (e, stack) {
      AppLogger.error('TELEGRAM', 'Kesalahan jaringan saat mengirim pesan Telegram: $e', e, stack);
      return TelegramSendResult(
        status: TelegramSendStatus.networkError,
        message: 'Gagal terhubung ke Telegram Bot API: $e',
      );
    }
  }
}
