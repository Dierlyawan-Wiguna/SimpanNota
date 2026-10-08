import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/receipt.dart';
import '../../services/receipt_repository.dart';

import '../../domain/category.dart';

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

  return receiptsState.whenData((receipts) {
    return receipts.where((receipt) {
      final matchesQuery = receipt.productName.toLowerCase().contains(searchQuery) ||
                           receipt.storeName.toLowerCase().contains(searchQuery);
      final matchesCategory = selectedCategory == null || receipt.category == selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
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
      await loadReceipts(); // refresh list
    } catch (e) {
      // Handle error visually if necessary
    }
  }
}
