import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/navigation/fade_page_route.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../domain/warranty_status.dart';
import '../../domain/receipt.dart';

import 'package:gal/gal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/telegram_service.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/services/profile_repository.dart';
import '../controllers/receipt_list_notifier.dart';
import 'add_receipt_screen.dart';

class ReceiptDetailScreen extends ConsumerStatefulWidget {
  final Receipt receipt;

  const ReceiptDetailScreen({super.key, required this.receipt});

  @override
  ConsumerState<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends ConsumerState<ReceiptDetailScreen> {
  int _selectedImageIndex = 0; // 0: Foto Nota, 1: Foto Kartu Garansi

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sinkronisasi data nota jika baru saja diedit
    final receipt = ref.watch(receiptListProvider).maybeWhen(
      data: (list) => list.firstWhere(
        (r) => r.id == widget.receipt.id,
        orElse: () => widget.receipt,
      ),
      orElse: () => widget.receipt,
    );

    final hasWarrantyCard = receipt.warrantyCardPath != null &&
        receipt.warrantyCardPath!.trim().isNotEmpty;
    final activeIndex = hasWarrantyCard ? _selectedImageIndex : 0;
    final currentImagePath =
        activeIndex == 0 ? receipt.imagePath : receipt.warrantyCardPath!;
    final isCurrentWarrantyCard = activeIndex == 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detail Nota'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          Semantics(
            button: true,
            label: 'Ubah nota',
            hint: 'Ketuk untuk mengedit data nota ini',
            child: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  FadePageRoute(
                    page: AddReceiptScreen(receiptToEdit: receipt),
                  ),
                );
              },
            ),
          ),
          Semantics(
            button: true,
            label: 'Hapus nota',
            hint: 'Ketuk untuk menghapus nota ini dari sistem',
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Nota?'),
                    content: const Text(
                      'Apakah Anda yakin ingin menghapus nota ini?',
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    actions: [
                      Semantics(
                        button: true,
                        label: 'Batal hapus',
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Konfirmasi hapus',
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Hapus'),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true && receipt.id != null) {
                  ref
                      .read(receiptListProvider.notifier)
                      .deleteReceipt(receipt.id!);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(child: Text('${receipt.productName} berhasil dihapus')),
                          ],
                        ),
                        backgroundColor: Colors.black87,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 260,
              color: Colors.grey.shade900,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      key: ValueKey(currentImagePath),
                      child: Center(
                        child: currentImagePath.startsWith('http')
                            ? Image.network(
                                currentImagePath,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.broken_image,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                              )
                            : Image.file(
                                File(currentImagePath),
                                fit: BoxFit.contain,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.broken_image,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                  ),

                  // Pill Toggle Selector jika memiliki 2 lampiran (Foto Nota & Kartu Garansi Fisik)
                  if (hasWarrantyCard)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _selectedImageIndex = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: activeIndex == 0 ? AppColors.primaryBlue : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_rounded,
                                        size: 14,
                                        color: activeIndex == 0 ? Colors.white : Colors.white70,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Foto Nota',
                                        style: TextStyle(
                                          color: activeIndex == 0 ? Colors.white : Colors.white70,
                                          fontSize: 12,
                                          fontWeight: activeIndex == 0 ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _selectedImageIndex = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: activeIndex == 1 ? AppColors.primaryBlue : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified_user_rounded,
                                        size: 14,
                                        color: activeIndex == 1 ? Colors.white : Colors.white70,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Kartu Garansi',
                                        style: TextStyle(
                                          color: activeIndex == 1 ? Colors.white : Colors.white70,
                                          fontSize: 12,
                                          fontWeight: activeIndex == 1 ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Tombol Download ke Galeri
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Semantics(
                        button: true,
                        label: 'Unduh foto ke galeri',
                        hint: 'Ketuk untuk menyimpan foto ke galeri foto perangkat',
                        child: IconButton(
                          icon: const Icon(Icons.download, color: Colors.white),
                          onPressed: () async {
                            try {
                              final hasAccess = await Gal.hasAccess();
                              if (!hasAccess) {
                                await Gal.requestAccess();
                              }

                              await Gal.putImage(currentImagePath);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text(isCurrentWarrantyCard
                                            ? 'Foto kartu garansi berhasil disimpan ke Galeri!'
                                            : 'Foto nota berhasil disimpan ke Galeri!'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text('Gagal menyimpan foto: $e')),
                                      ],
                                    ),
                                    backgroundColor: Colors.red.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.productName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Icon(Icons.storefront_outlined, color: AppColors.textGrey, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          receipt.storeName,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? const Color(0xFFCBD5E1) : AppColors.textBody,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(receipt.status, isDark: isDark),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(receipt.status).withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _getStatusColor(receipt.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          receipt.status.label,
                          style: TextStyle(
                            color: _getStatusColor(receipt.status),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Detail card dengan styling premium
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withValues(alpha: 0.25) : AppColors.shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(context, 'Kategori', receipt.category.label),
                        Divider(height: 20, color: isDark ? const Color(0xFF334155) : AppColors.cardBorder),
                        _buildDetailRow(
                          context,
                          'Tanggal Beli',
                          DateFormat(
                            'dd MMMM yyyy',
                            'id_ID',
                          ).format(receipt.purchaseDate),
                        ),
                        Divider(height: 20, color: isDark ? const Color(0xFF334155) : AppColors.cardBorder),
                        _buildDetailRow(
                          context,
                          'Durasi Garansi',
                          receipt.warrantyDurationLabel,
                        ),
                        Divider(height: 20, color: isDark ? const Color(0xFF334155) : AppColors.cardBorder),
                        _buildDetailRow(
                          context,
                          'Tanggal Kedaluwarsa',
                          DateFormat('dd MMMM yyyy', 'id_ID').format(
                            receipt.expirationDate,
                          ),
                        ),
                        Divider(height: 20, color: isDark ? const Color(0xFF334155) : AppColors.cardBorder),
                        _buildDetailRow(
                          context,
                          'Kartu Garansi Fisik',
                          hasWarrantyCard ? 'Terlampir (Ketuk tab di atas)' : 'Tidak Ada',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Task 5: Kartu Pengingat Garansi Telegram Otomatis
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F2B48) : const Color(0xFFE8F5FD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF1E4976) : const Color(0xFFBCE1F9)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0088CC).withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0088CC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pengingat Garansi Telegram (Otomatis)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF006699),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Kirim rincian masa aktif garansi langsung ke akun Telegram Anda secara otomatis.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textGrey,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Semantics(
                          button: true,
                          label: 'Kirim Pengingat Otomatis ke Telegram',
                          hint: 'Mengirimkan rincian masa aktif garansi langsung ke akun Telegram Anda',
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => _sendTelegramReminder(context, receipt),
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: const Text(
                                'Kirim Pengingat Otomatis',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0088CC),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTelegramReminder(BuildContext context, Receipt receipt) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileRepo = ref.read(profileRepositoryProvider);
    final profile = await profileRepo.fetchProfile();
    final userName = profile.displayName;
    final chatId = profile.telegramChatId?.trim();
    final botToken = (profile.telegramBotToken != null && profile.telegramBotToken!.trim().isNotEmpty)
        ? profile.telegramBotToken!.trim()
        : SupabaseConstants.telegramBotToken.trim();

    final message = TelegramService.formatWarrantyReminderMessage(
      receipt: receipt,
      userName: userName,
    );

    // Kasus 1: User belum mengisi Telegram Chat ID di profil
    if (chatId == null || chatId.isEmpty) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF0088CC), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Telegram Chat ID Belum Diatur',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Untuk dapat mengirim pengingat secara otomatis langsung ke Telegram Anda, silakan hubungkan Telegram Chat ID Anda di menu Profil Saya.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? const Color(0xFFCBD5E1) : AppColors.textGrey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                _launchManualTelegram(context, message, receipt.productName);
              },
              child: Text(
                'Kirim Manual Saja',
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : AppColors.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.push(
                  context,
                  FadePageRoute(page: const ProfileScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0088CC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Atur di Profil'),
            ),
          ],
        ),
      );
      return;
    }

    // Kasus 2: Chat ID ada, dan Bot Token tersedia -> Kirim 100% Otomatis!
    if (botToken.isNotEmpty) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Mengirim pengingat otomatis ke Telegram...',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      final result = await TelegramService.sendAutomatedMessage(
        chatId: chatId,
        message: message,
        botToken: botToken,
      );

      if (context.mounted) {
        Navigator.pop(context); // Tutup progress dialog
      }

      if (result.isSuccess) {
        if (context.mounted) {
          AppSnackBar.showSuccess(
            context,
            'Pengingat garansi otomatis terkirim langsung ke akun Telegram Anda!',
          );
        }
        return;
      }

      // Jika user belum tekan /start pada bot (Error 403)
      if (result.status == TelegramSendStatus.userNotStarted) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aktifkan Bot Telegram Anda',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'Telegram mengharuskan Anda menekan "Mulai / Start" pada bot sekali saja agar bot diizinkan mengirimkan pesan otomatis ke akun Anda.\n\nSilakan buka bot Anda di Telegram, ketuk Mulai, lalu coba kirim kembali.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? const Color(0xFFCBD5E1) : AppColors.textGrey,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  _launchManualTelegram(context, message, receipt.productName);
                },
                child: Text(
                  'Kirim Manual',
                  style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : AppColors.textGrey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0088CC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        );
        return;
      }

      // Jika ada error lain saat kirim otomatis
      if (context.mounted) {
        AppSnackBar.showError(
          context,
          'Gagal mengirim otomatis: ${result.message}',
        );
        _launchManualTelegram(context, message, receipt.productName);
      }
      return;
    }

    // Kasus 3: Chat ID ada, tapi Bot Token belum terisi
    if (!context.mounted) return;
    _showBotConfigOrManualDialog(
      context: context,
      chatId: chatId,
      message: message,
      productName: receipt.productName,
      isDark: isDark,
    );
  }

  void _showBotConfigOrManualDialog({
    required BuildContext context,
    required String chatId,
    required String message,
    required String productName,
    required bool isDark,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F2B48) : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.send_rounded, color: Color(0xFF0088CC), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pengingat Telegram',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Telegram Chat ID Anda ($chatId) sudah terhubung.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih metode pengiriman yang Anda inginkan:',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFFCBD5E1) : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : AppColors.cardBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '100% Otomatis (via Bot)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pesan langsung masuk ke Telegram tanpa perlu memilih atau meneruskan kontak secara manual.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textGrey,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _launchManualTelegram(context, message, productName);
            },
            child: Text(
              'Kirim Manual (Buka Aplikasi)',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textGrey,
                fontSize: 12,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _promptInputBotToken(context, chatId, message, productName);
            },
            icon: const Icon(Icons.smart_toy_outlined, size: 16),
            label: const Text('Aktifkan Otomatis'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0088CC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _promptInputBotToken(
    BuildContext context,
    String chatId,
    String message,
    String productName,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokenController = TextEditingController();
    bool isSaving = false;
    String? localError;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F2B48) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.smart_toy_outlined, color: Color(0xFF0088CC), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Masukkan Bot Token',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dapatkan token bot dari @BotFather di Telegram (kirim /newbot lalu salin HTTP API Token yang diberikan).',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFCBD5E1) : AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse('https://t.me/BotFather');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new, size: 14, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                      const SizedBox(width: 6),
                      Text(
                        'Buka @BotFather di Telegram',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tokenController,
                  enabled: !isSaving,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Contoh: 123456789:ABCdefGhIJKlmNo...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF0088CC)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.cardBorder),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFF0088CC), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                if (localError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      localError!,
                      style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
              child: Text(
                'Batal',
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : AppColors.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final token = tokenController.text.trim();
                      if (token.isEmpty) {
                        setDialogState(() => localError = 'Token tidak boleh kosong.');
                        return;
                      }
                      setDialogState(() {
                        isSaving = true;
                        localError = null;
                      });
                      try {
                        final currentProfile = ref.read(profileRepositoryProvider).getCurrentProfile();
                        await ref.read(profileRepositoryProvider).updateProfile(
                              displayName: currentProfile.displayName,
                              phone: currentProfile.phone,
                              telegramChatId: chatId,
                              telegramBotToken: token,
                            );
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (context.mounted) {
                          AppSnackBar.showSuccess(
                            context,
                            'Bot Token tersimpan! Mengirim pesan otomatis...',
                          );
                          // Langsung kirim pesan otomatis
                          final result = await TelegramService.sendAutomatedMessage(
                            chatId: chatId,
                            message: message,
                            botToken: token,
                          );
                          if (result.isSuccess && context.mounted) {
                            AppSnackBar.showSuccess(
                              context,
                              'Pengingat garansi otomatis berhasil terkirim langsung ke akun Telegram Anda!',
                            );
                          } else if (result.status == TelegramSendStatus.userNotStarted && context.mounted) {
                            AppSnackBar.showInfo(
                              context,
                              'Buka bot Anda di Telegram lalu klik Mulai/Start sekali saja agar pesan dapat masuk.',
                            );
                          }
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSaving = false;
                          localError = 'Gagal menyimpan: $e';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0088CC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Simpan & Kirim'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchManualTelegram(
    BuildContext context,
    String message,
    String productName,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tgSchemeUri = Uri.parse('tg://resolve');
    final isInstalled = await canLaunchUrl(tgSchemeUri);

    if (!isInstalled) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFF0088CC), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Telegram Belum Terpasang',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Aplikasi Telegram dibutuhkan untuk mengirim dan menerima pengingat garansi. Silakan unduh Telegram melalui Google Play Store.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDark ? const Color(0xFFCBD5E1) : AppColors.textGrey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Batal',
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : AppColors.textGrey),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final playStoreUri = Uri.parse(
                  'https://play.google.com/store/apps/details?id=org.telegram.messenger',
                );
                if (await canLaunchUrl(playStoreUri)) {
                  await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download Telegram'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0088CC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final encoded = Uri.encodeComponent(message);
    final tgMsgUri = Uri.parse('tg://msg?text=$encoded');
    final tgWebUri = Uri.parse('https://t.me/share/url?url=&text=$encoded');

    try {
      AppLogger.info('TELEGRAM', 'Membuka aplikasi Telegram untuk pesan pengingat: $productName');
      if (await canLaunchUrl(tgMsgUri)) {
        await launchUrl(tgMsgUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(tgWebUri, mode: LaunchMode.externalApplication);
      }
    } catch (e, stack) {
      AppLogger.error('TELEGRAM', 'Gagal meluncurkan Telegram: $e', e, stack);
      if (context.mounted) {
        AppSnackBar.showError(context, 'Tidak dapat membuka Telegram: $e');
      }
    }
  }

  Color _getStatusColor(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.active:
        return AppColors.statusActive;
      case WarrantyStatus.expiringSoon:
        return AppColors.statusExpiring;
      case WarrantyStatus.expired:
        return AppColors.statusExpired;
    }
  }

  Color _getStatusBgColor(WarrantyStatus status, {bool isDark = false}) {
    if (isDark) {
      return _getStatusColor(status).withValues(alpha: 0.16);
    }
    switch (status) {
      case WarrantyStatus.active:
        return AppColors.statusActiveBg;
      case WarrantyStatus.expiringSoon:
        return AppColors.statusExpiringBg;
      case WarrantyStatus.expired:
        return AppColors.statusExpiredBg;
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textGrey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
