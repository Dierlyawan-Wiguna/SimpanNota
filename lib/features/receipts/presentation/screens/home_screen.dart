import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/category_chips.dart';
import '../widgets/receipt_card.dart';
import 'add_receipt_screen.dart';
import 'receipt_detail_screen.dart';
import '../../../auth/presentation/screens/auth_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/receipt_list_notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptListState = ref.watch(filteredReceiptListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SimpanNota'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari barang atau toko...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).update(value);
              },
            ),
          ),
          const CategoryChips(),
          const SizedBox(height: 8),
          Expanded(
            child: receiptListState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (receipts) {
                if (receipts.isEmpty) {
                  return const Center(child: Text('Belum ada nota tersimpan.'));
                }
                return ListView.builder(
                  itemCount: receipts.length,
                  itemBuilder: (context, index) {
                    final receipt = receipts[index];
                    return Dismissible(
                      key: ValueKey(receipt.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        if (receipt.id != null) {
                          ref.read(receiptListProvider.notifier).deleteReceipt(receipt.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${receipt.productName} dihapus')),
                          );
                        }
                      },
                      child: ReceiptCard(
                        receipt: receipt,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReceiptDetailScreen(receipt: receipt),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddReceiptScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
