import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/category.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/receipt_list_notifier.dart';

class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    
    // 'Semua' (null) is represented by the first item
    final categoriesList = [null, ...Category.values];

    return SizedBox(
      height: 50,
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
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
              onSelected: (bool selected) {
                if (selected) {
                  ref.read(selectedCategoryProvider.notifier).select(cat);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
