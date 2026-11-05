import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

/// URL WhatsApp resmi Customer Service SimpanNota
const String kCustomerServiceWaUrl = 'https://wa.me/6285781740989';

/// Helper untuk membuka tautan WhatsApp Customer Service
Future<void> openCustomerService(BuildContext context) async {
  final uri = Uri.parse(kCustomerServiceWaUrl);
  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Tidak dapat membuka WhatsApp. Silakan hubungi 0857-8174-0989 secara langsung.'),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              Expanded(
                child: Text('Gagal membuka WhatsApp: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

/// Widget Tombol "Butuh Bantuan?" dengan logo CS resmi
class CustomerServiceButton extends StatelessWidget {
  final bool isFloating;

  const CustomerServiceButton({
    super.key,
    this.isFloating = false,
  });

  /// Varian tombol melayang (Floating) untuk Dashboard:
  /// Menggunakan FloatingActionButton.extended agar ukurannya, radiusnya,
  /// dan tingginya 100% presisi dan sejajar dengan tombol "Tambah Nota"
  const CustomerServiceButton.floating({
    super.key,
  }) : isFloating = true;

  @override
  Widget build(BuildContext context) {
    if (isFloating) {
      return Semantics(
        button: true,
        label: 'Tombol customer service WhatsApp: Butuh Bantuan?',
        hint: 'Ketuk untuk langsung menghubungi customer service via WhatsApp',
        child: FloatingActionButton.extended(
          heroTag: 'customer_service_fab',
          elevation: 4,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppColors.primaryBlue.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          onPressed: () => openCustomerService(context),
          icon: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/cs_logo.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/cs_logo.jpg',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.support_agent_rounded,
                    size: 24,
                    color: AppColors.primaryBlue,
                  ),
                );
              },
            ),
          ),
          label: const Text(
            'Butuh Bantuan?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
              letterSpacing: -0.1,
            ),
          ),
        ),
      );
    }

    // Varian biasa untuk halaman Login / Register
    return Semantics(
      button: true,
      label: 'Tombol customer service WhatsApp: Butuh Bantuan?',
      hint: 'Ketuk untuk langsung menghubungi customer service via WhatsApp',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openCustomerService(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.25),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/cs_logo.png',
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/cs_logo.jpg',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.support_agent_rounded,
                          size: 22,
                          color: AppColors.primaryBlue,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Butuh Bantuan?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
