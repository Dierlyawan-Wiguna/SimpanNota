import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/warranty_status.dart';
import '../../domain/receipt.dart';

/// Kartu nota bergaya modern, premium, dengan rounded radius dan shadow halus
class ReceiptCard extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;

  const ReceiptCard({
    super.key,
    required this.receipt,
    required this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(receipt.status);
    final statusBg = _getStatusBgColor(receipt.status);

    return Semantics(
      label: 'Nota untuk ${receipt.productName}, toko ${receipt.storeName}, masa garansi ${receipt.warrantyMonths} bulan, status ${receipt.status.label}',
      hint: 'Ketuk untuk melihat detail nota dan dokumen klaim garansi',
      button: true,
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.shadowColorMedium,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                children: [
                  // Icon badge dengan rounded corners dan background warna status halus
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: statusColor,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Detail Informasi Nota
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          receipt.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textDark,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront_outlined,
                              size: 13,
                              color: AppColors.textGrey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                receipt.storeName,
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Status Badge berbentuk Pill yang elegan
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                receipt.status.label,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chevron indicator
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
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
}
