import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product_model.dart';
import '../providers/catalog_provider.dart';
import '../widgets/category_filter.dart';
import '../widgets/product_card.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SortSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(catalogFilterProvider);
    final productsAsync = ref.watch(filteredProductsProvider);
    final theme = Theme.of(context);
    final hasActiveFilter =
        filter.selectedCategory != null || filter.searchQuery.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Catalog'),
            floating: true,
            snap: true,
            actions: [
              IconButton(
                tooltip: 'Sort',
                icon: Icon(
                  Icons.sort_rounded,
                  color: filter.sortOrder != SortOrder.none
                      ? theme.colorScheme.primary
                      : null,
                ),
                onPressed: () => _showSortSheet(context),
              ),
              if (hasActiveFilter)
                IconButton(
                  tooltip: 'Clear filters',
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  onPressed: () {
                    ref.read(catalogFilterProvider.notifier).clearAll();
                    _searchController.clear();
                  },
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(104),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SearchBar(
                      controller: _searchController,
                      hintText: 'Search products…',
                      leading: const Icon(Icons.search),
                      trailing: [
                        if (filter.searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(catalogFilterProvider.notifier)
                                  .setSearchQuery('');
                            },
                          ),
                      ],
                      onChanged: (v) =>
                          ref.read(catalogFilterProvider.notifier).setSearchQuery(v),
                    ),
                  ),
                  const CategoryFilter(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          productsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              child: _ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(allProductsProvider),
              ),
            ),
            data: (products) => products.isEmpty
                ? const SliverFillRemaining(child: _EmptyState())
                : _ProductGrid(products: products),
          ),
        ],
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(product: products[index]),
          childCount: products.length,
        ),
      ),
    );
  }
}

class _SortSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(catalogFilterProvider.select((f) => f.sortOrder));
    final theme = Theme.of(context);

    final options = [
      (SortOrder.none, 'Default', Icons.sort_rounded),
      (SortOrder.priceAsc, 'Price: Low to High', Icons.arrow_upward_rounded),
      (SortOrder.priceDesc, 'Price: High to Low', Icons.arrow_downward_rounded),
      (SortOrder.ratingDesc, 'Top Rated', Icons.star_rounded),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Sort by',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ...options.map((entry) {
            final (order, label, icon) = entry;
            return ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: current == order
                  ? Icon(Icons.check_rounded,
                  color: theme.colorScheme.primary)
                  : null,
              selected: current == order,
              onTap: () {
                ref
                    .read(catalogFilterProvider.notifier)
                    .setSortOrder(order);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 72, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('No products found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}