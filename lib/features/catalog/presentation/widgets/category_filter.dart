import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/catalog_provider.dart';

class CategoryFilter extends ConsumerWidget {
  const CategoryFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(
      catalogFilterProvider.select((f) => f.selectedCategory),
    );

    return categoriesAsync.when(
      loading: () => const SizedBox(
        height: 44,
        child: Center(
          child: LinearProgressIndicator(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (categories) => SizedBox(
        height: 44,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = category == selectedCategory;
            return FilterChip(
              label: Text(_formatCategory(category)),
              selected: isSelected,
              onSelected: (_) => ref
                  .read(catalogFilterProvider.notifier)
                  .selectCategory(category),
              showCheckmark: false,
            );
          },
        ),
      ),
    );
  }

  String _formatCategory(String raw) {
    return raw
        .split("'")
        .map((w) => w.isEmpty
        ? w
        : w[0].toUpperCase() + w.substring(1))
        .join("'");
  }
}