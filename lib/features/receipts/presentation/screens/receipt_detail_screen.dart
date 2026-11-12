import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/navigation/fade_page_route.dart';
import '../../domain/warranty_status.dart';
import '../../domain/receipt.dart';

import 'package:gal/gal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                      color: _getStatusBgColor(receipt.status),
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
                      color: Theme.of(context).cardTheme.color ?? AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : AppColors.cardBorder,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowColor,
                          blurRadius: 10,
                          offset: Offset(0, 2),
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

                  // Task 5: Kartu Pengingat Garansi WhatsApp Otomatis
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.08),
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
                                color: const Color(0xFF25D366),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pengingat Garansi WhatsApp',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF075E54),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Kirim rincian masa aktif garansi barang ini langsung ke WhatsApp.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _sendWhatsAppReminder(context, receipt),
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text(
                              'Kirim Pengingat ke WhatsApp',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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

  Future<void> _sendWhatsAppReminder(BuildContext context, Receipt receipt) async {
    String? userPhone;
    String userName = 'Pengguna SimpanNota';

    if (SupabaseConstants.isConfigured) {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final meta = user.userMetadata;
          final name = meta?['full_name'] ?? meta?['name'];
          if (name != null && name.toString().isNotEmpty) {
            userName = name.toString();
          }
          final phone = user.phone ?? meta?['phone'];
          if (phone != null && phone.toString().isNotEmpty) {
            userPhone = phone.toString().replaceAll(RegExp(r'[^0-9]'), '');
          }
        }
      } catch (_) {}
    }

    final expiredDate = receipt.expirationDate;
    final daysLeft = expiredDate.difference(DateTime.now()).inDays;
    final formattedBuyDate = DateFormat('dd MMMM yyyy', 'id_ID').format(receipt.purchaseDate);
    final formattedExpDate = DateFormat('dd MMMM yyyy', 'id_ID').format(expiredDate);

    String statusText;
    if (daysLeft < 0) {
      statusText = '❌ KEDALUWARSA (Telah berakhir ${-daysLeft} hari lalu)';
    } else if (daysLeft <= 30) {
      statusText = '⚠️ SEGERA BERAKHIR ($daysLeft hari lagi tersisa!)';
    } else {
      statusText = '✅ AKTIF ($daysLeft hari lagi tersisa)';
    }

    final message = '''
🔔 *PENGINGAT MASA GARANSI SIMPANNOTA*

Halo *$userName*,
Berikut adalah pengingat status masa garansi barang Anda:

📦 *Barang:* ${receipt.productName}
🏪 *Toko:* ${receipt.storeName}
🏷️ *Kategori:* ${receipt.category.label}
📅 *Tanggal Beli:* $formattedBuyDate
⏳ *Durasi Garansi:* ${receipt.warrantyDurationLabel}
🛑 *Jatuh Tempo:* $formattedExpDate
📊 *Status Garansi:* $statusText

_Pesan ini dikirimkan otomatis melalui aplikasi SimpanNota untuk mengamankan bukti klaim garansi Anda._'''.trim();

    final encoded = Uri.encodeComponent(message);
    Uri waUri;

    if (userPhone != null && userPhone.isNotEmpty) {
      waUri = Uri.parse('https://wa.me/$userPhone?text=$encoded');
    } else {
      waUri = Uri.parse('https://api.whatsapp.com/send?text=$encoded');
    }

    try {
      final canLaunch = await canLaunchUrl(waUri);
      if (canLaunch) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(waUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka WhatsApp: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
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

  Color _getStatusBgColor(WarrantyStatus status) {
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
