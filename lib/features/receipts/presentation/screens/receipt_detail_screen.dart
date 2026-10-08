import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
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
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddReceiptScreen(receiptToEdit: receipt),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Nota?'),
                  content: const Text(
                    'Apakah Anda yakin ingin menghapus nota ini?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(color: Colors.red),
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
                    SnackBar(content: Text('${receipt.productName} dihapus')),
                  );
                }
              }
            },
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
                        child: Image.file(
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
                      child: IconButton(
                        icon: const Icon(Icons.download, color: Colors.white),
                        onPressed: () async {
                          try {
                            // Cek apakah punya akses untuk menyimpan ke Galeri
                            final hasAccess = await Gal.hasAccess();
                            if (!hasAccess) {
                              await Gal.requestAccess();
                            }

                            // Gunakan Gal.putImage untuk benar-benar menyimpannya ke Galeri Bawaan HP
                            await Gal.putImage(receipt.imagePath);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Foto berhasil disimpan ke Galeri!',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal menyimpan foto: $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.productName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.store, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        receipt.storeName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(receipt.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      receipt.status.label,
                      style: TextStyle(
                        color: _getStatusColor(receipt.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  _buildDetailRow('Kategori', receipt.category.label),
                  _buildDetailRow(
                    'Tanggal Beli',
                    DateFormat(
                      'dd MMMM yyyy',
                      'id_ID',
                    ).format(receipt.purchaseDate),
                  ),
                  _buildDetailRow(
                    'Durasi Garansi',
                    '${receipt.warrantyMonths} Bulan',
                  ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
