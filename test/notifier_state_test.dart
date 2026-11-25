import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpan_nota/features/receipts/domain/category.dart';
import 'package:simpan_nota/features/receipts/domain/receipt.dart';
import 'package:simpan_nota/features/receipts/presentation/controllers/add_receipt_notifier.dart';
import 'package:simpan_nota/features/receipts/presentation/controllers/receipt_list_notifier.dart';

void main() {
  group('SearchQueryNotifier Tests', () {
    test('initial state is empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialQuery = container.read(searchQueryProvider);
      expect(initialQuery, '');
    });

    test('update sets query string accurately', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(searchQueryProvider.notifier).update('Laptop');
      expect(container.read(searchQueryProvider), 'Laptop');
    });

    test('update handles multiple successive queries', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(searchQueryProvider.notifier);
      notifier.update('Asus');
      expect(container.read(searchQueryProvider), 'Asus');

      notifier.update('MacBook Pro');
      expect(container.read(searchQueryProvider), 'MacBook Pro');

      notifier.update('');
      expect(container.read(searchQueryProvider), '');
    });
  });

  group('SortOptionNotifier Tests', () {
    test('initial sort option is newest', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(sortOptionProvider), ReceiptSortOption.newest);
    });

    test('select updates to expiringSoon', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(sortOptionProvider.notifier).select(ReceiptSortOption.expiringSoon);
      expect(container.read(sortOptionProvider), ReceiptSortOption.expiringSoon);
    });

    test('select updates to oldest', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(sortOptionProvider.notifier).select(ReceiptSortOption.oldest);
      expect(container.read(sortOptionProvider), ReceiptSortOption.oldest);
    });

    test('select updates to alphabetical', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(sortOptionProvider.notifier).select(ReceiptSortOption.alphabetical);
      expect(container.read(sortOptionProvider), ReceiptSortOption.alphabetical);
    });

    test('ReceiptSortOption labels and icons are defined', () {
      for (final option in ReceiptSortOption.values) {
        expect(option.label.isNotEmpty, isTrue);
        expect(option.icon, isNotNull);
      }
    });
  });

  group('SelectedCategoryNotifier Tests', () {
    test('initial category selection is null (all)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedCategoryProvider), isNull);
    });

    test('select sets specific category', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedCategoryProvider.notifier).select(Category.elektronik);
      expect(container.read(selectedCategoryProvider), Category.elektronik);
    });

    test('select switches category to kendaraan', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(selectedCategoryProvider.notifier);
      notifier.select(Category.elektronik);
      notifier.select(Category.kendaraan);
      expect(container.read(selectedCategoryProvider), Category.kendaraan);
    });

    test('select null resets to all categories', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(selectedCategoryProvider.notifier);
      notifier.select(Category.pakaian);
      expect(container.read(selectedCategoryProvider), Category.pakaian);

      notifier.select(null);
      expect(container.read(selectedCategoryProvider), isNull);
    });
  });

  group('AddReceiptState Immutability & CopyWith Tests', () {
    test('initializes with default values', () {
      final state = AddReceiptState(
        categoriesState: const AsyncValue.loading(),
      );

      expect(state.isSubmitting, isFalse);
      expect(state.validationError, isNull);
      expect(state.categoriesState.isLoading, isTrue);
    });

    test('copyWith updates isSubmitting flag', () {
      final state = AddReceiptState(
        categoriesState: const AsyncValue.data([]),
      );

      final updated = state.copyWith(isSubmitting: true);
      expect(updated.isSubmitting, isTrue);
      expect(state.isSubmitting, isFalse);
    });

    test('copyWith updates validation error', () {
      final state = AddReceiptState(
        categoriesState: const AsyncValue.data([]),
      );

      final updated = state.copyWith(validationError: 'Nama barang wajib diisi');
      expect(updated.validationError, 'Nama barang wajib diisi');
    });

    test('copyWith clearValidationError clears previous error message', () {
      final state = AddReceiptState(
        categoriesState: const AsyncValue.data([]),
        validationError: 'Foto belum dipilih',
      );

      final cleared = state.copyWith(clearValidationError: true);
      expect(cleared.validationError, isNull);
    });

    test('copyWith preserves unchanged properties', () {
      final state = AddReceiptState(
        categoriesState: const AsyncValue.data([Category.elektronik]),
        isSubmitting: true,
        validationError: 'Ada kendala',
      );

      final copy = state.copyWith(isSubmitting: false);
      expect(copy.isSubmitting, isFalse);
      expect(copy.validationError, 'Ada kendala');
      expect(copy.categoriesState.value, [Category.elektronik]);
    });
  });

  group('FilteredReceiptListProvider Sorting & Filtering Logic', () {
    final r1 = Receipt(
      id: 1,
      productName: 'Apple iPhone 15',
      category: Category.elektronik,
      storeName: 'Digimap',
      purchaseDate: DateTime(2026, 1, 10),
      warrantyMonths: 12, // Exp: 2027-01-10
      warrantyDays: 0,
      imagePath: '/mock/1.jpg',
    );

    final r2 = Receipt(
      id: 2,
      productName: 'Samsung Galaxy S24',
      category: Category.elektronik,
      storeName: 'Samsung Store',
      purchaseDate: DateTime(2026, 3, 15),
      warrantyMonths: 6, // Exp: 2026-09-15
      warrantyDays: 0,
      imagePath: '/mock/2.jpg',
    );

    final r3 = Receipt(
      id: 3,
      productName: 'Jaket Motor Contin',
      category: Category.pakaian,
      storeName: 'Tokopedia',
      purchaseDate: DateTime(2026, 5, 1),
      warrantyMonths: 1, // Exp: 2026-06-01
      warrantyDays: 0,
      imagePath: '/mock/3.jpg',
    );

    final mockList = [r1, r2, r3];

    test('filters list by product name search query', () async {
      final container = ProviderContainer(
        overrides: [
          receiptListProvider.overrideWith(() => _MockReceiptListNotifier(mockList)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(receiptListProvider.future);
      container.read(searchQueryProvider.notifier).update('iphone');
      final filtered = container.read(filteredReceiptListProvider).value!;

      expect(filtered.length, 1);
      expect(filtered.first.productName, 'Apple iPhone 15');
    });

    test('filters list by store name search query', () async {
      final container = ProviderContainer(
        overrides: [
          receiptListProvider.overrideWith(() => _MockReceiptListNotifier(mockList)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(receiptListProvider.future);
      container.read(searchQueryProvider.notifier).update('samsung store');
      final filtered = container.read(filteredReceiptListProvider).value!;

      expect(filtered.length, 1);
      expect(filtered.first.storeName, 'Samsung Store');
    });

    test('filters list by selected category', () async {
      final container = ProviderContainer(
        overrides: [
          receiptListProvider.overrideWith(() => _MockReceiptListNotifier(mockList)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(receiptListProvider.future);
      container.read(selectedCategoryProvider.notifier).select(Category.pakaian);
      final filtered = container.read(filteredReceiptListProvider).value!;

      expect(filtered.length, 1);
      expect(filtered.first.category, Category.pakaian);
    });

    test('sorts list by newest purchase date', () async {
      final container = ProviderContainer(
        overrides: [
          receiptListProvider.overrideWith(() => _MockReceiptListNotifier(mockList)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(receiptListProvider.future);
      container.read(sortOptionProvider.notifier).select(ReceiptSortOption.newest);
      final list = container.read(filteredReceiptListProvider).value!;

      expect(list.first.productName, 'Jaket Motor Contin'); // 2026-05-01
      expect(list.last.productName, 'Apple iPhone 15'); // 2026-01-10
    });

    test('sorts list by oldest purchase date', () async {
      final container = ProviderContainer(
        overrides: [
          receiptListProvider.overrideWith(() => _MockReceiptListNotifier(mockList)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(receiptListProvider.future);
      container.read(sortOptionProvider.notifier).select(ReceiptSortOption.oldest);
      final list = container.read(filteredReceiptListProvider).value!;

      expect(list.first.productName, 'Apple iPhone 15'); // 2026-01-10
      expect(list.last.productName, 'Jaket Motor Contin'); // 2026-05-01
    });

    test('sorts list alphabetically', () async {
      final container = ProviderContainer(
        overrides: [
          receiptListProvider.overrideWith(() => _MockReceiptListNotifier(mockList)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(receiptListProvider.future);
      container.read(sortOptionProvider.notifier).select(ReceiptSortOption.alphabetical);
      final list = container.read(filteredReceiptListProvider).value!;

      expect(list[0].productName, 'Apple iPhone 15');
      expect(list[1].productName, 'Jaket Motor Contin');
      expect(list[2].productName, 'Samsung Galaxy S24');
    });

    test('sorts list by expiring soonest', () async {
      final container = ProviderContainer(
        overrides: [
          receiptListProvider.overrideWith(() => _MockReceiptListNotifier(mockList)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(receiptListProvider.future);
      container.read(sortOptionProvider.notifier).select(ReceiptSortOption.expiringSoon);
      final list = container.read(filteredReceiptListProvider).value!;

      // Expirations:
      // r3: 2026-06-01 (earliest)
      // r2: 2026-09-15
      // r1: 2027-01-10 (latest)
      expect(list[0].productName, 'Jaket Motor Contin');
      expect(list[1].productName, 'Samsung Galaxy S24');
      expect(list[2].productName, 'Apple iPhone 15');
    });
  });
}

class _MockReceiptListNotifier extends AsyncNotifier<List<Receipt>> implements ReceiptListNotifier {
  final List<Receipt> initial;
  _MockReceiptListNotifier(this.initial);

  @override
  Future<List<Receipt>> build() async => initial;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
