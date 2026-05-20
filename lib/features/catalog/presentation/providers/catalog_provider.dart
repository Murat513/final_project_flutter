import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

enum SortOrder { none, priceAsc, priceDesc, ratingDesc }

class CatalogFilter {
  const CatalogFilter({
    this.selectedCategory,
    this.searchQuery = '',
    this.sortOrder = SortOrder.none,
  });

  final String? selectedCategory;
  final String searchQuery;
  final SortOrder sortOrder;

  CatalogFilter copyWith({
    String? selectedCategory,
    bool clearCategory = false,
    String? searchQuery,
    SortOrder? sortOrder,
  }) {
    return CatalogFilter(
      selectedCategory: clearCategory ? null : selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

final allProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  return ref.watch(productRepositoryProvider).getProducts();
});

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(productRepositoryProvider).getCategories();
});

final catalogFilterProvider =
StateNotifierProvider<CatalogFilterNotifier, CatalogFilter>((ref) {
  return CatalogFilterNotifier();
});

class CatalogFilterNotifier extends StateNotifier<CatalogFilter> {
  CatalogFilterNotifier() : super(const CatalogFilter());

  void selectCategory(String? category) {
    if (state.selectedCategory == category) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortOrder(SortOrder order) {
    state = state.copyWith(sortOrder: order);
  }

  void clearAll() {
    state = const CatalogFilter();
  }
}

final filteredProductsProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  final allAsync = ref.watch(allProductsProvider);
  final filter = ref.watch(catalogFilterProvider);

  return allAsync.whenData((products) {
    var result = products;

    if (filter.selectedCategory != null) {
      result = result
          .where((p) => p.category == filter.selectedCategory)
          .toList();
    }

    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      result = result
          .where((p) =>
      p.title.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q))
          .toList();
    }

    result = List<ProductModel>.from(result);
    switch (filter.sortOrder) {
      case SortOrder.priceAsc:
        result.sort((a, b) => a.price.compareTo(b.price));
      case SortOrder.priceDesc:
        result.sort((a, b) => b.price.compareTo(a.price));
      case SortOrder.ratingDesc:
        result.sort((a, b) => b.rating.compareTo(a.rating));
      case SortOrder.none:
        break;
    }

    return result;
  });
});

final productDetailProvider =
FutureProvider.family<ProductModel, int>((ref, id) async {
  return ref.watch(productRepositoryProvider).getProductById(id);
});