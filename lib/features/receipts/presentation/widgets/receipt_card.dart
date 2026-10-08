import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/warranty_status.dart';

import '../../domain/receipt.dart';

class ReceiptCard extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback onTap;

  const ReceiptCard({super.key, required this.receipt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      receipt.storeName,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(receipt.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        receipt.status.label,
                        style: TextStyle(
                          color: _getStatusColor(receipt.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
}
