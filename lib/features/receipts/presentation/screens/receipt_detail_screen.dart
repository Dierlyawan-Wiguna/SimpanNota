import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/warranty_status.dart';

class ReceiptDetailScreen extends StatelessWidget {
  const ReceiptDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Nota'),
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Delete action mock
              Navigator.pop(context);
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
              child: InteractiveViewer(
                child: const Center(
                  child: Icon(Icons.image, size: 100, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laptop Asus ROG',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.store, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Text('Tokopedia', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.statusActive.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      WarrantyStatus.active.label,
                      style: const TextStyle(
                        color: AppColors.statusActive,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  _buildDetailRow('Kategori', 'Elektronik'),
                  _buildDetailRow('Tanggal Beli', '01 Oktober 2026'),
                  _buildDetailRow('Durasi Garansi', '12 Bulan'),
                  _buildDetailRow('Tanggal Kedaluwarsa', '01 Oktober 2027'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
