import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/category.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = ['Semua', ...Category.values.map((e) => e.label)];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == 0; // Mock: 'Semua' selected
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: isSelected,
              selectedColor: AppColors.primaryTeal.withValues(alpha: 0.2),
              onSelected: (bool selected) {},
            ),
          );
        },
      ),
    );
  }
}
