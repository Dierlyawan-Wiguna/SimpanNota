import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/receipt_list_notifier.dart';

/// Filter kategori bergaya pill rounded yang elegan dan konsisten
class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    
    // 'Semua' (null) is represented by the first item
    final categoriesList = [null, ...Category.values];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categoriesList.length,
        itemBuilder: (context, index) {
          final cat = categoriesList[index];
          final isSelected = selectedCategory == cat;
          final label = cat == null ? 'Semua' : cat.label;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: 'Filter kategori $label',
              hint: isSelected
                  ? 'Kategori sedang aktif'
                  : 'Ketuk untuk memfilter daftar nota berdasarkan kategori $label',
              child: ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textBody,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primaryBlue,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: isSelected ? AppColors.primaryBlue : AppColors.cardBorder,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onSelected: (bool selected) {
                  if (selected) {
                    ref.read(selectedCategoryProvider.notifier).select(cat);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
