import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/navigation/fade_page_route.dart';
import '../../../../core/widgets/customer_service_button.dart';
import '../widgets/category_chips.dart';
import '../widgets/receipt_card.dart';
import 'add_receipt_screen.dart';
import 'receipt_detail_screen.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../controllers/receipt_list_notifier.dart';
import '../../domain/receipt.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun SimpanNota?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        actions: [
          Semantics(
            button: true,
            label: 'Batal keluar akun',
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
          ),
          Semantics(
            button: true,
            label: 'Konfirmasi keluar akun',
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Keluar'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      if (SupabaseConstants.isConfigured) {
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (_) {}
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Anda telah berhasil keluar.'),
              ],
            ),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          FadePageRoute(page: const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildDismissibleReceipt(
    BuildContext context,
    WidgetRef ref,
    Receipt receipt, {
    required bool isGrid,
  }) {
    return Dismissible(
      key: ValueKey(receipt.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: isGrid ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.statusExpired,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        if (receipt.id != null) {
          ref.read(receiptListProvider.notifier).deleteReceipt(receipt.id!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.delete_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${receipt.productName} berhasil dihapus')),
                ],
              ),
              backgroundColor: AppColors.primaryNavy,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: ReceiptCard(
        receipt: receipt,
        margin: isGrid ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            FadePageRoute(
              page: ReceiptDetailScreen(receipt: receipt),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptListState = ref.watch(filteredReceiptListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SimpanNota',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            Text(
              'Daftar Nota & Dokumen Garansi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Semantics(
            label: 'Profil Pengguna',
            hint: 'Ketuk untuk melihat informasi profil akun',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.account_circle_outlined, size: 28),
              tooltip: 'Profil Saya',
              onPressed: () {
                Navigator.push(
                  context,
                  FadePageRoute(page: const ProfileScreen()),
                );
              },
            ),
          ),
          Semantics(
            label: 'Tombol keluar akun',
            hint: 'Ketuk untuk keluar dari akun SimpanNota',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Keluar',
              onPressed: () => _confirmSignOut(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 10.0),
            child: Semantics(
              label: 'Kolom pencarian nota',
              hint: 'Ketik nama barang atau toko untuk memfilter daftar nota',
              textField: true,
              child: Container(
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
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Cari barang atau toko...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.textGrey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).update(value);
                  },
                ),
              ),
            ),
          ),
          const CategoryChips(),
          const SizedBox(height: 8),
          Expanded(
            child: receiptListState.when(
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Memuat data nota...',
                      style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.statusExpired,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.statusExpired),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      button: true,
                      label: 'Tombol coba lagi',
                      hint: 'Ketuk untuk memuat ulang daftar nota',
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(receiptListProvider.notifier).loadReceipts();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ),
                  ],
                ),
              ),
              data: (receipts) {
                if (receipts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            size: 54,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum Ada Nota Tersimpan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ketuk tombol (+) di bawah untuk mulai menambah nota.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                // Layout Adaptif: Gunakan LayoutBuilder.
                // Jika lebar layar besar (tablet/landscape >= 600px), tampilkan Grid.
                // Jika lebar layar kecil (HP < 600px), gunakan List biasa.
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideScreen = constraints.maxWidth >= 600;

                    if (isWideScreen) {
                      final crossAxisCount = constraints.maxWidth >= 900 ? 3 : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 3.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: receipts.length,
                        itemBuilder: (context, index) {
                          final receipt = receipts[index];
                          return _buildDismissibleReceipt(context, ref, receipt, isGrid: true);
                        },
                      );
                    } else {
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: receipts.length,
                        itemBuilder: (context, index) {
                          final receipt = receipts[index];
                          return _buildDismissibleReceipt(context, ref, receipt, isGrid: false);
                        },
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Pojok Kiri: Tombol Customer Service "Butuh Bantuan?"
            const CustomerServiceButton.floating(),

            // Pojok Kanan: Tombol Tambah Nota
            Semantics(
              label: 'Tombol tambah nota',
              hint: 'Ketuk untuk membuka formulir penambahan nota baru',
              button: true,
              child: FloatingActionButton.extended(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onPressed: () {
                  Navigator.push(
                    context,
                    FadePageRoute(page: const AddReceiptScreen()),
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Tambah Nota',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
