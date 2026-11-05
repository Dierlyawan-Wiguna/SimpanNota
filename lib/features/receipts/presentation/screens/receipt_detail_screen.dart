import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/navigation/fade_page_route.dart';
import '../../domain/warranty_status.dart';
import '../../domain/receipt.dart';

import 'package:gal/gal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/receipt_list_notifier.dart';
import 'add_receipt_screen.dart';

class ReceiptDetailScreen extends ConsumerWidget {
  final Receipt receipt;

  const ReceiptDetailScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
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
              height: 250,
              color: Colors.grey.shade300,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      child: Center(
                        child: receipt.imagePath.startsWith('http')
                            ? Image.network(
                                receipt.imagePath,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.broken_image,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                              )
                            : Image.file(
                                File(receipt.imagePath),
                                fit: BoxFit.cover,
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
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Semantics(
                        button: true,
                        label: 'Unduh foto nota ke galeri',
                        hint: 'Ketuk untuk menyimpan file foto nota ke galeri foto perangkat',
                        child: IconButton(
                          icon: const Icon(Icons.download, color: Colors.white),
                          onPressed: () async {
                            try {
                              final hasAccess = await Gal.hasAccess();
                              if (!hasAccess) {
                                await Gal.requestAccess();
                              }

                              await Gal.putImage(receipt.imagePath);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Foto berhasil disimpan ke Galeri!'),
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
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
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
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textBody,
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
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
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
                        _buildDetailRow('Kategori', receipt.category.label),
                        const Divider(height: 20, color: AppColors.cardBorder),
                        _buildDetailRow(
                          'Tanggal Beli',
                          DateFormat(
                            'dd MMMM yyyy',
                            'id_ID',
                          ).format(receipt.purchaseDate),
                        ),
                        const Divider(height: 20, color: AppColors.cardBorder),
                        _buildDetailRow(
                          'Durasi Garansi',
                          '${receipt.warrantyMonths} Bulan',
                        ),
                        const Divider(height: 20, color: AppColors.cardBorder),
                        _buildDetailRow(
                          'Tanggal Kedaluwarsa',
                          DateFormat('dd MMMM yyyy', 'id_ID').format(
                            receipt.purchaseDate.add(
                              Duration(days: receipt.warrantyMonths * 30),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
