import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/receipt.dart';
import '../../services/receipt_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/category.dart';

enum ReceiptSortOption {
  newest('Tanggal Beli (Terbaru)', Icons.calendar_today_rounded),
  expiringSoon('Garansi Segera Habis', Icons.hourglass_bottom_rounded),
  oldest('Tanggal Beli (Terlama)', Icons.history_rounded),
  alphabetical('Nama Barang (A - Z)', Icons.sort_by_alpha_rounded);

  final String label;
  final IconData icon;
  const ReceiptSortOption(this.label, this.icon);
}

class SortOptionNotifier extends Notifier<ReceiptSortOption> {
  @override
  ReceiptSortOption build() => ReceiptSortOption.newest;
  
  void select(ReceiptSortOption option) => state = option;
}
final sortOptionProvider = NotifierProvider<SortOptionNotifier, ReceiptSortOption>(SortOptionNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  
  void update(String query) => state = query;
}
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SelectedCategoryNotifier extends Notifier<Category?> {
  @override
  Category? build() => null;
  
  void select(Category? category) => state = category;
}
final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, Category?>(SelectedCategoryNotifier.new);

final receiptListProvider = AsyncNotifierProvider<ReceiptListNotifier, List<Receipt>>(() {
  return ReceiptListNotifier();
});

final filteredReceiptListProvider = Provider<AsyncValue<List<Receipt>>>((ref) {
  final receiptsState = ref.watch(receiptListProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final sortOption = ref.watch(sortOptionProvider);

  return receiptsState.whenData((receipts) {
    var filtered = receipts.where((receipt) {
      final matchesQuery = receipt.productName.toLowerCase().contains(searchQuery) ||
                           receipt.storeName.toLowerCase().contains(searchQuery);
      final matchesCategory = selectedCategory == null || receipt.category == selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    switch (sortOption) {
      case ReceiptSortOption.expiringSoon:
        filtered.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
        break;
      case ReceiptSortOption.newest:
        filtered.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
        break;
      case ReceiptSortOption.oldest:
        filtered.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
        break;
      case ReceiptSortOption.alphabetical:
        filtered.sort((a, b) => a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));
        break;
    }

    return filtered;
  });
});

class ReceiptListNotifier extends AsyncNotifier<List<Receipt>> {
  @override
  Future<List<Receipt>> build() async {
    return _fetchReceipts();
  }

  Future<List<Receipt>> _fetchReceipts() async {
    final repository = ref.read(receiptRepositoryProvider);
    return await repository.getReceipts();
  }

  Future<void> loadReceipts() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchReceipts());
  }

  Future<void> deleteReceipt(int id) async {
    try {
      final repository = ref.read(receiptRepositoryProvider);
      await repository.deleteReceipt(id);
      await NotificationService().cancelNotification(id);
      await loadReceipts(); // refresh list
    } catch (e) {
      // Handle error visually if necessary
    }
  }
}
